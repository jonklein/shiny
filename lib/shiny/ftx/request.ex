defmodule Shiny.FTX.Request do
  def headers(method, path, body \\ "") do
    ts = timestamp()

    [
      "FTX-KEY": api_key(),
      "FTX-TS": ts,
      "FTX-SIGN": signature(ts, method, path, body)
    ]
  end

  def get(path) do
    {:ok, result} = HTTPoison.get(url(path), headers("GET", path))
    parse_response(result)
  end

  def post(path, data \\ %{}) do
    {:ok, result} = HTTPoison.post(url(path), Jason.encode(data), headers("POST", path, data))
    parse_response(result)
  end

  def put(path, data \\ %{}) do
    {:ok, result} = HTTPoison.put(url(path), URI.encode_query(data), headers("PUT", path, data))
    parse_response(result)
  end

  def delete(path) do
    {:ok, result} = HTTPoison.delete(url(path), headers("DELETE", path))
    parse_response(result)
  end

  defp parse_response(result) when result.status_code >= 400 do
    {:error, result.body}
  end

  defp parse_response(result) do
    Jason.decode(result.body, keys: :atoms)
  end

  defp url(path) do
    "https://ftx.com/api#{path}"
  end

  def signature(timestamp, method, path, body, secret_key \\ secret()) do
    :crypto.mac(
      :hmac,
      :sha256,
      secret_key,
      Integer.to_string(timestamp) <> method <> path <> body
    )
    |> Base.encode16()
    |> String.downcase()
  end

  defp secret() do
    System.get_env("FTX_API_SECRET")
  end

  defp api_key() do
    System.get_env("FTX_API_KEY")
  end

  defp timestamp() do
    (DateTime.utc_now() |> DateTime.to_unix()) * 1000
  end
end

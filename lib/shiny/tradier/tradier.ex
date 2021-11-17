defmodule Breaker.Tradier do
  defmacro environment do
    quote do
      System.get_env("TRADIER_ENVIRONMENT")
    end
  end

  def order(portfolio, order) do
    Breaker.Tradier.Order.create(portfolio, order)
  end

  def get(path) do
    {:ok, result} = Shiny.HttpCache.get(url(path), headers())
    parse_response(result)
  end

  def post(path, data \\ %{}) do
    {:ok, result} = HTTPoison.post(url(path), URI.encode_query(data), headers())
    parse_response(result)
  end

  def put(path, data \\ %{}) do
    {:ok, result} = HTTPoison.put(url(path), URI.encode_query(data), headers())
    parse_response(result)
  end

  def delete(path) do
    {:ok, result} = HTTPoison.delete(url(path), headers())
    parse_response(result)
  end

  defp parse_response(result) when result.status_code >= 400 do
    {:error, result.body}
  end

  defp parse_response(result) do
    Jason.decode(result.body, keys: :atoms)
  end

  defp url(path) do
    url(path, System.get_env("TRADIER_ENVIRONMENT"))
  end

  defp url(path, "sandbox") do
    "https://sandbox.tradier.com#{path}"
  end

  defp url(path, _) do
    "https://api.tradier.com#{path}"
  end

  defp access_token() do
    access_token(System.get_env("TRADIER_ENVIRONMENT"))
  end

  defp access_token("sandbox") do
    System.get_env("TRADIER_SANDBOX_ACCESS_TOKEN")
  end

  defp access_token(_) do
    System.get_env("TRADIER_ACCESS_TOKEN")
  end

  defp headers do
    [
      Authorization: "Bearer #{access_token()}",
      Accept: "application/json"
    ]
  end
end

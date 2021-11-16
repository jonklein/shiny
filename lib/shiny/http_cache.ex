defmodule Shiny.HttpCache do
  require Logger

  def get!(url) do
    :dets.open_file(:url_cache, [])

    case :dets.lookup(:url_cache, url) do
      [] ->
        IO.inspect("#{url} not found in cache")
        response = HTTPoison.get!(url)
        :dets.insert(:url_cache, {url, response})
        :dets.close(:url_cache)
        response

      [{url, value}] ->
        Logger.info("Using #{url} from cache")
        value
    end
  end
end

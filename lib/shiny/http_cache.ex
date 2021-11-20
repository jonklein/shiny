defmodule Shiny.HttpCache do
  require Logger

  def get(url, headers \\ []) do
    :dets.open_file(:url_cache, [])

    case :dets.lookup(:url_cache, Base.encode64(url)) do
      [] ->
        Logger.debug("#{url} not found in cache")
        response = HTTPoison.get(url, headers)
        :dets.insert(:url_cache, {Base.encode64(url), response})
        :dets.close(:url_cache)
        response

      [{_, value}] ->
        Logger.debug("#{url} found in cache")
        value
    end
  end
end

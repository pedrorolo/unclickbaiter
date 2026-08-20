defmodule Unclickbaiter.PreviewMetadata.HTTP do
  @moduledoc """
  Fetches the preview metadata of a given URL.

  Uses `Unclickbaiter.PreviewMetadata.HTTP.Simple` to fetch and parse the page.
  When that fails, falls back to the jsonlink.io API via
  `Unclickbaiter.PreviewMetadata.HTTP.JsonLink`, and finally to the opengraph.io
  API via `Unclickbaiter.PreviewMetadata.HTTP.OpenGraphIO`.

  When a fallback provider succeeds for a domain, it is cached in
  `Unclickbaiter.PreviewMetadata.HTTP.ProviderCache`, so later fetches for the
  same domain go straight to the cached provider, skipping the providers that
  failed before.
  """

  alias Unclickbaiter.PreviewMetadata.HTTP.JsonLink
  alias Unclickbaiter.PreviewMetadata.HTTP.OpenGraphIO
  alias Unclickbaiter.PreviewMetadata.HTTP.ProviderCache
  alias Unclickbaiter.PreviewMetadata.HTTP.Simple

  @doc """
  Fetches `url` and returns `{:ok, %PreviewMetadata{}}` with the extracted
  metadata, or `{:error, reason}`.
  """
  def fetch(url) when is_binary(url) do
    host = URI.parse(url).host

    case host && ProviderCache.get(String.downcase(host)) do
      nil -> fetch_chain(url, host)
      provider -> provider.fetch(url)
    end
  end

  def fetch(_url), do: {:error, :invalid_url}

  defp fetch_chain(url, host) do
    case Simple.get(url) do
      {:ok, response, final_url} ->
        {:ok, Simple.parse(response.body, final_url)}

      {:error, _reason} ->
        json_link_fallback(url, host)
    end
  rescue
    _exception -> json_link_fallback(url, host)
  end

  defp json_link_fallback(url, host) do
    case JsonLink.fetch(url) do
      {:ok, _pm} = ok ->
        cache(host, JsonLink)
        ok

      # we want this fallback to be here as we have only
      # 100 requests to this service, requiring a fallback
      # even when the provider is cached
      {:error, _reason} ->
        opengraph_fallback(url, host)
    end
  end

  defp opengraph_fallback(url, host) do
    case OpenGraphIO.fetch(url) do
      {:ok, _pm} = ok ->
        cache(host, OpenGraphIO)
        ok

      {:error, _reason} = error ->
        error
    end
  end

  defp cache(nil, _provider), do: :ok

  defp cache(host, provider),
    do: ProviderCache.put_if_new(String.downcase(host), provider)

  @doc """
  Returns true when `url` is fetchable, i.e. it has an http/https scheme
  and a non-empty host.
  """
  def fetchable_url?(url) do
    case URI.parse(url) do
      %URI{scheme: scheme, host: host} when scheme in ["http", "https"] ->
        is_binary(host) and host != ""

      _ ->
        false
    end
  end
end

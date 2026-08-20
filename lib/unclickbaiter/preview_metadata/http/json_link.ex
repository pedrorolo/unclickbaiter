defmodule Unclickbaiter.PreviewMetadata.HTTP.JsonLink do
  @moduledoc """
  Fetches preview metadata from the jsonlink.io API.

  Used as a fallback by `Unclickbaiter.PreviewMetadata.HTTP` when fetching
  the site directly fails. The opengraph.io fallback for this module lives in
  `Unclickbaiter.PreviewMetadata.HTTP`. The API key is stored in the encrypted
  secrets file (`config/secrets/secrets.yml.enc`) and read via the `:secrets`
  application environment.
  """

  alias Unclickbaiter.PreviewMetadata.PreviewMetadata

  @user_agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
  @api_url "https://jsonlink.io/api/extract"

  @doc """
  Fetches `url` through the jsonlink.io API and returns `{:ok, %PreviewMetadata{}}`
  with the extracted metadata, or `{:error, reason}`.
  """
  def fetch(url) when is_binary(url) do
    api_url = @api_url <> "?" <> URI.encode_query(url: url, api_key: api_key())

    case request(
           url: api_url,
           receive_timeout: 10_000,
           headers: [{"user-agent", @user_agent}]
         ) do
      {:ok, %{body: body}} when is_map(body) ->
        metadata = %PreviewMetadata{
          title: normalize(body["title"]),
          description: normalize(body["description"]),
          image_url:
            normalize(body["image"] || List.first(body["images"] || []))
        }

        if metadata.title == nil and metadata.description == nil and
             metadata.image_url == nil do
          {:error, :empty_metadata}
        else
          {:ok, metadata}
        end

      {:ok, _response} ->
        {:error, :invalid_response}

      {:error, reason} ->
        {:error, reason}
    end
  rescue
    exception -> {:error, exception}
  end

  def fetch(_url), do: {:error, :invalid_url}

  defp api_key do
    Application.get_env(:unclickbaiter, :secrets)[:json_link_api_key]
  end

  defp normalize(nil), do: nil
  defp normalize(""), do: nil
  defp normalize(value), do: String.trim(value)

  defp request(options) do
    options =
      options
      |> Keyword.put(:retry, false)
      |> Keyword.merge(Application.get_env(:unclickbaiter, :req_options, []))

    case Req.Request.run_request(Req.new(options)) do
      {_request, %{status: status} = response} when status in 200..299 ->
        {:ok, response}

      {_request, %{status: status}} ->
        {:error, {:http_error, status}}

      {_request, %{__exception__: true} = exception} ->
        {:error, exception}
    end
  end
end

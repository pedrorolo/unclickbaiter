defmodule Unclickbaiter.PreviewMetadata.HTTP.OpenGraphIO do
  @moduledoc """
  Fetches preview metadata from the opengraph.io API.

  Used as a fallback by `Unclickbaiter.PreviewMetadata.HTTP.JsonLink` when the
  jsonlink.io API fails. Requests use the API's residential and mobile proxies
  with JavaScript rendering enabled to circumvent bot protection. The API key
  is stored in the encrypted secrets file (`priv/secrets/secrets.yml.enc`)
  and read via the `:secrets` application environment.
  """

  alias Unclickbaiter.PreviewMetadata.PreviewMetadata

  @user_agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
  @api_url "https://opengraph.io/api/3.0/site/"

  @doc """
  Fetches `url` through the opengraph.io API and returns `{:ok, %PreviewMetadata{}}`
  with the extracted metadata, or `{:error, reason}`.
  """
  def fetch(url) when is_binary(url) do
    api_url =
      @api_url <> URI.encode_www_form(url) <> "?" <> URI.encode_query(params())

    case request(
           url: api_url,
           receive_timeout: 30_000,
           headers: [{"user-agent", @user_agent}]
         ) do
      {:ok, %{body: body}} when is_map(body) ->
        {:ok,
         %PreviewMetadata{
           title: extract(body, "title"),
           description: extract(body, "description"),
           image_url: extract_image(body)
         }}

      {:ok, _response} ->
        {:error, :invalid_response}

      {:error, reason} ->
        {:error, reason}
    end
  rescue
    exception -> {:error, exception}
  end

  def fetch(_url), do: {:error, :invalid_url}

  defp params do
    [
      app_id: api_key(),
      cache_ok: false,
      retry: true,
      auto_proxy: true,
      auto_render: true,
      use_premium: true,
      use_superior: true,
      full_render: true
    ]
  end

  defp api_key do
    Application.get_env(:unclickbaiter, :secrets)[:open_graph_io_api_key]
  end

  defp extract(body, key) do
    Enum.find_value(
      ["hybridGraph", "openGraph", "htmlInferred"],
      nil,
      fn section ->
        case body[section] do
          %{} = value when map_size(value) > 0 -> value[key]
          _ -> nil
        end
      end
    )
  end

  defp extract_image(body) do
    case extract(body, "image") do
      %{"url" => url} when is_binary(url) and url != "" -> url
      url when is_binary(url) and url != "" -> url
      _ -> nil
    end
  end

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

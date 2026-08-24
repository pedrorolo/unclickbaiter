defmodule Unclickbaiter.PreviewMetadata.HTTP.Simple do
  @moduledoc """
  Fetches the HTML of a given URL (following redirects) and extracts the
  OpenGraph/Twitter preview metadata from it.

  Used by `Unclickbaiter.PreviewMetadata.HTTP` before falling back to the
  jsonlink.io API.
  """

  alias Unclickbaiter.PreviewMetadata.PreviewMetadata

  @user_agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"

  @doc """
  Fetches `url` and returns `{:ok, response, final_url}` after following
  redirects, or `{:error, reason}`.
  """
  def get(url) do
    request(
      url: url,
      max_redirects: 5,
      receive_timeout: 10_000,
      headers: [{"user-agent", @user_agent}]
    )
  end

  @doc """
  Parses the given HTML and returns a `%PreviewMetadata{}` with the extracted
  metadata. `url` is used to resolve relative image URLs.
  """
  def parse(html, url) do
    {:ok, document} = Floki.parse_document(html)

    %PreviewMetadata{
      title: normalize(meta_content(document, "og:title") || title(document)),
      description:
        normalize(
          meta_content(document, "og:description") ||
            meta_content(document, "description")
        ),
      image_url: normalize(image_url(document, url))
    }
  end

  defp request(options) do
    options =
      options
      |> Keyword.put(:retry, false)
      |> Keyword.merge(Application.get_env(:unclickbaiter, :req_options, []))

    case Req.Request.run_request(Req.new(options)) do
      {request, %{status: status} = response} when status in 200..299 ->
        cond do
          challenged?(response) ->
            {:error, {:challenge, URI.to_string(request.url)}}

          empty_body?(response.body) ->
            {:error, :empty_body}

          true ->
            {:ok, response, URI.to_string(request.url)}
        end

      {_request, %{status: status}} ->
        {:error, {:http_error, status}}

      {_request, %{__exception__: true} = exception} ->
        {:error, exception}
    end
  end

  defp empty_body?(body) when is_binary(body), do: String.trim(body) == ""
  defp empty_body?(_body), do: false

  defp challenged?(%{headers: headers}) do
    case headers["x-amzn-waf-action"] do
      ["challenge" | _] -> true
      ["captcha" | _] -> true
      _ -> false
    end
  end

  defp title(document) do
    case Floki.find(document, "title") do
      [title | _] -> Floki.text(title)
      _ -> nil
    end
  end

  defp meta_content(document, key) do
    Enum.find_value(["property", "name"], fn attr ->
      case Floki.attribute(document, ~s(meta[#{attr}="#{key}"]), "content") do
        [content | _] -> content
        _ -> nil
      end
    end)
  end

  defp image_url(document, base_url) do
    with url when is_binary(url) <- meta_content(document, "og:image") do
      if String.starts_with?(url, "http") do
        url
      else
        base_url |> URI.merge(url) |> URI.to_string()
      end
    end
  end

  defp normalize(nil), do: nil
  defp normalize(""), do: nil
  defp normalize(value), do: String.trim(value)
end

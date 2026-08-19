defmodule Unclickbaiter.PreviewMetadata.HTTP.Parser do
  @moduledoc """
  Parses HTML and extracts the OpenGraph/Twitter preview metadata from it.
  """

  alias Unclickbaiter.PreviewMetadata.PreviewMetadata

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

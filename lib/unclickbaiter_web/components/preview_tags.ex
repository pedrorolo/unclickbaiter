defmodule UnclickbaiterWeb.Components.PreviewTags do
  @moduledoc """
  Function component to render OpenGraph/Twitter meta tags.

  Accepts a map of metadata (title, description, url, image, site_name,
  type, twitter_card) and renders them as meta tags.
  """

  use Phoenix.Component

  @default_site_name "unclickbaiter"
  @default_description "Share links with custom OpenGraph metadata — bringing awareness to clickbaits as a form of misinformation and disinformation."
  @default_type "website"
  @default_twitter_card "summary_large_image"

  attr :metadata, :map, default: nil

  def preview_tags(assigns) do
    metadata = assigns.metadata || default_metadata()
    assigns = assign(assigns, :tags, to_meta_tags(metadata))

    ~H"""
    <%!-- Render each meta tag, using property for og:* and name for others --%>
    <%= for {name, content} <- @tags do %>
      <%= if String.starts_with?(name, "og:") do %>
        <meta property={name} content={content} />
      <% else %>
        <meta name={name} content={content} />
      <% end %>
    <% end %>
    """
  end

  @doc """
  Convert a metadata map to a list of meta tag tuples.

  Filters out nil and empty string values.

  ## Examples

      iex> to_meta_tags(%{
      ...>   title: "My Site",
      ...>   description: "My description",
      ...>   image: "https://example.com/img.png"
      ...> })
      [
        {"description", "My description"},
        {"image", "https://example.com/img.png"},
        {"og:type", "website"},
        {"og:title", "My Site"},
        {"twitter:card", "summary_large_image"},
        {"twitter:title", "My Site"}
      ]
  """
  @spec to_meta_tags(map()) :: [{String.t(), String.t()}]
  def to_meta_tags(metadata) do
    metadata = Map.merge(default_metadata(), metadata)

    [
      {"description", metadata[:description]},
      {"image", metadata[:image]},
      {"og:type", metadata[:type]},
      {"og:title", metadata[:title]},
      {"og:description", metadata[:description]},
      {"og:url", metadata[:url]},
      {"og:site_name", metadata[:site_name]},
      {"og:image", metadata[:image]},
      {"twitter:card", metadata[:twitter_card]},
      {"twitter:title", metadata[:title]},
      {"twitter:description", metadata[:description]},
      {"twitter:image", metadata[:image]}
    ]
    |> Enum.filter(fn {_k, v} -> not is_nil(v) and v != "" end)
  end

  defp default_metadata do
    %{
      title: @default_site_name,
      description: @default_description,
      site_name: @default_site_name,
      type: @default_type,
      twitter_card: @default_twitter_card
    }
  end
end

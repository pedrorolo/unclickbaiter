defmodule UnclickbaiterWeb.PreviewMetadata do
  use Phoenix.Component

  @moduledoc """
  Render OpenGraph and Twitter meta tags from assigns.

  This module embeds a small OpenGraph struct and helpers directly so
  there's no separate OpenGraph module.

  Accepts either:
    * :og - a %UnclickbaiterWeb.PreviewMetadata{} struct representing OG data
    * :site - a %Unclickbaiter.Sites.Site{} struct (converted via from_site/2)
    * page_title, page_description, page_image_url assigns (fallback)
  """

  @derive {Inspect, only: [:title, :description, :url, :image, :site_name]}
  defstruct [
    :title,
    :description,
    :url,
    :image,
    :site_name,
    :type,
    :twitter_card
  ]

  @type t :: %__MODULE__{
          title: String.t() | nil,
          description: String.t() | nil,
          url: String.t() | nil,
          image: String.t() | nil,
          site_name: String.t() | nil,
          type: String.t() | nil,
          twitter_card: String.t() | nil
        }

  @doc """
  Create a new OG struct (PreviewMetadata struct) from attrs.
  """
  @spec new(map() | keyword()) :: t()
  def new(attrs \\ %{}) do
    struct(__MODULE__, attrs)
  end

  @doc """
  Build an OG struct from a Site struct.
  """
  @spec from_site(Unclickbaiter.Sites.Site.t(), keyword()) :: t()
  def from_site(%Unclickbaiter.Sites.Site{} = site, opts \\ []) do
    %__MODULE__{
      title: site.title,
      description: site.description,
      url: site.url,
      image: site.image_url,
      site_name: Keyword.get(opts, :site_name),
      type: Keyword.get(opts, :type, "website"),
      twitter_card: Keyword.get(opts, :twitter_card, "summary_large_image")
    }
  end

  @doc """
  Convert an OG struct into a list of {name, content} tuples
  suitable for rendering meta tags in templates. Filters out nil/empty values.
  """
  @spec to_meta_tags(t()) :: [{String.t(), String.t()}]
  def to_meta_tags(%__MODULE__{} = og) do
    [
      {"og:type", og.type},
      {"og:title", og.title},
      {"og:description", og.description},
      {"og:url", og.url},
      {"og:site_name", og.site_name},
      {"og:image", og.image},
      {"twitter:card", og.twitter_card},
      {"twitter:title", og.title},
      {"twitter:description", og.description},
      {"twitter:image", og.image}
    ]
    |> Enum.filter(fn {_k, v} -> not is_nil(v) and v != "" end)
  end

  def meta_tags(assigns) do
    og = build_og_from_assigns(assigns)
    assigns = Map.put(assigns, :og, og)

    ~H"""
    <%!-- Render each meta tag, using property for og:* and name for others --%>
    <%= for {name, content} <- to_meta_tags(@og) do %>
      <%= if String.starts_with?(name, "og:") do %>
        <meta property={name} content={content} />
      <% else %>
        <meta name={name} content={content} />
      <% end %>
    <% end %>
    """
  end

  defp build_og_from_assigns(assigns) do
    cond do
      assigns[:og] ->
        assigns.og

      assigns[:site] ->
        from_site(assigns.site)

      assigns[:page_title] || assigns[:page_description] ||
          assigns[:page_image_url] ->
        new(%{
          title: assigns[:page_title],
          description: assigns[:page_description],
          url: assigns[:page_url] || nil,
          image: assigns[:page_image_url] || nil,
          type: "website",
          twitter_card: "summary_large_image"
        })

      true ->
        new()
    end
  end
end

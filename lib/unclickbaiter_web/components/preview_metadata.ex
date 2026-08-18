defmodule UnclickbaiterWeb.PreviewMetadata do
  @moduledoc """
  Function component to render preview OpenGraph/Twitter meta tags.

  Can accept individual fields as component attrs (title, description, url,
  image, site_name, type, twitter_card) or be passed a struct via the
  assigns in templates (assigns[:preview_metadata]).
  """

  use Phoenix.Component

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
    defaults = %{type: "website", twitter_card: "summary_large_image"}
    struct(__MODULE__, Map.merge(defaults, Map.new(attrs)))
  end

  @spec to_meta_tags(t()) :: [{String.t(), String.t()}]
  def to_meta_tags(%__MODULE__{} = preview_metadata) do
    [
      {"og:type", preview_metadata.type},
      {"og:title", preview_metadata.title},
      {"og:description", preview_metadata.description},
      {"og:url", preview_metadata.url},
      {"og:site_name", preview_metadata.site_name},
      {"og:image", preview_metadata.image},
      {"twitter:card", preview_metadata.twitter_card},
      {"twitter:title", preview_metadata.title},
      {"twitter:description", preview_metadata.description},
      {"twitter:image", preview_metadata.image}
    ]
    |> Enum.filter(fn {_k, v} -> not is_nil(v) and v != "" end)
  end

  attr :preview_metadata, :map, default: nil

  def preview_metadata(assigns) do
    assigns = assign_new(assigns, :preview_metadata, fn -> nil end)

    attrs =
      case assigns.preview_metadata do
        %_{} = struct -> Map.from_struct(struct)
        m when is_map(m) -> m
        _ -> %{}
      end

    og = new(attrs)

    assigns = assign(assigns, :tags, to_meta_tags(og))

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
end

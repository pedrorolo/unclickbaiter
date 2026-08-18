defmodule UnclickbaiterWeb.OpenGraph do
  @moduledoc """
  Small OpenGraph struct and helpers used for rendering preview metadata.
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
  Create a new OpenGraph struct from a map of attrs.
  """
  @spec new(map() | keyword()) :: t()
  def new(attrs \\ %{}) do
    struct(__MODULE__, attrs)
  end

  @doc """
  Build an OpenGraph struct from a Site struct.

  Options:
    * :site_name - a string to use as og:site_name (optional)
    * :type - og:type (defaults to "website")
    * :twitter_card - twitter:card (defaults to "summary_large_image")
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
  Convert an OpenGraph struct into a list of {name, content} tuples
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
end

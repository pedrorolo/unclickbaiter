defmodule Unclickbaiter.Sites.Site do
  use Ecto.Schema
  import Ecto.Changeset

  alias Unclickbaiter.PreviewMetadata.PreviewMetadata

  schema "sites" do
    field :url, :string

    belongs_to :preview_metadata, PreviewMetadata, on_replace: :delete
    belongs_to :original_preview_metadata, PreviewMetadata, on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(site, attrs) do
    site
    |> cast(attrs, [:url])
    |> validate_required([:url])
    |> cast_assoc(:preview_metadata, required: true)
    |> cast_assoc(:original_preview_metadata)
  end
end

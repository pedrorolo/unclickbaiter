defmodule Unclickbaiter.PreviewMetadata.PreviewMetadata do
  @moduledoc """
  Schema for the preview metadata of a preview.

  Holds the fields used to build the OpenGraph/Twitter preview metadata
  for a preview: title, description and image_url.
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false

  alias Unclickbaiter.Previews.Preview
  alias Unclickbaiter.Repo

  schema "preview_metadata" do
    field :title, :string
    field :description, :string
    field :image_url, :string

    has_many :previews, Preview, foreign_key: :original_preview_metadata_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(preview_metadata, attrs) do
    preview_metadata
    |> cast(attrs, [:title, :description, :image_url])
    |> validate_required([:title, :description])
  end

  @doc """
  Returns the number of previews referencing the preview metadata with the
  given `id` as their `original_preview_metadata`.
  """
  def referencing_previews_count(id) when is_integer(id) do
    Repo.aggregate(
      from(s in Preview, where: s.original_preview_metadata_id == ^id),
      :count
    )
  end
end

defmodule Unclickbaiter.PreviewMetadata do
  @moduledoc """
  Schema for the preview metadata of a site.

  Holds the fields used to build the OpenGraph/Twitter preview metadata
  for a site: title, description and image_url.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "preview_metadata" do
    field :title, :string
    field :description, :string
    field :image_url, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(preview_metadata, attrs) do
    preview_metadata
    |> cast(attrs, [:title, :description, :image_url])
    |> validate_required([:title, :description])
  end
end

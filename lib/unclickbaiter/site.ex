defmodule Unclickbaiter.Site do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sites" do
    field :url, :string
    field :title, :string
    field :description, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(site, attrs) do
    site
    |> cast(attrs, [:url, :title, :description])
    |> validate_required([:url, :title, :description])
  end
end

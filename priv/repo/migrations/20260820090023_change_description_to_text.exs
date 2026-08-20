defmodule Unclickbaiter.Repo.Migrations.ChangeDescriptionToText do
  use Ecto.Migration

  def change do
    alter table(:preview_metadata) do
      modify :description, :text, from: :string
      modify :image_url, :text, from: :string
    end

    alter table(:sites) do
      modify :url, :text, from: :string
    end
  end
end

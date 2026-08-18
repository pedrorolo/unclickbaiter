defmodule Unclickbaiter.Repo.Migrations.AddImageUrlToSites do
  use Ecto.Migration

  def change do
    alter table(:sites) do
      add :image_url, :string
    end
  end
end

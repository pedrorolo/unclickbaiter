defmodule Unclickbaiter.Repo.Migrations.CreateSites do
  use Ecto.Migration

  def change do
    create table(:sites) do
      add :url, :string
      add :title, :string
      add :description, :string

      timestamps(type: :utc_datetime)
    end
  end
end

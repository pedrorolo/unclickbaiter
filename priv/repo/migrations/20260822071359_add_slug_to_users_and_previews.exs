defmodule Unclickbaiter.Repo.Migrations.AddSlugToUsersAndPreviews do
  use Ecto.Migration

  def up do
    alter table(:users) do
      add :slug, :string
    end

    alter table(:previews) do
      add :slug, :string
    end

    create unique_index(:users, [:slug])
    create unique_index(:previews, [:slug])
  end

  def down do
    drop unique_index(:users, [:slug])
    drop unique_index(:previews, [:slug])

    alter table(:users) do
      remove :slug
    end

    alter table(:previews) do
      remove :slug
    end
  end
end

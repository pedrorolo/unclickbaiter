defmodule Unclickbaiter.Repo.Migrations.RemoveSlugFromUsers do
  use Ecto.Migration

  def change do
    drop_if_exists index(:users, [:slug])

    alter table(:users) do
      remove :slug
    end
  end
end

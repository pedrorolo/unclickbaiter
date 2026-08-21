defmodule Unclickbaiter.Repo.Migrations.RemovePasswordFromUsers do
  use Ecto.Migration

  def up do
    alter table(:users) do
      remove :hashed_password
    end
  end

  def down do
    alter table(:users) do
      add :hashed_password, :string
    end
  end
end

defmodule Unclickbaiter.Repo.Migrations.RenameSitesToPreviews do
  use Ecto.Migration

  def change do
    rename table(:sites), to: table(:previews)
  end
end

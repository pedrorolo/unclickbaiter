defmodule Unclickbaiter.Repo.Migrations.CreatePreviewMetadata do
  use Ecto.Migration

  def up do
    create table(:preview_metadata) do
      add :title, :string
      add :description, :string
      add :image_url, :string

      timestamps(type: :utc_datetime)
    end

    execute("TRUNCATE TABLE sites RESTART IDENTITY")

    alter table(:sites) do
      add :preview_metadata_id, references(:preview_metadata, on_delete: :nilify_all)
      add :original_preview_metadata_id, references(:preview_metadata, on_delete: :nilify_all)
    end

    alter table(:sites) do
      remove :title
      remove :description
      remove :image_url
    end
  end

  def down do
    alter table(:sites) do
      add :title, :string
      add :description, :string
      add :image_url, :string
    end

    alter table(:sites) do
      remove :preview_metadata_id
      remove :original_preview_metadata_id
    end

    drop table(:preview_metadata)
  end
end

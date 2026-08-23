defmodule Unclickbaiter.Repo.Migrations.AddUserIdToPreviews do
  use Ecto.Migration

  def up do
    alter table(:previews) do
      add :user_id, references(:users, on_delete: :delete_all)
    end

    flush()

    execute """
    UPDATE previews
    SET user_id = (SELECT id FROM users WHERE email = 'pedrorolo@gmail.com' LIMIT 1)
    WHERE user_id IS NULL
    """

    alter table(:previews) do
      modify :user_id, :bigint, null: false
    end

    create index(:previews, [:user_id])
  end

  def down do
    drop index(:previews, [:user_id])

    alter table(:previews) do
      remove :user_id
    end
  end
end

defmodule Unclickbaiter.Repo.Migrations.BackfillSlugsForExistingRecords do
  use Ecto.Migration

  import Ecto.Query

  alias Unclickbaiter.Slug

  def up do
    backfill(Unclickbaiter.Accounts.User)
    backfill(Unclickbaiter.Previews.Preview)
  end

  def down do
    execute("UPDATE users SET slug = NULL")
    execute("UPDATE previews SET slug = NULL")
  end

  defp backfill(schema) do
    schema
    |> where([s], is_nil(s.slug))
    |> select([s], s.id)
    |> repo().all()
    |> Enum.each(fn id ->
      {:ok, slug} = Unclickbaiter.Slug.unique_slug(schema)

      repo().update_all(
        from(s in schema, where: s.id == ^id),
        set: [slug: slug]
      )
    end)
  end
end

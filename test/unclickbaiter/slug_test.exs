defmodule Unclickbaiter.SlugTest do
  use Unclickbaiter.DataCase

  import Ecto.Changeset
  import Unclickbaiter.AccountsFixtures

  alias Unclickbaiter.PreviewMetadata.PreviewMetadata
  alias Unclickbaiter.Previews.Preview
  alias Unclickbaiter.Repo
  alias Unclickbaiter.Slug

  describe "unique_slug/2" do
    test "returns a slug of the requested length" do
      {:ok, slug} = Slug.unique_slug(Preview, length: 5)
      assert String.length(slug) == 5
    end

    test "avoids a slug already present in the database" do
      {:ok, taken} = Slug.unique_slug(Preview, length: 5)
      insert_preview_with_slug(taken)

      {:ok, slug} = Slug.unique_slug(Preview, length: 5)

      assert slug != taken
      assert String.length(slug) == 5
    end
  end

  describe "with_new_slug/3" do
    test "assigns a slug and runs the callback" do
      user = user_fixture()

      {:ok, preview} =
        Slug.with_new_slug(Preview, fn changeset ->
          changeset
          |> change(url: "https://example.com", user_id: user.id)
          |> Ecto.Changeset.cast_assoc(:preview_metadata,
            with: &PreviewMetadata.changeset/2
          )
          |> Ecto.Changeset.put_assoc(:preview_metadata, %{
            title: "Title",
            description: "Desc"
          })
          |> Repo.insert()
        end)

      assert String.length(preview.slug) == 5
    end

    test "honors a custom length" do
      user = user_fixture()

      {:ok, preview} =
        Slug.with_new_slug(
          Preview,
          fn changeset ->
            changeset
            |> change(url: "https://example.com", user_id: user.id)
            |> Ecto.Changeset.cast_assoc(:preview_metadata,
              with: &PreviewMetadata.changeset/2
            )
            |> Ecto.Changeset.put_assoc(:preview_metadata, %{
              title: "Title",
              description: "Desc"
            })
            |> Repo.insert()
          end,
          length: 3
        )

      assert String.length(preview.slug) == 3
    end
  end

  defp insert_preview_with_slug(slug) do
    user = user_fixture()

    %Preview{}
    |> change(url: "https://example.com", slug: slug, user_id: user.id)
    |> Ecto.Changeset.cast_assoc(:preview_metadata,
      with: &PreviewMetadata.changeset/2
    )
    |> Ecto.Changeset.put_assoc(:preview_metadata, %{
      title: "T",
      description: "D"
    })
    |> Repo.insert!()
  end
end

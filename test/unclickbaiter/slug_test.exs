defmodule Unclickbaiter.SlugTest do
  use Unclickbaiter.DataCase

  import Ecto.Changeset
  import Unclickbaiter.AccountsFixtures

  alias Unclickbaiter.Accounts.User
  alias Unclickbaiter.Repo
  alias Unclickbaiter.Slug

  describe "unique_slug/2" do
    test "returns a slug of the requested length" do
      {:ok, slug} = Slug.unique_slug(User, length: 5)
      assert String.length(slug) == 5
    end

    test "avoids a slug already present in the database" do
      {:ok, taken} = Slug.unique_slug(User, length: 5)
      insert_user_with_slug(taken)

      {:ok, slug} = Slug.unique_slug(User, length: 5)

      assert slug != taken
      assert String.length(slug) == 5
    end
  end

  describe "with_new_slug/3" do
    test "assigns a slug and runs the callback" do
      {:ok, user} =
        Slug.with_new_slug(User, fn changeset ->
          changeset |> change(email: unique_user_email()) |> Repo.insert()
        end)

      assert String.length(user.slug) == 5
    end

    test "honors a custom length" do
      {:ok, user} =
        Slug.with_new_slug(
          User,
          fn changeset ->
            changeset |> change(email: unique_user_email()) |> Repo.insert()
          end,
          length: 3
        )

      assert String.length(user.slug) == 3
    end
  end

  defp insert_user_with_slug(slug) do
    %User{}
    |> change(email: unique_user_email())
    |> put_change(:confirmed_at, DateTime.utc_now(:second))
    |> put_change(:slug, slug)
    |> Repo.insert!()
  end
end

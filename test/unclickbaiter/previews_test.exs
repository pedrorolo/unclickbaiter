defmodule Unclickbaiter.SitesTest do
  use Unclickbaiter.DataCase

  alias Unclickbaiter.Previews

  describe "previews" do
    alias Unclickbaiter.Previews.Preview

    import Unclickbaiter.AccountsFixtures
    import Unclickbaiter.PreviewsFixtures

    @invalid_attrs %{
      url: nil,
      preview_metadata: %{description: nil, title: nil}
    }

    setup do
      user = user_fixture()
      scope = user_scope_fixture(user)
      %{user: user, scope: scope}
    end

    test "list_previews/1 returns all previews for the scope", %{scope: scope} do
      preview = preview_fixture(%{user_id: scope.user.id})
      {previews, _pagination} = Previews.list_previews(scope)
      assert length(previews) == 1
      assert hd(previews).id == preview.id
    end

    test "get_preview!/1 returns the preview with given id" do
      preview = preview_fixture()
      result = Previews.get_preview!(preview.id)
      assert result.id == preview.id
      assert result.url == preview.url
      assert result.slug == preview.slug
      assert result.user_id == preview.user_id
      assert result.preview_metadata_id == preview.preview_metadata_id
    end

    test "create_preview/2 with valid data creates a preview", %{scope: scope} do
      valid_attrs = %{
        url: "some url",
        preview_metadata: %{
          description: "some description",
          title: "some title"
        }
      }

      assert {:ok, %Preview{} = preview} =
               Previews.create_preview(scope, valid_attrs)

      assert preview.url == "some url"
      assert preview.preview_metadata.description == "some description"
      assert preview.preview_metadata.title == "some title"
      assert preview.slug
      assert String.length(preview.slug) == 5
      assert preview.user_id == scope.user.id
    end

    test "create_preview/2 with original_preview_metadata stores both metadata records",
         %{scope: scope} do
      attrs = %{
        url: "some url",
        preview_metadata: %{
          description: "some description",
          title: "some title"
        },
        original_preview_metadata: %{
          description: "original description",
          title: "original title",
          image_url: "https://example.com/original.png"
        }
      }

      assert {:ok, %Preview{} = preview} = Previews.create_preview(scope, attrs)
      assert preview.preview_metadata.title == "some title"
      assert preview.original_preview_metadata.title == "original title"

      assert preview.original_preview_metadata.image_url ==
               "https://example.com/original.png"
    end

    test "create_preview/2 with invalid data returns error changeset", %{
      scope: scope
    } do
      assert {:error, %Ecto.Changeset{}} =
               Previews.create_preview(scope, @invalid_attrs)
    end

    test "update_preview/2 with valid data updates the preview" do
      preview = preview_fixture()

      update_attrs = %{
        url: "some updated url",
        preview_metadata: %{
          description: "some updated description",
          title: "some updated title"
        }
      }

      assert {:ok, %Preview{} = preview} =
               Previews.update_preview(preview, update_attrs)

      assert preview.url == "some updated url"
      assert preview.preview_metadata.description == "some updated description"
      assert preview.preview_metadata.title == "some updated title"
    end

    test "update_preview/2 with invalid data returns error changeset" do
      preview = preview_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Previews.update_preview(preview, @invalid_attrs)

      result = Previews.get_preview!(preview.id)
      assert result.url == preview.url
      assert result.slug == preview.slug
    end

    test "delete_preview/1 deletes the preview" do
      preview = preview_fixture()
      assert {:ok, %Preview{}} = Previews.delete_preview(preview)

      assert_raise Ecto.NoResultsError, fn ->
        Previews.get_preview!(preview.id)
      end
    end

    test "delete_preview/1 deletes the preview metadata records" do
      preview = preview_fixture()

      {:ok, preview} =
        Previews.update_preview(preview, %{
          original_preview_metadata: %{
            title: "original title",
            description: "original description"
          }
        })

      pm = preview.preview_metadata
      original_pm = preview.original_preview_metadata

      assert {:ok, %Preview{}} = Previews.delete_preview(preview)

      assert_raise Ecto.NoResultsError, fn ->
        Repo.get!(Unclickbaiter.PreviewMetadata.PreviewMetadata, pm.id)
      end

      assert_raise Ecto.NoResultsError, fn ->
        Repo.get!(Unclickbaiter.PreviewMetadata.PreviewMetadata, original_pm.id)
      end
    end

    test "delete_preview/1 keeps the original preview metadata when other previews reference it",
         %{scope: scope} do
      {:ok, preview} =
        Previews.create_preview(scope, %{
          url: "some url",
          preview_metadata: %{title: "title", description: "desc"},
          original_preview_metadata: %{
            title: "original title",
            description: "original desc"
          }
        })

      original_pm = preview.original_preview_metadata

      {:ok, other_preview} =
        Previews.create_preview(scope, %{
          url: "other url",
          preview_metadata: %{title: "other title", description: "other desc"}
        })

      {:ok, other_preview} =
        other_preview
        |> Ecto.Changeset.change(original_preview_metadata_id: original_pm.id)
        |> Repo.update()

      assert {:ok, %Preview{}} = Previews.delete_preview(preview)

      assert Repo.get(
               Unclickbaiter.PreviewMetadata.PreviewMetadata,
               original_pm.id
             )

      assert Repo.get!(Preview, other_preview.id).original_preview_metadata_id ==
               original_pm.id

      assert {:ok, %Preview{}} = Previews.delete_preview(other_preview)

      refute Repo.get(
               Unclickbaiter.PreviewMetadata.PreviewMetadata,
               original_pm.id
             )
    end

    test "change_preview/1 returns a preview changeset" do
      preview = preview_fixture()
      assert %Ecto.Changeset{} = Previews.change_preview(preview)
    end
  end
end

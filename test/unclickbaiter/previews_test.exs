defmodule Unclickbaiter.SitesTest do
  use Unclickbaiter.DataCase

  alias Unclickbaiter.Previews

  describe "previews" do
    alias Unclickbaiter.Previews.Preview

    import Unclickbaiter.PreviewsFixtures

    @invalid_attrs %{
      url: nil,
      preview_metadata: %{description: nil, title: nil}
    }

    test "list_sites/0 returns all previews" do
      preview = preview_fixture()
      assert Previews.list_sites() == [preview]
    end

    test "get_preview!/1 returns the preview with given id" do
      preview = preview_fixture()
      assert Previews.get_preview!(preview.id) == preview
    end

    test "create_preview/1 with valid data creates a preview" do
      valid_attrs = %{
        url: "some url",
        preview_metadata: %{
          description: "some description",
          title: "some title"
        }
      }

      assert {:ok, %Preview{} = preview} = Previews.create_preview(valid_attrs)
      assert preview.url == "some url"
      assert preview.preview_metadata.description == "some description"
      assert preview.preview_metadata.title == "some title"
    end

    test "create_preview/1 with original_preview_metadata stores both metadata records" do
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

      assert {:ok, %Preview{} = preview} = Previews.create_preview(attrs)
      assert preview.preview_metadata.title == "some title"
      assert preview.original_preview_metadata.title == "original title"

      assert preview.original_preview_metadata.image_url ==
               "https://example.com/original.png"
    end

    test "create_preview/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               Previews.create_preview(@invalid_attrs)
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

      assert preview == Previews.get_preview!(preview.id)
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

    test "delete_preview/1 keeps the original preview metadata when other previews reference it" do
      {:ok, preview} =
        Previews.create_preview(%{
          url: "some url",
          preview_metadata: %{title: "title", description: "desc"},
          original_preview_metadata: %{
            title: "original title",
            description: "original desc"
          }
        })

      original_pm = preview.original_preview_metadata

      {:ok, other_preview} =
        Previews.create_preview(%{
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

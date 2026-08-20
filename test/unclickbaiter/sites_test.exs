defmodule Unclickbaiter.SitesTest do
  use Unclickbaiter.DataCase

  alias Unclickbaiter.Sites

  describe "sites" do
    alias Unclickbaiter.Sites.Site

    import Unclickbaiter.SitesFixtures

    @invalid_attrs %{
      url: nil,
      preview_metadata: %{description: nil, title: nil}
    }

    test "list_sites/0 returns all sites" do
      site = site_fixture()
      assert Sites.list_sites() == [site]
    end

    test "get_site!/1 returns the site with given id" do
      site = site_fixture()
      assert Sites.get_site!(site.id) == site
    end

    test "create_site/1 with valid data creates a site" do
      valid_attrs = %{
        url: "some url",
        preview_metadata: %{
          description: "some description",
          title: "some title"
        }
      }

      assert {:ok, %Site{} = site} = Sites.create_site(valid_attrs)
      assert site.url == "some url"
      assert site.preview_metadata.description == "some description"
      assert site.preview_metadata.title == "some title"
    end

    test "create_site/1 with original_preview_metadata stores both metadata records" do
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

      assert {:ok, %Site{} = site} = Sites.create_site(attrs)
      assert site.preview_metadata.title == "some title"
      assert site.original_preview_metadata.title == "original title"

      assert site.original_preview_metadata.image_url ==
               "https://example.com/original.png"
    end

    test "create_site/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Sites.create_site(@invalid_attrs)
    end

    test "update_site/2 with valid data updates the site" do
      site = site_fixture()

      update_attrs = %{
        url: "some updated url",
        preview_metadata: %{
          description: "some updated description",
          title: "some updated title"
        }
      }

      assert {:ok, %Site{} = site} = Sites.update_site(site, update_attrs)
      assert site.url == "some updated url"
      assert site.preview_metadata.description == "some updated description"
      assert site.preview_metadata.title == "some updated title"
    end

    test "update_site/2 with invalid data returns error changeset" do
      site = site_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Sites.update_site(site, @invalid_attrs)

      assert site == Sites.get_site!(site.id)
    end

    test "delete_site/1 deletes the site" do
      site = site_fixture()
      assert {:ok, %Site{}} = Sites.delete_site(site)
      assert_raise Ecto.NoResultsError, fn -> Sites.get_site!(site.id) end
    end

    test "delete_site/1 deletes the preview metadata records" do
      site = site_fixture()

      {:ok, site} =
        Sites.update_site(site, %{
          original_preview_metadata: %{
            title: "original title",
            description: "original description"
          }
        })

      pm = site.preview_metadata
      original_pm = site.original_preview_metadata

      assert {:ok, %Site{}} = Sites.delete_site(site)

      assert_raise Ecto.NoResultsError, fn ->
        Repo.get!(Unclickbaiter.PreviewMetadata.PreviewMetadata, pm.id)
      end

      assert_raise Ecto.NoResultsError, fn ->
        Repo.get!(Unclickbaiter.PreviewMetadata.PreviewMetadata, original_pm.id)
      end
    end

    test "delete_site/1 keeps the original preview metadata when other sites reference it" do
      {:ok, site} =
        Sites.create_site(%{
          url: "some url",
          preview_metadata: %{title: "title", description: "desc"},
          original_preview_metadata: %{
            title: "original title",
            description: "original desc"
          }
        })

      original_pm = site.original_preview_metadata

      {:ok, other_site} =
        Sites.create_site(%{
          url: "other url",
          preview_metadata: %{title: "other title", description: "other desc"}
        })

      {:ok, other_site} =
        other_site
        |> Ecto.Changeset.change(original_preview_metadata_id: original_pm.id)
        |> Repo.update()

      assert {:ok, %Site{}} = Sites.delete_site(site)

      assert Repo.get(
               Unclickbaiter.PreviewMetadata.PreviewMetadata,
               original_pm.id
             )

      assert Repo.get!(Site, other_site.id).original_preview_metadata_id ==
               original_pm.id

      assert {:ok, %Site{}} = Sites.delete_site(other_site)

      refute Repo.get(
               Unclickbaiter.PreviewMetadata.PreviewMetadata,
               original_pm.id
             )
    end

    test "change_site/1 returns a site changeset" do
      site = site_fixture()
      assert %Ecto.Changeset{} = Sites.change_site(site)
    end
  end
end

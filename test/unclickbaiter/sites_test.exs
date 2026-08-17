defmodule Unclickbaiter.SitesTest do
  use Unclickbaiter.DataCase

  alias Unclickbaiter.Sites

  describe "sites" do
    alias Unclickbaiter.Sites.Site

    import Unclickbaiter.SitesFixtures

    @invalid_attrs %{description: nil, title: nil, url: nil}

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
        description: "some description",
        title: "some title",
        url: "some url"
      }

      assert {:ok, %Site{} = site} = Sites.create_site(valid_attrs)
      assert site.description == "some description"
      assert site.title == "some title"
      assert site.url == "some url"
    end

    test "create_site/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Sites.create_site(@invalid_attrs)
    end

    test "update_site/2 with valid data updates the site" do
      site = site_fixture()

      update_attrs = %{
        description: "some updated description",
        title: "some updated title",
        url: "some updated url"
      }

      assert {:ok, %Site{} = site} = Sites.update_site(site, update_attrs)
      assert site.description == "some updated description"
      assert site.title == "some updated title"
      assert site.url == "some updated url"
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

    test "change_site/1 returns a site changeset" do
      site = site_fixture()
      assert %Ecto.Changeset{} = Sites.change_site(site)
    end
  end
end

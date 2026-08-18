defmodule UnclickbaiterWeb.SiteLiveTest do
  use UnclickbaiterWeb.ConnCase

  import Phoenix.LiveViewTest
  import Unclickbaiter.SitesFixtures

  @create_attrs %{
    description: "some description",
    title: "some title",
    url: "some url"
  }
  @update_attrs %{
    description: "some updated description",
    title: "some updated title",
    url: "some updated url"
  }
  @invalid_attrs %{description: nil, title: nil, url: nil}
  defp create_site(_) do
    site = site_fixture()

    %{site: site}
  end

  describe "Index" do
    setup [:create_site]

    test "lists all sites", %{conn: conn, site: site} do
      {:ok, _index_live, html} = live(conn, ~p"/sites")

      assert html =~ "Listing Sites"
      assert html =~ site.url
    end

    test "saves new site", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/sites")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Site")
               |> render_click()
               |> follow_redirect(conn, ~p"/sites/new")

      assert render(form_live) =~ "New Site"

      assert form_live
             |> form("#site-form", site: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#site-form", site: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/sites")

      html = render(index_live)
      assert html =~ "Site created successfully"
      assert html =~ "some url"
    end

    test "updates site in listing", %{conn: conn, site: site} do
      {:ok, index_live, _html} = live(conn, ~p"/sites")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#sites-#{site.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/sites/#{site}/edit")

      assert render(form_live) =~ "Edit Site"

      assert form_live
             |> form("#site-form", site: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#site-form", site: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/sites")

      html = render(index_live)
      assert html =~ "Site updated successfully"
      assert html =~ "some updated url"
    end

    test "deletes site in listing", %{conn: conn, site: site} do
      {:ok, index_live, _html} = live(conn, ~p"/sites")

      assert index_live
             |> element("#sites-#{site.id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#sites-#{site.id}")
    end
  end

  describe "Show" do
    setup [:create_site]

    test "displays site with og metadata", %{conn: conn, site: site} do
      {:ok, _show_live, html} = live(conn, ~p"/sites/#{site}")

      assert html =~ site.title
      assert html =~ site.description
      assert html =~ site.url
      assert html =~ ~s(property="og:title")
      assert html =~ ~s(property="og:description")
    end

    test "shows redirect notice", %{conn: conn, site: site} do
      {:ok, show_live, _html} = live(conn, ~p"/sites/#{site}")

      assert has_element?(show_live, "#redirect-notice")
      assert render(show_live) =~ site.url
    end
  end
end

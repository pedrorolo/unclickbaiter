defmodule UnclickbaiterWeb.SiteLiveTest do
  use UnclickbaiterWeb.ConnCase

  import Phoenix.LiveViewTest
  import Req.Test
  import Unclickbaiter.SitesFixtures

  alias Unclickbaiter.PreviewMetadata.HTTP.ProviderCache

  setup do
    ProviderCache.clear()
    :ok
  end

  @create_attrs %{
    url: "some url",
    preview_metadata: %{
      description: "some description",
      title: "some title"
    }
  }
  @update_attrs %{
    url: "some updated url",
    preview_metadata: %{
      description: "some updated description",
      title: "some updated title"
    }
  }
  @invalid_attrs %{url: nil, preview_metadata: %{description: nil, title: nil}}
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

    test "falls back to the page title when there is no metadata", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/sites")

      assert html =~ ~r/<title[^>]*>\s*Listing Sites\s*<\/title>/
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

      assert html =~ site.preview_metadata.title
      assert html =~ site.preview_metadata.description
      assert html =~ site.url
      assert html =~ ~s(property="og:title")
      assert html =~ ~s(property="og:description")
      assert html =~ ~s(property="og:image")
      assert html =~ ~s(name="description")
      assert html =~ ~s(name="image")

      assert html =~
               ~s(property="og:url" content="http://localhost:4000/sites/#{site.id}")
    end

    test "sets the document title from the preview metadata", %{
      conn: conn,
      site: site
    } do
      {:ok, _show_live, html} = live(conn, ~p"/sites/#{site}")

      assert html =~
               ~r/<title[^>]*>\s*#{Regex.escape(site.preview_metadata.title)}\s*<\/title>/
    end

    test "keeps the app name in the header", %{conn: conn, site: site} do
      {:ok, show_live, _html} = live(conn, ~p"/sites/#{site}")

      assert has_element?(show_live, "header h1", "Unclickbaiter")
      refute has_element?(show_live, "header h1", site.preview_metadata.title)
    end

    test "shows link to the original site", %{conn: conn, site: site} do
      {:ok, show_live, _html} = live(conn, ~p"/sites/#{site}")

      assert has_element?(show_live, "#original-site-link")

      assert render(element(show_live, "#original-site-link")) =~
               ~s(href="#{site.url}")
    end

    test "shows original and new previews side by side", %{conn: conn} do
      site =
        site_fixture(%{
          url: "https://example.com",
          preview_metadata: %{
            title: "New Title",
            description: "New description",
            image_url: "https://cdn.example.com/new.png"
          },
          original_preview_metadata: %{
            title: "Original Title",
            description: "Original description",
            image_url: "https://cdn.example.com/original.png"
          }
        })

      {:ok, show_live, _html} = live(conn, ~p"/sites/#{site}")

      assert has_element?(show_live, "#original-preview-card")
      assert has_element?(show_live, "#new-preview-card")

      original_card = render(element(show_live, "#original-preview-card"))
      assert original_card =~ "Original Title"
      assert original_card =~ "Original description"
      assert original_card =~ ~s(src="https://cdn.example.com/original.png")

      new_card = render(element(show_live, "#new-preview-card"))
      assert new_card =~ "New Title"
      assert new_card =~ "New description"
      assert new_card =~ ~s(src="https://cdn.example.com/new.png")
    end
  end

  describe "Form metadata fetching" do
    defp allow_metadata_mock(lv) do
      Req.Test.allow(Unclickbaiter.PreviewMetadata.HTTP, self(), lv.pid)
    end

    defp wait_until_fetched(lv, timeout \\ 2000) do
      deadline = System.monotonic_time(:millisecond) + timeout

      html =
        Enum.reduce_while(1..100, nil, fn _, _ ->
          html = render(lv)

          if html =~ "Fetching preview metadata" and
               System.monotonic_time(:millisecond) < deadline do
            Process.sleep(20)
            {:cont, nil}
          else
            {:halt, html}
          end
        end)

      html
    end

    test "fetches and fills preview metadata fields when the url changes",
         %{conn: conn} do
      expect(Unclickbaiter.PreviewMetadata.HTTP, fn conn ->
        html(conn, """
        <html>
          <head>
            <meta property="og:title" content="Fetched Title" />
            <meta property="og:description" content="Fetched description" />
            <meta property="og:image" content="https://cdn.example.com/img.png" />
          </head>
        </html>
        """)
      end)

      {:ok, form_live, _html} = live(conn, ~p"/sites/new")
      allow_metadata_mock(form_live)

      form_live
      |> form("#site-form", site: %{url: "https://example.com"})
      |> render_change()

      html = wait_until_fetched(form_live)
      refute html =~ "Fetching preview metadata"

      assert render(
               element(
                 form_live,
                 "#site-form textarea[name='site[preview_metadata][title]']"
               )
             ) =~ ">Fetched Title</textarea>"

      assert render(
               element(
                 form_live,
                 "#site-form textarea[name='site[preview_metadata][description]']"
               )
             ) =~ ">Fetched description</textarea>"

      assert render(
               element(
                 form_live,
                 "#site-form input[name='site[preview_metadata][image_url]']"
               )
             ) =~
               ~s(value="https://cdn.example.com/img.png")

      assert render(
               element(
                 form_live,
                 "#site-form input[name='site[original_preview_metadata][title]']"
               )
             ) =~
               ~s(value="Fetched Title")

      assert render(
               element(
                 form_live,
                 "#site-form input[name='site[original_preview_metadata][description]']"
               )
             ) =~
               ~s(value="Fetched description")

      assert render(
               element(
                 form_live,
                 "#site-form input[name='site[original_preview_metadata][image_url]']"
               )
             ) =~
               ~s(value="https://cdn.example.com/img.png")
    end

    test "shows the fetched metadata in the preview card", %{conn: conn} do
      expect(Unclickbaiter.PreviewMetadata.HTTP, fn conn ->
        html(conn, """
        <html>
          <head>
            <meta property="og:title" content="Fetched Title" />
            <meta property="og:description" content="Fetched description" />
            <meta property="og:image" content="https://cdn.example.com/img.png" />
          </head>
        </html>
        """)
      end)

      {:ok, form_live, _html} = live(conn, ~p"/sites/new")
      allow_metadata_mock(form_live)

      form_live
      |> form("#site-form", site: %{url: "https://example.com"})
      |> render_change()

      html = wait_until_fetched(form_live)
      refute html =~ "Fetching preview metadata"

      assert render(form_live) =~ ~s(src="https://cdn.example.com/img.png")
      assert render(element(form_live, "#preview-card")) =~ "Fetched Title"

      assert render(element(form_live, "#preview-card")) =~
               "Fetched description"
    end

    test "does not fetch metadata for invalid urls", %{conn: conn} do
      {:ok, form_live, _html} = live(conn, ~p"/sites/new")

      form_live
      |> form("#site-form", site: %{url: "some url"})
      |> render_change()

      html = render(form_live)
      refute html =~ "Fetching preview metadata"
      refute html =~ "original_preview_metadata"
    end

    test "keeps the form usable when the metadata fetch fails", %{conn: conn} do
      expect(Unclickbaiter.PreviewMetadata.HTTP, 3, fn conn ->
        case conn.host do
          "example.com" -> Plug.Conn.send_resp(conn, 404, "nope")
          "jsonlink.io" -> Plug.Conn.send_resp(conn, 500, "nope")
          "opengraph.io" -> Plug.Conn.send_resp(conn, 500, "nope")
        end
      end)

      {:ok, form_live, _html} = live(conn, ~p"/sites/new")
      allow_metadata_mock(form_live)

      form_live
      |> form("#site-form", site: %{url: "https://example.com"})
      |> render_change()

      html = wait_until_fetched(form_live)
      refute html =~ "Fetching preview metadata"

      assert has_element?(form_live, "#metadata-fetch-error")

      assert render(element(form_live, "#metadata-fetch-error")) =~
               "We couldn&#39;t fetch the preview metadata for this site"

      assert render(element(form_live, "#site-form input[name='site[url]']")) =~
               ~s(value="https://example.com")
    end

    test "shows a live preview of the preview metadata under the form", %{
      conn: conn
    } do
      {:ok, form_live, _html} = live(conn, ~p"/sites/new")

      assert has_element?(form_live, "#preview-card")

      form_live
      |> form("#site-form",
        site: %{
          url: "https://example.com",
          preview_metadata: %{
            title: "Preview Title",
            description: "Preview description",
            image_url: "https://cdn.example.com/img.png"
          }
        }
      )
      |> render_change()

      html = wait_until_fetched(form_live)
      assert html =~ "Preview Title"
      assert html =~ "Preview description"
      assert html =~ ~s(src="https://cdn.example.com/img.png")
    end

    test "edit page shows saved metadata in the preview card", %{conn: conn} do
      site =
        site_fixture(%{
          url: "https://example.com",
          preview_metadata: %{
            title: "Saved Title",
            description: "Saved description",
            image_url: "https://cdn.example.com/saved.png"
          }
        })

      {:ok, form_live, _html} = live(conn, ~p"/sites/#{site}/edit")

      card = render(element(form_live, "#preview-card"))
      assert card =~ "Saved Title"
      assert card =~ "Saved description"
      assert card =~ ~s(src="https://cdn.example.com/saved.png")
    end
  end
end

defmodule UnclickbaiterWeb.SiteLiveTest do
  use UnclickbaiterWeb.ConnCase

  import Phoenix.LiveViewTest
  import Req.Test
  import Unclickbaiter.PreviewsFixtures

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
  defp create_preview(_) do
    preview = preview_fixture()

    %{preview: preview}
  end

  describe "Index" do
    setup [:create_preview]

    test "lists all previews", %{conn: conn, preview: preview} do
      {:ok, _index_live, html} = live(conn, ~p"/previews")

      assert html =~ "Listing Previews"
      assert html =~ preview.url
    end

    test "falls back to the page title when there is no metadata", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/previews")

      assert html =~ ~r/<title[^>]*>\s*Listing Previews\s*<\/title>/
    end

    test "saves new preview", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/previews")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Preview")
               |> render_click()
               |> follow_redirect(conn, ~p"/previews/new")

      assert render(form_live) =~ "New Preview"

      assert form_live
             |> form("#preview-form", preview: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#preview-form", preview: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/previews")

      html = render(index_live)
      assert html =~ "Preview created successfully"
      assert html =~ "some url"
    end

    test "updates preview in listing", %{conn: conn, preview: preview} do
      {:ok, index_live, _html} = live(conn, ~p"/previews")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#previews-#{preview.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/previews/#{preview}/edit")

      assert render(form_live) =~ "Edit Preview"

      assert form_live
             |> form("#preview-form", preview: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#preview-form", preview: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/previews")

      html = render(index_live)
      assert html =~ "Preview updated successfully"
      assert html =~ "some updated url"
    end

    test "deletes preview in listing", %{conn: conn, preview: preview} do
      {:ok, index_live, _html} = live(conn, ~p"/previews")

      assert index_live
             |> element("#previews-#{preview.id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#previews-#{preview.id}")
    end
  end

  describe "Show" do
    setup [:create_preview]

    test "displays preview with og metadata", %{conn: conn, preview: preview} do
      {:ok, _show_live, html} = live(conn, ~p"/previews/#{preview}")

      assert html =~ preview.preview_metadata.title
      assert html =~ preview.preview_metadata.description
      assert html =~ preview.url
      assert html =~ ~s(property="og:title")
      assert html =~ ~s(property="og:description")
      assert html =~ ~s(property="og:image")
      assert html =~ ~s(name="description")
      assert html =~ ~s(name="image")
    end

    test "sets the document title from the preview metadata", %{
      conn: conn,
      preview: preview
    } do
      {:ok, _show_live, html} = live(conn, ~p"/previews/#{preview}")

      assert html =~
               ~r/<title[^>]*>\s*#{Regex.escape(preview.preview_metadata.title)}\s*<\/title>/
    end

    test "keeps the app name in the header", %{conn: conn, preview: preview} do
      {:ok, show_live, _html} = live(conn, ~p"/previews/#{preview}")

      assert has_element?(show_live, "header h1", "Unclickbaiter")

      refute has_element?(
               show_live,
               "header h1",
               preview.preview_metadata.title
             )
    end

    test "shows link to the original preview", %{conn: conn, preview: preview} do
      {:ok, show_live, _html} = live(conn, ~p"/previews/#{preview}")

      assert has_element?(show_live, "#original-preview-link")

      assert render(element(show_live, "#original-preview-link")) =~
               ~s(href="#{preview.url}")
    end

    test "shows original and new previews side by side", %{conn: conn} do
      preview =
        preview_fixture(%{
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

      {:ok, show_live, _html} = live(conn, ~p"/previews/#{preview}")

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

      {:ok, form_live, _html} = live(conn, ~p"/previews/new")
      allow_metadata_mock(form_live)

      form_live
      |> form("#preview-form", preview: %{url: "https://example.com"})
      |> render_change()

      html = wait_until_fetched(form_live)
      refute html =~ "Fetching preview metadata"

      assert render(
               element(
                 form_live,
                 "#preview-form textarea[name='preview[preview_metadata][title]']"
               )
             ) =~ ">Fetched Title</textarea>"

      assert render(
               element(
                 form_live,
                 "#preview-form textarea[name='preview[preview_metadata][description]']"
               )
             ) =~ ">Fetched description</textarea>"

      assert render(
               element(
                 form_live,
                 "#preview-form input[name='preview[preview_metadata][image_url]']"
               )
             ) =~
               ~s(value="https://cdn.example.com/img.png")

      assert render(
               element(
                 form_live,
                 "#preview-form input[name='preview[original_preview_metadata][title]']"
               )
             ) =~
               ~s(value="Fetched Title")

      assert render(
               element(
                 form_live,
                 "#preview-form input[name='preview[original_preview_metadata][description]']"
               )
             ) =~
               ~s(value="Fetched description")

      assert render(
               element(
                 form_live,
                 "#preview-form input[name='preview[original_preview_metadata][image_url]']"
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

      {:ok, form_live, _html} = live(conn, ~p"/previews/new")
      allow_metadata_mock(form_live)

      form_live
      |> form("#preview-form", preview: %{url: "https://example.com"})
      |> render_change()

      html = wait_until_fetched(form_live)
      refute html =~ "Fetching preview metadata"

      assert render(form_live) =~ ~s(src="https://cdn.example.com/img.png")
      assert render(element(form_live, "#preview-card")) =~ "Fetched Title"

      assert render(element(form_live, "#preview-card")) =~
               "Fetched description"
    end

    test "does not fetch metadata for invalid urls", %{conn: conn} do
      {:ok, form_live, _html} = live(conn, ~p"/previews/new")

      form_live
      |> form("#preview-form", preview: %{url: "some url"})
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

      {:ok, form_live, _html} = live(conn, ~p"/previews/new")
      allow_metadata_mock(form_live)

      form_live
      |> form("#preview-form", preview: %{url: "https://example.com"})
      |> render_change()

      html = wait_until_fetched(form_live)
      refute html =~ "Fetching preview metadata"

      assert has_element?(form_live, "#metadata-fetch-error")

      assert render(element(form_live, "#metadata-fetch-error")) =~
               "We couldn&#39;t fetch the preview metadata for this preview"

      assert render(
               element(form_live, "#preview-form input[name='preview[url]']")
             ) =~
               ~s(value="https://example.com")
    end

    test "shows a live preview of the preview metadata under the form", %{
      conn: conn
    } do
      {:ok, form_live, _html} = live(conn, ~p"/previews/new")

      assert has_element?(form_live, "#preview-card")

      form_live
      |> form("#preview-form",
        preview: %{
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
      preview =
        preview_fixture(%{
          url: "https://example.com",
          preview_metadata: %{
            title: "Saved Title",
            description: "Saved description",
            image_url: "https://cdn.example.com/saved.png"
          }
        })

      {:ok, form_live, _html} = live(conn, ~p"/previews/#{preview}/edit")

      card = render(element(form_live, "#preview-card"))
      assert card =~ "Saved Title"
      assert card =~ "Saved description"
      assert card =~ ~s(src="https://cdn.example.com/saved.png")
    end
  end
end

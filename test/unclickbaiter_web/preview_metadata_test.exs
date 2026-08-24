defmodule UnclickbaiterWeb.PreviewMetadataTest do
  use UnclickbaiterWeb.ConnCase

  import Phoenix.LiveViewTest
  import Unclickbaiter.PreviewsFixtures

  alias Unclickbaiter.AccountsFixtures

  defp assert_default_preview_metadata(html) do
    assert html =~ ~s(property="og:title" content="unclickbaiter")

    assert html =~
             ~s(property="og:description" content="Alternative social-media previews to existing pages")

    assert html =~ ~s(property="og:type" content="website")
    assert html =~ ~s(name="twitter:card" content="summary_large_image")
  end

  test "main page renders the default preview metadata", %{conn: conn} do
    conn = get(conn, ~p"/")

    assert_default_preview_metadata(html_response(conn, 200))
  end

  test "previews page renders the default preview metadata", %{conn: conn} do
    user = AccountsFixtures.user_fixture()
    conn = log_in_user(conn, user)
    preview_fixture(%{user_id: user.id})

    {:ok, _index_live, html} = live(conn, ~p"/p")

    assert_default_preview_metadata(html)
  end

  test "edit page renders the default preview metadata", %{conn: conn} do
    user = AccountsFixtures.user_fixture()
    conn = log_in_user(conn, user)
    preview = preview_fixture(%{user_id: user.id})

    {:ok, _edit_live, html} = live(conn, ~p"/p/#{preview}/edit")

    assert_default_preview_metadata(html)
  end

  test "show page renders the preview metadata according to the preview contents",
       %{conn: conn} do
    preview = preview_fixture()

    {:ok, _show_live, html} = live(conn, ~p"/p/#{preview}")

    assert html =~
             ~s(property="og:title" content="#{preview.preview_metadata.title}")

    assert html =~
             ~s(property="og:description" content="#{preview.preview_metadata.description}")

    assert html =~
             ~s(property="og:url" content="http://localhost:4000/p/#{preview.slug}")

    assert html =~
             ~s(property="og:image" content="#{preview.preview_metadata.image_url}")

    assert html =~ ~s(name="twitter:card" content="summary_large_image")
  end
end

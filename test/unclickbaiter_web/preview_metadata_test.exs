defmodule UnclickbaiterWeb.PreviewMetadataTest do
  use UnclickbaiterWeb.ConnCase

  import Phoenix.LiveViewTest
  import Unclickbaiter.PreviewsFixtures

  alias Unclickbaiter.AccountsFixtures

  @default_title "unclickbaiter"
  @default_description "Share links with custom OpenGraph metadata — bringing awareness to clickbaits as a form of misinformation and disinformation."
  @default_site_name "unclickbaiter"
  @default_type "website"
  @default_twitter_card "summary_large_image"

  defp assert_default_preview_metadata(html) do
    assert html =~ ~s(property="og:title" content="#{@default_title}")

    assert html =~
             ~s(property="og:description" content="#{@default_description}")

    assert html =~ ~s(property="og:type" content="#{@default_type}")
    assert html =~ ~s(property="og:site_name" content="#{@default_site_name}")
    assert html =~ ~s(name="twitter:card" content="#{@default_twitter_card}")
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

    assert html =~ ~s(property="og:url" content="#{preview.url}")

    assert html =~
             ~s(property="og:image" content="#{preview.preview_metadata.image_url}")

    assert html =~ ~s(name="twitter:card" content="#{@default_twitter_card}")
  end
end

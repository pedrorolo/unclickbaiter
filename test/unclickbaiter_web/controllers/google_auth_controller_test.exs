defmodule UnclickbaiterWeb.GoogleAuthControllerTest do
  use UnclickbaiterWeb.ConnCase, async: true

  import Unclickbaiter.AccountsFixtures

  describe "GET /auth/google" do
    test "redirects to the Google authorization page", %{conn: conn} do
      conn = get(conn, ~p"/auth/google")

      assert redirected_to(conn) =~
               "https://accounts.google.com/o/oauth2/v2/auth"

      assert get_session(conn, :google_session_params)
    end
  end

  describe "GET /auth/google/callback" do
    test "flashes an error when google reports one", %{conn: conn} do
      conn = get(conn, "/auth/google/callback?error=access_denied")

      assert redirected_to(conn) == "/"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "Google"
    end
  end

  describe "DELETE /log-out" do
    test "logs the user out and clears the session", %{conn: conn} do
      conn =
        conn
        |> log_in_user(user_fixture())
        |> delete(~p"/log-out")

      assert redirected_to(conn) == "/"
      refute get_session(conn, :user_token)
    end
  end
end

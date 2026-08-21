defmodule UnclickbaiterWeb.GoogleAuthController do
  use UnclickbaiterWeb, :controller

  @app Mix.Project.config()[:app]

  require Logger

  alias Assent.Strategy.Google

  alias Unclickbaiter.Accounts
  alias UnclickbaiterWeb.UserAuth

  @doc """
  Redirects the user to Google to authorize access.
  """
  def request(conn, _params) do
    case Google.authorize_url(google_config()) do
      {:ok, %{url: url, session_params: session_params}} ->
        conn
        |> put_session(:google_session_params, session_params)
        |> redirect(external: url)

      {:error, error} ->
        handle_auth_error(conn, error)
    end
  end

  @doc """
  Handles the OAuth2 callback: exchanges the code for a Google profile,
  upserts a local account for the verified email and logs the user in.
  """
  def callback(conn, %{"code" => _code} = params) do
    session_params = get_session(conn, :google_session_params)

    config = Keyword.put(google_config(), :session_params, session_params)

    with {:ok, %{user: google_user}} <-
           Google.callback(config, params),
         %{"email" => _email, "email_verified" => true} <- google_user,
         {:ok, user} <- Accounts.upsert_google_user(google_user) do
      conn
      |> delete_session(:google_session_params)
      |> put_flash(:info, "Signed in with Google successfully.")
      |> UserAuth.log_in_user(user)
    else
      %{"email_verified" => false} ->
        handle_auth_error(
          conn,
          "the email on your Google account is not verified"
        )

      _error ->
        handle_auth_error(conn)
    end
  end

  def callback(conn, _params), do: handle_auth_error(conn)

  @doc """
  Logs the user out.
  """
  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end

  defp google_config do
    google = Application.get_env(@app, :secrets, %{})[:google] || %{}

    [
      client_id: google[:client_id],
      client_secret: google[:client_secret],
      redirect_uri: url(~p"/auth/google/callback"),
      authorize_url: "https://accounts.google.com/o/oauth2/v2/auth",
      token_url: "https://oauth2.googleapis.com/token",
      user_url: "https://openidconnect.googleapis.com/v1/userinfo",
      http_adapter: Assent.HTTPAdapter.Req
    ]
  end

  defp handle_auth_error(conn, reason \\ nil) do
    Logger.warning("Google sign-in failed: #{inspect(reason)}")

    conn
    |> put_flash(:error, "Could not sign you in with Google.")
    |> redirect(to: ~p"/")
  end
end

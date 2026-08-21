defmodule Unclickbaiter.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Unclickbaiter.Accounts` context.
  """

  import Ecto.Query

  alias Unclickbaiter.Accounts
  alias Unclickbaiter.Accounts.Scope

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"

  def valid_google_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{"email" => unique_user_email(), "email_verified" => true})
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_google_attributes()
      |> Accounts.upsert_google_user()

    user
  end

  def user_scope_fixture(user \\ user_fixture()) do
    Scope.for_user(user)
  end

  def override_token_authenticated_at(token, authenticated_at)
      when is_binary(token) do
    Unclickbaiter.Repo.update_all(
      from(t in Accounts.UserToken,
        where: t.token == ^token
      ),
      set: [authenticated_at: authenticated_at]
    )
  end

  def offset_user_token(token, amount_to_add, unit) do
    dt = DateTime.add(DateTime.utc_now(:second), amount_to_add, unit)

    Unclickbaiter.Repo.update_all(
      from(ut in Accounts.UserToken, where: ut.token == ^token),
      set: [inserted_at: dt, authenticated_at: dt]
    )
  end
end

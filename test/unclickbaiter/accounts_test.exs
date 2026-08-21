defmodule Unclickbaiter.AccountsTest do
  use Unclickbaiter.DataCase

  alias Unclickbaiter.Accounts
  alias Unclickbaiter.Accounts.User

  import Unclickbaiter.AccountsFixtures

  describe "get_user_by_email/1" do
    test "returns the user by email" do
      %{email: email} = user_fixture()
      assert %User{} = Accounts.get_user_by_email(email)
    end

    test "returns nil for unknown email" do
      refute Accounts.get_user_by_email("unknown@example.com")
    end
  end

  describe "get_user!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_user!(123_456_789)
      end
    end
  end

  describe "upsert_google_user/1" do
    test "creates a confirmed user from a verified google profile" do
      email = unique_user_email()

      {:ok, user} =
        Accounts.upsert_google_user(%{
          "email" => email,
          "email_verified" => true
        })

      assert user.email == email
      assert user.confirmed_at
    end

    test "returns the existing user on subsequent sign-ins" do
      attrs = valid_google_attributes()
      {:ok, first} = Accounts.upsert_google_user(attrs)
      {:ok, second} = Accounts.upsert_google_user(attrs)

      assert first.id == second.id
    end

    test "rejects invalid emails" do
      assert {:error, %Ecto.Changeset{}} =
               Accounts.upsert_google_user(%{
                 "email" => "not-an-email",
                 "email_verified" => true
               })
    end
  end

  describe "sudo_mode?/2" do
    test "is true when the user authenticated recently" do
      assert Accounts.sudo_mode?(%User{authenticated_at: DateTime.utc_now()})
    end

    test "is false when authentication is stale or missing" do
      refute Accounts.sudo_mode?(%User{
               authenticated_at: DateTime.add(DateTime.utc_now(), -60, :minute)
             })

      refute Accounts.sudo_mode?(%User{})
    end
  end

  describe "session tokens" do
    test "generates a token that can be fetched with its owner" do
      user = user_fixture()
      token = Accounts.generate_user_session_token(user)

      assert {%User{id: id}, %DateTime{}} =
               Accounts.get_user_by_session_token(token)

      assert id == user.id
    end

    test "deleted session tokens are no longer fetchable" do
      user = user_fixture()
      token = Accounts.generate_user_session_token(user)

      assert :ok = Accounts.delete_user_session_token(token)
      refute Accounts.get_user_by_session_token(token)
    end
  end
end

defmodule Unclickbaiter.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :slug, :string
    field :confirmed_at, :utc_datetime
    field :authenticated_at, :utc_datetime, virtual: true

    timestamps(type: :utc_datetime)
  end

  @doc """
  A user changeset for registering an account from a verified Google profile.

  The email is provided and verified by Google, so uniqueness is enforced at
  the database level only, and the account is confirmed right away.
  """
  def google_changeset(user, attrs) do
    user
    |> cast(attrs, [:email])
    |> validate_email()
    |> unique_constraint(:email)
    |> put_change(:confirmed_at, DateTime.utc_now(:second))
  end

  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^@,;\s]+@[^@,;\s]+$/,
      message: "must have the @ sign and no spaces"
    )
    |> validate_length(:email, max: 160)
  end
end

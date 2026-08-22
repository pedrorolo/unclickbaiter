defmodule Unclickbaiter.Slug do
  @moduledoc """
  Generates a short random slug for new records.

  A slug is a random alphanumeric string of `:length` characters (defaults to
  `@default_length`). If a generated slug is already taken, a new one is tried.
  The attribute that stores the slug can be customized via `:slug_attribute`
  (defaults to `@default_slug_attribute`).
  """

  import Ecto.Changeset
  import Ecto.Query, warn: false

  alias Unclickbaiter.Repo

  @default_length 5
  @max_attempts 10
  @default_slug_attribute :slug

  @spec with_new_slug(module(), (Ecto.Changeset.t() -> result), keyword()) ::
          result
        when result: term()
  def with_new_slug(schema, callback, opts \\ []) do
    length = Keyword.get(opts, :length, @default_length)
    slug_attribute = Keyword.get(opts, :slug_attribute, @default_slug_attribute)

    case Repo.transaction(fn ->
           {:ok, slug} =
             unique_slug(schema, length: length, slug_attribute: slug_attribute)

           schema
           |> struct()
           |> change()
           |> put_change(slug_attribute, slug)
           |> unique_constraint(slug_attribute)
           |> callback.()
         end) do
      {:ok, result} -> result
      {:error, _} = error -> error
    end
  end

  @spec unique_slug(module(), keyword()) :: {:ok, String.t()}
  def unique_slug(schema_module, opts \\ []) do
    length = Keyword.get(opts, :length, @default_length)
    slug_attribute = Keyword.get(opts, :slug_attribute, @default_slug_attribute)
    max_attempts = Keyword.get(opts, :max_attempts, @max_attempts)
    generate(schema_module, length, slug_attribute, max_attempts, 0)
  end

  defp generate(schema, _length, _slug_attribute, max_attempts, attempt)
       when attempt >= max_attempts do
    raise RuntimeError,
          "could not generate a unique slug for #{inspect(schema)} after #{attempt} attempts"
  end

  defp generate(schema, length, slug_attribute, max_attempts, attempt) do
    slug = random_slug(length)

    if Repo.exists?(from s in schema, where: field(s, ^slug_attribute) == ^slug) do
      generate(schema, length, slug_attribute, max_attempts, attempt + 1)
    else
      {:ok, slug}
    end
  end

  defp random_slug(length) do
    length
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
    |> String.slice(0, length)
  end
end

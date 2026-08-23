defmodule Unclickbaiter.PreviewsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Unclickbaiter.Previews` context.
  """

  import Unclickbaiter.AccountsFixtures
  alias Unclickbaiter.Accounts.{Scope, User}

  @doc """
  Generate a preview.
  """
  def preview_fixture(attrs \\ %{}) do
    user_id =
      cond do
        Map.has_key?(attrs, :user_id) ->
          attrs.user_id

        is_map_key(attrs, :user) and Map.has_key?(attrs.user, :id) ->
          attrs.user.id

        true ->
          user_fixture().id
      end

    scope =
      Scope.for_user(%User{
        id: user_id
      })

    clean_attrs =
      attrs
      |> Map.drop([:user_id, :user])
      |> Map.new(fn
        {k, v} when is_atom(k) -> {Atom.to_string(k), v}
        other -> other
      end)

    {:ok, preview} =
      Unclickbaiter.Previews.create_preview(scope, %{
        url: clean_attrs["url"] || "some url",
        preview_metadata:
          clean_attrs["preview_metadata"] ||
            %{
              description: "some description",
              title: "some title",
              image_url: "https://example.com/image.png"
            },
        original_preview_metadata: clean_attrs["original_preview_metadata"]
      })

    preview
  end
end

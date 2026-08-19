defmodule Unclickbaiter.Sites do
  @moduledoc """
  The Sites context.
  """

  import Ecto.Query, warn: false
  alias Unclickbaiter.Repo

  alias Unclickbaiter.PreviewMetadata.PreviewMetadata
  alias Unclickbaiter.Sites.Site

  @doc """
  Returns the list of sites.

  ## Examples

      iex> list_sites()
      [%Site{}, ...]

  """
  def list_sites do
    Site
    |> Repo.all()
    |> Repo.preload([:preview_metadata, :original_preview_metadata])
  end

  @doc """
  Gets a single site.

  Raises `Ecto.NoResultsError` if the Site does not exist.

  ## Examples

      iex> get_site!(123)
      %Site{}

      iex> get_site!(456)
      ** (Ecto.NoResultsError)

  """
  def get_site!(id) do
    Repo.get!(Site, id)
    |> Repo.preload([:preview_metadata, :original_preview_metadata])
  end

  @doc """
  Creates a site.

  ## Examples

      iex> create_site(%{field: value})
      {:ok, %Site{}}

      iex> create_site(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_site(attrs) do
    %Site{}
    |> Site.changeset(attrs)
    |> Repo.insert()
    |> preload_preview_metadata()
  end

  @doc """
  Updates a site.

  ## Examples

      iex> update_site(site, %{field: new_value})
      {:ok, %Site{}}

      iex> update_site(site, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_site(%Site{} = site, attrs) do
    site
    |> Site.changeset(attrs)
    |> Repo.update()
    |> preload_preview_metadata()
  end

  @doc """
  Deletes a site.

  ## Examples

      iex> delete_site(site)
      {:ok, %Site{}}

      iex> delete_site(site)
      {:error, %Ecto.Changeset{}}

  """
  def delete_site(%Site{} = site) do
    Repo.transaction(fn ->
      Repo.delete_all(
        from(p in PreviewMetadata,
          where:
            p.id in [
              ^site.preview_metadata_id,
              ^site.original_preview_metadata_id
            ]
        )
      )

      Repo.delete!(site)
    end)
  end

  defp preload_preview_metadata({:ok, site}) do
    {:ok, Repo.preload(site, [:preview_metadata, :original_preview_metadata])}
  end

  defp preload_preview_metadata({:error, changeset}), do: {:error, changeset}

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking site changes.

  ## Examples

      iex> change_site(site)
      %Ecto.Changeset{data: %Site{}}

  """
  def change_site(%Site{} = site, attrs \\ %{}) do
    Site.changeset(site, attrs)
  end
end

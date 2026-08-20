defmodule Unclickbaiter.PreviewMetadata.HTTP.ProviderCache do
  @moduledoc """
  Caches, per domain, which provider succeeded in fetching preview metadata
  for it.

  Entries are stored in an ETS table owned by this GenServer, so subsequent
  fetches for a known domain can skip the failed providers and go straight to
  the provider that worked before.
  """

  use GenServer

  @table __MODULE__

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    :ets.new(@table, [
      :named_table,
      :public,
      read_concurrency: true,
      write_concurrency: true
    ])

    {:ok, %{}}
  end

  @doc """
  Returns the cached provider for `domain`, or `nil` when there is none.
  """
  def get(domain) do
    case :ets.lookup(@table, domain) do
      [{^domain, provider}] -> provider
      [] -> nil
    end
  end

  @doc """
  Caches `provider` as the provider that succeeded for `domain`, unless
  `domain` is already cached.

  Returns `true` when the provider was cached, `false` when `domain` was
  already cached.
  """
  def put_if_new(domain, provider) when is_binary(domain) do
    :ets.insert_new(@table, {domain, provider})
  end

  @doc """
  Clears all cached providers.
  """
  def clear do
    :ets.delete_all_objects(@table)
  end
end

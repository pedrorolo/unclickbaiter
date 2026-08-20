defmodule Unclickbaiter.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    env = Application.get_env(:unclickbaiter, :env)
    secrets = read_secrets(env)[env]
    Application.put_env(:unclickbaiter, :secrets, secrets)

    children = [
      UnclickbaiterWeb.Telemetry,
      Unclickbaiter.Repo,
      {DNSCluster,
       query: Application.get_env(:unclickbaiter, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Unclickbaiter.PubSub},
      Unclickbaiter.PreviewMetadata.HTTP.ProviderCache,
      # Start a worker by calling: Unclickbaiter.Worker.start_link(arg)
      # {Unclickbaiter.Worker, arg},
      # Start to serve requests, typically the last entry
      UnclickbaiterWeb.Endpoint
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Unclickbaiter.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    UnclickbaiterWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp read_secrets(:prod) do
    EncryptedSecrets.read!(System.fetch_env!("MASTER_KEY"), secrets_path())
  end

  defp read_secrets(_env) do
    EncryptedSecrets.read!(File.read!(master_key_path()), secrets_path())
  end

  defp secrets_path, do: Path.join(priv_dir(), "secrets/secrets.yml.enc")
  defp master_key_path, do: Path.join(priv_dir(), "secrets/master.key")
  defp priv_dir, do: :code.priv_dir(:unclickbaiter)
end

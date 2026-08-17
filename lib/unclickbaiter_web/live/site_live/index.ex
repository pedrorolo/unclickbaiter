defmodule UnclickbaiterWeb.SiteLive.Index do
  use UnclickbaiterWeb, :live_view

  alias Unclickbaiter.Sites

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Listing Sites
        <:actions>
          <.button variant="primary" navigate={~p"/sites/new"}>
            <.icon name="hero-plus" /> New Site
          </.button>
        </:actions>
      </.header>

      <.table
        id="sites"
        rows={@streams.sites}
        row_click={fn {_id, site} -> JS.navigate(~p"/sites/#{site}") end}
      >
        <:col :let={{_id, site}} label="Url">{site.url}</:col>
        <:col :let={{_id, site}} label="Title">{site.title}</:col>
        <:col :let={{_id, site}} label="Description">{site.description}</:col>
        <:action :let={{_id, site}}>
          <div class="sr-only">
            <.link navigate={~p"/sites/#{site}"}>Show</.link>
          </div>
          <.link navigate={~p"/sites/#{site}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, site}}>
          <.link
            phx-click={JS.push("delete", value: %{id: site.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Listing Sites")
     |> stream(:sites, list_sites())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    site = Sites.get_site!(id)
    {:ok, _} = Sites.delete_site(site)

    {:noreply, stream_delete(socket, :sites, site)}
  end

  defp list_sites do
    Sites.list_sites()
  end
end

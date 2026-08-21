defmodule UnclickbaiterWeb.PreviewLive.Index do
  use UnclickbaiterWeb, :live_view

  alias Unclickbaiter.Previews

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Listing Previews
        <:actions>
          <.button variant="primary" navigate={~p"/previews/new"}>
            <.icon name="hero-plus" /> New Preview
          </.button>
        </:actions>
      </.header>

      <.table
        id="previews"
        rows={@streams.previews}
        row_click={fn {_id, preview} -> JS.navigate(~p"/previews/#{preview}") end}
      >
        <:col :let={{_id, preview}} label="Url">{preview.url}</:col>
        <:col :let={{_id, preview}} label="Title">
          {preview.preview_metadata.title}
        </:col>
        <:col :let={{_id, preview}} label="Description">
          {preview.preview_metadata.description}
        </:col>
        <:action :let={{_id, preview}}>
          <div class="sr-only">
            <.link navigate={~p"/previews/#{preview}"}>Show</.link>
          </div>
          <.link navigate={~p"/previews/#{preview}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, preview}}>
          <.link
            phx-click={
              JS.push("delete", value: %{id: preview.id}) |> hide("##{id}")
            }
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
     |> assign(:page_title, "Listing Previews")
     |> stream(:previews, list_sites())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    preview = Previews.get_preview!(id)
    {:ok, _} = Previews.delete_preview(preview)

    {:noreply, stream_delete(socket, :previews, preview)}
  end

  defp list_sites do
    Previews.list_sites()
  end
end

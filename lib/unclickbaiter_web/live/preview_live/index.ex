defmodule UnclickbaiterWeb.PreviewLive.Index do
  use UnclickbaiterWeb, :live_view

  alias Unclickbaiter.Previews

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <header class="flex items-center justify-between gap-6 pb-4">
        <div>
          <h1 class="text-lg font-semibold leading-8">
            Listing Previews
          </h1>
        </div>
        <div class="flex-none">
          <.button variant="primary" navigate={~p"/p/new"}>
            <.icon name="hero-plus" /> New Preview
          </.button>
        </div>
      </header>

      <.table
        id="previews"
        rows={@streams.previews}
        row_click={fn {_id, preview} -> JS.navigate(~p"/p/#{preview}") end}
      >
        <:col :let={{_id, preview}} label="Title">
          {preview.preview_metadata.title}
        </:col>
        <:col :let={{_id, preview}} label="Description">
          <span class="block line-clamp-2">{preview.preview_metadata.description}</span>
        </:col>
        <:col :let={{_id, preview}} label="Url">
          <span class="block line-clamp-2 break-all">{preview.url}</span>
        </:col>
        <:action :let={{_id, preview}}>
          <button
            type="button"
            class="btn btn-xs btn-ghost tooltip"
            data-tip="Copy link"
            phx-click="copy-show-url"
            phx-value-slug={preview.slug}
            aria-label="Copy link"
          >
            <.icon name="hero-clipboard" class="size-4" />
          </button>
        </:action>
        <:action :let={{_id, preview}}>
          <div class="sr-only">
            <.link navigate={~p"/p/#{preview}"}>Show</.link>
          </div>
          <%= if preview.user_id == @current_scope.user.id do %>
            <.link
              navigate={~p"/p/#{preview}/edit"}
              class="btn btn-xs btn-ghost tooltip"
              data-tip="Edit"
              aria-label="Edit"
            >
              <.icon name="hero-pencil" class="size-4" />
            </.link>
          <% end %>
        </:action>
        <:action :let={{id, preview}}>
          <%= if preview.user_id == @current_scope.user.id do %>
            <.link
              phx-click={
                JS.push("delete", value: %{id: preview.id}) |> hide("##{id}")
              }
              data-confirm="Are you sure?"
              class="btn btn-xs btn-ghost tooltip"
              data-tip="Delete"
              aria-label="Delete"
            >
              <.icon name="hero-trash" class="size-4" />
            </.link>
          <% end %>
        </:action>
      </.table>

      <%= if @pagination.total_pages > 1 do %>
        <div class="flex items-center justify-between mt-6">
          <p class="text-sm text-base-content/60">
            Page {@pagination.page} of {@pagination.total_pages} ({@pagination.total} previews)
          </p>
          <div class="flex gap-2">
            <.button
              :if={@pagination.page > 1}
              phx-click="paginate"
              phx-value-page={@pagination.page - 1}
            >
              <.icon name="hero-chevron-left" class="size-4" /> Previous
            </.button>
            <.button
              :if={@pagination.page < @pagination.total_pages}
              phx-click="paginate"
              phx-value-page={@pagination.page + 1}
            >
              Next <.icon name="hero-chevron-right" class="size-4" />
            </.button>
          </div>
        </div>
      <% end %>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {previews, pagination} = list_previews(socket.assigns.current_scope, %{})

    {:ok,
     socket
     |> assign(:page_title, "Listing Previews")
     |> assign(:pagination, pagination)
     |> stream(:previews, previews)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    preview = Previews.get_preview!(id)

    if preview.user_id == socket.assigns.current_scope.user.id do
      {:ok, _} = Previews.delete_preview(preview)
      {:noreply, stream_delete(socket, :previews, preview)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("paginate", %{"page" => page}, socket) do
    {previews, pagination} =
      list_previews(socket.assigns.current_scope, %{"page" => page})

    {:noreply,
     socket
     |> assign(:pagination, pagination)
     |> stream(:previews, previews, reset: true)}
  end

  def handle_event("copy-show-url", %{"slug" => slug}, socket) do
    url = "/p/#{slug}"
    {:noreply, push_event(socket, "copy-to-clipboard", %{url: url})}
  end

  defp list_previews(scope, params) do
    Previews.list_previews(scope, params)
  end
end

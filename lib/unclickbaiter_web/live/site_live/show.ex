defmodule UnclickbaiterWeb.SiteLive.Show do
  use UnclickbaiterWeb, :live_view

  alias Unclickbaiter.Sites

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Site {@site.id}
        <:subtitle>This is a site record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/sites"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button
            variant="primary"
            navigate={~p"/sites/#{@site}/edit?return_to=show"}
          >
            <.icon name="hero-pencil-square" /> Edit site
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Url">{@site.url}</:item>
        <:item title="Title">{@site.title}</:item>
        <:item title="Description">{@site.description}</:item>
      </.list>

      <div class="mt-8 overflow-hidden rounded-2xl border border-zinc-200 shadow-sm">
        <iframe
          id="site-frame"
          src={@site.url}
          title={@site.title}
          class="h-[70vh] w-full bg-white"
          loading="lazy"
        />
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Show Site")
     |> assign(:site, Sites.get_site!(id))}
  end
end

defmodule UnclickbaiterWeb.Components.PreviewCard do
  @moduledoc """
  Function component that renders a link preview card, similar to how a
  shared link looks when unfurled on social media platforms.

  Accepts plain values (`url`, `title`, `description`, `image_url`) so it can
  be used both from forms (values extracted from a form/changeset) and from
  loaded structs.
  """

  use Phoenix.Component

  import UnclickbaiterWeb.CoreComponents, only: [icon: 1]

  attr :id, :string, required: true
  attr :class, :string, default: nil
  attr :fetching, :boolean, default: false
  attr :url, :string, default: nil
  attr :title, :string, default: nil
  attr :description, :string, default: nil
  attr :image_url, :string, default: nil

  def preview_card(assigns) do
    ~H"""
    <a
      id={@id}
      href={@url}
      target="_blank"
      rel="noopener noreferrer"
      class={[
        "card overflow-hidden border border-base-300 bg-base-100 hover:shadow-lg transition-shadow",
        @class
      ]}
    >
      <%= if @fetching do %>
        <div class="flex h-40 w-full items-center justify-center bg-base-200">
          <.icon
            name="hero-arrow-path"
            class="size-10 animate-spin text-base-content/30"
          />
        </div>
        <div class="space-y-2 p-4">
          <div class="h-4 w-1/2 animate-pulse rounded bg-base-200"></div>
          <div class="h-3 w-3/4 animate-pulse rounded bg-base-200"></div>
          <div class="h-3 w-2/3 animate-pulse rounded bg-base-200"></div>
        </div>
      <% else %>
        <%= if @image_url do %>
          <div class="bg-base-200">
            <img
              src={@image_url}
              alt="Preview image"
              class="mx-auto max-h-60 w-full object-contain"
              onerror="this.remove()"
            />
          </div>
        <% else %>
          <div class="flex h-40 w-full items-center justify-center bg-base-200">
            <.icon name="hero-photo" class="size-10 text-base-content/30" />
          </div>
        <% end %>
        <div class="p-4">
          <h3 class="mt-1 text-xl font-semibold leading-snug">
            {@title || "Title"}
          </h3>
          <p class="mt-1 text-sm text-base-content/70">
            {@description || "Description"}
          </p>
        </div>
      <% end %>
    </a>
    """
  end
end

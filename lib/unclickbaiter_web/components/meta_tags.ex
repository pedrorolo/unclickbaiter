defmodule UnclickbaiterWeb.MetaTags do
  use Phoenix.Component

  alias UnclickbaiterWeb.OpenGraph

  @moduledoc """
  Render OpenGraph and Twitter meta tags from assigns.

  Accepts either:
    * :og - an %OpenGraph{} struct
    * :site - a %Unclickbaiter.Sites.Site{} struct (converted via OpenGraph.from_site/2)
    * page_title, page_description, page_image_url assigns (fallback)
  """

  def meta_tags(assigns) do
    og = build_og_from_assigns(assigns)
    assigns = Map.put(assigns, :og, og)

    ~H"""
    <%!-- Render each meta tag, using property for og:* and name for others --%>
    <%= for {name, content} <- OpenGraph.to_meta_tags(@og) do %>
      <%= if String.starts_with?(name, "og:") do %>
        <meta property={name} content={content} />
      <% else %>
        <meta name={name} content={content} />
      <% end %>
    <% end %>
    """
  end

  defp build_og_from_assigns(assigns) do
    cond do
      assigns[:site] ->
        OpenGraph.from_site(assigns.site)

      assigns[:page_title] || assigns[:page_description] ||
          assigns[:page_image_url] ->
        %OpenGraph{
          title: assigns[:page_title],
          description: assigns[:page_description],
          url: assigns[:page_url] || nil,
          image: assigns[:page_image_url] || nil,
          type: "website",
          twitter_card: "summary_large_image"
        }

      true ->
        %OpenGraph{}
    end
  end
end

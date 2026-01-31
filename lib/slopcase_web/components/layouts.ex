defmodule SlopcaseWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use SlopcaseWeb, :html

  defp admin?(nil), do: false
  defp admin?(%{user: nil}), do: false
  defp admin?(%{user: user}), do: user.admin

  defp logged_in?(nil), do: false
  defp logged_in?(%{user: nil}), do: false
  defp logged_in?(%{user: _user}), do: true

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block, required: true
  slot :modal, doc: "slot for modal dialogs, rendered outside main container"

  def app(assigns) do
    ~H"""
    <header class="app-header">
      <div class="app-header__inner">
        <a href="/" class="brand">
          <span class="brand-mark">VC</span>
          <span class="brand-copy">
            <span class="brand-title">Vibecheck</span>
            <span class="brand-subtitle">Is it valid or is it slop?</span>
          </span>
        </a>
        <nav class="app-nav">
          <.link :if={admin?(@current_scope)} navigate="/admin/submissions" class="nav-link">
            Admin
          </.link>
          <%= if logged_in?(@current_scope) do %>
            <.link navigate="/users/settings" class="nav-link">
              Settings
            </.link>
            <.link href="/users/log-out" method="delete" class="nav-link">
              Log out
            </.link>
          <% else %>
            <.link navigate="/users/log-in" class="nav-link">
              Log in
            </.link>
          <% end %>
          <button type="button" class="btn btn--primary" phx-click="open-submit-modal">
            Submit
          </button>
        </nav>
      </div>
    </header>

    <main class="app-main">
      <div class="app-container">
        {render_slot(@inner_block)}
      </div>
    </main>

    <footer class="app-footer">
      <div class="app-footer__inner">
        <p class="footer-text">
          Built with Phoenix LiveView. No apologies, just vibes.
        </p>
      </div>
    </footer>

    <.flash_group flash={@flash} />
    {render_slot(@modal)}
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite" class="flash-stack">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title="We can't find the internet"
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        Attempting to reconnect
        <.icon name="hero-arrow-path" class="icon icon--xs icon--spin flash-inline-icon" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title="Something went wrong!"
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        Attempting to reconnect
        <.icon name="hero-arrow-path" class="icon icon--xs icon--spin flash-inline-icon" />
      </.flash>
    </div>
    """
  end
end

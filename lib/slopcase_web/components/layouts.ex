defmodule SlopcaseWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use SlopcaseWeb, :html

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

  def app(assigns) do
    ~H"""
    <header class="app-header">
      <div class="app-header__inner">
        <a href="/" class="brand">
          <span class="brand-mark">SC</span>
          <span class="brand-copy">
            <span class="brand-title">Slopcase</span>
            <span class="brand-subtitle">AI Slop Showcase</span>
          </span>
        </a>
        <nav class="app-nav">
          <a href="#submission-form" class="nav-link">Submit</a>
          <a href="#submissions-list" class="nav-link">Browse</a>
        </nav>
        <a href="#submission-form" class="btn btn--primary">Submit</a>
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
        <a href="#submission-form" class="footer-link">Drop your slop</a>
      </div>
    </footer>

    <.flash_group flash={@flash} />
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

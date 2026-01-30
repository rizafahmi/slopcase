defmodule SlopcaseWeb.ShowcaseLive do
  use SlopcaseWeb, :live_view

  def mount(_params, _session, socket) do
    form = to_form(%{}, as: :submission)

    {:ok,
     socket
     |> assign(:page_title, "Slopcase Showcase")
     |> assign(:form, form)
     |> stream(:submissions, [])}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <section id="showcase-hero" class="showcase-hero">
        <div class="showcase-hero__inner">
          <p class="showcase-kicker">Let’s embrace the AI Slop</p>
          <h1 class="showcase-title">Vibe-coded apps, proudly imperfect.</h1>
          <p class="showcase-lede">
            Submit what you built, vote if it’s slop, and celebrate the chaotic beauty of shipping.
          </p>
          <div class="showcase-hero__actions">
            <a class="cta-link" href="#submission-form">Submit your slop</a>
            <span class="cta-meta">No account. No judgment. Just vibes.</span>
          </div>
        </div>
      </section>

      <section class="showcase-section">
        <div class="section-header">
          <h2 class="section-title">Submit your creation</h2>
          <p class="section-subtitle">Tell us what you shipped and why it’s iconic.</p>
        </div>

        <.form for={@form} id="submission-form" phx-change="validate" phx-submit="save">
          <div class="form-grid">
            <.input field={@form[:title]} type="text" label="Title" required />

            <div class="form-field">
              <span class="form-label">Is it slop?</span>
              <div class="pill-toggle" role="radiogroup" aria-label="Is it slop">
                <label class="pill-option" for="submission_slop_true">
                  <input
                    type="radio"
                    id="submission_slop_true"
                    name={@form[:slop].name}
                    value="true"
                    required
                  />
                  Slop
                </label>
                <label class="pill-option" for="submission_slop_false">
                  <input
                    type="radio"
                    id="submission_slop_false"
                    name={@form[:slop].name}
                    value="false"
                    required
                  />
                  Not slop
                </label>
              </div>
            </div>

            <.input field={@form[:app_url]} type="url" label="App URL" placeholder="https://..." />
            <.input field={@form[:repo_url]} type="url" label="Repo URL" placeholder="https://..." />
            <.input field={@form[:model]} type="text" label="Model" placeholder="GPT-5, Claude, etc." />
            <.input field={@form[:tools]} type="text" label="Tools" placeholder="Cursor, Replit, etc." />
            <.input field={@form[:notes]} type="textarea" label="Notes" placeholder="Anything else worth flexing?" />
          </div>

          <div class="form-actions">
            <.button type="submit">Submit the slop</.button>
          </div>
        </.form>
      </section>

      <section class="showcase-section">
        <div class="section-header">
          <h2 class="section-title">Fresh from the slop stream</h2>
          <p class="section-subtitle">New drops appear here the moment they’re submitted.</p>
        </div>

        <div id="submissions-list" class="submissions-grid" phx-update="stream">
          <div id="submissions-empty" class="submissions-empty hidden only:block">
            No slop yet. Be the first to ship.
          </div>
          <div :for={{id, submission} <- @streams.submissions} id={id} class="submission-card">
            <div class="submission-card__header">
              <span class="submission-title">{submission.title}</span>
              <span class="submission-pill">Slop</span>
            </div>
            <p class="submission-meta">Details will appear once submissions roll in.</p>
          </div>
        </div>
      </section>
    </Layouts.app>
    """
  end
end

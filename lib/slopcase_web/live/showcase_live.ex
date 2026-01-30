defmodule SlopcaseWeb.ShowcaseLive do
  use SlopcaseWeb, :live_view

  alias Slopcase.Showcase
  alias Slopcase.Showcase.Submission

  def mount(_params, _session, socket) do
    submissions = Showcase.list_submissions()

    form =
      %Submission{}
      |> Showcase.change_submission()
      |> to_form()

    {:ok,
     socket
     |> assign(:page_title, "Slopcase Showcase")
     |> assign(:form, form)
     |> stream(:submissions, submissions)}
  end

  def handle_event("validate", %{"submission" => submission_params}, socket) do
    changeset =
      %Submission{}
      |> Showcase.change_submission(submission_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("save", %{"submission" => submission_params}, socket) do
    case Showcase.create_submission(submission_params) do
      {:ok, submission} ->
        {:noreply,
         socket
         |> stream_insert(:submissions, submission, at: 0)
         |> assign(:form, to_form(Showcase.change_submission(%Submission{})))
         |> put_flash(:info, "Slop logged. The vibes are immaculate.")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.hero />
      <.submission_form form={@form} />
      <.submissions_list streams={@streams} />
    </Layouts.app>
    """
  end

  defp hero(assigns) do
    ~H"""
    <section id="showcase-hero" class="showcase-hero">
      <div class="showcase-hero__inner">
        <p class="showcase-kicker">Let's embrace the AI Slop</p>
        <h1 class="showcase-title">Vibe-coded apps, proudly imperfect.</h1>
        <p class="showcase-lede">
          Submit what you built, vote if it's slop, and celebrate the chaotic beauty of shipping.
        </p>
        <div class="showcase-hero__actions">
          <a class="cta-link" href="#submission-form">Submit your slop</a>
          <span class="cta-meta">No account. No judgment. Just vibes.</span>
        </div>
      </div>
    </section>
    """
  end

  defp submission_form(assigns) do
    ~H"""
    <section class="showcase-section">
      <div class="section-header">
        <h2 class="section-title">Submit your creation</h2>
        <p class="section-subtitle">Tell us what you shipped and why it's iconic.</p>
      </div>

      <.form for={@form} id="submission-form" phx-change="validate" phx-submit="save">
        <div class="form-grid">
          <.input field={@form[:title]} type="text" label="Title" required />

          <div class="form-field">
            <div class="form-label">
              <span class="form-label__text">Is it slop?</span>
            </div>
            <.slop_radio_group field={@form[:slop]} />
          </div>

          <.input field={@form[:app_url]} type="url" label="App URL" placeholder="https://..." />
          <.input field={@form[:repo_url]} type="url" label="Repo URL" placeholder="https://..." />
          <.input
            field={@form[:model]}
            type="text"
            label="Model"
            placeholder="GPT-5, Claude, etc."
          />
          <.input
            field={@form[:tools]}
            type="text"
            label="Tools"
            placeholder="Cursor, Replit, etc."
          />
          <.input
            field={@form[:notes]}
            type="textarea"
            label="Notes"
            placeholder="Anything else worth flexing?"
          />
        </div>

        <div class="form-actions">
          <.button type="submit" variant="primary">Submit the slop</.button>
        </div>
      </.form>
    </section>
    """
  end

  defp slop_radio_group(assigns) do
    ~H"""
    <div class="pill-toggle" role="radiogroup" aria-label="Is it slop">
      <label class="pill-option" for="submission_slop_true">
        <input
          type="radio"
          id="submission_slop_true"
          name={@field.name}
          value="true"
          checked={@field.value in [true, "true"]}
          required
        /> Slop
      </label>
      <label class="pill-option" for="submission_slop_false">
        <input
          type="radio"
          id="submission_slop_false"
          name={@field.name}
          value="false"
          checked={@field.value in [false, "false"]}
          required
        /> Not slop
      </label>
    </div>
    """
  end

  defp submissions_list(assigns) do
    ~H"""
    <section class="showcase-section">
      <div class="section-header">
        <h2 class="section-title">Fresh from the slop stream</h2>
        <p class="section-subtitle">New drops appear here the moment they're submitted.</p>
      </div>

      <div id="submissions-list" class="submissions-grid" phx-update="stream">
        <div id="submissions-empty" class="submissions-empty hidden only:block">
          No slop yet. Be the first to ship.
        </div>
        <.submission_card
          :for={{id, submission} <- @streams.submissions}
          id={id}
          submission={submission}
        />
      </div>
    </section>
    """
  end

  defp submission_card(assigns) do
    ~H"""
    <div id={@id} class="submission-card">
      <div class="submission-card__header">
        <span class="submission-title">{@submission.title}</span>
        <span class={slop_badge_class(@submission.slop)}>{slop_label(@submission.slop)}</span>
      </div>
      <div class="submission-card__links">
        <a
          :if={@submission.app_url}
          class="submission-link"
          href={@submission.app_url}
          target="_blank"
          rel="noreferrer noopener"
        >
          App
        </a>
        <a
          :if={@submission.repo_url}
          class="submission-link"
          href={@submission.repo_url}
          target="_blank"
          rel="noreferrer noopener"
        >
          Repo
        </a>
      </div>
      <div class="submission-meta">
        <span :if={@submission.model} class="submission-detail">
          Model: {@submission.model}
        </span>
        <span :if={@submission.tools} class="submission-detail">
          Tools: {@submission.tools}
        </span>
      </div>
      <p :if={@submission.notes} class="submission-notes">{@submission.notes}</p>
    </div>
    """
  end

  defp slop_label(true), do: "Slop"
  defp slop_label(false), do: "Not slop"

  defp slop_badge_class(true), do: ["submission-pill", "submission-pill--slop"]
  defp slop_badge_class(false), do: ["submission-pill", "submission-pill--clean"]
end

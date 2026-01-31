defmodule SlopcaseWeb.ShowcaseLive do
  use SlopcaseWeb, :live_view

  alias Slopcase.Showcase
  alias Slopcase.Showcase.Submission

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Showcase.subscribe()
    end

    submissions = Showcase.list_submissions()
    submission_ids = Enum.map(submissions, & &1.id)
    vote_counts = Showcase.vote_counts(submission_ids)

    form =
      %Submission{}
      |> Showcase.change_submission()
      |> to_form()

    voter_ip =
      if connected?(socket) do
        case get_connect_info(socket, :peer_data) do
          %{address: addr} -> addr |> :inet.ntoa() |> to_string()
          # Fallback for test environment where peer_data is not available
          _ -> "127.0.0.1"
        end
      else
        # Static render (pre-connect), use fallback
        "127.0.0.1"
      end

    {:ok,
     socket
     |> assign(:page_title, "Vibecheck")
     |> assign(:form, form)
     |> assign(:vote_counts, vote_counts)
     |> assign(:voter_ip, voter_ip)
     |> stream(:submissions, submissions)}
  end

  def handle_event("open-submit-modal", _params, socket) do
    {:noreply, push_event(socket, "js-exec", %{to: "#submission-modal", attr: "data-show"})}
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
        vote_counts = Map.put(socket.assigns.vote_counts, submission.id, %{slop: 0, not_slop: 0})

        {:noreply,
         socket
         |> stream_insert(:submissions, submission, at: 0)
         |> assign(:vote_counts, vote_counts)
         |> assign(:form, to_form(Showcase.change_submission(%Submission{})))
         |> push_event("js-exec", %{to: "#submission-modal", attr: "phx-remove"})
         |> put_flash(:info, "Submitted! The vibes are immaculate.")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  def handle_event("vote", %{"id" => id_str, "verdict" => verdict_str}, socket) do
    submission_id = String.to_integer(id_str)
    verdict = verdict_str == "true"
    voter_ip = socket.assigns.voter_ip

    if is_nil(voter_ip) do
      {:noreply, put_flash(socket, :error, "Unable to record vote.")}
    else
      case Showcase.vote(submission_id, verdict, voter_ip) do
        {:ok, _vote} ->
          {:noreply, socket}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, "You've already voted on this submission.")}
      end
    end
  end

  def handle_info({:vote_updated, vote}, socket) do
    key = if vote.verdict, do: :slop, else: :not_slop
    submission_id = vote.submission_id
    default = %{slop: 0, not_slop: 0}

    new_counts =
      Map.update(
        socket.assigns.vote_counts,
        submission_id,
        Map.put(default, key, 1),
        &Map.update!(&1, key, fn count -> count + 1 end)
      )

    # Stream items only re-render on stream_insert, so we need to
    # re-insert the submission to update its displayed vote counts
    socket =
      case Showcase.get_submission(submission_id) do
        nil -> socket
        submission -> stream_insert(socket, :submissions, submission)
      end

    {:noreply, assign(socket, :vote_counts, new_counts)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.submissions_list streams={@streams} vote_counts={@vote_counts} />
      <:modal>
        <.submission_modal form={@form} />
      </:modal>
    </Layouts.app>
    """
  end

  defp submission_modal(assigns) do
    ~H"""
    <.modal id="submission-modal">
      <div class="section-header">
        <h2 class="section-title">Submit your creation</h2>
        <p class="section-subtitle">Tell us what you shipped and why it's iconic.</p>
      </div>

      <.form for={@form} id="submission-form" phx-change="validate" phx-submit="save">
        <div class="form-grid">
          <.input field={@form[:title]} type="text" label="Title" required />
          <.input field={@form[:app_url]} type="text" label="App URL" placeholder="example.com" />
          <.input
            field={@form[:repo_url]}
            type="text"
            label="Repo URL"
            placeholder="github.com/user/repo"
          />
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
          <.button type="submit" variant="primary">Drop it</.button>
        </div>
      </.form>
    </.modal>
    """
  end

  defp submissions_list(assigns) do
    ~H"""
    <section class="showcase-section">
      <div class="section-header">
        <h2 class="section-title">Fresh drops</h2>
        <p class="section-subtitle">New drops appear here the moment they're submitted.</p>
      </div>

      <div id="submissions-list" class="submissions-grid" phx-update="stream">
        <div id="submissions-empty" class="submissions-empty hidden only:block">
          Nothing here yet. Be the first to ship.
        </div>
        <.submission_card
          :for={{id, submission} <- @streams.submissions}
          id={id}
          submission={submission}
          vote_counts={@vote_counts}
        />
      </div>
    </section>
    """
  end

  defp submission_card(assigns) do
    counts = Map.get(assigns.vote_counts, assigns.submission.id, %{slop: 0, not_slop: 0})
    assigns = assign(assigns, :counts, counts)

    ~H"""
    <div id={@id} class="submission-card">
      <div class="submission-card__thumbnail">
        <img
          :if={@submission.thumbnail_url}
          src={@submission.thumbnail_url}
          alt={"Screenshot of #{@submission.title}"}
          loading="lazy"
        />
        <div :if={!@submission.thumbnail_url} class="submission-card__placeholder">
          <.icon name="hero-photo" class="w-8 h-8" />
        </div>
      </div>
      <div class="submission-card__header">
        <span class="submission-title">{@submission.title}</span>
      </div>
      <div class="submission-card__links">
        <a
          :if={@submission.app_url}
          class="submission-link"
          href={@submission.app_url}
          target="_blank"
          rel="noreferrer noopener"
        >
          <.icon name="hero-globe-alt" class="icon--xs" />
          <span>App</span>
          <.icon name="hero-arrow-top-right-on-square" class="icon--xs submission-link__external" />
        </a>
        <a
          :if={@submission.repo_url}
          class="submission-link"
          href={@submission.repo_url}
          target="_blank"
          rel="noreferrer noopener"
        >
          <.icon name="hero-code-bracket" class="icon--xs" />
          <span>Repo</span>
          <.icon name="hero-arrow-top-right-on-square" class="icon--xs submission-link__external" />
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
      <div class="submission-votes">
        <button
          type="button"
          class="vote-btn vote-btn--slop"
          phx-click="vote"
          phx-value-id={@submission.id}
          phx-value-verdict="true"
        >
          Slop <span class="vote-count">{@counts.slop}</span>
        </button>
        <button
          type="button"
          class="vote-btn vote-btn--clean"
          phx-click="vote"
          phx-value-id={@submission.id}
          phx-value-verdict="false"
        >
          Valid <span class="vote-count">{@counts.not_slop}</span>
        </button>
      </div>
    </div>
    """
  end
end

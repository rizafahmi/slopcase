defmodule SlopcaseWeb.ShowcaseLive do
  use SlopcaseWeb, :live_view

  alias Slopcase.Showcase
  alias Slopcase.Showcase.Submission

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Showcase.subscribe()
    end

    submissions = Showcase.list_submissions(limit: 20)

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

    first_id = case submissions do
      [first | _] -> first.id
      [] -> nil
    end

    {:ok,
     socket
     |> assign(:page_title, "Vibecheck")
     |> assign(:form, form)
     |> assign(:voter_ip, voter_ip)
     |> assign(:page, 1)
     |> assign(:first_submission_id, first_id)
     # We need to track if we have more submissions to load.
     # A simple heuristic check: if we got exactly the limit (20), assume more exist.
     |> assign(:has_more?, length(submissions) == 20)
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
         {:noreply,
          socket
          |> stream_insert(:submissions, submission, at: 0)
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

  def handle_event("load-more", _params, socket) do
    page = socket.assigns.page + 1
    offset = (page - 1) * 20
    submissions = Showcase.list_submissions(limit: 20, offset: offset)

    {:noreply,
     socket
     |> assign(:page, page)
     |> assign(:has_more?, length(submissions) == 20)
     |> stream(:submissions, submissions, at: -1)}
  end

  def handle_info({:submission_created, submission}, socket) do
    {:noreply, stream_insert(socket, :submissions, submission, at: 0)}
  end

  def handle_info({:submission_updated, submission}, socket) do
    {:noreply, stream_insert(socket, :submissions, submission)}
  end

  def handle_info({:vote_updated, vote}, socket) do
    # Re-fetch the submission to get updated counts
    # This is more efficient than re-fetching everything, but still hits DB
    # Optimized flow: the DB update happened, now we get the fresh state.
    # Since we are using virtual fields, we must reload the submission.
    case Showcase.get_submission(vote.submission_id) do
      nil -> {:noreply, socket}
      submission -> {:noreply, stream_insert(socket, :submissions, submission)}
    end
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.submissions_list streams={@streams} has_more?={@has_more?} first_submission_id={@first_submission_id} />
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
        <h2 class="section-title">Check the Vibe</h2>
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
          priority={submission.id == @first_submission_id}
        />
      </div>

      <div :if={@has_more?} class="load-more-container mt-8 flex justify-center">
        <.button phx-click="load-more">Load More</.button>
      </div>
    </section>
    """
  end

  attr :id, :string, required: true
  attr :submission, :map, required: true
  attr :priority, :boolean, default: false

  defp submission_card(assigns) do
    ~H"""
    <div id={@id} class="submission-card">
      <div class="submission-card__thumbnail">
        <img
          :if={@submission.thumbnail_url && @priority}
          src={@submission.thumbnail_url}
          alt={"Screenshot of #{@submission.title}"}
          fetchpriority="high"
        />
        <img
          :if={@submission.thumbnail_url && !@priority}
          src={@submission.thumbnail_url}
          alt={"Screenshot of #{@submission.title}"}
          loading="lazy"
        />
        <div :if={!@submission.thumbnail_url} class="submission-card__placeholder">
          <.icon name="hero-photo" class="w-8 h-8" />
        </div>
      </div>
      <div class="submission-card__header">
        <.link navigate={~p"/p/#{@submission.slug}"} class="submission-title">
          {@submission.title}
        </.link>
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
          Miss <span class="vote-count">{@submission.slop_count || 0}</span>
        </button>
        <button
          type="button"
          class="vote-btn vote-btn--clean"
          phx-click="vote"
          phx-value-id={@submission.id}
          phx-value-verdict="false"
        >
          Hit <span class="vote-count">{@submission.not_slop_count || 0}</span>
        </button>
      </div>
    </div>
    """
  end
end

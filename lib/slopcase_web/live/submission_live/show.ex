defmodule SlopcaseWeb.SubmissionLive.Show do
  use SlopcaseWeb, :live_view

  alias Slopcase.Showcase

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    case Showcase.get_submission(slug) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Submission not found")
         |> redirect(to: ~p"/")}

      submission ->
        if connected?(socket), do: Showcase.subscribe()

        voter_ip =
          if connected?(socket) do
            case get_connect_info(socket, :peer_data) do
              %{address: addr} -> addr |> :inet.ntoa() |> to_string()
              _ -> "127.0.0.1"
            end
          else
            "127.0.0.1"
          end

        {:ok,
         socket
         |> assign(:submission, submission)
         |> assign(:voter_ip, voter_ip)
         |> assign(:page_title, submission.title)
         |> assign(:meta_description, build_meta_description(submission))
         |> assign(:og_image, submission.thumbnail_url)}
    end
  end

  defp build_meta_description(submission) do
    base = "#{submission.title} - An AI-generated project"

    details =
      [
        if(submission.model, do: "built with #{submission.model}"),
        if(submission.tools, do: "using #{submission.tools}")
      ]
      |> Enum.filter(& &1)
      |> Enum.join(" ")

    if details != "", do: "#{base} #{details}. Vote: slop or valid?", else: "#{base}. Vote: slop or valid?"
  end

  @impl true
  def handle_event("vote", %{"verdict" => verdict_str}, socket) do
    verdict = verdict_str == "true"
    voter_ip = socket.assigns.voter_ip
    submission_id = socket.assigns.submission.id

    case Showcase.vote(submission_id, verdict, voter_ip) do
      {:ok, _vote} ->
        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "You've already voted on this submission.")}
    end
  end

  @impl true
  def handle_info({:vote_updated, vote}, socket) do
    if vote.submission_id == socket.assigns.submission.id do
      # Reload the submission to get updated counts
      case Showcase.get_submission(vote.submission_id) do
        nil -> {:noreply, socket}
        submission -> {:noreply, assign(socket, :submission, submission)}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_info({:submission_updated, submission}, socket) do
    if submission.id == socket.assigns.submission.id do
      {:noreply, assign(socket, :submission, submission)}
    else
      {:noreply, socket}
    end
  end

  def handle_info(_msg, socket), do: {:noreply, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="submission-detail">
        <.link navigate={~p"/"} class="back-link">
          <.icon name="hero-arrow-left" class="icon--xs" />
          <span>Back to all submissions</span>
        </.link>

        <article class="submission-detail__card">
          <div class="submission-detail__thumbnail">
            <img
              :if={@submission.thumbnail_url}
              src={@submission.thumbnail_url}
              alt={"Screenshot of #{@submission.title}"}
            />
            <div :if={!@submission.thumbnail_url} class="submission-card__placeholder submission-card__placeholder--large">
              <.icon name="hero-photo" class="w-12 h-12" />
            </div>
          </div>

          <div class="submission-detail__content">
            <h1 class="submission-detail__title">{@submission.title}</h1>

            <div class="submission-detail__links">
              <a
                :if={@submission.app_url}
                class="submission-link submission-link--large"
                href={@submission.app_url}
                target="_blank"
                rel="noreferrer noopener"
              >
                <.icon name="hero-globe-alt" class="icon--sm" />
                <span>Visit App</span>
                <.icon name="hero-arrow-top-right-on-square" class="icon--xs" />
              </a>
              <a
                :if={@submission.repo_url}
                class="submission-link submission-link--large"
                href={@submission.repo_url}
                target="_blank"
                rel="noreferrer noopener"
              >
                <.icon name="hero-code-bracket" class="icon--sm" />
                <span>View Repo</span>
                <.icon name="hero-arrow-top-right-on-square" class="icon--xs" />
              </a>
            </div>

            <dl class="submission-detail__meta">
              <div :if={@submission.model} class="meta-item">
                <dt>Model</dt>
                <dd>{@submission.model}</dd>
              </div>
              <div :if={@submission.tools} class="meta-item">
                <dt>Tools</dt>
                <dd>{@submission.tools}</dd>
              </div>
            </dl>

            <p :if={@submission.notes} class="submission-detail__notes">{@submission.notes}</p>

            <div class="submission-detail__votes">
              <span class="vote-label">What's the verdict?</span>
              <div class="vote-buttons">
                <button
                  type="button"
                  class="vote-btn vote-btn--slop vote-btn--large"
                  phx-click="vote"
                  phx-value-verdict="true"
                >
                  🗑️ Slop <span class="vote-count">{@submission.slop_count || 0}</span>
                </button>
                <button
                  type="button"
                  class="vote-btn vote-btn--clean vote-btn--large"
                  phx-click="vote"
                  phx-value-verdict="false"
                >
                  ✨ Valid <span class="vote-count">{@submission.not_slop_count || 0}</span>
                </button>
              </div>
            </div>

            <div class="submission-detail__share">
              <span class="share-label">Share this submission:</span>
              <div class="share-buttons">
                <.share_button platform="twitter" submission={@submission} />
                <.share_button platform="copy" submission={@submission} />
              </div>
            </div>
          </div>
        </article>
      </div>
    </Layouts.app>
    """
  end

  defp share_button(%{platform: "twitter"} = assigns) do
    text = "Check out \"#{assigns.submission.title}\" on Vibecheck – is it slop or valid? 🎰"

    assigns = assign(assigns, :share_url, "https://twitter.com/intent/tweet?text=#{URI.encode(text)}&url=")

    ~H"""
    <a
      href={@share_url}
      target="_blank"
      rel="noopener noreferrer"
      class="share-btn share-btn--twitter"
      data-submission-url={~p"/p/#{@submission.slug}"}
      onclick="this.href = this.href + encodeURIComponent(window.location.origin + this.dataset.submissionUrl)"
    >
      <svg class="icon--sm" viewBox="0 0 24 24" fill="currentColor">
        <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z" />
      </svg>
      <span>Share on X</span>
    </a>
    """
  end

  defp share_button(%{platform: "copy"} = assigns) do
    ~H"""
    <button
      type="button"
      class="share-btn share-btn--copy"
      data-submission-url={~p"/p/#{@submission.slug}"}
      onclick="navigator.clipboard.writeText(window.location.origin + this.dataset.submissionUrl).then(() => { this.querySelector('span').textContent = 'Copied!'; setTimeout(() => this.querySelector('span').textContent = 'Copy Link', 2000); })"
    >
      <.icon name="hero-link" class="icon--sm" />
      <span>Copy Link</span>
    </button>
    """
  end
end

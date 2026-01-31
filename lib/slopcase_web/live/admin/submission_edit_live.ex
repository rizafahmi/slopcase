defmodule SlopcaseWeb.Admin.SubmissionEditLive do
  use SlopcaseWeb, :live_view

  alias Slopcase.Showcase

  def mount(%{"id" => id}, _session, socket) do
    submission = Showcase.get_submission!(id)

    form =
      submission
      |> Showcase.change_submission()
      |> to_form()

    {:ok,
     socket
     |> assign(:page_title, "Edit Submission")
     |> assign(:submission, submission)
     |> assign(:form, form)}
  end

  def handle_event("validate", %{"submission" => params}, socket) do
    changeset =
      socket.assigns.submission
      |> Showcase.change_submission(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("save", %{"submission" => params}, socket) do
    case Showcase.update_submission(socket.assigns.submission, params) do
      {:ok, _submission} ->
        {:noreply,
         socket
         |> put_flash(:info, "Submission updated.")
         |> push_navigate(to: ~p"/admin/submissions")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="admin-section">
        <.header>
          Edit Submission
          <:subtitle>{@submission.title}</:subtitle>
        </.header>

        <.form for={@form} id="edit-submission-form" phx-change="validate" phx-submit="save">
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
            <.button navigate={~p"/admin/submissions"}>Cancel</.button>
            <.button type="submit" variant="primary">Save changes</.button>
          </div>
        </.form>
      </div>
    </Layouts.app>
    """
  end
end

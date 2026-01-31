defmodule SlopcaseWeb.Admin.SubmissionsLive do
  use SlopcaseWeb, :live_view

  alias Slopcase.Showcase

  def mount(_params, _session, socket) do
    submissions = Showcase.list_submissions()

    {:ok,
     socket
     |> assign(:page_title, "Admin - Submissions")
     |> stream(:submissions, submissions)}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    submission = Showcase.get_submission!(id)

    case Showcase.delete_submission(submission) do
      {:ok, _} ->
        {:noreply,
         socket
         |> stream_delete(:submissions, submission)
         |> put_flash(:info, "Submission deleted.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not delete submission.")}
    end
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="admin-section">
        <.header>
          Submissions
          <:subtitle>Manage all submissions</:subtitle>
        </.header>

        <.table id="admin-submissions" rows={@streams.submissions}>
          <:col :let={{_id, submission}} label="Title">{submission.title}</:col>
          <:col :let={{_id, submission}} label="App URL">
            <a :if={submission.app_url} href={submission.app_url} target="_blank" class="admin-link">
              {truncate_url(submission.app_url)}
            </a>
          </:col>
          <:col :let={{_id, submission}} label="Model">{submission.model}</:col>
          <:col :let={{_id, submission}} label="Tools">{submission.tools}</:col>
          <:action :let={{_id, submission}}>
            <.link navigate={~p"/admin/submissions/#{submission.id}/edit"} class="admin-action">
              Edit
            </.link>
          </:action>
          <:action :let={{id, submission}}>
            <.link
              phx-click={JS.push("delete", value: %{id: submission.id}) |> hide("##{id}")}
              data-confirm="Are you sure you want to delete this submission?"
              class="admin-action admin-action--danger"
            >
              Delete
            </.link>
          </:action>
        </.table>
      </div>
    </Layouts.app>
    """
  end

  defp truncate_url(nil), do: nil

  defp truncate_url(url) do
    url
    |> String.replace(~r/^https?:\/\//, "")
    |> String.slice(0, 30)
    |> then(&if(String.length(url) > 30, do: &1 <> "...", else: &1))
  end
end

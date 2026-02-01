defmodule Slopcase.Showcase do
  import Ecto.Query, warn: false

  alias Slopcase.Repo
  alias Slopcase.Showcase.Submission
  alias Slopcase.Showcase.SubmissionVote
  alias Slopcase.Showcase.ThumbnailFetcher

  @topic "showcase"

  def list_submissions do
    Submission
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  def get_submission(id) do
    Repo.get(Submission, id)
  end

  def get_submission!(id) do
    Repo.get!(Submission, id)
  end

  def create_submission(attrs) do
    %Submission{}
    |> Submission.changeset(attrs)
    |> Repo.insert()
    |> tap(fn
      {:ok, submission} ->
        Task.Supervisor.start_child(Slopcase.TaskSupervisor, fn ->
          fetch_and_update_thumbnail(submission)
        end)

        broadcast_created({:ok, submission})

      _ ->
        :ok
    end)
  end

  defp fetch_and_update_thumbnail(submission) do
    case ThumbnailFetcher.fetch_thumbnail(submission.app_url, submission.repo_url) do
      {:ok, thumbnail_url} ->
        update_submission(submission, %{thumbnail_url: thumbnail_url})

      :error ->
        :ok
    end
  end

  def change_submission(%Submission{} = submission, attrs \\ %{}) do
    Submission.changeset(submission, attrs)
  end

  def update_submission(%Submission{} = submission, attrs) do
    submission
    |> Submission.changeset(attrs)
    |> Repo.update()
    |> broadcast_updated()
  end

  def delete_submission(%Submission{} = submission) do
    Repo.delete(submission)
  end

  @doc """
  Records a vote for a submission.

  Returns `{:ok, vote}` on success, or `{:error, changeset}` if the vote
  fails (e.g., duplicate vote from the same IP).
  """
  def vote(submission_id, verdict, voter_ip) when is_boolean(verdict) do
    %SubmissionVote{}
    |> SubmissionVote.changeset(%{
      submission_id: submission_id,
      verdict: verdict,
      voter_ip: voter_ip
    })
    |> Repo.insert()
    |> broadcast_vote()
  end

  @doc """
  Returns vote counts for the given submission IDs.

  Returns a map of `%{submission_id => %{slop: count, not_slop: count}}`.
  """
  def vote_counts([]), do: %{}

  def vote_counts(submission_ids) when is_list(submission_ids) do
    SubmissionVote
    |> where([v], v.submission_id in ^submission_ids)
    |> group_by([v], [v.submission_id, v.verdict])
    |> select([v], {v.submission_id, v.verdict, count(v.id)})
    |> Repo.all()
    |> Enum.reduce(%{}, fn {sub_id, verdict, count}, acc ->
      key = if verdict, do: :slop, else: :not_slop
      default = %{slop: 0, not_slop: 0}

      Map.update(acc, sub_id, Map.put(default, key, count), &Map.put(&1, key, count))
    end)
  end

  def subscribe do
    Phoenix.PubSub.subscribe(Slopcase.PubSub, @topic)
  end

  defp broadcast_vote({:ok, vote} = result) do
    Phoenix.PubSub.broadcast(Slopcase.PubSub, @topic, {:vote_updated, vote})
    result
  end

  defp broadcast_vote(result), do: result

  defp broadcast_created({:ok, submission} = result) do
    Phoenix.PubSub.broadcast(Slopcase.PubSub, @topic, {:submission_created, submission})
    result
  end

  defp broadcast_created(result), do: result

  defp broadcast_updated({:ok, submission} = result) do
    Phoenix.PubSub.broadcast(Slopcase.PubSub, @topic, {:submission_updated, submission})
    result
  end

  defp broadcast_updated(result), do: result
end

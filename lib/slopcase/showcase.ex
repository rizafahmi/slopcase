defmodule Slopcase.Showcase do
  import Ecto.Query, warn: false

  alias Slopcase.Repo
  alias Slopcase.Showcase.Submission
  alias Slopcase.Showcase.SubmissionVote
  alias Slopcase.Showcase.ThumbnailFetcher

  @topic "showcase"

  def list_submissions(opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)
    offset = Keyword.get(opts, :offset, 0)

    submission_query()
    |> order_by(desc: :inserted_at, desc: :id)
    |> limit(^limit)
    |> offset(^offset)
    |> Repo.all()
  end

  def get_submission(id_or_slug) do
    query = submission_query()

    if is_integer(id_or_slug) or String.match?(to_string(id_or_slug), ~r/^\d+$/) do
      Repo.one(from s in query, where: s.id == ^id_or_slug)
    else
      Repo.one(from s in query, where: s.slug == ^id_or_slug)
    end
  end

  def get_submission!(id_or_slug) do
    query = submission_query()

    result =
      if is_integer(id_or_slug) or String.match?(to_string(id_or_slug), ~r/^\d+$/) do
        Repo.one(from s in query, where: s.id == ^id_or_slug)
      else
        Repo.one(from s in query, where: s.slug == ^id_or_slug)
      end

    result || raise Ecto.NoResultsError, queryable: Submission
  end

  def create_submission(attrs) do
    %Submission{}
    |> Submission.changeset(attrs)
    |> Repo.insert()
    |> tap(fn
      {:ok, submission} ->
        broadcast_created({:ok, submission})

        if Application.get_env(:slopcase, :sync_thumbnail_fetch) do
          fetch_and_update_thumbnail(submission)
        else
          Task.Supervisor.start_child(Slopcase.TaskSupervisor, fn ->
            fetch_and_update_thumbnail(submission)
          end)
        end

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

  defp submission_query do
    Submission
    |> join(:left, [s], v in SubmissionVote, on: s.id == v.submission_id)
    |> group_by([s], s.id)
    |> select([s, v], %{s |
      slop_count: filter(count(v.id), v.verdict == true),
      not_slop_count: filter(count(v.id), v.verdict == false)
    })
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

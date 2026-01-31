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

  def create_submission(attrs) do
    %Submission{}
    |> Submission.changeset(attrs)
    |> maybe_fetch_thumbnail()
    |> Repo.insert()
  end

  defp maybe_fetch_thumbnail(%Ecto.Changeset{valid?: false} = changeset), do: changeset

  defp maybe_fetch_thumbnail(changeset) do
    app_url = Ecto.Changeset.get_field(changeset, :app_url)
    repo_url = Ecto.Changeset.get_field(changeset, :repo_url)

    case ThumbnailFetcher.fetch_thumbnail(app_url, repo_url) do
      {:ok, thumbnail_url} -> Ecto.Changeset.put_change(changeset, :thumbnail_url, thumbnail_url)
      :error -> changeset
    end
  end

  def change_submission(%Submission{} = submission, attrs \\ %{}) do
    Submission.changeset(submission, attrs)
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
end

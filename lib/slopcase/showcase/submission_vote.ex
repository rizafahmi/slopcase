defmodule Slopcase.Showcase.SubmissionVote do
  use Ecto.Schema

  import Ecto.Changeset

  alias Slopcase.Showcase.Submission

  schema "submission_votes" do
    field :verdict, :boolean
    field :voter_ip, :string

    belongs_to :submission, Submission

    timestamps()
  end

  def changeset(vote, attrs) do
    vote
    |> cast(attrs, [:submission_id, :verdict, :voter_ip])
    |> validate_required([:submission_id, :verdict, :voter_ip])
    |> unique_constraint([:submission_id, :voter_ip],
      name: :submission_votes_submission_id_voter_ip_index,
      message: "you have already voted on this submission"
    )
    |> foreign_key_constraint(:submission_id)
  end
end

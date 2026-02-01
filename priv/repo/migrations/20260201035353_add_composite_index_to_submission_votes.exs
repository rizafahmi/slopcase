defmodule Slopcase.Repo.Migrations.AddCompositeIndexToSubmissionVotes do
  use Ecto.Migration

  def change do
    create index(:submission_votes, [:submission_id, :verdict])
  end
end

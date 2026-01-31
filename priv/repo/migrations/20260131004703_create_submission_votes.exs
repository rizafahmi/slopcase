defmodule Slopcase.Repo.Migrations.CreateSubmissionVotes do
  use Ecto.Migration

  def change do
    create table(:submission_votes) do
      add :submission_id, references(:submissions, on_delete: :delete_all), null: false
      add :verdict, :boolean, null: false
      add :voter_ip, :string, null: false

      timestamps()
    end

    create unique_index(:submission_votes, [:submission_id, :voter_ip])
    create index(:submission_votes, [:submission_id])
  end
end

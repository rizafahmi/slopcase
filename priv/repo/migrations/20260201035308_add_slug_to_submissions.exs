defmodule Slopcase.Repo.Migrations.AddSlugToSubmissions do
  use Ecto.Migration

  def change do
    alter table(:submissions) do
      add :slug, :string
    end

    execute "UPDATE submissions SET slug = 'submission-' || rowid"

    create unique_index(:submissions, [:slug])
  end
end

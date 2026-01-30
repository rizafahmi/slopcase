defmodule Slopcase.Repo.Migrations.CreateSubmissions do
  use Ecto.Migration

  def change do
    create table(:submissions) do
      add :title, :string, null: false
      add :slop, :boolean, null: false
      add :app_url, :string
      add :repo_url, :string
      add :model, :string
      add :tools, :string
      add :notes, :string

      timestamps()
    end

    create index(:submissions, [:inserted_at])
  end
end

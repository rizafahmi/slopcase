defmodule Slopcase.Repo.Migrations.DropSlopFromSubmissions do
  use Ecto.Migration

  def change do
    alter table(:submissions) do
      remove :slop, :boolean, null: false
    end
  end
end

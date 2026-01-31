defmodule Slopcase.Repo.Migrations.AddThumbnailUrlToSubmissions do
  use Ecto.Migration

  def change do
    alter table(:submissions) do
      add :thumbnail_url, :string
    end
  end
end

defmodule Slopcase.Showcase.Submission do
  use Ecto.Schema

  import Ecto.Changeset

  @url_regex ~r/^https?:\/\//

  schema "submissions" do
    field :title, :string
    field :app_url, :string
    field :repo_url, :string
    field :model, :string
    field :tools, :string
    field :notes, :string

    timestamps()
  end

  def changeset(submission, attrs) do
    submission
    |> cast(attrs, [:title, :app_url, :repo_url, :model, :tools, :notes])
    |> validate_required([:title])
    |> validate_length(:title, min: 2, max: 120)
    |> validate_length(:model, max: 120)
    |> validate_length(:tools, max: 200)
    |> validate_length(:notes, max: 600)
    |> validate_format(:app_url, @url_regex, message: "must start with http:// or https://")
    |> validate_format(:repo_url, @url_regex, message: "must start with http:// or https://")
  end
end

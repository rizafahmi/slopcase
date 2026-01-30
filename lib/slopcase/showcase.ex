defmodule Slopcase.Showcase do
  import Ecto.Query, warn: false

  alias Slopcase.Repo
  alias Slopcase.Showcase.Submission

  def list_submissions do
    Submission
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  def create_submission(attrs) do
    %Submission{}
    |> Submission.changeset(attrs)
    |> Repo.insert()
  end

  def change_submission(%Submission{} = submission, attrs \\ %{}) do
    Submission.changeset(submission, attrs)
  end
end

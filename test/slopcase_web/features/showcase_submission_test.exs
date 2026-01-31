defmodule SlopcaseWeb.ShowcaseSubmissionTest do
  use SlopcaseWeb.ConnCase, async: false

  alias Slopcase.Showcase

  test "submitting an app adds it to the list with vote buttons", %{conn: conn} do
    conn
    |> visit("/")
    |> click_button(".app-nav button", "Submit")
    |> within("#submission-form", fn session ->
      session
      |> fill_in("Title", with: "SlopGPT")
      |> fill_in("App URL", with: "https://slopgpt.example")
      |> fill_in("Repo URL", with: "https://github.com/slop/ai")
      |> fill_in("Model", with: "GPT-5")
      |> fill_in("Tools", with: "Cursor, LiveView")
      |> fill_in("Notes", with: "Ship it. It is slop, but it ships.")
      |> click_button("Drop it")
    end)
    |> assert_has("#submissions-list .submission-card", count: 1)
    |> assert_has("#submissions-list .submission-title", text: "SlopGPT")
    |> assert_has("#submissions-list .vote-btn--slop", text: "Slop")
    |> assert_has("#submissions-list .vote-btn--clean", text: "Valid")
    |> assert_has("#submissions-list .submission-link", text: "App")
    |> assert_has("#submissions-list .submission-link", text: "Repo")
  end

  test "voting increments the count", %{conn: conn} do
    {:ok, submission} = Showcase.create_submission(%{title: "VoteTest App"})

    # Vote directly via the context to verify it works
    assert {:ok, _vote} = Showcase.vote(submission.id, true, "127.0.0.1")

    # Verify the vote was recorded
    counts = Showcase.vote_counts([submission.id])
    assert counts[submission.id].slop == 1

    # Now test the UI shows the vote count
    conn
    |> visit("/")
    |> assert_has(".vote-btn--slop .vote-count", text: "1")
  end

  test "duplicate vote from same IP returns error", %{conn: _conn} do
    {:ok, submission} = Showcase.create_submission(%{title: "DupeVote App"})

    # First vote succeeds
    assert {:ok, _vote} = Showcase.vote(submission.id, true, "127.0.0.1")

    # Second vote from same IP fails
    assert {:error, changeset} = Showcase.vote(submission.id, true, "127.0.0.1")
    assert {"you have already voted on this submission", _} = changeset.errors[:submission_id]

    # Count should still be 1
    counts = Showcase.vote_counts([submission.id])
    assert counts[submission.id].slop == 1
  end
end

defmodule SlopcaseWeb.ShowcaseSubmissionTest do
  use SlopcaseWeb.ConnCase, async: false

  test "submitting an app adds it to the list", %{conn: conn} do
    conn
    |> visit("/")
    |> within("#submission-form", fn session ->
      session
      |> fill_in("Title", with: "SlopGPT")
      |> choose("Slop")
      |> fill_in("App URL", with: "https://slopgpt.example")
      |> fill_in("Repo URL", with: "https://github.com/slop/ai")
      |> fill_in("Model", with: "GPT-5")
      |> fill_in("Tools", with: "Cursor, LiveView")
      |> fill_in("Notes", with: "Ship it. It is slop, but it ships.")
      |> click_button("Submit the slop")
    end)
    |> assert_has("#submissions-list .submission-card", count: 1)
    |> assert_has("#submissions-list .submission-title", text: "SlopGPT")
    |> assert_has("#submissions-list .submission-pill", text: "Slop")
    |> assert_has("#submissions-list .submission-link", text: "App")
    |> assert_has("#submissions-list .submission-link", text: "Repo")
  end
end

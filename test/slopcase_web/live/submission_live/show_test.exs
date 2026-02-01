defmodule SlopcaseWeb.SubmissionLive.ShowTest do
  use SlopcaseWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  alias Slopcase.Showcase

  describe "Submission Detail Page" do
    setup do
      {:ok, submission} =
        Showcase.create_submission(%{
          title: "Test Submission",
          app_url: "https://example.com",
          repo_url: "https://github.com/test/repo",
          model: "Claude 3.5",
          tools: "Phoenix, LiveView",
          notes: "This is a test note"
        })

      # Wait for async thumbnail fetch to complete
      Process.sleep(500)

      %{submission: submission}
    end

    test "renders submission details", %{conn: conn, submission: submission} do
      {:ok, _live, html} = live(conn, ~p"/p/#{submission.slug}")

      assert html =~ "Test Submission"
      assert html =~ "Claude 3.5"
      assert html =~ "Phoenix, LiveView"
      assert html =~ "This is a test note"
      assert html =~ "Back to all submissions"
      # Note: The apostrophe is HTML-encoded as &#39;
      assert html =~ "vote-label"
      assert html =~ "Share this submission"
    end

    test "allows voting on submission", %{conn: conn, submission: submission} do
      {:ok, live, _html} = live(conn, ~p"/p/#{submission.slug}")

      # Initially vote counts should be 0
      assert has_element?(live, ".vote-count", "0")

      # Vote "slop"
      live
      |> element("button.vote-btn--slop")
      |> render_click()

      # Wait for PubSub update
      Process.sleep(100)

      # Should now have 1 slop vote
      assert has_element?(live, "button.vote-btn--slop .vote-count", "1")
    end

    test "sets correct page title and meta tags", %{conn: conn, submission: submission} do
      {:ok, _live, html} = live(conn, ~p"/p/#{submission.slug}")

      assert html =~ "Test Submission"
    end

    test "redirects to home for non-existent submission", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/", flash: %{"error" => "Submission not found"}}}} =
               live(conn, ~p"/p/non-existent-slug")
    end

    test "has share buttons", %{conn: conn, submission: submission} do
      {:ok, live, _html} = live(conn, ~p"/p/#{submission.slug}")

      assert has_element?(live, ".share-btn--twitter")
      assert has_element?(live, ".share-btn--copy")
    end
  end
end

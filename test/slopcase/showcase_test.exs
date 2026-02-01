defmodule Slopcase.ShowcaseTest do
  use Slopcase.DataCase, async: false

  alias Slopcase.Showcase

  describe "submissions" do
    @valid_attrs %{
      title: "Super Slop",
      app_url: "https://slop.example.com",
      repo_url: "https://github.com/user/project",
      model: "GPT-4",
      tools: "Cursor"
    }

    test "create_submission/1 creates a submission and broadcasts events" do
      # Subscribe to the topic to catch broadcasts
      Showcase.subscribe()

      # Create the submission
      assert {:ok, %{id: id} = submission} = Showcase.create_submission(@valid_attrs)

      # 1. Assert specific values
      assert submission.title == "Super Slop"
      # Initially, thumbnail might not be set yet (async)
      # or if it was fast enough, it might be. But typically it's nil or empty unless provided.
      # The fetcher logic: if GitHub URL, it constructs immediately but runs in TASK.
      # So here it should definitively be nil (or whatever default)
      refute submission.thumbnail_url

      # 2. Check for creation broadcast
      assert_receive {:submission_created, created_sub}
      assert created_sub.id == id

      # 3. Check for update broadcast (async thumbnail fetch)
      # Since we used a GitHub URL, ThumbnailFetcher should succeed without HTTP
      assert_receive {:submission_updated, updated_sub}, 1000
      assert updated_sub.id == id
      assert updated_sub.thumbnail_url == "https://opengraph.githubassets.com/1/user/project"

      # Verify it's persisted
      fetched = Showcase.get_submission!(id)
      assert fetched.thumbnail_url == "https://opengraph.githubassets.com/1/user/project"
    end
  end
end

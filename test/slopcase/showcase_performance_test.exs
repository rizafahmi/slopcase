defmodule Slopcase.ShowcaseTest.Performance do
  use Slopcase.DataCase, async: false # Async false for SQLite

  alias Slopcase.Showcase

  describe "pagination and counts" do
    @valid_attrs %{
      title: "Super Slop",
      app_url: "https://slop.example.com",
      repo_url: "https://github.com/user/project",
      model: "GPT-4",
      tools: "Cursor",
      slug: "super-slop" # Provide slug or rely on generation
    }

    test "list_submissions/1 paginates and counts votes correctly" do
      # 1. Create submissions
      {:ok, s1} = Showcase.create_submission(%{@valid_attrs | title: "S1"})
      {:ok, s2} = Showcase.create_submission(%{@valid_attrs | title: "S2"})
      {:ok, s3} = Showcase.create_submission(%{@valid_attrs | title: "S3"})

      # 2. Add votes
      # s1: 2 slop, 1 valid
      Showcase.vote(s1.id, true, "1.1.1.1")
      Showcase.vote(s1.id, true, "1.1.1.2")
      Showcase.vote(s1.id, false, "1.1.1.3")

      # s2: 0 slop, 2 valid
      Showcase.vote(s2.id, false, "2.2.2.1")
      Showcase.vote(s2.id, false, "2.2.2.2")

      # s3: 0 votes

      # 3. Test pagination (limit 2, offset 0) -> s3, s2 (desc inserted_at)
      # Wait, default order is `desc: :inserted_at`. s3 is newest.
      page1 = Showcase.list_submissions(limit: 2, offset: 0)
      assert length(page1) == 2
      [r3, r2] = page1
      assert r3.id == s3.id
      assert r2.id == s2.id

      # 4. Test counts on page 1
      assert r3.slop_count == 0
      assert r3.not_slop_count == 0

      assert r2.slop_count == 0
      assert r2.not_slop_count == 2

      # 5. Test page 2 (limit 2, offset 2) -> s1
      page2 = Showcase.list_submissions(limit: 2, offset: 2)
      assert length(page2) == 1
      [r1] = page2
      assert r1.id == s1.id

      # 6. Test counts on page 2
      assert r1.slop_count == 2
      assert r1.not_slop_count == 1
    end
  end
end

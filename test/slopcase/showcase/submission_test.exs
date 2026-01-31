defmodule Slopcase.Showcase.SubmissionTest do
  use Slopcase.DataCase, async: true

  alias Slopcase.Showcase.Submission

  describe "changeset/2 URL normalization" do
    test "auto-prepends https:// to app_url without protocol" do
      changeset = Submission.changeset(%Submission{}, %{title: "Test", app_url: "example.com"})

      assert changeset.changes.app_url == "https://example.com"
    end

    test "auto-prepends https:// to repo_url without protocol" do
      changeset =
        Submission.changeset(%Submission{}, %{title: "Test", repo_url: "github.com/user/repo"})

      assert changeset.changes.repo_url == "https://github.com/user/repo"
    end

    test "preserves https:// URLs as-is" do
      changeset =
        Submission.changeset(%Submission{}, %{title: "Test", app_url: "https://example.com"})

      assert changeset.changes.app_url == "https://example.com"
    end

    test "preserves http:// URLs as-is" do
      changeset =
        Submission.changeset(%Submission{}, %{title: "Test", app_url: "http://example.com"})

      assert changeset.changes.app_url == "http://example.com"
    end

    test "handles empty URL strings" do
      changeset = Submission.changeset(%Submission{}, %{title: "Test", app_url: ""})

      # Empty strings are not included as changes by Ecto cast
      refute Map.has_key?(changeset.changes, :app_url)
    end

    test "handles nil URLs" do
      changeset = Submission.changeset(%Submission{}, %{title: "Test"})

      refute Map.has_key?(changeset.changes, :app_url)
    end
  end
end

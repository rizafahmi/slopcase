defmodule SlopcaseWeb.AdminSubmissionsTest do
  use SlopcaseWeb.ConnCase, async: false

  alias Slopcase.Showcase

  describe "admin submissions page" do
    setup :register_and_log_in_admin

    test "admin can view submissions list", %{conn: conn} do
      {:ok, _submission} = Showcase.create_submission(%{title: "Test App", model: "Claude"})

      conn
      |> visit("/admin/submissions")
      |> assert_has("h1", text: "Submissions")
      |> assert_has("#admin-submissions", text: "Test App")
      |> assert_has("#admin-submissions", text: "Claude")
    end

    test "admin can edit a submission", %{conn: conn} do
      {:ok, submission} = Showcase.create_submission(%{title: "Original Title", model: "GPT-4"})

      conn
      |> visit("/admin/submissions/#{submission.id}/edit")
      |> assert_has("h1", text: "Edit Submission")
      |> within("#edit-submission-form", fn session ->
        session
        |> fill_in("Title", with: "Updated Title")
        |> fill_in("Model", with: "Claude 3.5")
        |> click_button("Save changes")
      end)
      |> assert_has(".flash-message", text: "Submission updated")
      |> assert_has("#admin-submissions", text: "Updated Title")
      |> assert_has("#admin-submissions", text: "Claude 3.5")
    end

    test "admin can delete a submission", %{conn: conn} do
      {:ok, _submission} = Showcase.create_submission(%{title: "To Be Deleted"})

      conn
      |> visit("/admin/submissions")
      |> assert_has("#admin-submissions", text: "To Be Deleted")
      |> click_link("Delete")
      |> assert_has(".flash-message", text: "Submission deleted")
      |> refute_has("#admin-submissions", text: "To Be Deleted")
    end
  end

  describe "admin access control" do
    test "non-authenticated users cannot access admin pages", %{conn: conn} do
      conn
      |> visit("/admin/submissions")
      |> assert_has(".flash-message", text: "You must log in")
    end

    test "non-admin users cannot access admin pages", %{conn: conn} do
      conn = register_and_log_in_user(%{conn: conn}).conn

      conn
      |> visit("/admin/submissions")
      |> assert_has(".flash-message", text: "do not have permission")
    end
  end

  describe "admin link in navigation" do
    test "admin users see Admin link in nav", %{conn: conn} do
      conn = register_and_log_in_admin(%{conn: conn}).conn

      conn
      |> visit("/")
      |> assert_has(".app-nav a", text: "Admin")
    end

    test "non-admin users do not see Admin link", %{conn: conn} do
      conn = register_and_log_in_user(%{conn: conn}).conn

      conn
      |> visit("/")
      |> refute_has(".app-nav a", text: "Admin")
    end

    test "anonymous users do not see Admin link", %{conn: conn} do
      conn
      |> visit("/")
      |> refute_has(".app-nav a", text: "Admin")
    end
  end
end

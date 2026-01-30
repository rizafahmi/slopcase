defmodule SlopcaseWeb.ShowcasePageTest do
  use SlopcaseWeb.ConnCase, async: false

  test "shows the showcase page skeleton", %{conn: conn} do
    conn
    |> visit("/")
    |> assert_has("#showcase-hero")
    |> assert_has("#submission-form")
    |> assert_has("#submissions-list")
    |> assert_has("#submissions-empty")
  end
end

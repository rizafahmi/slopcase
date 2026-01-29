defmodule SlopcaseWeb.PageController do
  use SlopcaseWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end

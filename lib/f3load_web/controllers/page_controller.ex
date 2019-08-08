defmodule F3loadWeb.PageController do
  use F3loadWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end

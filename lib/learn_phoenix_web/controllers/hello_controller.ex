defmodule LearnPhoenixWeb.HelloController do
  use LearnPhoenixWeb, :controller

  def index(conn, _params) do
    render(conn, :index)
  end
end
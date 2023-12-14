defmodule LearnPhoenixWeb.HelloController do
  use LearnPhoenixWeb, :controller

  def index(conn, _params) do
    # render(conn, :index)
    conn
    # |> put_root_layout(html: false)
    |> put_layout(html: :admin)
    |> render(:index)
  end

  def show(conn, %{"messenger" => messenger}) do
    # text(conn, "From messenger #{messenger}")
    # json(conn, %{id: messenger})
    # render(conn, :show, messenger: messenger)
    # conn
    # |> Plug.Conn.assign(:messenger, messenger)
    # |> render(:show)

    # conn
    # |> assign(:messenger, messenger)
    # |> assign(:receiver, "Dweezil")
    # |> render(:show)

    render(conn, :show, messenger: messenger, receiver: "Dweezil")
  end
end

defmodule LearnPhoenixWeb.PageController do
  use LearnPhoenixWeb, :controller
  plug LearnPhoenixWeb.Plugs.Locale, "en" when action in [:index]
  plug :put_view, html: LearnPhoenixWeb.PageHTML, json: LearnPhoenixWeb.PageJSON
  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    # render(conn, :home, layout: false)

    # conn
    # |> put_resp_content_type("text/plain")
    # |> send_resp(201, "halo")

    # conn
    # |> put_status(202)
    # |> render(:home, layout: false)

    # redirect(conn, to: ~p"/redirect_test")
    # redirect(conn, external: "https://elixir-lang.org")

    conn
    |> put_flash(:error, "Let's pretend we have an error.")
    # |> render(:home, layout: false)
    |> redirect(to: ~p"/redirect_test")
  end

  def redirect_test(conn, _params) do
    render(conn, :home, layout: false)
  end
end

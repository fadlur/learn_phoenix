defmodule LearnPhoenixWeb.PageController do
  use LearnPhoenixWeb, :controller
  plug LearnPhoenixWeb.Plugs.Locale, "en" when action in [:index]
  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false)
  end
end

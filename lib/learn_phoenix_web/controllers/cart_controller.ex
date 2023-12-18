defmodule LearnPhoenixWeb.CartController do
  use LearnPhoenixWeb, :controller

  alias LearnPhoenix.ShoppingCart

  def show(conn, _params) do
    render(conn, :show, changeset: ShoppingCart.change_cart(conn.assigns.cart))
  end
end

defmodule LearnPhoenixWeb.CartItemController do
  use LearnPhoenixWeb, :controller
alias LearnPhoenix.ShoppingCart
  def create(conn, %{"product_id" => product_id}) do
    case ShoppingCart.add_item_to_cart(conn.assigns.cart, product_id) do
      {:ok, _item} ->
        conn
        |> put_flash(:info, "item added to your cart")
        |> redirect(to: ~p"/cart")

        {:error, _changeset} ->
          conn
          |> put_flash(:error, "There was an error adding the item to your cart")
          |> redirect(to: ~p"/cart")
  end

  def delete(conn, %{"id" => product_id}) do
{:ok, _cart} = ShoppingCart.remove_item_from_cart(conn.assigns.cart, product_id)
redirect(conn, ~p"/cart")
  end
end

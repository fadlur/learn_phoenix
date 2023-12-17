defmodule LearnPhoenix.CatalogFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `LearnPhoenix.Catalog` context.
  """

  @doc """
  Generate a product.
  """
  def product_fixture(attrs \\ %{}) do
    {:ok, product} =
      attrs
      |> Enum.into(%{
        description: "some description",
        price: "120.5",
        title: "some title",
        views: 42
      })
      |> LearnPhoenix.Catalog.create_product()

    product
  end
end

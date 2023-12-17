defmodule LearnPhoenix.Catalog.Product do
  use Ecto.Schema
  alias LearnPhoenix.Catalog.Category
  import Ecto.Changeset

  schema "products" do
    field :description, :string
    field :title, :string
    field :price, :decimal
    field :views, :integer

    many_to_many :categories, Category, join_through: "product_categories", on_replace: :delete

    timestamps()
  end

  @doc false
  def changeset(product, attrs) do
    product
    |> cast(attrs, [:title, :description, :price, :views])
    |> validate_required([:title, :description, :price, :views])
  end
end

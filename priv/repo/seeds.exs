# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     LearnPhoenix.Repo.insert!(%LearnPhoenix.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
for title <- ["Home Improvement", "Power Tools", "Gardening", "Books", "Education"] do
  {:ok, _} = LearnPhoenix.Catalog.create_category(%{title: title})
end

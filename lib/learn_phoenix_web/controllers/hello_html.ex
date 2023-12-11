defmodule LearnPhoenixWeb.HelloHTML do
  use LearnPhoenixWeb, :html

  # def index(assigns) do
  #   ~H"""
  #   Hello!
  #   """
  # end

  embed_templates "hello_html/*"
end

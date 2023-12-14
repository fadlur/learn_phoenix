defmodule LearnPhoenixWeb.HelloHTML do
  use LearnPhoenixWeb, :html

  # def index(assigns) do
  #   ~H"""
  #   Hello!
  #   """
  # end

  embed_templates "hello_html/*"

  attr :messenger, :string

  def greet(assigns) do
    ~H"""
    <h2>Hello World, from <%= @messenger %>!</h2>
    <%= raw "<b>Bold?</b>" %>
    """
  end
end

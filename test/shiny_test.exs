defmodule ShinyTest do
  use ExUnit.Case
  doctest Shiny

  test "greets the world" do
    assert Shiny.hello() == :world
  end
end

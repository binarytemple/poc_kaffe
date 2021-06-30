defmodule PocKaffeTest do
  use ExUnit.Case
  doctest PocKaffe

  test "greets the world" do
    assert PocKaffe.hello() == :world
  end
end

defmodule MLLParty.ValidConfigFilesTest do
  use ExUnit.Case, async: true

  describe "application config file validity" do
    @config_file_paths Path.wildcard("config/*.exs")

    test "this test finds config files" do
      assert length(@config_file_paths) > 0
    end

    for file_path <- @config_file_paths do
      test "#{file_path} is valid elixir code" do
        contents = File.read!(unquote(file_path))
        Code.string_to_quoted!(contents)
      end
    end
  end
end

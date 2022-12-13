defmodule MLLParty.HelpersTest do
  use ExUnit.Case

  # Module under test
  alias MLLParty.Helpers

  describe inspect(&Helpers.valid_ip?/1) do
    test "with valid ip" do
      assert Helpers.valid_ip?("127.0.0.1")
      assert Helpers.valid_ip?("10.120.0.1")
      assert Helpers.valid_ip?("134.25.14.82")
    end

    test "with invalid ip" do
      refute Helpers.valid_ip?("somehost.com")
      refute Helpers.valid_ip?("1.1.1.1.1")
    end
  end

  describe inspect(&Helpers.valid_port?/1) do
    test "with valid port" do
      assert Helpers.valid_port?(1)
      assert Helpers.valid_port?("3000")
      assert Helpers.valid_port?(3000)
      assert Helpers.valid_port?(65535)
    end

    test "with invalid port" do
      refute Helpers.valid_port?(0)
      refute Helpers.valid_port?(-1)
      refute Helpers.valid_port?(65536)
    end
  end
end

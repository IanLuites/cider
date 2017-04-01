defmodule CiderTest do
  use ExUnit.Case
  doctest Cider

  describe "parse" do
    test "from string with subnetmask" do
      assert Cider.parse("192.168.0.0/24") == {3232235520, 4294967040}
    end

    test "from string without subnetmask" do
      assert Cider.parse("192.168.0.1") == {3232235521, 4294967295}
    end

    test "from arguments with subnetmask" do
      assert Cider.parse(192, 168, 0, 0, 24) == {3232235520, 4294967040}
    end

    test "from arguments without subnetmask" do
      assert Cider.parse(192, 168, 0, 1) == {3232235521, 4294967295}
    end

    test "from ip and subnetmask" do
      assert Cider.parse({192, 168, 0, 0}, 24) == {3232235520, 4294967040}
    end

    test "from ip and subnetmask with non %8 bit mask" do
      assert Cider.parse({192, 168, 0, 0}, 3) == {3221225472, 3758096384}
    end
  end

  describe "contains?" do
    test "with non %8 bit mask" do
      cidr = Cider.parse({192, 168, 0, 0}, 30)

      assert Cider.contains?({192, 168, 0, 2}, cidr)
      refute Cider.contains?({192, 168, 0, 4}, cidr)
    end

    test "with full 32 bit mask" do
      cidr = Cider.parse({192, 168, 0, 5}, 32)

      assert Cider.contains?({192, 168, 0, 5}, cidr)
      refute Cider.contains?({192, 168, 0, 4}, cidr)
    end

    @tag :cider_full
    test "correct for whole ip range" do
      cidr = Cider.parse "192.168.0.0/24"

      for octet1 <- 191..193, do:
        for octet2 <- 0..255,  do:
          for octet3 <- 0..255, do:
            for octet4 <- 0..255, do:
              assert Cider.contains?({octet1, octet2, octet3, octet4}, cidr)
                      == (octet1 == 192 && octet2 == 168 && octet3 == 0)
    end
  end
end

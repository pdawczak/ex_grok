defmodule ExGrok.NgrokLogParserTest do
  use ExUnit.Case, async: true
  doctest ExGrok.NgrokLogParser

  alias ExGrok.NgrokLogParser

  describe "ExGrok.NgrokLogParser.parse/1" do
    test "parses single element" do
      str = "t=2016-11-11T20:52:54+0000"

      parsed = NgrokLogParser.parse(str)

      assert parsed == %{"t" => "2016-11-11T20:52:54+0000"}
    end

    test "parses two elements" do
      str = "t=2016-11-11T20:52:54+0000 lvl=info"

      parsed = NgrokLogParser.parse(str)

      assert parsed == %{"t"   => "2016-11-11T20:52:54+0000",
                         "lvl" => "info"}
    end

    test "parses embedded string, the string is the only content" do
      str = "msg=\"all component stopped\""

      parsed = NgrokLogParser.parse(str)

      assert parsed == %{"msg" => "all component stopped"}
    end

    test "parses embedded string, the string is in the end of the log content" do
      str = "t=2016-11-11T20:52:54+0000 msg=\"all component stopped\""

      parsed = NgrokLogParser.parse(str)

      assert parsed == %{"t"   => "2016-11-11T20:52:54+0000",
                         "msg" => "all component stopped"}
    end

    test "parses embedded string, there is more content after the string" do
      str = "msg=\"all component stopped\" another=val"

      parsed = NgrokLogParser.parse(str)

      assert parsed == %{"msg"     => "all component stopped",
                         "another" => "val"}
    end
  end
end

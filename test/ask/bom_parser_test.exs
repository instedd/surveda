defmodule Ask.BomParserTest do
  use ExUnit.Case
  alias Ask.BomParser

  test "parse UTF-8 string without BOM" do
    assert BomParser.parse("hello") == "hello"
  end

  test "parse UTF-8 string with BOM" do
    assert BomParser.parse(<<0xEF, 0xBB, 0xBF, 0x68, 0x65, 0x6C, 0x6C, 0x6F>>) == "hello"
  end

  test "parse UTF-16 LE string with BOM" do
    assert BomParser.parse(
             <<0xFF, 0xFE, 0x68, 0x00, 0x65, 0x00, 0x6C, 0x00, 0x6C, 0x00, 0x6F, 0x00>>
           ) == "hello"
  end

  test "parse UTF-16 BE string with BOM" do
    assert BomParser.parse(
             <<0xFE, 0xFF, 0x00, 0x68, 0x00, 0x65, 0x00, 0x6C, 0x00, 0x6C, 0x00, 0x6F>>
           ) == "hello"
  end
end

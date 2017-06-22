# Parser and stripper of BOM (byte order mark)
defmodule Ask.BomParser do
  def parse(string) do
    case :unicode.bom_to_encoding(string) do
      {_, 0} -> string

      {encoding, bom_size} ->
        # Strip BOM
        bom_bits = bom_size * 8
        <<_bom::size(bom_bits), string::binary>> = string

        # Convert to UTF-8
        :unicode.characters_to_binary(string, encoding)
    end
  end
end

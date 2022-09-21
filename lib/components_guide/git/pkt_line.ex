defmodule ComponentsGuide.Git.PktLine do
  defstruct ref: "", oid: "", attrs: %{}, attrs_raw: []

  def decode_line_string(line) do
    parts = line |> String.trim_trailing() |> String.split(" ")

    case parts do
      ["#" | _] ->
        nil

      [oid, ref_raw | attrs_raw] ->
        [ref | _] = ref_raw |> String.split("\u0000")
        attrs = for attr_raw <- attrs_raw do
          # case String.split(attr_raw, ":", parts: 2) do
          case String.split(attr_raw, "=", parts: 2) do
            [attr] ->
              {attr, true}
              [key, value] ->
                {key, value}

          end
        end
        %__MODULE__{oid: oid, ref: ref, attrs: attrs, attrs_raw: attrs_raw}

      _ ->
        nil
    end
  end

  def decode_line(<<length_hex::bytes-size(4)>> <> data = full_data) when is_binary(data) do
    case Integer.parse(length_hex, 16) do
      :error ->
        IO.puts("Error parsing #{full_data}")

      {0, _} ->
        {nil, data}

      {1, _} ->
        {nil, data}

      {length, _} ->
        length = length - 4
        <<line_bytes::bytes-size(length)>> <> data = data

        case line_bytes do
          <<>> ->
            {nil, <<>>}

          line_bytes ->
            decoded = decode_line_string(line_bytes)
            {decoded, data}
        end
    end
  end

  # Invalid short line
  def decode_line(data) when is_binary(data), do: {nil, data}

  def decode_lines(<<>>, lines) do
    Enum.reverse(lines)
  end

  def decode_lines(data, lines) when is_binary(data) do
    case decode_line(data) do
      {nil, data} ->
        decode_lines(data, lines)

      {line, data} ->
        decode_lines(data, [line | lines])
    end
  end

  def decode(data) when is_binary(data) do
    decode_lines(data, [])
    # return function* decodePktLine() {
    #   let current = 0
    #   linesLoop: while (true) {
    #     const utf8Decoder = new TextDecoder('utf-8')
    #     const lengthHex = utf8Decoder.decode(
    #       arrayBuffer.slice(current, current + 4),
    #     )
    #     current += 4
    #     const length = parseInt(lengthHex, '16')
    #     if (length <= 1) {
    #       continue linesLoop
    #     }

    #     const bytes = arrayBuffer.slice(current, current + length - 4)
    #     if (bytes.byteLength === 0) break linesLoop
    #     current += length - 4

    #     const line = utf8Decoder.decode(bytes).trimEnd()
    #     const [oid, refRaw, ...attrs] = line.split(' ')
    #     if (oid === '#') {
    #       continue linesLoop
    #     }

    #     const [ref] = refRaw.split('\u0000')

    #     const r = { ref, oid }
    #     // r.attrs = attrs;
    #     for (const attr of attrs) {
    #       const [name, value] = attr.split(':')
    #       if (name === 'symref-target') {
    #         r.target = value
    #       } else if (name === 'peeled') {
    #         r.peeled = value
    #       } else if (name === 'symref=HEAD') {
    #         r.HEADRef = value
    #       } else if (name === 'object-format') {
    #         r.objectFormat = value
    #       } else if (name === 'agent') {
    #         r.agent = value
    #       }
    #     }
    #     yield Object.freeze(r)
    #   }
    # }
  end
end

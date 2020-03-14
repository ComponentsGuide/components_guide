defmodule ComponentsGuideWeb.Snippets do
  require EEx
  use Phoenix.HTML

  defmacro __using__(_opts) do
    quote do
      def section(label, attrs, block) do
        content_tag(:section, [aria_label: label] ++ attrs, block)
      end
    end
  end

  defmacro defhello do
    quote do
      def yep, do: 5
    end
  end

  defmacro def_E(call1, source) do
    # call2 = Macro.escape(call1, unquote: nil)
    # call2 = Macro.escape(call1, unquote: true)
    # call2 = Macro.escape(call1)
    # call2 = :topic_article
    # args = Macro.generate_arguments(2, nil)

    # source2 = Macro.escape(source)

    quote bind_quoted: binding() do
      info = Keyword.merge([file: __ENV__.file, line: __ENV__.line], engine: Phoenix.HTML.Engine)
      args = [{:assigns, [line: info[:line]], nil}, {:block, [line: info[:line]], nil}]
      # compiled = EEx.compile_string(source, info)
      compiled =
        quote do
          compiled = unquote(source)
        end

      # def topic_article(assigns, block), do: 4
      # def topic_article(assigns, block), do: 4

      # def unquote(call1)(assigns, block), do: unquote(compiled)

      def unquote(call1)(unquote_splicing(args)), do: unquote(source)

      # def unquote(call2)(assigns, block) do
      #   unquote(compiled)
      # end

      # def({
      #     quote do
      #       call
      #     end,
      #     Macro.generate_arguments(2, __MODULE__)
      #   },
      #   do: 4
      # )

      # unquote(
      #   quote do
      #     def unquote(call)(assigns, block), do: quote(compiled)
      #   end
      # )
    end
  end
end

defmodule Koans do
  defmacro __using__(_opts) do
    quote do
      use ExUnit.Case, async: false
      import Koans, only: [koan: 2, __: 0, verdict: 4]
      import Koans.Hidden, only: [run_checks: 2]
    end
  end

  defmacro koan(meditation, do: body) do
    file = __CALLER__.file
    line = __CALLER__.line
    name = "#{chapter(file)}:#{line}"
    tags = [meditation: meditation] ++ review_module_tag(body, __CALLER__)
    body = replace_blanks(body, file)

    wrapped =
      quote do
        Koans.keep_frame(unquote(body))
      end

    quote bind_quoted: [
            file: file,
            line: line,
            name: name,
            tags: tags,
            wrapped: Macro.escape(wrapped)
          ] do
      test_name = ExUnit.Case.register_test(__MODULE__, file, line, :test, name, tags)

      def unquote(test_name)(_context), do: unquote(wrapped)
    end
  end

  defmacro __() do
    used =
      __CALLER__.versioned_vars
      |> Map.keys()
      |> Enum.flat_map(fn
        {name, nil} ->
          if String.starts_with?(Atom.to_string(name), "_"), do: [], else: [Macro.var(name, nil)]

        _ ->
          []
      end)

    quote do
      _ = {unquote_splicing(used)}
      Koans.Blank.code!(unquote(__CALLER__.file), unquote(__CALLER__.line))
    end
  end

  defmacro verdict(file, answer, digests, source_digest) do
    quote do
      Koans.Verdict.check!(
        unquote(file),
        unquote(answer),
        unquote(digests),
        unquote(source_digest)
      )
    end
  end

  # Keeps the body out of tail position so a failing last expression stays in the stacktrace.
  def keep_frame(value), do: value

  defp replace_blanks(body, file) do
    Macro.prewalk(body, fn
      {:verdict, meta, [review, {:__, blank_meta, ctx}, digests, source]} when is_atom(ctx) ->
        answer =
          quote do
            Koans.Blank.verdict!(
              unquote(file),
              unquote(blank_meta[:line]),
              Koans.Verdict.review_path(unquote(review))
            )
          end

        {:verdict, meta, [review, answer, digests, source]}

      {:__, meta, ctx} when is_atom(ctx) ->
        quote do
          Koans.Blank.value!(unquote(file), unquote(meta[:line]))
        end

      node ->
        node
    end)
  end

  defp review_module_tag(body, caller) do
    {_body, modules} =
      Macro.prewalk(body, [], fn
        {:run_checks, _meta, [_context, module]} = node, found ->
          {node, [Macro.expand(module, caller) | found]}

        node, found ->
          {node, found}
      end)

    case Enum.reverse(modules) do
      [] -> []
      [module | _] -> [review_module: module]
    end
  end

  defp chapter(file) do
    case Regex.run(~r/^(\d+)/, Path.basename(file)) do
      [_, digits] -> digits
      nil -> "00"
    end
  end
end

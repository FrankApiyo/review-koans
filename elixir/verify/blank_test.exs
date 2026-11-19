defmodule Verify.BlankTest do
  use ExUnit.Case, async: false

  @sample "verify/blank_sample.exs"

  setup_all do
    [{module, _}] =
      Code.compile_string(
        ~S'''
        defmodule Verify.BlankSample do
          use ExUnit.Case, register: false
          import Koans, only: [koan: 2, __: 0, verdict: 4]

          koan "A value blank." do
            assert 1 + 1 == __
          end

          koan "A verdict blank." do
            verdict("cart.ex", __, "d5882bb7c9", "04510edbdf")
          end

          koan "A code blank." do
            items = [1, 2]
            __()
          end

          koan "A fix koan." do
            run_checks(:context, Review.Cart)
          end

          defp run_checks(_context, _module), do: :ok
        end
        ''',
        @sample
      )

    %{tests: Map.new(module.__ex_unit__().tests, &{&1.tags.meditation, &1})}
  end

  defp blank(%{tests: tests}, meditation) do
    test = Map.fetch!(tests, meditation)
    apply(test.module, test.name, [%{}])
    flunk("expected Koans.Blank from #{inspect(meditation)}")
  rescue
    error in Koans.Blank -> error
  end

  test "a value blank raises Koans.Blank with the value message at its own line", context do
    assert %Koans.Blank{
             message: "Replace __ with the value that makes this true.",
             file: file,
             line: 6
           } = blank(context, "A value blank.")

    assert Path.relative_to_cwd(file) == @sample
  end

  test "a verdict blank names the review path", context do
    previous = System.get_env("KOANS_DIR")
    System.put_env("KOANS_DIR", "koans")

    try do
      assert %Koans.Blank{
               message:
                 "Replace __ with :fine, or the number of the line with the bug in koans/review/cart.ex.",
               line: 10
             } = blank(context, "A verdict blank.")
    after
      if previous, do: System.put_env("KOANS_DIR", previous), else: System.delete_env("KOANS_DIR")
    end
  end

  test "a code blank raises with the code message", context do
    assert %Koans.Blank{
             message: "Replace __() with the code the meditation describes.",
             line: 15
           } = blank(context, "A code blank.")
  end

  test "a koan is named by chapter and line and tagged with its meditation", %{tests: tests} do
    test = Map.fetch!(tests, "A value blank.")
    assert test.name == :"test 00:5"
    assert test.tags.line == 5
  end

  test "a koan that calls run_checks is tagged with the review module", %{tests: tests} do
    assert Map.fetch!(tests, "A fix koan.").tags.review_module == Review.Cart
    refute Map.has_key?(Map.fetch!(tests, "A value blank.").tags, :review_module)
  end
end

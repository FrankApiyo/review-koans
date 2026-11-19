defmodule Koans.Checks do
  @callback cases() :: [{:exploit | :twin, String.t(), (-> any())}]

  # A fix that changes an arity would make the compiler quote a check's line, input included.
  defmacro __using__(opts) do
    review = opts |> Keyword.fetch!(:review) |> Macro.expand(__CALLER__)

    quote do
      @behaviour Koans.Checks
      @compile {:no_warn_undefined, unquote(review)}
      import ExUnit.Assertions
    end
  end
end

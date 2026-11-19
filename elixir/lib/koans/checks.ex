defmodule Koans.Checks do
  @callback cases() :: [{:exploit | :twin, String.t(), (-> any())}]
end

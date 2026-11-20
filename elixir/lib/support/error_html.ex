defmodule Support.ErrorHTML do
  @spec render(String.t(), map()) :: String.t()
  def render(template, _assigns), do: template
end

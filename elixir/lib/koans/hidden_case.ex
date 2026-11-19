defmodule Koans.HiddenCase do
  @type cause :: nil | {:raised, module()} | :exited

  defexception [:label, :kind, :review_path, :cause]

  @impl true
  def message(%__MODULE__{label: label, cause: cause}),
    do: "A hidden case still fails: #{label}" <> suffix(cause)

  defp suffix(nil), do: ""
  defp suffix({:raised, module}), do: " (it raised #{inspect(module)})"
  defp suffix(:exited), do: " (it exited)"
end

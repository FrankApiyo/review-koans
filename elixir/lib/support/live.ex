defmodule Support.Live do
  @doc "A test conn whose session holds the signed-in user's id."
  @spec conn(pos_integer()) :: Plug.Conn.t()
  def conn(uid) when is_integer(uid) and uid > 0 do
    Plug.Test.init_test_session(Phoenix.ConnTest.build_conn(), %{"uid" => uid})
  end
end

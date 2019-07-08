defmodule DBConnection.ConnectionPool.Pool do
  @moduledoc false
  use Supervisor, restart: :temporary

  def start_supervised(tag, mod, opts) do
    IO.puts "[Debug] DBConnection.ConnectionPool.Pool.start_supervised"
    IO.puts "[Debug] args=#{inspect [mod, opts]}"
    IO.puts ""
    DBConnection.Watcher.watch(
      DBConnection.ConnectionPool.Supervisor,
      {DBConnection.ConnectionPool.Pool, {self(), tag, mod, opts}}
    )
  end

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg)
  end

  def init({owner, tag, mod, opts}) do
    IO.puts "[Debug] DBConnection.ConnectionPool.Pool.init"
    IO.puts "[Debug] self=#{inspect self()}"
    IO.puts ""
    size = Keyword.get(opts, :pool_size, 1)
    children = for id <- 1..size, do: conn(owner, tag, id, mod, opts)
    sup_opts = [strategy: :one_for_one] ++ Keyword.take(opts, [:max_restarts, :max_seconds])
    Supervisor.init(children, sup_opts)
  end

  ## Helpers

  defp conn(owner, tag, id, mod, opts) do
    child_opts = [id: {mod, owner, id}] ++ Keyword.take(opts, [:shutdown])
    DBConnection.Connection.child_spec(mod, opts, owner, tag, child_opts)
  end
end

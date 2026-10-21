defmodule CaptainNotes.Pronote.ReadRefresh do
  @moduledoc false
  use GenServer

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  def init(_), do: {:ok, %{}}

  # Coalesce only concurrent reads. No result survives the current refresh.
  def run(key, read) do
    result =
      case GenServer.call(__MODULE__, {:join, key}, :infinity) do
        :run ->
          result =
            try do
              {:return, read.()}
            catch
              kind, reason -> {:raise, kind, reason, __STACKTRACE__}
            end

          GenServer.call(__MODULE__, {:complete, key, result}, :infinity)
          result

        result ->
          result
      end

    case result do
      {:return, value} -> value
      {:raise, kind, reason, stack} -> :erlang.raise(kind, reason, stack)
    end
  end

  def handle_call({:join, key}, {pid, _} = from, state) do
    case Map.get(state, key) do
      nil ->
        entry = %{leader: pid, monitor: Process.monitor(pid), waiters: []}
        {:reply, :run, Map.put(state, key, entry)}

      entry ->
        {:noreply, Map.put(state, key, %{entry | waiters: [from | entry.waiters]})}
    end
  end

  def handle_call({:complete, key, result}, {pid, _}, state) do
    case Map.get(state, key) do
      %{leader: ^pid} = entry ->
        Process.demonitor(entry.monitor, [:flush])
        Enum.each(entry.waiters, &GenServer.reply(&1, result))
        {:reply, :ok, Map.delete(state, key)}

      _ ->
        {:reply, :ok, state}
    end
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, state) do
    state =
      Map.reject(state, fn {_key, entry} ->
        if entry.monitor == ref do
          Enum.each(entry.waiters, &GenServer.reply(&1, {:raise, :exit, :refresh_cancelled, []}))
          true
        else
          false
        end
      end)

    {:noreply, state}
  end

  def format_status(status), do: %{status | state: :redacted}
end

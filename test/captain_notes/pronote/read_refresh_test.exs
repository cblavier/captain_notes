defmodule CaptainNotes.Pronote.ReadRefreshTest do
  use ExUnit.Case, async: true
  alias CaptainNotes.Pronote.ReadRefresh

  test "concurrent readers share one result but a later refresh runs again" do
    key = make_ref()
    owner = self()

    leader =
      Task.async(fn ->
        ReadRefresh.run(key, fn ->
          send(owner, {:started, self()})

          receive do
            :finish -> :result
          end
        end)
      end)

    assert_receive {:started, pid}
    follower = Task.async(fn -> ReadRefresh.run(key, fn -> flunk("duplicate read") end) end)
    await_waiter(key)
    send(pid, :finish)
    assert Task.await(leader) == :result
    assert Task.await(follower) == :result
    assert ReadRefresh.run(key, fn -> :next end) == :next
  end

  test "a cancelled leader releases waiting readers" do
    key = make_ref()
    owner = self()

    pid =
      spawn(fn ->
        ReadRefresh.run(key, fn ->
          send(owner, :started)

          receive do
            :never -> :done
          end
        end)
      end)

    assert_receive :started

    follower =
      Task.async(fn ->
        catch_exit(ReadRefresh.run(key, fn -> flunk("duplicate read") end))
      end)

    await_waiter(key)
    Process.exit(pid, :kill)
    assert Task.await(follower) == :refresh_cancelled
    assert ReadRefresh.run(key, fn -> :recovered end) == :recovered
  end

  defp await_waiter(key, attempts \\ 100)
  defp await_waiter(_key, 0), do: flunk("reader did not join")

  defp await_waiter(key, attempts) do
    if :sys.get_state(ReadRefresh)[key].waiters == [] do
      Process.sleep(1)
      await_waiter(key, attempts - 1)
    end
  end
end

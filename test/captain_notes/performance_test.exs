defmodule CaptainNotes.PerformanceTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureLog
  alias CaptainNotes.Performance

  setup do
    level = Logger.level()
    Logger.configure(level: :info)
    on_exit(fn -> Logger.configure(level: level) end)
    :ok
  end

  test "measures cache hits without logging cached data" do
    log =
      capture_log([level: :info], fn ->
        assert {:ok, "private school data"} =
                 Performance.measure(:display_cache, [section: "notes", operation: :load], fn ->
                   {:ok, "private school data"}
                 end)
      end)

    assert log =~ "stage=display_cache"
    assert log =~ "duration_ms="
    assert log =~ "outcome=hit"
    refute log =~ "private school data"
  end

  test "records failures without swallowing or logging their contents" do
    log =
      capture_log([level: :info], fn ->
        assert_raise RuntimeError, "secret", fn ->
          Performance.measure(:pronote_read, [operation: :grades], fn -> raise "secret" end)
        end

        assert {:error, "private error"} =
                 Performance.measure(:dashboard_read, [], fn -> {:error, "private error"} end)
      end)

    assert log =~ "outcome=error"
    refute log =~ "secret"
    refute log =~ "private error"
  end

  test "navigation telemetry exposes only the section and state flags" do
    socket = %Phoenix.LiveView.Socket{
      view: CaptainNotesWeb.DashboardLive,
      assigns: %{section: "notes", loading: false, child: %{name: "Private name"}}
    }

    log =
      capture_log([level: :info], fn ->
        :telemetry.execute(
          [:phoenix, :live_view, :handle_params, :stop],
          %{duration: System.convert_time_unit(12, :millisecond, :native)},
          %{socket: socket, uri: "/private-child/notes", params: %{secret: "private"}}
        )
      end)

    assert log =~ "stage=navigation duration_ms=12.0 section=notes"
    refute log =~ "Private name"
    refute log =~ "private"
  end
end

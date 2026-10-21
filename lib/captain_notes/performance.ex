defmodule CaptainNotes.Performance do
  @moduledoc false
  require Logger

  def attach do
    :telemetry.attach(
      __MODULE__,
      [:phoenix, :live_view, :handle_params, :stop],
      &__MODULE__.handle_navigation/4,
      nil
    )
  end

  def handle_navigation(_event, %{duration: duration}, %{socket: socket}, _config) do
    if socket.view == CaptainNotesWeb.DashboardLive do
      log(:navigation, duration,
        section: socket.assigns.section,
        connected: Phoenix.LiveView.connected?(socket),
        loading: socket.assigns.loading
      )
    end
  end

  def measure(stage, fields, fun) do
    started = System.monotonic_time()

    try do
      result = fun.()

      outcome =
        case {stage, result} do
          {:display_cache, {:miss, _}} -> :miss
          {:display_cache, {_, true}} -> :fresh
          {:display_cache, {_, false}} -> :stale
          {:display_cache, :miss} -> :miss
          {:display_cache, _} -> :hit
          _ -> outcome(result)
        end

      log(stage, System.monotonic_time() - started, fields ++ [outcome: outcome])
      result
    catch
      kind, reason ->
        log(stage, System.monotonic_time() - started, fields ++ [outcome: kind])
        :erlang.raise(kind, reason, __STACKTRACE__)
    end
  end

  defp outcome(:miss), do: :miss
  defp outcome({:hit, _}), do: :hit
  defp outcome({:miss, _}), do: :miss
  defp outcome({:error, _}), do: :error
  defp outcome(_), do: :ok

  # Callers supply only operation names and flags, never URLs, IDs or payloads.
  defp log(stage, duration, fields) do
    milliseconds = System.convert_time_unit(duration, :native, :microsecond) / 1000

    Logger.info(fn ->
      "performance stage=#{stage} duration_ms=#{Float.round(milliseconds, 2)} " <>
        Enum.map_join(fields, " ", fn {key, value} -> "#{key}=#{value}" end)
    end)
  end
end

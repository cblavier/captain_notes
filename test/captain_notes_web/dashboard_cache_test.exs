defmodule CaptainNotesWeb.DashboardCacheTest do
  use ExUnit.Case, async: true

  alias CaptainNotesWeb.DashboardCache

  for {section, kind} <- [{"agenda", :lessons}, {"cantine", :menus}, {"devoirs", :homework}] do
    test "#{section} waits for both events and its content before rendering empty states" do
      assigns = %{
        selected_slug: "alice",
        grade_period: nil,
        today: ~D[2026-09-28],
        week: ~D[2026-09-28],
        agenda_from: ~D[2026-09-28],
        mode: :week,
        section: unquote(section),
        account: %{role: :parent}
      }

      content_key = {unquote(kind), "a", ~D[2026-09-28], ~D[2026-10-04]}
      entries = %{{:children} => [%{id: "a", name: "Alice"}]}

      assert DashboardCache.fetch(Map.put(entries, {:events, "a"}, []), assigns, :load) ==
               :miss

      assert DashboardCache.fetch(Map.put(entries, content_key, []), assigns, :load) ==
               :miss

      complete = entries |> Map.put({:events, "a"}, []) |> Map.put(content_key, [])
      assert {:ok, result} = DashboardCache.fetch(complete, assigns, :load)
      assert result.events == {:ok, []}
      assert result[unquote(kind)] == {:ok, []}
    end
  end

  test "homework waits for its requested range even when events and urgent homework are cached" do
    assigns = %{
      selected_slug: "alice",
      grade_period: nil,
      today: ~D[2026-09-28],
      week: ~D[2026-09-28],
      agenda_from: ~D[2026-09-28],
      mode: :week,
      section: "devoirs",
      account: %{role: :parent}
    }

    entries = %{
      {:children} => [%{id: "a", name: "Alice"}],
      {:events, "a"} => [],
      {:homework, "a", ~D[2026-09-28], ~D[2026-09-29]} => []
    }

    assert DashboardCache.fetch(entries, assigns, :load) == :miss

    entries = Map.put(entries, {:homework, "a", ~D[2026-09-28], ~D[2026-10-04]}, [])
    assert {:ok, %{homework: {:ok, []}}} = DashboardCache.fetch(entries, assigns, :load)

    task = %{date: ~D[2026-09-30], done: false}
    entries = Map.put(entries, {:homework, "a", ~D[2026-09-28], ~D[2026-10-04]}, [task])
    assert {:ok, %{homework: {:ok, [^task]}}} = DashboardCache.fetch(entries, assigns, :load)
  end
end

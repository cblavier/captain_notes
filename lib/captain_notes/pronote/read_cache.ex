defmodule CaptainNotes.Pronote.ReadCache do
  @moduledoc "Bounded, memory-only cache of successful reads; never refreshes in the background."
  use GenServer

  def start_link(options),
    do: GenServer.start_link(__MODULE__, options, name: Keyword.get(options, :name, __MODULE__))

  def fetch(key, server \\ __MODULE__), do: GenServer.call(server, {:fetch, key})

  def put(key, value, ttl, generation, server \\ __MODULE__),
    do: GenServer.call(server, {:put, key, value, ttl, generation})

  def invalidate(scope, server \\ __MODULE__), do: GenServer.call(server, {:invalidate, scope})

  # Display snapshots survive ordinary read expiry, but share logout/session invalidation.
  def generation(key), do: GenServer.call(__MODULE__, {:generation, key})

  def notes(owner, server \\ __MODULE__), do: GenServer.call(server, {:notes, owner})

  def display(owner, server \\ __MODULE__), do: GenServer.call(server, {:display, owner})

  # Project in the cache process so unrelated snapshots never cross process heaps.
  def select_display(owner, select, server \\ __MODULE__),
    do: GenServer.call(server, {:select_display, owner, select})

  def display_status(owner, select, complete, server \\ __MODULE__),
    do: GenServer.call(server, {:display_status, owner, select, complete})

  def revision, do: GenServer.call(__MODULE__, :revision)

  def remember(owner, operation, value, token \\ nil) do
    key = {owner, {:display, operation}}
    put(key, value, :timer.hours(24), token || generation(key))
  end

  def ttl(kind) when kind in [:lessons, :events], do: 300_000

  def ttl(kind) when kind in [:homework, :discussions, :parent_discussions, :correspondence],
    do: 300_000

  def ttl(:grades), do: 300_000
  def ttl(:menus), do: 1_800_000

  @impl true
  def init(options) do
    {:ok,
     %{
       entries: %{},
       generation: make_ref(),
       kind_generations: %{},
       limit: Keyword.get(options, :limit, 256),
       clock: Keyword.get(options, :clock, fn -> System.monotonic_time(:millisecond) end)
     }}
  end

  @impl true
  def handle_call({:invalidate, {:owner_reads, owner}}, _from, state) do
    entries =
      Map.reject(state.entries, fn
        {{pid, {identity, _}}, _} -> pid == owner and identity != :display
        _ -> false
      end)

    entries = stale_display(entries, owner, :all, state.clock.())
    {:reply, :ok, %{state | entries: entries, generation: make_ref()}}
  end

  def handle_call({:invalidate, {:owner_kinds, owner, kinds}}, _from, state) do
    entries =
      Map.reject(state.entries, fn
        {{pid, {identity, _}} = key, _} ->
          pid == owner and identity != :display and kind(key) in kinds

        _ ->
          false
      end)

    entries = stale_display(entries, owner, kinds, state.clock.())
    {:reply, :ok, %{state | entries: entries, generation: make_ref()}}
  end

  def handle_call({:generation, key}, _from, state), do: {:reply, generation(state, key), state}

  def handle_call(:revision, _from, state),
    do: {:reply, {state.generation, state.kind_generations}, state}

  def handle_call({:display_status, owner, select, complete}, _from, state) do
    state = prune(state)
    now = state.clock.()

    all =
      for {{^owner, {:display, op}}, {value, _, _}} <- state.entries, into: %{}, do: {op, value}

    fresh =
      for {{^owner, {:display, op}}, {value, _, inserted}} <- state.entries,
          now - inserted < display_ttl(elem(op, 0)),
          into: %{},
          do: {op, value}

    result = select.(all)
    {:reply, {result, result != :miss and complete.(fresh) == result}, state}
  end

  def handle_call({:display, owner}, _from, state) do
    handle_call({:select_display, owner, &Function.identity/1}, nil, state)
  end

  def handle_call({:select_display, owner, select}, _from, state) do
    state = prune(state)

    entries =
      for {{^owner, {:display, operation}}, {value, _, _}} <- state.entries,
          into: %{},
          do: {operation, value}

    {:reply, select.(entries), state}
  end

  def handle_call({:notes, owner}, _from, state) do
    state = prune(state)
    notes = for {{^owner, {:display, {:grades, _}}}, {value, _, _}} <- state.entries, do: value
    {:reply, notes, state}
  end

  def handle_call({:fetch, key}, _from, state) do
    state = prune(state)

    reply =
      case Map.get(state.entries, key) do
        nil -> {:miss, generation(state, key)}
        {value, _, _} -> {:hit, value}
      end

    {:reply, reply, state}
  end

  def handle_call({:put, key, value, ttl, generation}, _from, state) do
    state = prune(state)

    if generation == generation(state, key) do
      now = state.clock.()
      entries = Map.put(state.entries, key, {value, now + ttl, now})

      entries =
        if map_size(entries) > state.limit do
          {oldest, _} = Enum.min_by(entries, fn {_, {_, _, inserted}} -> inserted end)
          Map.delete(entries, oldest)
        else
          entries
        end

      {:reply, :ok, %{state | entries: entries}}
    else
      {:reply, :ok, state}
    end
  end

  def handle_call({:invalidate, {:kind, kind}}, _from, state) do
    entries = Map.reject(state.entries, fn {key, _} -> kind(key) == kind end)
    generations = Map.put(state.kind_generations, kind, make_ref())
    {:reply, :ok, %{state | entries: entries, kind_generations: generations}}
  end

  def handle_call({:invalidate, scope}, _from, state) do
    entries =
      if scope == :all,
        do: %{},
        else: Map.reject(state.entries, fn {{owner, _}, _} -> owner == scope end)

    {:reply, :ok, %{state | entries: entries, generation: make_ref()}}
  end

  @impl true
  def format_status(status), do: %{status | state: :redacted}

  defp generation(state, key),
    do: {state.generation, Map.get(state.kind_generations, kind(key))}

  defp kind({_owner, {_identity, operation}}) when is_tuple(operation), do: elem(operation, 0)
  defp kind(_key), do: nil

  defp prune(state) do
    now = state.clock.()

    entries =
      Map.reject(state.entries, fn {{owner, _}, {_, expires, _}} ->
        expires <= now or not Process.alive?(owner)
      end)

    %{state | entries: entries}
  end

  defp display_ttl(kind)
       when kind in [
              :lessons,
              :events,
              :homework,
              :discussions,
              :parent_discussions,
              :correspondence,
              :grades,
              :menus
            ],
       do: ttl(kind)

  defp display_ttl(_), do: :timer.hours(24)

  defp stale_display(entries, owner, kinds, now) do
    Map.new(entries, fn
      {{^owner, {:display, operation}} = key, {value, expires, inserted}} ->
        inserted =
          if kinds == :all or elem(operation, 0) in kinds,
            do: now - :timer.hours(24),
            else: inserted

        {key, {value, expires, inserted}}

      entry ->
        entry
    end)
  end
end

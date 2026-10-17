defmodule CaptainNotes.Agenda do
  @moduledoc "Presentation of a day's lessons, replacements and gaps."

  @doc "Identifies a school holiday covering the displayed dates using Pronote events."
  def holiday(events, from, to) do
    Enum.find_value(events, fn event ->
      with kind when not is_nil(kind) <- holiday_kind(event.title),
           %NaiveDateTime{} = first <- event.start,
           %NaiveDateTime{} = last <- event.end,
           :lt <- NaiveDateTime.compare(first, last) do
        resume =
          if NaiveDateTime.to_time(last) == ~T[00:00:00],
            do: NaiveDateTime.to_date(last),
            else: last |> NaiveDateTime.to_date() |> Date.add(1)

        resume = next_weekday(resume)

        if Date.compare(from, NaiveDateTime.to_date(first)) != :lt &&
             Date.compare(to, from) != :lt && Date.compare(to, resume) == :lt do
          %{kind: kind, return_date: resume}
        end
      else
        _ -> nil
      end
    end)
  end

  defp holiday_kind(title) do
    title =
      (title || "")
      |> String.downcase()
      |> String.normalize(:nfd)
      |> String.replace(~r/\p{Mn}/u, "")

    if Regex.match?(~r/\b(vacances|conges)\b/u, title) do
      cond do
        Regex.match?(~r/\b(toussaint|automne)\b/u, title) -> :autumn
        Regex.match?(~r/\bnoel\b/u, title) -> :christmas
        Regex.match?(~r/\b(hiver|fevrier)\b/u, title) -> :winter
        Regex.match?(~r/\b(paques|printemps)\b/u, title) -> :spring
        Regex.match?(~r/\bete\b|\bgrandes\s+vacances\b/u, title) -> :summer
        true -> nil
      end
    end
  end

  defp next_weekday(date) do
    case Date.day_of_week(date) do
      6 -> Date.add(date, 2)
      7 -> Date.add(date, 1)
      _ -> date
    end
  end

  @doc "Hides canceled lessons replaced by an overlapping active lesson."
  def without_replaced_cancellations(lessons) do
    active = Enum.reject(lessons, & &1.canceled)

    lessons
    |> Enum.reject(fn lesson ->
      lesson.canceled and Enum.any?(active, &overlap?(lesson, &1))
    end)
  end

  def entries(lessons) do
    lessons
    |> without_replaced_cancellations()
    |> Enum.sort_by(& &1.start, NaiveDateTime)
    |> Enum.map_reduce(nil, fn lesson, previous_end ->
      pause =
        if previous_end && NaiveDateTime.compare(previous_end, lesson.start) == :lt do
          %{start: previous_end, end: lesson.start}
        end

      ending =
        if previous_end && NaiveDateTime.compare(previous_end, lesson.end) == :gt,
          do: previous_end,
          else: lesson.end

      {Map.put(lesson, :pauses_before, split_pause(pause, lesson.lunch_window)), ending}
    end)
    |> elem(0)
  end

  defp split_pause(nil, _), do: []
  defp split_pause(pause, nil), do: [Map.put(pause, :label, "Pause")]

  defp split_pause(pause, lunch) do
    [pause.start, pause.end, lunch.start, lunch.end]
    |> Enum.filter(fn time ->
      NaiveDateTime.compare(time, pause.start) != :lt and
        NaiveDateTime.compare(time, pause.end) != :gt
    end)
    |> Enum.uniq()
    |> Enum.sort(NaiveDateTime)
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.map(fn [from, to] ->
      label =
        if NaiveDateTime.compare(from, lunch.start) != :lt and
             NaiveDateTime.compare(to, lunch.end) != :gt,
           do: "Repas",
           else: "Pause"

      %{start: from, end: to, label: label}
    end)
  end

  defp overlap?(left, right) do
    NaiveDateTime.compare(left.start, right.end) == :lt and
      NaiveDateTime.compare(right.start, left.end) == :lt
  end
end

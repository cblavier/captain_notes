defmodule Pronotex.Pronote.Recipient do
  @moduledoc false

  def parse_list(rows) do
    Enum.flat_map(rows, fn
      # Parent-space responses contain groups (class parents, delegates),
      # whose actual recipients live in listeResp rather than at the top level.
      %{"listeResp" => %{"V" => parents}} = group when is_list(parents) ->
        for %{"G" => 5} = parent <- parents do
          case parse(parent) do
            nil ->
              nil

            recipient ->
              %{
                recipient
                | roles: Enum.uniq(group_roles(group) ++ recipient.roles),
                  groups: group_names(group)
              }
          end
        end

      raw ->
        [parse(raw)]
    end)
  end

  def parse(raw) do
    # The server-provided parent list does not require avecDiscussion;
    # PRONOTE applies that flag only to teachers and staff.
    if (raw["G"] == 5 or (raw["G"] in [3, 34] and raw["avecDiscussion"] == true)) and
         is_binary(raw["N"]) and is_binary(raw["L"]) do
      %{
        id: "#{raw["G"]}:#{raw["N"]}",
        name: raw["L"],
        type: %{3 => "Professeur", 5 => "Responsable", 34 => "Personnel"}[raw["G"]],
        subjects: subjects(raw),
        roles: delegate_roles(raw),
        groups: [],
        resource: Map.take(raw, ["N", "G", "L"])
      }
    end
  end

  def merge(recipients) do
    recipients
    |> Enum.reject(&is_nil/1)
    |> Enum.group_by(& &1.id)
    |> Enum.map(fn {_, [first | _] = entries} ->
      %{
        first
        | subjects: entries |> Enum.flat_map(& &1.subjects) |> Enum.uniq(),
          roles: entries |> Enum.flat_map(& &1.roles) |> Enum.uniq(),
          groups: entries |> Enum.flat_map(& &1.groups) |> Enum.uniq()
      }
    end)
    |> Enum.sort_by(&String.downcase(&1.name))
  end

  def groups(recipients) do
    recipients
    |> Enum.flat_map(fn recipient ->
      Enum.map(Map.get(recipient, :groups, []), &{&1, recipient.id})
    end)
    |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
    |> Enum.map(fn {name, ids} ->
      %{
        id: "group:" <> Base.url_encode64(name, padding: false),
        name: name,
        type: "Groupe",
        subjects: [],
        roles: [],
        member_ids: Enum.uniq(ids)
      }
    end)
    |> Enum.sort_by(& &1.name)
  end

  defp group_names(%{"L" => label} = group) do
    if group_roles(group) == [],
      do: [],
      else: [label |> String.trim() |> String.replace(~r/\s*\(([^)]+)\)$/, " \\1")]
  end

  defp group_names(_), do: []

  defp subjects(%{"G" => 3} = raw) do
    (get_in(raw, ["listeRessources", "V"]) || [])
    |> Enum.filter(&(is_map(&1) and &1["G"] in [nil, 16] and &1["estUneSousMatiere"] != true))
    |> Enum.map(& &1["L"])
    |> Enum.filter(&is_binary/1)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()
  end

  defp subjects(_), do: []

  defp group_roles(%{"L" => label}) when is_binary(label) do
    cond do
      match = Regex.run(~r/^Parents de la classe\s*\(([^)]+)\)$/u, String.trim(label)) ->
        ["Parent (#{String.trim(Enum.at(match, 1))})"]

      match = Regex.run(~r/^Parents délégués\s*\(([^)]+)\)$/u, String.trim(label)) ->
        ["Parent délégué (#{String.trim(Enum.at(match, 1))})"]

      true ->
        []
    end
  end

  defp group_roles(_), do: []

  defp delegate_roles(%{"G" => 5, "delegueDesClasses" => classes}) when is_binary(classes) do
    classes
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(&"Parent délégué (#{&1})")
  end

  defp delegate_roles(_), do: []

  def valid_message?(ids, subject, content) do
    is_list(ids) and ids != [] and length(ids) <= 100 and Enum.all?(ids, &is_binary/1) and
      is_binary(subject) and String.trim(subject) != "" and String.length(subject) <= 200 and
      not placeholders?(subject) and
      valid_content?(content)
  end

  def valid_content?(content),
    do:
      is_binary(content) and String.trim(content) != "" and String.length(content) <= 20_000 and
        not placeholders?(content)

  def placeholders?(text) when is_binary(text), do: Regex.match?(~r/\[[^\[\]]+\]/u, text)
  def placeholders?(_), do: false
end

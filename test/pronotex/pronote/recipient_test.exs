defmodule Pronotex.Pronote.RecipientTest do
  use ExUnit.Case, async: true
  alias Pronotex.Pronote.Recipient

  test "parent groups expose individual recipients without treating groups or children as recipients" do
    parent = %{"N" => "parent", "G" => 5, "L" => "Mme Dupont"}
    delegate = %{"N" => "delegate", "G" => 5, "L" => "M. Martin"}

    rows = [
      %{
        "N" => 0,
        "G" => 6,
        "L" => "Parents de la classe (5B)",
        "listeResp" => %{"V" => [parent, %{"N" => "child", "G" => 4, "L" => "Alice"}]}
      },
      %{"L" => "Parents délégués (5B)", "listeResp" => %{"V" => [parent, delegate]}},
      %{"L" => "Parents délégués (3A)", "listeResp" => %{"V" => []}},
      %{"N" => "teacher", "G" => 3, "L" => "Mme Robert", "avecDiscussion" => true}
    ]

    recipients = rows |> Recipient.parse_list() |> Recipient.merge()
    assert Enum.sort(Enum.map(recipients, & &1.id)) == ["3:teacher", "5:delegate", "5:parent"]
    assert Enum.find(recipients, &(&1.id == "5:parent")).resource == parent
    assert Enum.find(recipients, &(&1.id == "5:delegate")).resource == delegate

    assert Enum.find(recipients, &(&1.id == "5:parent")).roles == [
             "Parent (5B)",
             "Parent délégué (5B)"
           ]

    assert Enum.find(recipients, &(&1.id == "5:delegate")).roles == ["Parent délégué (5B)"]
    assert [class, delegates] = Recipient.groups(recipients)
    assert class.name == "Parents de la classe 5B"
    assert class.member_ids == ["5:parent"]
    assert delegates.name == "Parents délégués 5B"
    assert Enum.sort(delegates.member_ids) == ["5:delegate", "5:parent"]
    assert Recipient.groups(recipients ++ recipients) == [class, delegates]
    assert Recipient.parse_list([]) == []
  end

  test "roles from different classes and the all-delegates group merge without duplicates" do
    parent = %{"N" => "parent", "G" => 5, "L" => "Mme Dupont"}
    delegate = Map.put(parent, "delegueDesClasses", "4A, 6B")

    rows = [
      %{"L" => "Parents de la classe (6B)", "listeResp" => %{"V" => [parent]}},
      %{"L" => "Parents délégués (4A)", "listeResp" => %{"V" => [parent]}},
      %{"L" => "Tous les parents délégués", "listeResp" => %{"V" => [delegate]}}
    ]

    assert [recipient] = (rows ++ rows) |> Recipient.parse_list() |> Recipient.merge()
    assert recipient.roles == ["Parent (6B)", "Parent délégué (4A)", "Parent délégué (6B)"]
    assert recipient.resource == parent
    # Class membership comes from the actual groups, not inferred delegate tags.
    assert Enum.map(Recipient.groups([recipient]), & &1.name) == [
             "Parents de la classe 6B",
             "Parents délégués 4A"
           ]

    assert Recipient.parse(parent).roles == []
  end

  test "parents returned by Pronote do not require the teacher discussion flag" do
    raw = %{"N" => "parent", "G" => 5, "L" => "Mme Dupont"}

    for parent <- [raw, Map.put(raw, "avecDiscussion", false)] do
      assert %{id: "5:parent", type: "Responsable", resource: ^raw} = Recipient.parse(parent)
    end

    for kind <- [3, 34, 4, 6] do
      assert Recipient.parse(%{raw | "G" => kind}) == nil
    end

    assert Recipient.parse(Map.delete(raw, "N")) == nil
    assert Recipient.parse(Map.delete(raw, "L")) == nil
  end

  test "teachers shared across child contexts merge their subjects without duplicates" do
    raw = %{
      "N" => "123",
      "G" => 3,
      "L" => "Mme Martin",
      "avecDiscussion" => true,
      "listeRessources" => %{"V" => [%{"G" => 16, "L" => "Mathématiques"}]}
    }

    other =
      put_in(raw, ["listeRessources", "V"], [
        %{"L" => "Mathématiques"},
        %{"L" => "Physique-chimie"}
      ])

    merged =
      Recipient.merge([
        Recipient.parse(raw),
        Recipient.parse(other),
        Recipient.parse(%{raw | "G" => 5}),
        Recipient.parse(%{raw | "avecDiscussion" => false})
      ])

    assert length(merged) == 2

    assert Enum.find(merged, &(&1.type == "Professeur")).subjects == [
             "Mathématiques",
             "Physique-chimie"
           ]

    assert Enum.find(merged, &(&1.type == "Responsable")).subjects == []
    refute Map.has_key?(hd(merged), :children)
  end

  test "missing subjects stay empty and unrelated resources are excluded" do
    raw = %{"N" => "123", "G" => 3, "L" => "Mme Martin", "avecDiscussion" => true}
    assert Recipient.parse(raw).subjects == []

    raw =
      Map.put(raw, "listeRessources", %{
        "V" => [
          %{"L" => "Mathématiques", "G" => 16},
          %{"L" => "Géométrie", "estUneSousMatiere" => true},
          %{"L" => "Alice", "G" => 4},
          %{"L" => " "},
          %{}
        ]
      })

    assert Recipient.parse(raw).subjects == ["Mathématiques"]
  end
end

defmodule CaptainNotes.Pronote.InformationTest do
  use ExUnit.Case, async: true
  alias CaptainNotes.Pronote.Information

  test "acknowledged information is read even when the list still reports it unread" do
    for read <- [false, nil] do
      notice = parse(%{"lue" => read}, [true])

      assert notice.acknowledged
      refute notice.can_acknowledge
      assert notice.unread == 0
    end
  end

  test "pending and partially acknowledged information remains unread" do
    for acknowledgements <- [[], [false], [true, false]] do
      assert parse(%{"lue" => false}, acknowledgements).unread == 1
      assert parse(%{"lue" => true}, acknowledgements).unread == 0
    end
  end

  test "survey read status is independent of acknowledgement questions" do
    assert parse(%{"estSondage" => true, "lue" => false}, [true]).unread == 1
    assert parse(%{"estSondage" => true, "lue" => true}, [true]).unread == 0
  end

  defp parse(raw, acknowledgements) do
    questions =
      for {acknowledged, index} <- Enum.with_index(acknowledgements) do
        %{
          "N" => to_string(index),
          "genreReponse" => 0,
          "reponse" => %{"V" => %{"avecReponse" => acknowledged, "estRepondant" => true}}
        }
      end

    Information.parse(
      raw,
      %{"detailsActualite" => %{"listeQuestions" => %{"V" => questions}}},
      nil
    )
  end
end

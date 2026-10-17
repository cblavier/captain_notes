defmodule CaptainNotesWeb.DashboardRouteTest do
  use CaptainNotesWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Emploi du temps"
  end
end

defmodule CaptainNotesWeb.AvatarController do
  use CaptainNotesWeb, :controller

  def show(conn, %{"index" => index}) do
    conn =
      conn
      |> put_resp_header("cache-control", "private, no-store")
      |> put_resp_header("x-content-type-options", "nosniff")

    case if(CaptainNotesWeb.Auth.avatar_allowed?(conn, "/avatars/" <> index),
           do: CaptainNotes.Family.avatar_data(index),
           else: :error
         ) do
      {:ok, type, bytes} -> conn |> put_resp_content_type(type) |> send_resp(200, bytes)
      :error -> send_resp(conn, 404, "")
    end
  end
end

defmodule MLLPartyWeb.ReadyCheckTest do
  use MLLPartyWeb.ConnCase, async: true

  test "GET /readyz returns `200 OK`" do
    body =
      build_conn()
      |> get("/readyz")
      |> response(200)

    assert body == "OK"
  end
end

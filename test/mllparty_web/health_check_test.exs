defmodule MLLPartyWeb.HealthCheckTest do
  use MLLPartyWeb.ConnCase, async: true

  test "GET /healthz returns `200 OK`" do
    body =
      build_conn()
      |> get("/healthz")
      |> response(200)

    assert body == "OK"
  end
end

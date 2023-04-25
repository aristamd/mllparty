defmodule MLLPartyWeb.ConnectionControllerTest do
  use MLLPartyWeb.ConnCase

  @moduletag capture_log: true

  @api_key "test_sekret"
  @api_endpoint "/api/connections"

  setup do
    original_api_key = Application.get_env(:mllparty, :api_key)
    Application.put_env(:mllparty, :api_key, @api_key)

    authd_conn = build_conn() |> basic_auth("", @api_key)

    on_exit(fn ->
      MLLParty.ConnectionHub.reset()
      Application.put_env(:mllparty, :api_key, original_api_key)
    end)

    {:ok, %{conn: authd_conn}}
  end

  describe "GET #{@api_endpoint}" do
    test "with missing API key" do
      resp =
        build_conn()
        |> get(@api_endpoint)
        |> json_response(401)

      assert resp == %{"message" => "Missing API key"}
    end

    test "with invalid API key" do
      resp =
        build_conn()
        |> basic_auth("", "invalid")
        |> get(@api_endpoint)
        |> json_response(401)

      assert resp == %{"message" => "Invalid API key"}
    end

    test "when no active connections", %{conn: conn} do
      conn = get(conn, @api_endpoint)
      assert json_response(conn, 200)["connections"] == []
    end

    test "with active connections", %{conn: conn} do
      {:ok, _r6090} = MLLP.Receiver.start(port: 6090, dispatcher: MLLP.EchoDispatcher)

      MLLParty.ConnectionHub.start_client("127.0.0.1", 6090)
      MLLParty.ConnectionHub.start_client("127.0.0.1", 6091)

      conn = get(conn, @api_endpoint)

      assert json_response(conn, 200)["connections"] == [
               %{
                 "endpoint" => "127.0.0.1:6090",
                 "ip" => "127.0.0.1",
                 "port" => 6090,
                 "connected" => true,
                 "pending_reconnect" => false
               },
               %{
                 "endpoint" => "127.0.0.1:6091",
                 "ip" => "127.0.0.1",
                 "port" => 6091,
                 "connected" => false,
                 "pending_reconnect" => true
               }
             ]

      MLLP.Receiver.stop(6090)
    end
  end

  describe "POST #{@api_endpoint}" do
    test "with missing API key" do
      resp =
        build_conn()
        |> post(@api_endpoint)
        |> json_response(401)

      assert resp == %{"message" => "Missing API key"}
    end

    test "with invalid API key" do
      resp =
        build_conn()
        |> basic_auth("", "invalid")
        |> post(@api_endpoint)
        |> json_response(401)

      assert resp == %{"message" => "Invalid API key"}
    end

    test "with invalid endpoint", %{conn: conn} do
      conn = post(conn, @api_endpoint, %{endpoint: "127.0.0.1"})
      assert json_response(conn, 400)["message"] == "Invalid `endpoint` param: 127.0.0.1"
    end

    test "with valid endpoint", %{conn: conn} do
      conn = post(conn, @api_endpoint, %{endpoint: "127.0.0.1:6901"})
      assert json_response(conn, 200) == %{"started" => true}
    end
  end
end

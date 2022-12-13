defmodule MLLPartyWeb.Plug.APIKeyBasicAuth do
  @behaviour Plug
  import Plug.Conn

  alias MLLPartyWeb.FallbackController

  def init(opts), do: opts

  def call(conn, api_key: {module, func}) do
    call(conn, api_key: {module, func, []})
  end

  def call(conn, api_key: {module, func, args}) do
    # Dynmically get the api_key.
    api_key = apply(module, func, args)
    call(conn, api_key: api_key)
  end

  def call(conn, api_key: api_key) when is_binary(api_key) do
    case get_req_header(conn, "authorization") do
      ["Basic "] ->
        missing_api_key(conn)

      ["Basic " <> attempted_key] ->
        verify(conn, attempted_key, api_key: api_key)

      [] ->
        missing_api_key(conn)
    end
  end

  defp verify(conn, attempted_key, api_key: api_key) do
    # NB: We're prepending ":" to the key because Basic auth headers are like `username:password`
    #     and username should be blank (api_key should be used as basic auth password)
    case attempted_key == Base.encode64(":#{api_key}") do
      true -> conn
      false -> invalid_api_key(conn)
    end
  end

  defp missing_api_key(conn) do
    halt(FallbackController.call(conn, {:error, :missing_api_key}))
  end

  defp invalid_api_key(conn) do
    halt(FallbackController.call(conn, {:error, :invalid_api_key}))
  end
end

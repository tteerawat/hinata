defmodule HinataTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  alias Hinata.Schema

  defmodule Bear do
    @behaviour Schema

    defstruct [:name, :color]

    @impl true
    def from_response_body!(%{"object" => "bear", "name" => name, "color" => color}) do
      %__MODULE__{name: name, color: color}
    end
  end

  defmodule Error do
    @behaviour Schema

    defstruct [:message]

    @impl true
    def from_response_body!(%{"object" => "error", "message" => message}) do
      %__MODULE__{message: message}
    end
  end

  setup do
    {:ok, bypass: Bypass.open()}
  end

  defp get_bear(bypass, id, opts \\ []) do
    method = :get
    base_url = "http://localhost:#{bypass.port}"
    endpoint = "/bears/#{id}"

    Hinata.json_request(method, base_url, endpoint, opts)
  end

  defp list_bears(bypass, opts \\ []) do
    method = :get
    base_url = "http://localhost:#{bypass.port}"
    endpoint = "/bears"

    Hinata.json_request(method, base_url, endpoint, opts)
  end

  defp create_bear(bypass, opts) do
    method = :post
    base_url = "http://localhost:#{bypass.port}"
    endpoint = "/bears"

    Hinata.json_request(method, base_url, endpoint, opts)
  end

  describe "json_request/4" do
    test "returns schema when successfully requesting with :cast_successful_response_body_to option", %{bypass: bypass} do
      Bypass.expect_once(bypass, fn conn ->
        Plug.Conn.resp(conn, 200, ~s({"object": "bear", "color": "white", "name": "Ice Bear"}))
      end)

      result =
        create_bear(bypass,
          body_params: %{color: "white", name: "Ice Bear"},
          cast_successful_response_body_to: Bear,
          headers: [{"Authorization", "Bearer dummytoken"}]
        )

      assert result == {:ok, %Bear{name: "Ice Bear", color: "white"}}
    end

    test "returns map when successfully requesting without :cast_successful_response_body_to option", %{bypass: bypass} do
      Bypass.expect_once(bypass, fn conn ->
        Plug.Conn.resp(conn, 200, ~s({"object": "bear", "color": "white", "name": "Ice Bear"}))
      end)

      result = get_bear(bypass, "bear_123")

      assert result == {:ok, %{"color" => "white", "name" => "Ice Bear", "object" => "bear"}}
    end

    test "raises when requesting with invalid schema", %{bypass: bypass} do
      Bypass.expect_once(bypass, fn conn ->
        Plug.Conn.resp(conn, 200, ~s({"object": "bear", "colour": "white", "name": "Ice Bear"}))
      end)

      assert_raise Schema.Error, "invalid schema", fn ->
        assert capture_log(fn ->
                 get_bear(bypass, "bear_123", cast_successful_response_body_to: Bear)
               end) =~ "[error]"
      end
    end

    test "handles error response without :cast_error_response_body_to option", %{bypass: bypass} do
      Bypass.expect(bypass, fn conn ->
        Plug.Conn.resp(conn, 400, ~s({"object": "error", "message": "invalid params"}))
      end)

      assert capture_log(fn ->
               result = list_bears(bypass, query_params: %{limit: 100})

               assert result == {:error, %{"message" => "invalid params", "object" => "error"}}
             end) =~ "HTTP error response: 400"
    end

    test "handles error response with :cast_error_response_body_to option", %{bypass: bypass} do
      Bypass.expect(bypass, fn conn ->
        Plug.Conn.resp(conn, 400, ~s({"object": "error", "message": "invalid params"}))
      end)

      assert capture_log(fn ->
               result = list_bears(bypass, query_params: %{limit: 100}, cast_error_response_body_to: Error)

               assert result == {:error, %Error{message: "invalid params"}}
             end) =~ "HTTP error response: 400"
    end

    test "handles error response when response body is not a valid JSON", %{bypass: bypass} do
      Bypass.expect(bypass, fn conn ->
        Plug.Conn.resp(conn, 400, "bad request")
      end)

      assert capture_log(fn ->
               result = list_bears(bypass)

               assert result == {:error, %Hinata.ErrorResponse{status_code: 400, message: "bad request"}}
             end) =~ "HTTP error response: 400"
    end

    test "handles connection error", %{bypass: bypass} do
      Bypass.down(bypass)

      assert capture_log(fn ->
               result = list_bears(bypass)

               assert result == {:error, %Mint.TransportError{__exception__: true, reason: :econnrefused}}
             end) =~ "[error] connection refused"
    end

    test "requests with no scheme uri", %{bypass: bypass} do
      Bypass.expect_once(bypass, fn conn ->
        Plug.Conn.resp(conn, 200, ~s({"status": "ok"}))
      end)

      result = Hinata.json_request(:get, "localhost:#{bypass.port}", "/ping")

      assert result == {:ok, %{"status" => "ok"}}
    end
  end
end

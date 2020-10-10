defmodule Hinata.ErrorResponse do
  defexception [:status_code, :message]
end

defmodule Hinata.JSONResponseHandler do
  alias Finch.Response
  alias Hinata.{ErrorResponse, Schema}

  require Logger

  @spec handle_response({:ok, Response.t()} | {:error, Exception.t()}, Keyword.t()) ::
          {:ok, struct() | map()} | {:error, map()}
  def handle_response(response, opts \\ []) do
    case response do
      {:ok, %Response{status: status_code, body: body}} when status_code in 200..299 ->
        handle_successful_response(body, opts[:cast_successful_response_body_to])

      {:ok, %Response{status: status_code, body: body}} ->
        handle_error_response(body, status_code, opts[:cast_error_response_body_to])

      {:error, exception} ->
        handle_error_exception(exception)
    end
  end

  defp handle_successful_response(body, schema) do
    decoded_body = Jason.decode!(body)
    {:ok, maybe_cast_response_body(decoded_body, schema)}
  end

  defp handle_error_response(body, status_code, schema) do
    Logger.warn(fn -> "HTTP error response: #{status_code} - #{inspect(body)}" end)

    case Jason.decode(body) do
      {:ok, decoded_body} ->
        {:error, maybe_cast_response_body(decoded_body, schema)}

      {:error, _} ->
        {:error, %ErrorResponse{status_code: status_code, message: inspect(body)}}
    end
  end

  defp handle_error_exception(exception) do
    error_message = Exception.message(exception)
    Logger.error(error_message)
    {:error, exception}
  end

  defp maybe_cast_response_body(decoded_body, nil), do: decoded_body
  defp maybe_cast_response_body(decoded_body, schema), do: Schema.from_response_body!(decoded_body, to: schema)
end

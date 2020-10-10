defmodule Hinata do
  alias Hinata.{JSONRequestBuilder, JSONResponseHandler}

  @doc """
  Sends an HTTP request with JSON.

  ## Options

    * `:headers`
    * `:query_params`
    * `:body_params`
    * `:cast_successful_response_body_to`
    * `:cast_error_response_body_to`
  """
  @spec json_request(atom(), String.t(), String.t(), Keyword.t()) :: {:ok, struct() | map()} | {:error, map()}
  def json_request(method, base_url, endpoint \\ "", opts \\ []) do
    method
    |> JSONRequestBuilder.build_request(base_url, endpoint, opts)
    |> Finch.request(Hinata.Finch)
    |> JSONResponseHandler.handle_response(opts)
  end
end

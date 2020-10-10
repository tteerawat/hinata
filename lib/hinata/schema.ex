defmodule Hinata.Schema do
  @callback from_response_body!(map()) :: struct()

  defmodule Error do
    defexception [:message]
  end

  require Logger

  @spec from_response_body!(map(), Keyword.t()) :: struct()
  def from_response_body!(body, to: schema) do
    schema.from_response_body!(body)
  rescue
    exception ->
      Logger.error(inspect(exception))
      reraise Error, "invalid schema", __STACKTRACE__
  end
end

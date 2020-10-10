defmodule Hinata.JSONRequestBuilder do
  @json_headers [
    {"Accept", "application/json"},
    {"Content-Type", "application/json"}
  ]

  @spec build_request(atom() | String.t(), String.t(), String.t(), Keyword.t()) :: Finch.Request.t()
  def build_request(method, base_url, endpoint, opts \\ []) do
    url = build_url(base_url, endpoint, opts[:query_params])
    headers = build_headers(opts[:headers])
    body = build_json_body(opts[:body_params])

    Finch.build(method, url, headers, body)
  end

  defp build_url(base_url, endpoint, query_params) do
    base_url
    |> normalize_base_url()
    |> URI.merge(endpoint)
    |> set_query_params(query_params)
    |> URI.to_string()
  end

  defp normalize_base_url(base_url) do
    case URI.parse(base_url) do
      %URI{authority: nil} -> "http://" <> base_url
      _ -> base_url
    end
  end

  defp build_headers(nil), do: @json_headers
  defp build_headers(headers) when is_list(headers), do: @json_headers ++ headers

  defp build_json_body(nil), do: nil
  defp build_json_body(%{} = body_params), do: Jason.encode!(body_params)

  defp set_query_params(uri, nil), do: uri
  defp set_query_params(uri, %{} = query_params), do: %{uri | query: URI.encode_query(query_params)}
end

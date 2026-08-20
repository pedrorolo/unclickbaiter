defmodule Unclickbaiter.PreviewMetadata.HTTP.HttpcAdapter do
  @moduledoc """
  A minimal Req adapter backed by Erlang's `:httpc`.

  Used in tests so that ExVCR can record and replay the real HTTP requests made
  by `Unclickbaiter.PreviewMetadata.HTTP`. Req's default Finch adapter cannot be
  intercepted by ExVCR, while `:httpc` is one of ExVCR's supported clients.
  """

  def run(req) do
    if req.into != nil do
      raise ArgumentError, "HttpcAdapter does not support streaming responses"
    end

    url = URI.to_string(req.url)

    headers =
      req.headers
      |> Req.Fields.get_list()
      |> Enum.reject(fn {name, _value} ->
        String.downcase(name) == "accept-encoding"
      end)
      |> Enum.map(fn {name, value} ->
        {String.to_charlist(name), String.to_charlist(value)}
      end)

    request = {String.to_charlist(url), headers}

    case :httpc.request(:get, request, [timeout: timeout(req)],
           body_format: :binary
         ) do
      {:ok, {{_version, status, _reason}, headers, body}} ->
        response =
          Req.Response.new(
            status: status,
            headers:
              Enum.map(headers, fn {name, value} ->
                {to_string(name), to_string(value)}
              end),
            body: body
          )

        {req, response}

      {:error, {reason, _detail}} ->
        {req, %Req.TransportError{reason: reason}}

      {:error, reason} ->
        {req, %Req.TransportError{reason: reason}}
    end
  end

  defp timeout(req) do
    req.options[:receive_timeout] || 15_000
  end
end

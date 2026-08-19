defmodule Unclickbaiter.PreviewMetadata.HTTP do
  @moduledoc """
  Fetches the HTML of a given URL (following redirects) and extracts the
  OpenGraph/Twitter preview metadata from it.
  """

  alias Unclickbaiter.PreviewMetadata.HTTP.Parser

  @user_agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"

  @doc """
  Fetches `url` and returns `{:ok, %PreviewMetadata{}}` with the extracted
  metadata, or `{:error, reason}`.
  """
  def fetch(url) when is_binary(url) do
    case get(url) do
      {:ok, response, final_url} ->
        {:ok, Parser.parse(response.body, final_url)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def fetch(_url), do: {:error, :invalid_url}

  def get(url) do
    request(
      url: url,
      max_redirects: 5,
      receive_timeout: 10_000,
      headers: [{"user-agent", @user_agent}]
    )
  end

  defp request(options) do
    options =
      options
      |> Keyword.put(:retry, false)
      |> Keyword.merge(Application.get_env(:unclickbaiter, :req_options, []))

    case Req.Request.run_request(Req.new(options)) do
      {request, %{status: status} = response} when status in 200..299 ->
        if challenged?(response) do
          {:error, {:challenge, URI.to_string(request.url)}}
        else
          {:ok, response, URI.to_string(request.url)}
        end

      {_request, %{status: status}} ->
        {:error, {:http_error, status}}

      {_request, %{__exception__: true} = exception} ->
        {:error, exception}
    end
  end

  defp challenged?(%{headers: headers}) do
    case headers["x-amzn-waf-action"] do
      ["challenge" | _] -> true
      ["captcha" | _] -> true
      _ -> false
    end
  end
end

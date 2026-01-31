defmodule Slopcase.Showcase.ThumbnailFetcher do
  @moduledoc """
  Fetches thumbnail images for submissions by extracting Open Graph images
  from URLs or using GitHub's social preview for repository URLs.
  """

  @github_regex ~r{^https?://github\.com/([^/]+)/([^/]+)}
  @request_options [
    receive_timeout: 5_000,
    connect_options: [timeout: 5_000]
  ]

  @doc """
  Attempts to fetch a thumbnail URL from the given app_url or repo_url.

  Returns `{:ok, thumbnail_url}` if a thumbnail is found, or `:error` otherwise.
  Tries app_url first, then falls back to repo_url.
  """
  def fetch_thumbnail(app_url, repo_url) do
    with :error <- fetch_og_image(app_url),
         :error <- fetch_from_repo(repo_url) do
      :error
    end
  end

  defp fetch_og_image(nil), do: :error
  defp fetch_og_image(""), do: :error

  defp fetch_og_image(url) do
    case Req.get(url, @request_options) do
      {:ok, %{status: 200, body: body}} when is_binary(body) ->
        extract_og_image(body)

      _ ->
        :error
    end
  end

  defp fetch_from_repo(nil), do: :error
  defp fetch_from_repo(""), do: :error

  defp fetch_from_repo(repo_url) do
    case Regex.run(@github_regex, repo_url) do
      [_, owner, repo] ->
        # GitHub provides predictable OG image URLs
        repo = String.replace(repo, ~r/\.git$/, "")
        {:ok, "https://opengraph.githubassets.com/1/#{owner}/#{repo}"}

      nil ->
        # Not a GitHub URL, try to fetch OG image normally
        fetch_og_image(repo_url)
    end
  end

  defp extract_og_image(html) do
    with {:ok, document} <- Floki.parse_document(html),
         [meta | _] <- Floki.find(document, "meta[property='og:image']"),
         [content] when content != "" <- Floki.attribute(meta, "content") do
      {:ok, content}
    else
      _ -> :error
    end
  end
end

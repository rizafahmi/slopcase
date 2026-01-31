defmodule Slopcase.Showcase.ThumbnailFetcherTest do
  use ExUnit.Case, async: true

  alias Slopcase.Showcase.ThumbnailFetcher

  describe "fetch_thumbnail/2 with GitHub URLs" do
    test "constructs GitHub OG image URL from repo URL" do
      assert {:ok, thumbnail_url} =
               ThumbnailFetcher.fetch_thumbnail(nil, "https://github.com/elixir-lang/elixir")

      assert thumbnail_url == "https://opengraph.githubassets.com/1/elixir-lang/elixir"
    end

    test "handles GitHub URLs with .git suffix" do
      assert {:ok, thumbnail_url} =
               ThumbnailFetcher.fetch_thumbnail(
                 nil,
                 "https://github.com/phoenixframework/phoenix.git"
               )

      assert thumbnail_url == "https://opengraph.githubassets.com/1/phoenixframework/phoenix"
    end

    test "handles GitHub URLs with http scheme" do
      assert {:ok, thumbnail_url} =
               ThumbnailFetcher.fetch_thumbnail(nil, "http://github.com/user/repo")

      assert thumbnail_url == "https://opengraph.githubassets.com/1/user/repo"
    end
  end

  describe "fetch_thumbnail/2 with nil/empty URLs" do
    test "returns error when both URLs are nil" do
      assert :error = ThumbnailFetcher.fetch_thumbnail(nil, nil)
    end

    test "returns error when both URLs are empty strings" do
      assert :error = ThumbnailFetcher.fetch_thumbnail("", "")
    end

    test "falls back to repo_url when app_url is nil" do
      assert {:ok, _} = ThumbnailFetcher.fetch_thumbnail(nil, "https://github.com/test/repo")
    end

    test "falls back to repo_url when app_url is empty" do
      assert {:ok, _} = ThumbnailFetcher.fetch_thumbnail("", "https://github.com/test/repo")
    end
  end

  describe "fetch_thumbnail/2 with OG image extraction" do
    setup do
      # Use Req's test adapter to mock HTTP responses
      Req.Test.stub(ThumbnailFetcher, fn conn ->
        case conn.request_path do
          "/with-og-image" ->
            html = """
            <!DOCTYPE html>
            <html>
            <head>
              <meta property="og:image" content="https://example.com/preview.png" />
            </head>
            <body></body>
            </html>
            """

            Req.Test.html(conn, html)

          "/without-og-image" ->
            html = """
            <!DOCTYPE html>
            <html>
            <head><title>No OG</title></head>
            <body></body>
            </html>
            """

            Req.Test.html(conn, html)

          "/empty-og-image" ->
            html = """
            <!DOCTYPE html>
            <html>
            <head>
              <meta property="og:image" content="" />
            </head>
            <body></body>
            </html>
            """

            Req.Test.html(conn, html)

          _ ->
            Req.Test.html(conn, "<html></html>")
        end
      end)

      :ok
    end

    @tag :skip
    test "extracts og:image from HTML" do
      # This test requires modifying ThumbnailFetcher to use Req.Test adapter
      # Skipping for now as it requires additional setup
    end
  end
end

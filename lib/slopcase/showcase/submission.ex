defmodule Slopcase.Showcase.Submission do
  use Ecto.Schema

  import Ecto.Changeset

  @url_regex ~r/^https?:\/\//

  schema "submissions" do
    field :title, :string
    field :app_url, :string
    field :repo_url, :string
    field :model, :string
    field :tools, :string
    field :notes, :string
    field :thumbnail_url, :string
    field :slug, :string
    field :slop_count, :integer, virtual: true, default: 0
    field :not_slop_count, :integer, virtual: true, default: 0

    timestamps()
  end

  def changeset(submission, attrs) do
    submission
    |> cast(attrs, [:title, :app_url, :repo_url, :model, :tools, :notes, :thumbnail_url])
    |> generate_slug()
    |> normalize_urls([:app_url, :repo_url])
    |> validate_required([:title, :slug])
    |> validate_length(:title, min: 2, max: 120)
    |> validate_length(:model, max: 120)
    |> validate_length(:tools, max: 200)
    |> validate_length(:notes, max: 600)
    |> validate_format(:app_url, @url_regex, message: "must start with http:// or https://")
    |> validate_format(:repo_url, @url_regex, message: "must start with http:// or https://")
    |> unique_constraint(:slug)
  end

  defp generate_slug(changeset) do
    case get_change(changeset, :title) do
      nil ->
        changeset

      title ->
        slug = slugify(title)
        put_change(changeset, :slug, slug)
    end
  end

  defp slugify(str) do
    str
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\s-]/, "")
    |> String.replace(~r/\s+/, "-")
    |> String.slice(0, 80)
  end

  defp normalize_urls(changeset, fields) do
    Enum.reduce(fields, changeset, fn field, cs ->
      case get_change(cs, field) do
        nil -> cs
        url -> put_change(cs, field, normalize_url(url))
      end
    end)
  end

  defp normalize_url(nil), do: nil
  defp normalize_url(""), do: ""

  defp normalize_url(url) do
    if url =~ ~r/^https?:\/\// do
      url
    else
      "https://" <> url
    end
  end
end

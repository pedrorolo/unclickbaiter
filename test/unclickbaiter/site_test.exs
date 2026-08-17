defmodule Unclickbaiter.SiteTest do
  use Unclickbaiter.DataCase

  alias Unclickbaiter.Site

  describe "changeset/2" do
    @valid_attrs %{
      url: "https://example.com",
      title: "Example",
      description: "A factual description"
    }

    @invalid_attrs %{url: nil, title: nil, description: nil}

    test "is valid with all required fields" do
      changeset = Site.changeset(%Site{}, @valid_attrs)
      assert changeset.valid?
    end

    test "casts the given attributes" do
      changeset = Site.changeset(%Site{}, @valid_attrs)

      assert Ecto.Changeset.get_change(changeset, :url) == "https://example.com"
      assert Ecto.Changeset.get_change(changeset, :title) == "Example"

      assert Ecto.Changeset.get_change(changeset, :description) ==
               "A factual description"
    end

    test "is invalid when required fields are missing" do
      changeset = Site.changeset(%Site{}, @invalid_attrs)

      refute changeset.valid?
      assert %{url: ["can't be blank"]} = errors_on(changeset)
      assert %{title: ["can't be blank"]} = errors_on(changeset)
      assert %{description: ["can't be blank"]} = errors_on(changeset)
    end

    test "is invalid when url is missing" do
      changeset = Site.changeset(%Site{}, Map.delete(@valid_attrs, :url))
      refute changeset.valid?
      assert %{url: ["can't be blank"]} = errors_on(changeset)
    end

    test "ignores unknown attributes" do
      changeset =
        Site.changeset(%Site{}, Map.put(@valid_attrs, :unknown, "value"))

      assert changeset.valid?
    end
  end
end

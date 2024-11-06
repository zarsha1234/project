defmodule Todo.DifferentTest do
  use Todo.DataCase

  alias Todo.Different

  describe "gallerys" do
    alias Todo.Different.Gallery

    import Todo.DifferentFixtures

    @invalid_attrs %{name: nil, image: nil}

    test "list_gallerys/0 returns all gallerys" do
      gallery = gallery_fixture()
      assert Different.list_gallerys() == [gallery]
    end

    test "get_gallery!/1 returns the gallery with given id" do
      gallery = gallery_fixture()
      assert Different.get_gallery!(gallery.id) == gallery
    end

    test "create_gallery/1 with valid data creates a gallery" do
      valid_attrs = %{name: "some name", image: "some image"}

      assert {:ok, %Gallery{} = gallery} = Different.create_gallery(valid_attrs)
      assert gallery.name == "some name"
      assert gallery.image == "some image"
    end

    test "create_gallery/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Different.create_gallery(@invalid_attrs)
    end

    test "update_gallery/2 with valid data updates the gallery" do
      gallery = gallery_fixture()
      update_attrs = %{name: "some updated name", image: "some updated image"}

      assert {:ok, %Gallery{} = gallery} = Different.update_gallery(gallery, update_attrs)
      assert gallery.name == "some updated name"
      assert gallery.image == "some updated image"
    end

    test "update_gallery/2 with invalid data returns error changeset" do
      gallery = gallery_fixture()
      assert {:error, %Ecto.Changeset{}} = Different.update_gallery(gallery, @invalid_attrs)
      assert gallery == Different.get_gallery!(gallery.id)
    end

    test "delete_gallery/1 deletes the gallery" do
      gallery = gallery_fixture()
      assert {:ok, %Gallery{}} = Different.delete_gallery(gallery)
      assert_raise Ecto.NoResultsError, fn -> Different.get_gallery!(gallery.id) end
    end

    test "change_gallery/1 returns a gallery changeset" do
      gallery = gallery_fixture()
      assert %Ecto.Changeset{} = Different.change_gallery(gallery)
    end
  end
end

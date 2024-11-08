defmodule Todo.ChatTest do
  use Todo.DataCase

  alias Todo.Chat

  describe "messages" do
    alias Todo.Chat.Such

    import Todo.ChatFixtures

    @invalid_attrs %{name: nil, content: nil}

    test "list_messages/0 returns all messages" do
      such = such_fixture()
      assert Chat.list_messages() == [such]
    end

    test "get_such!/1 returns the such with given id" do
      such = such_fixture()
      assert Chat.get_such!(such.id) == such
    end

    test "create_such/1 with valid data creates a such" do
      valid_attrs = %{name: "some name", content: "some content"}

      assert {:ok, %Such{} = such} = Chat.create_such(valid_attrs)
      assert such.name == "some name"
      assert such.content == "some content"
    end

    test "create_such/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Chat.create_such(@invalid_attrs)
    end

    test "update_such/2 with valid data updates the such" do
      such = such_fixture()
      update_attrs = %{name: "some updated name", content: "some updated content"}

      assert {:ok, %Such{} = such} = Chat.update_such(such, update_attrs)
      assert such.name == "some updated name"
      assert such.content == "some updated content"
    end

    test "update_such/2 with invalid data returns error changeset" do
      such = such_fixture()
      assert {:error, %Ecto.Changeset{}} = Chat.update_such(such, @invalid_attrs)
      assert such == Chat.get_such!(such.id)
    end

    test "delete_such/1 deletes the such" do
      such = such_fixture()
      assert {:ok, %Such{}} = Chat.delete_such(such)
      assert_raise Ecto.NoResultsError, fn -> Chat.get_such!(such.id) end
    end

    test "change_such/1 returns a such changeset" do
      such = such_fixture()
      assert %Ecto.Changeset{} = Chat.change_such(such)
    end
  end
end

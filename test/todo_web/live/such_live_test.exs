defmodule TodoWeb.SuchLiveTest do
  use TodoWeb.ConnCase

  import Phoenix.LiveViewTest
  import Todo.ChatFixtures

  @create_attrs %{name: "some name", content: "some content"}
  @update_attrs %{name: "some updated name", content: "some updated content"}
  @invalid_attrs %{name: nil, content: nil}

  defp create_such(_) do
    such = such_fixture()
    %{such: such}
  end

  describe "Index" do
    setup [:create_such]

    test "lists all messages", %{conn: conn, such: such} do
      {:ok, _index_live, html} = live(conn, ~p"/messages")

      assert html =~ "Listing Messages"
      assert html =~ such.name
    end

    test "saves new ", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/messages")

      assert index_live |> element("a", "New") |> render_click() =~
               "New "

      assert_patch(index_live, ~p"/messages/new")

      assert index_live
             |> form("#such-form", such: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#such-form", such: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/messages")

      html = render(index_live)
      assert html =~ "Such created successfully"
      assert html =~ "some name"
    end

    test "updates such in listing", %{conn: conn, such: such} do
      {:ok, index_live, _html} = live(conn, ~p"/messages")

      assert index_live |> element("#messages-#{such.id} a", "Edit") |> render_click() =~
               "Edit Such"

      assert_patch(index_live, ~p"/messages/#{such}/edit")

      assert index_live
             |> form("#such-form", such: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#such-form", such: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/messages")

      html = render(index_live)
      assert html =~ "Such updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes such in listing", %{conn: conn, such: such} do
      {:ok, index_live, _html} = live(conn, ~p"/messages")

      assert index_live |> element("#messages-#{such.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#messages-#{such.id}")
    end
  end

  describe "Show" do
    setup [:create_such]

    test "displays such", %{conn: conn, such: such} do
      {:ok, _show_live, html} = live(conn, ~p"/messages/#{such}")

      assert html =~ "Show Such"
      assert html =~ such.name
    end

    test "updates such within modal", %{conn: conn, such: such} do
      {:ok, show_live, _html} = live(conn, ~p"/messages/#{such}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Such"

      assert_patch(show_live, ~p"/messages/#{such}/show/edit")

      assert show_live
             |> form("#such-form", such: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#such-form", such: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/messages/#{such}")

      html = render(show_live)
      assert html =~ "Such updated successfully"
      assert html =~ "some updated name"
    end
  end
end

defmodule TodoWeb.DayLiveTest do
  use TodoWeb.ConnCase

  import Phoenix.LiveViewTest
  import Todo.DaysFixtures

  @create_attrs %{names: "some names", weather: "some weather"}
  @update_attrs %{names: "some updated names", weather: "some updated weather"}
  @invalid_attrs %{names: nil, weather: nil}

  defp create_day(_) do
    day = day_fixture()
    %{day: day}
  end

  describe "Index" do
    setup [:create_day]

    test "lists all days", %{conn: conn, day: day} do
      {:ok, _index_live, html} = live(conn, ~p"/days")

      assert html =~ "Listing Days"
      assert html =~ day.names
    end

    test "saves new day", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/days")

      assert index_live |> element("a", "New Day") |> render_click() =~
               "New Day"

      assert_patch(index_live, ~p"/days/new")

      assert index_live
             |> form("#day-form", day: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#day-form", day: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/days")

      html = render(index_live)
      assert html =~ "Day created successfully"
      assert html =~ "some names"
    end

    test "updates day in listing", %{conn: conn, day: day} do
      {:ok, index_live, _html} = live(conn, ~p"/days")

      assert index_live |> element("#days-#{day.id} a", "Edit") |> render_click() =~
               "Edit Day"

      assert_patch(index_live, ~p"/days/#{day}/edit")

      assert index_live
             |> form("#day-form", day: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#day-form", day: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/days")

      html = render(index_live)
      assert html =~ "Day updated successfully"
      assert html =~ "some updated names"
    end

    test "deletes day in listing", %{conn: conn, day: day} do
      {:ok, index_live, _html} = live(conn, ~p"/days")

      assert index_live |> element("#days-#{day.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#days-#{day.id}")
    end
  end

  describe "Show" do
    setup [:create_day]

    test "displays day", %{conn: conn, day: day} do
      {:ok, _show_live, html} = live(conn, ~p"/days/#{day}")

      assert html =~ "Show Day"
      assert html =~ day.names
    end

    test "updates day within modal", %{conn: conn, day: day} do
      {:ok, show_live, _html} = live(conn, ~p"/days/#{day}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Day"

      assert_patch(show_live, ~p"/days/#{day}/show/edit")

      assert show_live
             |> form("#day-form", day: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#day-form", day: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/days/#{day}")

      html = render(show_live)
      assert html =~ "Day updated successfully"
      assert html =~ "some updated names"
    end
  end
end

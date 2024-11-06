defmodule TodoWeb.GalleryLiveTest do
  use TodoWeb.ConnCase

  import Phoenix.LiveViewTest
  import Todo.DifferentFixtures

  @create_attrs %{name: "some name", image: "some image"}
  @update_attrs %{name: "some updated name", image: "some updated image"}
  @invalid_attrs %{name: nil, image: nil}

  defp create_gallery(_) do
    gallery = gallery_fixture()
    %{gallery: gallery}
  end

  describe "Index" do
    setup [:create_gallery]

    test "lists all gallerys", %{conn: conn, gallery: gallery} do
      {:ok, _index_live, html} = live(conn, ~p"/gallerys")

      assert html =~ "Listing Gallerys"
      assert html =~ gallery.name
    end

    test "saves new gallery", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/gallerys")

      assert index_live |> element("a", "New Gallery") |> render_click() =~
               "New Gallery"

      assert_patch(index_live, ~p"/gallerys/new")

      assert index_live
             |> form("#gallery-form", gallery: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#gallery-form", gallery: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/gallerys")

      html = render(index_live)
      assert html =~ "Gallery created successfully"
      assert html =~ "some name"
    end

    test "updates gallery in listing", %{conn: conn, gallery: gallery} do
      {:ok, index_live, _html} = live(conn, ~p"/gallerys")

      assert index_live |> element("#gallerys-#{gallery.id} a", "Edit") |> render_click() =~
               "Edit Gallery"

      assert_patch(index_live, ~p"/gallerys/#{gallery}/edit")

      assert index_live
             |> form("#gallery-form", gallery: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#gallery-form", gallery: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/gallerys")

      html = render(index_live)
      assert html =~ "Gallery updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes gallery in listing", %{conn: conn, gallery: gallery} do
      {:ok, index_live, _html} = live(conn, ~p"/gallerys")

      assert index_live |> element("#gallerys-#{gallery.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#gallerys-#{gallery.id}")
    end
  end

  describe "Show" do
    setup [:create_gallery]

    test "displays gallery", %{conn: conn, gallery: gallery} do
      {:ok, _show_live, html} = live(conn, ~p"/gallerys/#{gallery}")

      assert html =~ "Show Gallery"
      assert html =~ gallery.name
    end

    test "updates gallery within modal", %{conn: conn, gallery: gallery} do
      {:ok, show_live, _html} = live(conn, ~p"/gallerys/#{gallery}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Gallery"

      assert_patch(show_live, ~p"/gallerys/#{gallery}/show/edit")

      assert show_live
             |> form("#gallery-form", gallery: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#gallery-form", gallery: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/gallerys/#{gallery}")

      html = render(show_live)
      assert html =~ "Gallery updated successfully"
      assert html =~ "some updated name"
    end
  end
end

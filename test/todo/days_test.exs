defmodule Todo.DaysTest do
  use Todo.DataCase

  alias Todo.Days

  describe "days" do
    alias Todo.Days.Day

    import Todo.DaysFixtures

    @invalid_attrs %{names: nil, weather: nil}

    test "list_days/0 returns all days" do
      day = day_fixture()
      assert Days.list_days() == [day]
    end

    test "get_day!/1 returns the day with given id" do
      day = day_fixture()
      assert Days.get_day!(day.id) == day
    end

    test "create_day/1 with valid data creates a day" do
      valid_attrs = %{names: "some names", weather: "some weather"}

      assert {:ok, %Day{} = day} = Days.create_day(valid_attrs)
      assert day.names == "some names"
      assert day.weather == "some weather"
    end

    test "create_day/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Days.create_day(@invalid_attrs)
    end

    test "update_day/2 with valid data updates the day" do
      day = day_fixture()
      update_attrs = %{names: "some updated names", weather: "some updated weather"}

      assert {:ok, %Day{} = day} = Days.update_day(day, update_attrs)
      assert day.names == "some updated names"
      assert day.weather == "some updated weather"
    end

    test "update_day/2 with invalid data returns error changeset" do
      day = day_fixture()
      assert {:error, %Ecto.Changeset{}} = Days.update_day(day, @invalid_attrs)
      assert day == Days.get_day!(day.id)
    end

    test "delete_day/1 deletes the day" do
      day = day_fixture()
      assert {:ok, %Day{}} = Days.delete_day(day)
      assert_raise Ecto.NoResultsError, fn -> Days.get_day!(day.id) end
    end

    test "change_day/1 returns a day changeset" do
      day = day_fixture()
      assert %Ecto.Changeset{} = Days.change_day(day)
    end
  end
end

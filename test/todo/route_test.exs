defmodule Todo.RouteTest do
  use Todo.DataCase

  alias Todo.Route

  import Todo.RouteFixtures
  alias Todo.Route.{Path, PathToken}

  describe "get_path_by_email/1" do
    test "does not return the path if the email does not exist" do
      refute Route.get_path_by_email("unknown@example.com")
    end

    test "returns the path if the email exists" do
      %{id: id} = path = path_fixture()
      assert %Path{id: ^id} = Route.get_path_by_email(path.email)
    end
  end

  describe "get_path_by_email_and_password/2" do
    test "does not return the path if the email does not exist" do
      refute Route.get_path_by_email_and_password("unknown@example.com", "hello world!")
    end

    test "does not return the path if the password is not valid" do
      path = path_fixture()
      refute Route.get_path_by_email_and_password(path.email, "invalid")
    end

    test "returns the path if the email and password are valid" do
      %{id: id} = path = path_fixture()

      assert %Path{id: ^id} =
               Route.get_path_by_email_and_password(path.email, valid_path_password())
    end
  end

  describe "get_path!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        Route.get_path!(-1)
      end
    end

    test "returns the path with the given id" do
      %{id: id} = path = path_fixture()
      assert %Path{id: ^id} = Route.get_path!(path.id)
    end
  end

  describe "register_path/1" do
    test "requires email and password to be set" do
      {:error, changeset} = Route.register_path(%{})

      assert %{
               password: ["can't be blank"],
               email: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "validates email and password when given" do
      {:error, changeset} = Route.register_path(%{email: "not valid", password: "not valid"})

      assert %{
               email: ["must have the @ sign and no spaces"],
               password: ["should be at least 12 character(s)"]
             } = errors_on(changeset)
    end

    test "validates maximum values for email and password for security" do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Route.register_path(%{email: too_long, password: too_long})
      assert "should be at most 160 character(s)" in errors_on(changeset).email
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates email uniqueness" do
      %{email: email} = path_fixture()
      {:error, changeset} = Route.register_path(%{email: email})
      assert "has already been taken" in errors_on(changeset).email

      # Now try with the upper cased email too, to check that email case is ignored.
      {:error, changeset} = Route.register_path(%{email: String.upcase(email)})
      assert "has already been taken" in errors_on(changeset).email
    end

    test "registers path with a hashed password" do
      email = unique_path_email()
      {:ok, path} = Route.register_path(valid_path_attributes(email: email))
      assert path.email == email
      assert is_binary(path.hashed_password)
      assert is_nil(path.confirmed_at)
      assert is_nil(path.password)
    end
  end

  describe "change_path_registration/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{} = changeset = Route.change_path_registration(%Path{})
      assert changeset.required == [:password, :email]
    end

    test "allows fields to be set" do
      email = unique_path_email()
      password = valid_path_password()

      changeset =
        Route.change_path_registration(
          %Path{},
          valid_path_attributes(email: email, password: password)
        )

      assert changeset.valid?
      assert get_change(changeset, :email) == email
      assert get_change(changeset, :password) == password
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "change_path_email/2" do
    test "returns a path changeset" do
      assert %Ecto.Changeset{} = changeset = Route.change_path_email(%Path{})
      assert changeset.required == [:email]
    end
  end

  describe "apply_path_email/3" do
    setup do
      %{path: path_fixture()}
    end

    test "requires email to change", %{path: path} do
      {:error, changeset} = Route.apply_path_email(path, valid_path_password(), %{})
      assert %{email: ["did not change"]} = errors_on(changeset)
    end

    test "validates email", %{path: path} do
      {:error, changeset} =
        Route.apply_path_email(path, valid_path_password(), %{email: "not valid"})

      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "validates maximum value for email for security", %{path: path} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Route.apply_path_email(path, valid_path_password(), %{email: too_long})

      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "validates email uniqueness", %{path: path} do
      %{email: email} = path_fixture()
      password = valid_path_password()

      {:error, changeset} = Route.apply_path_email(path, password, %{email: email})

      assert "has already been taken" in errors_on(changeset).email
    end

    test "validates current password", %{path: path} do
      {:error, changeset} =
        Route.apply_path_email(path, "invalid", %{email: unique_path_email()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "applies the email without persisting it", %{path: path} do
      email = unique_path_email()
      {:ok, path} = Route.apply_path_email(path, valid_path_password(), %{email: email})
      assert path.email == email
      assert Route.get_path!(path.id).email != email
    end
  end

  describe "deliver_path_update_email_instructions/3" do
    setup do
      %{path: path_fixture()}
    end

    test "sends token through notification", %{path: path} do
      token =
        extract_path_token(fn url ->
          Route.deliver_path_update_email_instructions(path, "current@example.com", url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert path_token = Repo.get_by(PathToken, token: :crypto.hash(:sha256, token))
      assert path_token.path_id == path.id
      assert path_token.sent_to == path.email
      assert path_token.context == "change:current@example.com"
    end
  end

  describe "update_path_email/2" do
    setup do
      path = path_fixture()
      email = unique_path_email()

      token =
        extract_path_token(fn url ->
          Route.deliver_path_update_email_instructions(%{path | email: email}, path.email, url)
        end)

      %{path: path, token: token, email: email}
    end

    test "updates the email with a valid token", %{path: path, token: token, email: email} do
      assert Route.update_path_email(path, token) == :ok
      changed_path = Repo.get!(Path, path.id)
      assert changed_path.email != path.email
      assert changed_path.email == email
      assert changed_path.confirmed_at
      assert changed_path.confirmed_at != path.confirmed_at
      refute Repo.get_by(PathToken, path_id: path.id)
    end

    test "does not update email with invalid token", %{path: path} do
      assert Route.update_path_email(path, "oops") == :error
      assert Repo.get!(Path, path.id).email == path.email
      assert Repo.get_by(PathToken, path_id: path.id)
    end

    test "does not update email if path email changed", %{path: path, token: token} do
      assert Route.update_path_email(%{path | email: "current@example.com"}, token) == :error
      assert Repo.get!(Path, path.id).email == path.email
      assert Repo.get_by(PathToken, path_id: path.id)
    end

    test "does not update email if token expired", %{path: path, token: token} do
      {1, nil} = Repo.update_all(PathToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Route.update_path_email(path, token) == :error
      assert Repo.get!(Path, path.id).email == path.email
      assert Repo.get_by(PathToken, path_id: path.id)
    end
  end

  describe "change_path_password/2" do
    test "returns a path changeset" do
      assert %Ecto.Changeset{} = changeset = Route.change_path_password(%Path{})
      assert changeset.required == [:password]
    end

    test "allows fields to be set" do
      changeset =
        Route.change_path_password(%Path{}, %{
          "password" => "new valid password"
        })

      assert changeset.valid?
      assert get_change(changeset, :password) == "new valid password"
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "update_path_password/3" do
    setup do
      %{path: path_fixture()}
    end

    test "validates password", %{path: path} do
      {:error, changeset} =
        Route.update_path_password(path, valid_path_password(), %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{path: path} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Route.update_path_password(path, valid_path_password(), %{password: too_long})

      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates current password", %{path: path} do
      {:error, changeset} =
        Route.update_path_password(path, "invalid", %{password: valid_path_password()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "updates the password", %{path: path} do
      {:ok, path} =
        Route.update_path_password(path, valid_path_password(), %{
          password: "new valid password"
        })

      assert is_nil(path.password)
      assert Route.get_path_by_email_and_password(path.email, "new valid password")
    end

    test "deletes all tokens for the given path", %{path: path} do
      _ = Route.generate_path_session_token(path)

      {:ok, _} =
        Route.update_path_password(path, valid_path_password(), %{
          password: "new valid password"
        })

      refute Repo.get_by(PathToken, path_id: path.id)
    end
  end

  describe "generate_path_session_token/1" do
    setup do
      %{path: path_fixture()}
    end

    test "generates a token", %{path: path} do
      token = Route.generate_path_session_token(path)
      assert path_token = Repo.get_by(PathToken, token: token)
      assert path_token.context == "session"

      # Creating the same token for another path should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%PathToken{
          token: path_token.token,
          path_id: path_fixture().id,
          context: "session"
        })
      end
    end
  end

  describe "get_path_by_session_token/1" do
    setup do
      path = path_fixture()
      token = Route.generate_path_session_token(path)
      %{path: path, token: token}
    end

    test "returns path by token", %{path: path, token: token} do
      assert session_path = Route.get_path_by_session_token(token)
      assert session_path.id == path.id
    end

    test "does not return path for invalid token" do
      refute Route.get_path_by_session_token("oops")
    end

    test "does not return path for expired token", %{token: token} do
      {1, nil} = Repo.update_all(PathToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Route.get_path_by_session_token(token)
    end
  end

  describe "delete_path_session_token/1" do
    test "deletes the token" do
      path = path_fixture()
      token = Route.generate_path_session_token(path)
      assert Route.delete_path_session_token(token) == :ok
      refute Route.get_path_by_session_token(token)
    end
  end

  describe "deliver_path_confirmation_instructions/2" do
    setup do
      %{path: path_fixture()}
    end

    test "sends token through notification", %{path: path} do
      token =
        extract_path_token(fn url ->
          Route.deliver_path_confirmation_instructions(path, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert path_token = Repo.get_by(PathToken, token: :crypto.hash(:sha256, token))
      assert path_token.path_id == path.id
      assert path_token.sent_to == path.email
      assert path_token.context == "confirm"
    end
  end

  describe "confirm_path/1" do
    setup do
      path = path_fixture()

      token =
        extract_path_token(fn url ->
          Route.deliver_path_confirmation_instructions(path, url)
        end)

      %{path: path, token: token}
    end

    test "confirms the email with a valid token", %{path: path, token: token} do
      assert {:ok, confirmed_path} = Route.confirm_path(token)
      assert confirmed_path.confirmed_at
      assert confirmed_path.confirmed_at != path.confirmed_at
      assert Repo.get!(Path, path.id).confirmed_at
      refute Repo.get_by(PathToken, path_id: path.id)
    end

    test "does not confirm with invalid token", %{path: path} do
      assert Route.confirm_path("oops") == :error
      refute Repo.get!(Path, path.id).confirmed_at
      assert Repo.get_by(PathToken, path_id: path.id)
    end

    test "does not confirm email if token expired", %{path: path, token: token} do
      {1, nil} = Repo.update_all(PathToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Route.confirm_path(token) == :error
      refute Repo.get!(Path, path.id).confirmed_at
      assert Repo.get_by(PathToken, path_id: path.id)
    end
  end

  describe "deliver_path_reset_password_instructions/2" do
    setup do
      %{path: path_fixture()}
    end

    test "sends token through notification", %{path: path} do
      token =
        extract_path_token(fn url ->
          Route.deliver_path_reset_password_instructions(path, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert path_token = Repo.get_by(PathToken, token: :crypto.hash(:sha256, token))
      assert path_token.path_id == path.id
      assert path_token.sent_to == path.email
      assert path_token.context == "reset_password"
    end
  end

  describe "get_path_by_reset_password_token/1" do
    setup do
      path = path_fixture()

      token =
        extract_path_token(fn url ->
          Route.deliver_path_reset_password_instructions(path, url)
        end)

      %{path: path, token: token}
    end

    test "returns the path with valid token", %{path: %{id: id}, token: token} do
      assert %Path{id: ^id} = Route.get_path_by_reset_password_token(token)
      assert Repo.get_by(PathToken, path_id: id)
    end

    test "does not return the path with invalid token", %{path: path} do
      refute Route.get_path_by_reset_password_token("oops")
      assert Repo.get_by(PathToken, path_id: path.id)
    end

    test "does not return the path if token expired", %{path: path, token: token} do
      {1, nil} = Repo.update_all(PathToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Route.get_path_by_reset_password_token(token)
      assert Repo.get_by(PathToken, path_id: path.id)
    end
  end

  describe "reset_path_password/2" do
    setup do
      %{path: path_fixture()}
    end

    test "validates password", %{path: path} do
      {:error, changeset} =
        Route.reset_path_password(path, %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{path: path} do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Route.reset_path_password(path, %{password: too_long})
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "updates the password", %{path: path} do
      {:ok, updated_path} = Route.reset_path_password(path, %{password: "new valid password"})
      assert is_nil(updated_path.password)
      assert Route.get_path_by_email_and_password(path.email, "new valid password")
    end

    test "deletes all tokens for the given path", %{path: path} do
      _ = Route.generate_path_session_token(path)
      {:ok, _} = Route.reset_path_password(path, %{password: "new valid password"})
      refute Repo.get_by(PathToken, path_id: path.id)
    end
  end

  describe "inspect/2 for the Path module" do
    test "does not include password" do
      refute inspect(%Path{password: "123456"}) =~ "password: \"123456\""
    end
  end
end

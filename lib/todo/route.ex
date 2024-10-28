defmodule Todo.Route do
  @moduledoc """
  The Route context.
  """

  import Ecto.Query, warn: false
  alias Todo.Repo

  alias Todo.Route.{Path, PathToken, PathNotifier}

  ## Database getters

  @doc """
  Gets a path by email.

  ## Examples

      iex> get_path_by_email("foo@example.com")
      %Path{}

      iex> get_path_by_email("unknown@example.com")
      nil

  """
  def get_path_by_email(email) when is_binary(email) do
    Repo.get_by(Path, email: email)
  end

  @doc """
  Gets a path by email and password.

  ## Examples

      iex> get_path_by_email_and_password("foo@example.com", "correct_password")
      %Path{}

      iex> get_path_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_path_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    path = Repo.get_by(Path, email: email)
    if Path.valid_password?(path, password), do: path
  end

  @doc """
  Gets a single path.

  Raises `Ecto.NoResultsError` if the Path does not exist.

  ## Examples

      iex> get_path!(123)
      %Path{}

      iex> get_path!(456)
      ** (Ecto.NoResultsError)

  """
  def get_path!(id), do: Repo.get!(Path, id)

  ## Path registration

  @doc """
  Registers a path.

  ## Examples

      iex> register_path(%{field: value})
      {:ok, %Path{}}

      iex> register_path(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_path(attrs) do
    %Path{}
    |> Path.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking path changes.

  ## Examples

      iex> change_path_registration(path)
      %Ecto.Changeset{data: %Path{}}

  """
  def change_path_registration(%Path{} = path, attrs \\ %{}) do
    Path.registration_changeset(path, attrs, hash_password: false, validate_email: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the path email.

  ## Examples

      iex> change_path_email(path)
      %Ecto.Changeset{data: %Path{}}

  """
  def change_path_email(path, attrs \\ %{}) do
    Path.email_changeset(path, attrs, validate_email: false)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_path_email(path, "valid password", %{email: ...})
      {:ok, %Path{}}

      iex> apply_path_email(path, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  def apply_path_email(path, password, attrs) do
    path
    |> Path.email_changeset(attrs)
    |> Path.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the path email using the given token.

  If the token matches, the path email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_path_email(path, token) do
    context = "change:#{path.email}"

    with {:ok, query} <- PathToken.verify_change_email_token_query(token, context),
         %PathToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(path_email_multi(path, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp path_email_multi(path, email, context) do
    changeset =
      path
      |> Path.email_changeset(%{email: email})
      |> Path.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:path, changeset)
    |> Ecto.Multi.delete_all(:tokens, PathToken.by_path_and_contexts_query(path, [context]))
  end

  @doc ~S"""
  Delivers the update email instructions to the given path.

  ## Examples

      iex> deliver_path_update_email_instructions(path, current_email, &url(~p"/path/settings/confirm_email/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_path_update_email_instructions(%Path{} = path, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, path_token} = PathToken.build_email_token(path, "change:#{current_email}")

    Repo.insert!(path_token)
    PathNotifier.deliver_update_email_instructions(path, update_email_url_fun.(encoded_token))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the path password.

  ## Examples

      iex> change_path_password(path)
      %Ecto.Changeset{data: %Path{}}

  """
  def change_path_password(path, attrs \\ %{}) do
    Path.password_changeset(path, attrs, hash_password: false)
  end
  def change_path_time(path, attrs \\ %{}) do
    Path.time_changeset(path, attrs)
  end
  @doc """
  Updates the path password.

  ## Examples

      iex> update_path_password(path, "valid password", %{password: ...})
      {:ok, %Path{}}

      iex> update_path_password(path, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_path_password(path, password, attrs) do
    changeset =
      path
      |> Path.password_changeset(attrs)
      |> Path.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:path, changeset)
    |> Ecto.Multi.delete_all(:tokens, PathToken.by_path_and_contexts_query(path, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{path: path}} -> {:ok, path}
      {:error, :path, changeset, _} -> {:error, changeset}
    end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_path_session_token(path) do
    {token, path_token} = PathToken.build_session_token(path)
    Repo.insert!(path_token)
    token
  end

  @doc """
  Gets the path with the given signed token.
  """
  def get_path_by_session_token(token) do
    {:ok, query} = PathToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_path_session_token(token) do
    Repo.delete_all(PathToken.by_token_and_context_query(token, "session"))
    :ok
  end

  ## Confirmation

  @doc ~S"""
  Delivers the confirmation email instructions to the given path.

  ## Examples

      iex> deliver_path_confirmation_instructions(path, &url(~p"/path/confirm/#{&1}"))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_path_confirmation_instructions(confirmed_path, &url(~p"/path/confirm/#{&1}"))
      {:error, :already_confirmed}

  """
  def deliver_path_confirmation_instructions(%Path{} = path, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if path.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, path_token} = PathToken.build_email_token(path, "confirm")
      Repo.insert!(path_token)
      PathNotifier.deliver_confirmation_instructions(path, confirmation_url_fun.(encoded_token))
    end
  end

  @doc """
  Confirms a path by the given token.

  If the token matches, the path account is marked as confirmed
  and the token is deleted.
  """
  def confirm_path(token) do
    with {:ok, query} <- PathToken.verify_email_token_query(token, "confirm"),
         %Path{} = path <- Repo.one(query),
         {:ok, %{path: path}} <- Repo.transaction(confirm_path_multi(path)) do
      {:ok, path}
    else
      _ -> :error
    end
  end

  defp confirm_path_multi(path) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:path, Path.confirm_changeset(path))
    |> Ecto.Multi.delete_all(:tokens, PathToken.by_path_and_contexts_query(path, ["confirm"]))
  end

  ## Reset password

  @doc ~S"""
  Delivers the reset password email to the given path.

  ## Examples

      iex> deliver_path_reset_password_instructions(path, &url(~p"/path/reset_password/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_path_reset_password_instructions(%Path{} = path, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, path_token} = PathToken.build_email_token(path, "reset_password")
    Repo.insert!(path_token)
    PathNotifier.deliver_reset_password_instructions(path, reset_password_url_fun.(encoded_token))
  end

  @doc """
  Gets the path by reset password token.

  ## Examples

      iex> get_path_by_reset_password_token("validtoken")
      %Path{}

      iex> get_path_by_reset_password_token("invalidtoken")
      nil

  """
  def get_path_by_reset_password_token(token) do
    with {:ok, query} <- PathToken.verify_email_token_query(token, "reset_password"),
         %Path{} = path <- Repo.one(query) do
      path
    else
      _ -> nil
    end
  end

  @doc """
  Resets the path password.

  ## Examples

      iex> reset_path_password(path, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %Path{}}

      iex> reset_path_password(path, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_path_password(path, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:path, Path.password_changeset(path, attrs))
    |> Ecto.Multi.delete_all(:tokens, PathToken.by_path_and_contexts_query(path, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{path: path}} -> {:ok, path}
      {:error, :path, changeset, _} -> {:error, changeset}
    end
  end

end

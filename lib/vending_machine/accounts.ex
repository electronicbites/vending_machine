defmodule VendingMachine.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias VendingMachine.Repo

  alias VendingMachine.Accounts.{User, UserToken}

  ## Database getters & more

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(User)
  end

  @doc """
  Gets a user by username.

  ## Examples

      iex> get_user_by_username("foo-bar")
      %User{}

      iex> get_user_by_username("bad-username")
      nil

  """
  def get_user_by_username(username) when is_binary(username) do
    Repo.get_by(User, username: username)
  end

  @doc """
  Gets a user by username and password.

  ## Examples

      iex> get_user_by_username_and_password("foo-bar", "correct_password")
      %User{}

      iex> get_user_by_username_and_password("foo-bar", "invalid_password")
      nil

  """
  def get_user_by_username_and_password(username, password)
      when is_binary(username) and is_binary(password) do
    user = Repo.get_by(User, username: username)
    if User.valid_password?(user, password), do: user
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  ## User registration

  @doc """
  Registers a user.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user_registration(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs, hash_password: false, validate_username: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user username.

  ## Examples

      iex> change_user_username(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_username(user, attrs \\ %{}) do
    User.username_changeset(user, attrs, validate_username: false)
  end

  @doc """
  Emulates that the username will change without actually changing
  it in the database.

  ## Examples

      iex> apply_user_username(user, "valid password", %{username: ...})
      {:ok, %User{}}

      iex> apply_user_username(user, "invalid password", %{username: ...})
      {:error, %Ecto.Changeset{}}

  """
  def apply_user_username(user, password, attrs) do
    user
    |> User.username_changeset(attrs)
    |> User.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the user username using the given token.

  If the token matches, the user username is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_user_username(user, token) do
    context = "change:#{user.username}"

    with {:ok, query} <- UserToken.verify_change_username_token_query(token, context),
         %UserToken{sent_to: username} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(user_username_multi(user, username, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp user_username_multi(user, username, context) do
    changeset =
      user
      |> User.username_changeset(%{username: username})
      |> User.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, [context]))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.

  ## Examples

      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_password(user, attrs \\ %{}) do
    User.password_changeset(user, attrs, hash_password: false)
  end

  @doc """
  Updates the user password.

  ## Examples

      iex> update_user_password(user, "valid password", %{password: ...})
      {:ok, %User{}}

      iex> update_user_password(user, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_password(user, password, attrs) do
    changeset =
      user
      |> User.password_changeset(attrs)
      |> User.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  def deposit(%User{role: "buyer"} = user, amount)
    when amount == 5 or amount == 10 or amount == 20 or amount == 50 or amount == 100 do
    user
    |> User.deposit_changeset(%{deposit: user.deposit + amount})
    |> Repo.update()
  end

  def deposit(_, _), do: {:error}

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_user_session_token(token) do
    Repo.delete_all(UserToken.by_token_and_context_query(token, "session"))
    :ok
  end

  @doc """
  Confirms a user by the given token.

  If the token matches, the user account is marked as confirmed
  and the token is deleted.
  """
  def confirm_user(token) do
    with {:ok, query} <- UserToken.verify_username_token_query(token, "confirm"),
         %User{} = user <- Repo.one(query),
         {:ok, %{user: user}} <- Repo.transaction(confirm_user_multi(user)) do
      {:ok, user}
    else
      _ -> :error
    end
  end

  defp confirm_user_multi(user) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.confirm_changeset(user))
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, ["confirm"]))
  end

  ## Reset password

  @doc """
  Gets the user by reset password token.

  ## Examples

      iex> get_user_by_reset_password_token("validtoken")
      %User{}

      iex> get_user_by_reset_password_token("invalidtoken")
      nil

  """
  def get_user_by_reset_password_token(token) do
    with {:ok, query} <- UserToken.verify_username_token_query(token, "reset_password"),
         %User{} = user <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  @doc """
  Resets the user password.

  ## Examples

      iex> reset_user_password(user, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %User{}}

      iex> reset_user_password(user, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_user_password(user, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.password_changeset(user, attrs))
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  ## API

  @doc """
  Generates an api token.
  """
  def generate_user_api_token(user) do
    existing_token = get_api_token_by_user(user)

    if is_nil(existing_token) do
      {token, user_token} = UserToken.build_api_token(user)
      Repo.insert!(user_token)
      token
    else
      existing_token
    end
  end

  @doc """
  Gets the api token for the given user.
  """
  def get_api_token_by_user(user) do
    with query <- UserToken.by_user_and_contexts_query(user, ["api"]),
         %UserToken{token: token} <- Repo.one(query) do
      token
    else
      _ -> nil
    end
  end

  @doc """
  Refresh api token.
  """
  def refresh_user_api_token(user) do
    Repo.delete_all(UserToken.by_user_and_contexts_query(user, ["api"]))
    generate_user_api_token(user)
  end

  @doc """
  Gets the user with the given api token.
  """
  def get_user_by_api_token(token) do
    {:ok, query} = UserToken.verify_api_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the api token.
  """
  def delete_user_api_token(token) do
    Repo.delete_all(UserToken.by_token_and_context_query(token, "api"))
    :ok
  end
end

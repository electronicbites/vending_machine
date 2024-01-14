defmodule VendingMachine.AccountsTest do
  use VendingMachine.DataCase

  alias VendingMachine.Accounts

  import VendingMachine.AccountsFixtures
  alias VendingMachine.Accounts.{User, UserToken}

  describe "list_users/0" do
    test "returns all users" do
      _user = user_fixture()
      assert [%User{} | _] = Accounts.list_users()
    end
  end

  describe "get_user_by_username/1" do
    test "does not return the user if the username does not exist" do
      refute Accounts.get_user_by_username("unknown@example.com")
    end

    test "returns the user if the username exists" do
      %{id: id} = user = user_fixture()
      assert %User{id: ^id} = Accounts.get_user_by_username(user.username)
    end
  end

  describe "get_user_by_username_and_password/2" do
    test "does not return the user if the username does not exist" do
      refute Accounts.get_user_by_username_and_password("unknown@example.com", "hello world!")
    end

    test "does not return the user if the password is not valid" do
      user = user_fixture()
      refute Accounts.get_user_by_username_and_password(user.username, "invalid")
    end

    test "returns the user if the username and password are valid" do
      %{id: id} = user = user_fixture()

      assert %User{id: ^id} =
               Accounts.get_user_by_username_and_password(user.username, valid_user_password())
    end
  end

  describe "get_user!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_user!(-1)
      end
    end

    test "returns the user with the given id" do
      %{id: id} = user = user_fixture()
      assert %User{id: ^id} = Accounts.get_user!(user.id)
    end
  end

  describe "register_user/1" do
    test "requires username and password to be set" do
      {:error, changeset} = Accounts.register_user(%{})

      assert %{
               password: ["can't be blank"],
               username: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "validates username and password when given" do
      {:error, changeset} = Accounts.register_user(%{
        username: "1234",
        password: "12345",
        role: "user",
        deposit: 0})

      assert %{
               username: ["should be at least 5 character(s)"],
               password: ["should be at least 6 character(s)"]
             } = errors_on(changeset)
    end

    test "validates username uniqueness" do
      %{username: username} = user_fixture()
      {:error, changeset} = Accounts.register_user(%{username: username})
      assert "has already been taken" in errors_on(changeset).username
    end

    test "validates deposit must minimun 0" do
      {:error, changeset} = Accounts.register_user(%{
        username: "username",
          password: "secret123",
          role: "user",
          deposit: -10})
      assert  %{
        deposit: ["must be greater than or equal to 0"]
      } = errors_on(changeset)
    end

    test "registers users with a hashed password" do
      username = unique_user_username()
      {:ok, user} = Accounts.register_user(valid_user_attributes(username: username))
      assert user.username == username
      assert is_binary(user.hashed_password)
      assert is_nil(user.password)
    end
  end

  describe "change_user_registration/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_registration(%User{})
      assert changeset.required == [:role, :deposit, :password, :username]
    end

    test "allows fields to be set" do
      username = unique_user_username()
      password = valid_user_password()

      changeset =
        Accounts.change_user_registration(
          %User{},
          valid_user_attributes(username: username, password: password)
        )

      assert changeset.valid?
      assert get_change(changeset, :username) == username
      assert get_change(changeset, :password) == password
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "change_user_username/2" do
    test "returns a user changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_username(%User{})
      assert changeset.required == [:username]
    end
  end

  describe "apply_user_username/3" do
    setup do
      %{user: user_fixture()}
    end

    test "requires username to change", %{user: user} do
      {:error, changeset} = Accounts.apply_user_username(user, valid_user_password(), %{})
      assert %{username: ["did not change"]} = errors_on(changeset)
    end

    test "validates minimum value for username for security", %{user: user} do
      too_short = String.duplicate("db", 2)

      {:error, changeset} =
        Accounts.apply_user_username(user, valid_user_password(), %{username: too_short})

      assert "should be at least 5 character(s)" in errors_on(changeset).username
    end

    test "validates username uniqueness", %{user: user} do
      %{username: username} = user_fixture()
      password = valid_user_password()

      {:error, changeset} = Accounts.apply_user_username(user, password, %{username: username})

      assert "has already been taken" in errors_on(changeset).username
    end

    test "validates current password", %{user: user} do
      {:error, changeset} =
        Accounts.apply_user_username(user, "invalid", %{username: unique_user_username()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "applies the username without persisting it", %{user: user} do
      username = unique_user_username()
      {:ok, user} = Accounts.apply_user_username(user, valid_user_password(), %{username: username})
      assert user.username == username
      assert Accounts.get_user!(user.id).username != username
    end
  end

  describe "generate_user_session_token/1" do
    setup do
      %{user: user_fixture()}
    end

    test "generates a token", %{user: user} do
      token = Accounts.generate_user_session_token(user)
      assert user_token = Repo.get_by(UserToken, token: token)
      assert user_token.context == "session"

      # Creating the same token for another user should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%UserToken{
          token: user_token.token,
          user_id: user_fixture().id,
          context: "session"
        })
      end
    end
  end

  describe "get_user_by_session_token/1" do
    setup do
      user = user_fixture()
      token = Accounts.generate_user_session_token(user)
      %{user: user, token: token}
    end

    test "returns user by token", %{user: user, token: token} do
      assert session_user = Accounts.get_user_by_session_token(token)
      assert session_user.id == user.id
    end

    test "does not return user for invalid token" do
      refute Accounts.get_user_by_session_token("oops")
    end

    test "does not return user for expired token", %{token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_user_by_session_token(token)
    end
  end

  describe "delete_user_session_token/1" do
    test "deletes the token" do
      user = user_fixture()
      token = Accounts.generate_user_session_token(user)
      assert Accounts.delete_user_session_token(token) == :ok
      refute Accounts.get_user_by_session_token(token)
    end
  end

  describe "inspect/2 for the User module" do
    test "does not include password" do
      refute inspect(%User{password: "123456"}) =~ "password: \"123456\""
    end
  end

  describe "generate_user_api_token/1" do
    setup do
      %{user: user_fixture()}
    end

    test "generates a token", %{user: user} do
      token = Accounts.generate_user_api_token(user)

      assert user_token = Repo.get_by(UserToken, token: token)
      assert user_token.context == "api"

      # Creating the same token for another user should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%UserToken{
          token: user_token.token,
          user_id: user_fixture().id,
          context: "api"
        })
      end
    end

    test "returns existing token if token already exists", %{user: user} do
      token = Accounts.generate_user_api_token(user)

      assert Accounts.generate_user_api_token(user) == token
    end
  end

  describe "get_api_token_by_user/1" do
    setup do
      %{user: user_fixture()}
    end

    test "returns nil if user has no api token", %{user: user} do
      refute Accounts.get_api_token_by_user(user)
    end

    test "returns api token by user", %{user: user} do
      token = Accounts.generate_user_api_token(user)

      assert Accounts.get_api_token_by_user(user) == token
    end
  end

  describe "get_user_by_api_token/1" do
    setup do
      user = user_fixture()
      token = Accounts.generate_user_api_token(user)
      %{user: user, token: token}
    end

    test "does not return user for invalid token" do
      refute Accounts.get_user_by_api_token("oops")
    end

    test "returns user by token", %{user: user, token: token} do
      assert api_user = Accounts.get_user_by_api_token(token)
      assert api_user.id == user.id
    end

    test "token won't expire", %{user: user, token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])

      assert api_user = Accounts.get_user_by_api_token(token)
      assert api_user.id == user.id
    end
  end

  describe "refresh_user_api_token/1" do
    setup do
      user = user_fixture()
      token = Accounts.generate_user_api_token(user)
      %{user: user, token: token}
    end

    test "deletes the current token and sets a new token", %{user: user, token: token} do
      refute Accounts.refresh_user_api_token(user) == token
    end
  end

  describe "delete_user_api_token/1" do
    setup do
      %{user: user_fixture()}
    end

    test "deletes the token", %{user: user} do
      token = Accounts.generate_user_api_token(user)
      assert Accounts.delete_user_api_token(token) == :ok
      refute Accounts.get_api_token_by_user(user)
    end
  end
end

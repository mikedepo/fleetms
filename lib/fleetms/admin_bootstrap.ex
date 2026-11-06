defmodule Fleetms.AdminBootstrap do
  @moduledoc """
  Creates the first platform admin on a fresh deploy.

  A new production install has no way in: sign-up requires email confirmation
  (and no mailer may be configured yet), and the demo seed uses a published
  password. So when `ADMIN_EMAIL` and `ADMIN_PASSWORD` are set, boot ensures a
  confirmed `is_super_admin` user with those credentials exists. It is
  idempotent — once a user with that email exists it does nothing (it never
  resets an existing password) — and does nothing at all when either variable
  is unset.

  The admin lands on `/admin`, from where clients are provisioned.
  """
  require Logger

  alias Fleetms.Accounts

  @doc "Runs the bootstrap using `ADMIN_EMAIL` / `ADMIN_PASSWORD` from the environment."
  def run do
    run(System.get_env("ADMIN_EMAIL"), System.get_env("ADMIN_PASSWORD"))
  end

  @doc false
  def run(email, password) when is_binary(email) and is_binary(password) do
    case String.trim(email) do
      "" -> :skipped
      email -> ensure_admin(email, password)
    end
  end

  def run(_email, _password), do: :skipped

  defp ensure_admin(email, password) do
    case Accounts.get_user_by_email(email, authorize?: false, not_found_error?: false) do
      {:ok, nil} -> create_admin(email, password)
      {:ok, _user} -> :exists
      {:error, error} -> {:error, error}
    end
  end

  # Mirrors the platform-admin setup in priv/repo/seeds.exs: `is_super_admin` and
  # `confirmed_at` aren't writable through actions, so they're set with Ash.Seed.
  #
  # Invalid input (a password under 8 characters, a malformed email) must not
  # take the deploy down: the app keeps running and the log says how to fix it.
  defp create_admin(email, password) do
    Accounts.User
    |> Ash.Changeset.for_create(:register_with_password, %{
      email: email,
      password: password,
      password_confirmation: password
    })
    |> Ash.create(authorize?: false)
    |> case do
      {:ok, user} ->
        user = Ash.Seed.update!(user, %{confirmed_at: DateTime.utc_now(), is_super_admin: true})

        Accounts.create_user_profile!(
          %{user_id: user.id, first_name: "Platform", last_name: "Admin"},
          authorize?: false
        )

        Logger.info("[AdminBootstrap] Created platform admin #{email}")
        :created

      {:error, error} ->
        Logger.warning(
          "[AdminBootstrap] Could not create the platform admin #{email}: " <>
            Exception.message(error) <>
            " Fix ADMIN_EMAIL or ADMIN_PASSWORD (at least 8 characters) and redeploy."
        )

        {:error, error}
    end
  end
end

defmodule FleetmsWeb.ApiAuthController do
  use FleetmsWeb, :controller

  # Honors the `user_registration` feature flag like the browser sign-up
  # (`FleetmsWeb.Plugs.PublicRegistration`), so an invite-only install can't be
  # joined through the API either.
  def register(conn, params) do
    if Fleetms.FeatureFlags.user_registration?() do
      do_register(conn, params)
    else
      error(conn, 403, "Sign-up is currently disabled.")
    end
  end

  defp do_register(conn, params) do
    strategy = AshAuthentication.Info.strategy!(Fleetms.Accounts.User, :password)

    case AshAuthentication.Strategy.action(strategy, :register, params) do
      {:ok, _user} ->
        conn
        |> put_status(:ok)
        |> json(%{message: "Registration successful. Please log in."})

      {:error, _error} ->
        error(conn, 400, "Registration failed or invalid parameters.")
    end
  end

  def request_password_reset(conn, params) do
    strategy = AshAuthentication.Info.strategy!(Fleetms.Accounts.User, :password)

    case AshAuthentication.Strategy.action(strategy, :request_password_reset, params) do
      :ok ->
        conn
        |> put_status(:ok)
        |> json(%{message: "Password reset instructions sent."})

      {:error, _error} ->
        error(conn, 400, "Failed to request password reset.")
    end
  end

  def reset_password(conn, params) do
    strategy = AshAuthentication.Info.strategy!(Fleetms.Accounts.User, :password)

    case AshAuthentication.Strategy.action(strategy, :reset, params) do
      {:ok, _user} ->
        conn
        |> put_status(:ok)
        |> json(%{message: "Password reset successful. Please log in."})

      {:error, _error} ->
        error(conn, 400, "Failed to reset password. Invalid or expired token.")
    end
  end

  defp error(conn, status, detail) do
    conn
    |> put_status(status)
    |> json(%{errors: [%{status: to_string(status), detail: detail}]})
  end
end

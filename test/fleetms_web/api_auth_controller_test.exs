defmodule FleetmsWeb.ApiAuthControllerTest do
  # Toggles a global feature flag, so not async.
  use FleetmsWeb.ConnCase, async: false

  alias Fleetms.FeatureFlags

  defp register_params do
    email = "api-signup-#{System.unique_integer([:positive])}@example.com"

    %{
      "user" => %{
        "email" => email,
        "password" => "password1234",
        "password_confirmation" => "password1234"
      }
    }
  end

  describe "POST /api/v1/register" do
    test "is refused when public sign-up is off", %{conn: conn} do
      FeatureFlags.disable(:user_registration)
      on_exit(fn -> FeatureFlags.enable(:user_registration) end)

      conn = post(conn, ~p"/api/v1/register", register_params())

      assert %{"errors" => [%{"status" => "403", "detail" => "Sign-up is currently disabled."}]} =
               json_response(conn, 403)
    end

    test "still works when public sign-up is on", %{conn: conn} do
      FeatureFlags.enable(:user_registration)

      conn = post(conn, ~p"/api/v1/register", register_params())

      refute conn.status == 403
    end
  end
end

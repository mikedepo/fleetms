defmodule Fleetms.AdminBootstrapTest do
  use Fleetms.DataCase, async: true

  alias Fleetms.Accounts
  alias Fleetms.AdminBootstrap

  defp unique_email, do: "admin-#{System.unique_integer([:positive])}@example.com"

  test "creates a confirmed platform admin with a profile" do
    email = unique_email()

    assert AdminBootstrap.run(email, "a-long-secret-pw") == :created

    user = Accounts.get_user_by_email!(email, authorize?: false, load: [:profile])
    assert user.is_super_admin
    assert user.confirmed_at
    assert user.profile.first_name == "Platform"
  end

  test "is idempotent and never touches an existing user" do
    email = unique_email()
    assert AdminBootstrap.run(email, "a-long-secret-pw") == :created
    before = Accounts.get_user_by_email!(email, authorize?: false)

    assert AdminBootstrap.run(email, "a-different-password") == :exists

    after_run = Accounts.get_user_by_email!(email, authorize?: false)
    assert after_run.hashed_password == before.hashed_password
  end

  test "skips when either variable is missing or blank" do
    assert AdminBootstrap.run(nil, "a-long-secret-pw") == :skipped
    assert AdminBootstrap.run(unique_email(), nil) == :skipped
    assert AdminBootstrap.run("   ", "a-long-secret-pw") == :skipped
  end
end

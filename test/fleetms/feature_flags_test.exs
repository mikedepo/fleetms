defmodule Fleetms.FeatureFlagsTest do
  use Fleetms.DataCase, async: false

  alias Fleetms.FeatureFlags

  test "a flag can be toggled on and off" do
    FeatureFlags.enable(:user_registration)
    assert FeatureFlags.user_registration?()

    FeatureFlags.disable(:user_registration)
    refute FeatureFlags.user_registration?()
  end

  test "ensure_defaults! does not override a value staff have already set" do
    FeatureFlags.disable(:individual_registration)
    FeatureFlags.ensure_defaults!()

    # It's already set (to off), so the default (on) must not clobber it.
    refute FeatureFlags.individual_registration?()
  end

  test "names lists the known flags" do
    assert :individual_registration in FeatureFlags.names()
    assert :user_registration in FeatureFlags.names()
  end

  describe "defaults/0" do
    setup do
      previous = Application.fetch_env(:fleetms, :user_registration_default)

      on_exit(fn ->
        case previous do
          {:ok, value} -> Application.put_env(:fleetms, :user_registration_default, value)
          :error -> Application.delete_env(:fleetms, :user_registration_default)
        end
      end)
    end

    test "user registration defaults to on" do
      Application.delete_env(:fleetms, :user_registration_default)
      assert FeatureFlags.defaults()[:user_registration] == true
    end

    test "a deployment can start with user registration off (USER_REGISTRATION=false)" do
      Application.put_env(:fleetms, :user_registration_default, false)
      assert FeatureFlags.defaults()[:user_registration] == false
      assert FeatureFlags.defaults()[:public_api] == true
    end
  end
end

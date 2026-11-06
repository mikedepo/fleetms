defmodule Fleetms.MailerTest do
  # Changes application env, so not async.
  use ExUnit.Case, async: false

  setup do
    previous = Application.get_env(:fleetms, Fleetms.Mailer)
    on_exit(fn -> Application.put_env(:fleetms, Fleetms.Mailer, previous) end)
  end

  test "delivers? is true for an adapter that sends or captures mail" do
    for adapter <- [Swoosh.Adapters.Test, Swoosh.Adapters.Local, Swoosh.Adapters.SMTP] do
      Application.put_env(:fleetms, Fleetms.Mailer, adapter: adapter)
      assert Fleetms.Mailer.delivers?(), "expected #{inspect(adapter)} to deliver"
    end
  end

  test "delivers? is false when mail is only logged (no provider set up)" do
    Application.put_env(:fleetms, Fleetms.Mailer, adapter: Swoosh.Adapters.Logger)
    refute Fleetms.Mailer.delivers?()
  end
end

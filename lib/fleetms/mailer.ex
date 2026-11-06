defmodule Fleetms.Mailer do
  use Swoosh.Mailer, otp_app: :fleetms

  @doc """
  Whether outgoing email actually reaches people.

  False when the mailer only logs: production with no email provider set up
  (see `config/prod.exs` and the email section of `config/runtime.exs`). Screens
  that would send an email check this, so they can offer what works instead of
  promising a message that never arrives.
  """
  @spec delivers?() :: boolean()
  def delivers? do
    adapter = Keyword.get(Application.get_env(:fleetms, __MODULE__, []), :adapter)
    adapter not in [nil, Swoosh.Adapters.Logger]
  end
end

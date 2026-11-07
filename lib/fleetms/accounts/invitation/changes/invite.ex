defmodule Fleetms.Accounts.Invitation.Changes.Invite do
  @moduledoc """
  Sets up a new invitation: generates the single-use token (storing only its
  hash), sets the expiry, and emails the link after the transaction commits.

  The plain token and organization name are captured in this change's closure, so
  they never need to be persisted or threaded through context.
  """
  use Ash.Resource.Change

  require Logger

  alias Fleetms.Accounts.Invitation.Changes.GenerateToken
  alias Fleetms.Accounts.Invitation.Senders.SendInvitationEmail

  @token_bytes 32
  @ttl_days 7

  @impl true
  def change(changeset, _opts, _context) do
    token = @token_bytes |> :crypto.strong_rand_bytes() |> Base.url_encode64(padding: false)
    org_name = Ash.Changeset.get_argument(changeset, :organization_name)
    expires_at = DateTime.add(DateTime.utc_now(), @ttl_days, :day)

    changeset
    |> Ash.Changeset.force_change_attribute(:hashed_token, GenerateToken.hash(token))
    |> Ash.Changeset.force_change_attribute(:expires_at, expires_at)
    |> Ash.Changeset.after_transaction(fn
      _changeset, {:ok, invitation} ->
        case SendInvitationEmail.send(invitation, token, org_name) do
          {:ok, _receipt} ->
            {:ok, invitation}

          {:error, reason} ->
            Logger.error("Invitation email to #{invitation.email} failed: #{inspect(reason)}")

            # The link never reached anyone; don't leave a pending invitation behind.
            Fleetms.Accounts.revoke_invitation(invitation, authorize?: false)

            {:error,
             Ash.Error.Changes.InvalidAttribute.exception(
               field: :email,
               message:
                 "The invitation email could not be sent. Check the server's email settings (sender address and SMTP credentials) and try again."
             )}
        end

      _changeset, other ->
        other
    end)
  end
end

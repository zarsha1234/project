defmodule Todo.Route.PathNotifier do
  import Swoosh.Email

  alias Todo.Mailer

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({"Todo", "contact@example.com"})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_confirmation_instructions(path, url) do
    deliver(path.email, "Confirmation instructions", """

    ==============================

    Hi #{path.email},

    You can confirm your account by visiting the URL below:

    #{url}

    If you didn't create an account with us, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to reset a path password.
  """
  def deliver_reset_password_instructions(path, url) do
    deliver(path.email, "Reset password instructions", """

    ==============================

    Hi #{path.email},

    You can reset your password by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to update a path email.
  """
  def deliver_update_email_instructions(path, url) do
    deliver(path.email, "Update email instructions", """

    ==============================

    Hi #{path.email},

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end
end

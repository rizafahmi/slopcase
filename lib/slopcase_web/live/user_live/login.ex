defmodule SlopcaseWeb.UserLive.Login do
  use SlopcaseWeb, :live_view

  alias Slopcase.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="auth-page">
        <div class="auth-card">
          <header class="auth-header">
            <h1 class="auth-title">Log in</h1>
            <p class="auth-subtitle">
              <%= if @current_scope do %>
                You need to reauthenticate to perform sensitive actions on your account.
              <% end %>
            </p>
          </header>

          <div :if={local_mail_adapter?()} class="auth-info">
            <.icon name="hero-information-circle" class="icon icon--lg auth-info__icon" />
            <div class="auth-info__content">
              <p>You are running the local mail adapter.</p>
              <p>
                To see sent emails, visit <.link href="/dev/mailbox">the mailbox page</.link>.
              </p>
            </div>
          </div>

          <.form
            for={@form}
            id="login_form_magic"
            action={~p"/users/log-in"}
            phx-submit="submit_magic"
            class="auth-form"
          >
            <.input
              id="magic_email"
              readonly={!!@current_scope}
              field={@form[:email]}
              type="email"
              label="Email"
              autocomplete="email"
              required
              phx-mounted={JS.focus()}
            />
            <.button class="btn btn--primary auth-btn">
              Log in with email <span aria-hidden="true">→</span>
            </.button>
          </.form>

          <div class="auth-divider">or use password</div>

          <.form
            for={@form}
            id="login_form_password"
            action={~p"/users/log-in"}
            phx-submit="submit_password"
            phx-trigger-action={@trigger_submit}
            class="auth-form"
          >
            <.input
              id="password_email"
              readonly={!!@current_scope}
              field={@form[:email]}
              type="email"
              label="Email"
              autocomplete="email"
              required
            />
            <.input
              id="password_password"
              field={@form[:password]}
              type="password"
              label="Password"
              autocomplete="current-password"
            />
            <.button
              class="btn btn--primary auth-btn"
              name={@form[:remember_me].name}
              value="true"
            >
              Log in and stay logged in <span aria-hidden="true">→</span>
            </.button>
            <.button class="btn btn--soft auth-btn">
              Log in only this time
            </.button>
          </.form>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    email =
      Phoenix.Flash.get(socket.assigns.flash, :email) ||
        get_in(socket.assigns, [:current_scope, Access.key(:user), Access.key(:email)])

    form = to_form(%{"email" => email}, as: "user")

    {:ok, assign(socket, form: form, trigger_submit: false)}
  end

  @impl true
  def handle_event("submit_password", _params, socket) do
    {:noreply, assign(socket, :trigger_submit, true)}
  end

  def handle_event("submit_magic", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_login_instructions(
        user,
        &url(~p"/users/log-in/#{&1}")
      )
    end

    info =
      "If your email is in our system, you will receive instructions for logging in shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> push_navigate(to: ~p"/users/log-in")}
  end

  defp local_mail_adapter? do
    Application.get_env(:slopcase, Slopcase.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end

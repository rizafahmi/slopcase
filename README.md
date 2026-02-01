# 🎰 Slopcase

[![Elixir](https://img.shields.io/badge/Elixir-~%3E%201.15-4B275F?logo=elixir&logoColor=white)](https://elixir-lang.org/)
[![Phoenix](https://img.shields.io/badge/Phoenix-~%3E%201.8-FD4F00?logo=phoenixframework&logoColor=white)](https://www.phoenixframework.org/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A showcase for AI-generated projects. Submit your AI-built apps and let the community vote: is it slop or not?

## ✨ Features

- **Project Submissions** — Share AI-generated projects with title, URLs, model used, and tools
- **Community Voting** — Vote on submissions to determine if they're "slop" or "clean"
- **Real-time Updates** — LiveView-powered interface with instant vote updates via PubSub
- **Thumbnail Previews** — Automatic thumbnail fetching for submitted URLs
- **Admin Dashboard** — Manage and moderate submissions
- **User Authentication** — Secure registration and login system

## 🛠️ Tech Stack

- **Framework:** Phoenix 1.8 with LiveView
- **Database:** SQLite (via Ecto)
- **Styling:** Open Props + Custom CSS
- **HTTP Client:** Req
- **Server:** Bandit

## 🚀 Getting Started

### Prerequisites

- Elixir ~> 1.15
- Erlang/OTP (compatible version)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/slopcase.git
   cd slopcase
   ```

2. Install dependencies and set up the database:
   ```bash
   mix setup
   ```

3. Start the Phoenix server:
   ```bash
   mix phx.server
   ```

4. Visit [`localhost:4000`](http://localhost:4000) in your browser.

### Running Tests

```bash
mix test
```

## 📁 Project Structure

```
lib/
├── slopcase/           # Business logic
│   ├── accounts/       # User authentication
│   └── showcase/       # Submissions & voting
└── slopcase_web/       # Web layer
    ├── components/     # UI components
    ├── controllers/    # HTTP controllers
    └── live/           # LiveView modules
```

## 🧪 Development

Run the precommit checks before pushing:

```bash
mix precommit
```

This runs compilation with warnings as errors, unlocks unused deps, formats code, and runs tests.

## 🚢 Deployment

This project includes a Dockerfile and `fly.toml` for deployment to [Fly.io](https://fly.io).

For other deployment options, see the [Phoenix deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## 📚 Learn More

- [Phoenix Framework](https://www.phoenixframework.org/)
- [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view)
- [Elixir Forum](https://elixirforum.com/c/phoenix-forum)

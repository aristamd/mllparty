# MLLParty

## Description

Small service that converts HTTP requests to MLLP messages.

## Quick Start

Send an HL7 message via MLLP with:

```bash
# Start mllp-catcher and http-debugger services
docker compose up -d

# Install dependencies
mix deps.get

# Send a message from command line
mix send_mllp mllp://0.0.0.0:2595 "<your HL7 message, or leave blank to send test message>"

# You should now see the message in the logs of the mllp-catcher and http-debugger... You'll see an invalid_ack_message output in the console because our test endpoint isn't returning an ACK like a real system will.
```

## Pre-Requisites

You'll need:
- An endpoint listening for MLLP messages (see below for setting up a simple)

## Usage

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix

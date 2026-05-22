# Discord Integration

Mercury features a complete, DI-based Discord integration that bridges the `AgentDispatcher` with Dimscord. The bot listens for mentions and commands, routes conversations into threads, and maintains session continuity using SQLite.

## Configuration

The bot uses the layered configuration system (`config.nim`). Configuration is defined under the `[discord]` section in TOML (or `DISCORD_` prefix in `.env`).

```toml
[discord]
# The environment variable holding the Discord token (default: DISCORD_BOT_TOKEN)
token_env = "DISCORD_BOT_TOKEN"
# Command prefix for bot commands (default: !)
prefix = "!"

[discord.admins]
# List of Discord user IDs who have admin privileges
allow = ["1234567890"]
deny = []

[discord.users]
# List of Discord user IDs allowed to interact with the bot
# If empty, all users can interact (subject to other limits)
allow = []
deny = []

[discord.file_rules]
# File access rules for the read/write tools
allow = ["src/*", "docs/*"]
deny = [".env*", "*.key", ".git/*"]

[discord.tools]
# Control which users can use which tools
allow = []
deny = []
```

## Permission Model

The permission model is evaluated at two levels:
1. **Bot Interaction (`discord.users`)**: Controls who can send messages to the bot and mention it.
2. **Bot Administration (`discord.admins`)**: Controls who can use administrative commands (like `!config`, `!admin`).
3. **Tool Usage (`discord.tools`)**: Restricts certain tools (like `file_write`) to specific users. Some paths require admin approval (`pathAsk`).

## File Tool Configuration

The File Tool uses `discord.file_rules` to determine access:
- **allow**: Paths the bot can read/write without restriction.
- **ask**: Paths the bot must ask for permission (currently acts as deny for automated processes without approval).
- **deny**: Paths that are strictly forbidden. There are mandatory deny rules for credentials (`.env`, `.ssh`, etc.).

## Bot Commands Reference

Commands can be invoked in channels where the bot is present using the configured prefix (`!` by default).

### `!status`
Available to: All allowed users
Shows the bot's current status, uptime, loaded config paths, and active admins.

### `!config`
Available to: Admins only
- `!config show`: Dumps the current parsed configuration.
- `!config set <key> <value>`: Updates a configuration value in memory.
- `!config reload`: Reloads the configuration from disk.
- `!config allowlist <add|remove|list> [path]`: Manages the dynamic file allowlist in memory.

### `!admin`
Available to: Admins only
- `!admin restart`: Restarts the bot process.
- `!admin reconnect`: Forces the Dimscord gateway to reconnect.

### `!session`
Available to: All allowed users
Manage the current agent session.

## Running the Daemon

To run the Mercury Discord bot, use the `daemon` command in the CLI:

```bash
export DISCORD_BOT_TOKEN="your_token_here"
mercury daemon
```

This will initialize the database, load the configuration, and connect to Discord via the Gateway.

## Local Testing Instructions

The Discord integration is built using Dependency Injection. `mercury_core/discord.nim` depends on callback procs for API actions rather than raw Dimscord endpoints.

To run the End-to-End Discord tests locally:

```bash
cd mercury_core
nim c -r tests/test_e2e_discord.nim
```

The E2E test uses `MockDiscordApi` and `MockShard` to completely simulate Discord's HTTP and Gateway interfaces, allowing full coverage of session routing, thread creation, permission checks, and file tools without making real network requests.
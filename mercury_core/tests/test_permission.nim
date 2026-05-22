import unittest
import mercury_core/discord_types
import mercury_core/permission

suite "Permission Framework":
  setup:
    var cfg = defaultDiscordConfig()
    cfg.admins.allow.add("admin_user")
    cfg.users.allow.add("normal_user")
    cfg.users.deny.add("banned_user")
    cfg.tools.deny.add("banned_tool")
    cfg.tools.allow.add("safe_tool")

  test "isAdmin":
    check isAdmin("admin_user", cfg) == true
    check isAdmin("normal_user", cfg) == false
    check isAdmin("unknown_user", cfg) == false

  test "isUserAllowed":
    check isUserAllowed("admin_user", cfg) == true
    check isUserAllowed("normal_user", cfg) == true
    check isUserAllowed("banned_user", cfg) == false
    check isUserAllowed("unknown_user", cfg) == false

  test "canUseTool - user not allowed":
    check canUseTool("unknown_user", "read_file", cfg) == pdDeny
    check canUseTool("banned_user", "read_file", cfg) == pdDeny

  test "canUseTool - explicit deny":
    check canUseTool("admin_user", "banned_tool", cfg) == pdDeny

  test "canUseTool - explicit allow":
    check canUseTool("normal_user", "safe_tool", cfg) == pdAllow

  test "canUseTool - risk low/none":
    check canUseTool("normal_user", "read_file", cfg) == pdAllow
    check canUseTool("admin_user", "read_file", cfg) == pdAllow

  test "canUseTool - risk medium":
    # normal user asks, admin bypasses ask
    check canUseTool("normal_user", "write_file", cfg) == pdAsk
    check canUseTool("admin_user", "write_file", cfg) == pdAllow

  test "canUseTool - risk high/critical":
    check canUseTool("normal_user", "bash", cfg) == pdAsk
    check canUseTool("admin_user", "bash", cfg) == pdAsk

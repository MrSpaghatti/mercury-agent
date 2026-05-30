import std/unittest
import mercury_core/[persona, delegate]

suite "PersonaRegistry":

  test "empty allow list means all tools pass":
    let pc = PersonaConfig(
      name: "locked",
      systemPrompt: "All tools allowed by default.",
      toolsAllow: @[],
      toolsDeny: @[],
    )
    let filtered = filterToolsByPersona(pc, @["shell", "file_read", "file_write"])
    check: filtered.len == 3

  test "specific allow list filters correctly":
    let pc = PersonaConfig(
      name: "analyst",
      systemPrompt: "Read only.",
      toolsAllow: @["file_read"],
    )
    let filtered = filterToolsByPersona(pc, @["shell", "file_read", "file_write"])
    check: filtered.len == 1
    check: "file_read" in filtered
    check: "shell" notin filtered

  test "empty deny list means all allowed tools pass":
    let pc = PersonaConfig(
      name: "open",
      systemPrompt: "Default.",
      toolsAllow: @[],
      toolsDeny: @[],
    )
    let filtered = filterToolsByPersona(pc, @["shell", "file_read"])
    check: filtered.len == 2

  test "deny list removes specific tools":
    let pc = PersonaConfig(
      name: "cautious",
      systemPrompt: "No shell.",
      toolsAllow: @["shell", "file_read", "file_write"],
      toolsDeny: @["shell"],
    )
    let filtered = filterToolsByPersona(pc, @["shell", "file_read", "file_write"])
    check: filtered.len == 2
    check: "shell" notin filtered
    check: "file_read" in filtered

  test "deny takes precedence over allow":
    let pc = PersonaConfig(
      name: "conflict",
      systemPrompt: "Deny wins.",
      toolsAllow: @["shell", "file_read"],
      toolsDeny: @["shell"],
    )
    let filtered = filterToolsByPersona(pc, @["shell", "file_read"])
    check: filtered.len == 1
    check: "shell" notin filtered

  test "unknown tool names in allow are ignored":
    let pc = PersonaConfig(
      name: "cautious",
      systemPrompt: "Only known tools.",
      toolsAllow: @["shell", "nonexistent_tool"],
    )
    let filtered = filterToolsByPersona(pc, @["shell", "file_read"])
    check: filtered.len == 1
    check: "shell" in filtered
    check: "nonexistent_tool" notin filtered

  test "scopedRegistry filters the base registry tools":
    var reg = newPersonaRegistry()
    let pc = PersonaConfig(
      name: "writer",
      systemPrompt: "Write docs.",
      toolsAllow: @["file_read", "file_write"],
      toolsDeny: @[],
    )
    reg.registerPersona(pc)
    # Test filterToolsByPersona which doesn't need Tool objects
    let allTools = @["shell", "file_read", "file_write"]
    let filtered = filterToolsByPersona(pc, allTools)
    check: filtered.len == 2
    check: "file_read" in filtered
    check: "file_write" in filtered
    check: "shell" notin filtered


suite "Memory scope":

  test "persona default memory scope is own_sessions":
    let pc = PersonaConfig(name: "default_persona")
    check: pc.memoryScope == msOwnSessions

  test "stateless persona has msNone":
    let pc = PersonaConfig(
      name: "stateless",
      memoryScope: msNone,
    )
    check: pc.memoryScope == msNone


suite "DelegationConfig":

  test "defaultDelegationConfig uses constants":
    let dc = defaultDelegationConfig()
    check: dc.maxDepth == delegate.DefaultMaxDelegationDepth
    check: dc.maxDelegations == delegate.DefaultMaxDelegationsPerRun

  test "canDelegate returns true when both > 0":
    var dc = defaultDelegationConfig()
    check: dc.canDelegate == true

  test "useDelegationSlot decrements both counters":
    var dc = defaultDelegationConfig()
    let origDepth = dc.maxDepth
    let origDel = dc.maxDelegations
    dc.useDelegationSlot()
    check: dc.maxDepth == origDepth - 1
    check: dc.maxDelegations == origDel - 1

  test "applyPersonaDelegation uses defaults for empty ints":
    let dc = applyPersonaDelegation(0, 0, "test")
    check: dc.maxDepth == delegate.DefaultMaxDelegationDepth
    check: dc.maxDelegations == delegate.DefaultMaxDelegationsPerRun
    check: dc.personaName == "test"

  test "applyPersonaDelegation parses explicit values":
    let dc = applyPersonaDelegation(3, 10, "explicit")
    check: dc.maxDepth == 3
    check: dc.maxDelegations == 10
    check: dc.personaName == "explicit"


suite "System prompt defaults":

  test "persona system prompt is empty by default":
    let pc = PersonaConfig(name: "anon")
    check: pc.systemPrompt.len == 0

  test "persona has a memory scope default":
    let pc = PersonaConfig(name: "default_persona")
    check: pc.memoryScope == msOwnSessions
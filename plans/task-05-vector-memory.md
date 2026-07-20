# Task 5: Vector Memory / Semantic Retrieval

**Status**: 🔴 Not Started
**Dependencies**: Task 1 (Agent Loop relocation — soft, for cleaner imports)
**Complexity**: Medium-Large

---

## Target

- `mercury_core/src/mercury_core/memory.nim`
- `mercury_core/src/mercury_core/embeddings.nim` (new)
- `mercury_core/src/mercury_core/config.nim`

## Current State

- `memory.nim` has SQLite + FTS5 for full-text search.
- No embedding support. No vector storage.
- The agent stores conversations but can only search by keyword match.

## Change

### Phase 5a — Embeddings client
1. Create `embeddings.nim`:
   ```nim
   type
     EmbeddingClient* = object
       baseUrl*: string
       apiKey*: string
       model*: string          # e.g. "text-embedding-3-small"
       timeoutMs*: int

     EmbeddingResult* = object
       vector*: seq[float32]
       tokensUsed*: int

   proc getEmbedding*(client: EmbeddingClient; text: string): EmbeddingResult
   ```
2. Uses the OpenAI `/v1/embeddings` endpoint (same auth as chat completions).
3. Config: add `[embeddings]` section to `MercuryConfig` — `provider`, `model`, `endpoint` (defaults to same as LLM provider).

### Phase 5b — Vector storage in SQLite
1. Extend `memory.nim`:
   - New table: `message_embeddings(message_id INTEGER, embedding BLOB, model TEXT)`.
   - Store embeddings as compact binary blobs (4 bytes per float32).
2. Add `storeEmbedding(db; messageId; embedding; model)` and `clearEmbeddings(db; model)`.
3. Add a `MessageVectorMatch` type:
   ```nim
   type
     MessageVectorMatch* = object
       messageId*: int64
       sessionId*: string
       content*: string
       score*: float32
   ```

### Phase 5c — Cosine similarity search
1. In `memory.nim`, add:
   ```nim
   proc searchByVector*(self: var Memory; query: string; embeddingClient: EmbeddingClient;
                        topK: int = 10; minScore: float32 = 0.7): seq[MessageVectorMatch]
   ```
2. Implementation:
   - Get embedding for query via `embeddingClient.getEmbedding(query)`.
   - Load all stored embeddings from DB.
   - Compute cosine similarity in Nim (avoid SQLite for float math).
   - Return top-K above threshold.
3. Fallback: if no embeddings stored yet (cold start), fall back to FTS5 search.

### Phase 5d — Automatic embedding on message store
1. Add optional `embeddingClient` parameter to `memory.appendMessage`.
2. If provided, compute embedding for the message content and store it.
3. Config flag: `memory.auto_embed = true/false` — embedding costs tokens, make it opt-in.
4. On `newSession`, optionally embed the first user message for session-level search.

### Phase 5e — Hybrid search
1. Add `searchHybrid*(query, topK, ftsWeight, vecWeight)`:
   - Runs FTS5 and vector search in parallel.
   - Merges results by weighted score (FTS5 rank + vector similarity).
   - Returns deduplicated ranked list.
2. Wire into CLI: `./mercury_agent search "concept" --semantic` uses hybrid search.

## Acceptance

- `getEmbedding` returns a valid 1536-dim (or model-appropriate) vector from OpenAI API.
- Unit test: mock embedding endpoint returns known vector; `searchByVector` returns correct matches.
- Integration test: store 3 messages, embed them, search for semantically similar query → correct message returned.
- FTS5 fallback works when embeddings not enabled.
- Hybrid search returns better results than FTS5 alone for semantic queries.
- All 460 existing tests pass.
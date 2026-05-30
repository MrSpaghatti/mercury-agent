## LLM client builder from a MercuryConfig.
##
## Centralizes the `MercuryConfig → LLMClient` construction so callers
## don't need to know the details of endpoint URL, API key, and model
## selection. Used by both `mercury_agent` and `mercury_code`.

import std/[strutils]

import mercury_core/config
import mercury_core/llm_client

proc activeBaseUrl*(cfg: MercuryConfig): string =
  case cfg.provider.toLowerAscii()
  of "vllm":      cfg.vllmEndpoint
  of "openrouter": cfg.openrouterEndpoint
  else:           cfg.openrouterEndpoint

proc activeApiKey*(cfg: MercuryConfig): string =
  case cfg.provider.toLowerAscii()
  of "openrouter": cfg.openrouterApiKey
  of "vllm":      ""
  else:           cfg.openrouterApiKey

proc activeModel*(cfg: MercuryConfig): string =
  case cfg.provider.toLowerAscii()
  of "vllm":      cfg.vllmModel
  of "openrouter": cfg.openrouterModel
  else:           cfg.openrouterModel

proc buildLLMClient*(cfg: MercuryConfig): LLMClient =
  ## Builds an LLMClient from a fully-resolved MercuryConfig.
  newLLMClient(
    baseUrl = activeBaseUrl(cfg),
    apiKey  = activeApiKey(cfg),
    model   = activeModel(cfg),
  )
// Auto-discovers models from the sipgate coding proxy (LiteLLM)
// Updates on first run and via /sipgate-refresh.

import type {
  ExtensionAPI,
  ExtensionContext,
  ProviderModelConfig,
} from "@earendil-works/pi-coding-agent";

const BASE_URL = "https://coding.sipgate.ai";
const PROVIDER_ID = "sipgate";
const REQUEST_TIMEOUT_MS = 10_000;
const REFRESH_TIMEOUT_MS = 15_000;

interface LitellmModelEntry {
  model_name: string;
  model_info: {
    max_input_tokens?: number;
    max_output_tokens?: number;
    max_tokens?: number;
    supports_reasoning?: boolean;
    supports_vision?: boolean;
    reasoning_effort_levels?: string[];
    supported_openai_params?: string[];
    input_cost_per_token?: number;
    output_cost_per_token?: number;
    cache_read_input_token_cost?: number;
    cache_creation_input_token_cost?: number;
    [key: string]: unknown;
  };
}

function usdPerMillion(costPerToken: unknown): number {
  return typeof costPerToken === "number" ? costPerToken * 1_000_000 : 0;
}

function tieredCosts(mi: LitellmModelEntry["model_info"]): ProviderModelConfig["cost"] {
  const base: ProviderModelConfig["cost"] = {
    input: usdPerMillion(mi.input_cost_per_token),
    output: usdPerMillion(mi.output_cost_per_token),
    cacheRead: usdPerMillion(mi.cache_read_input_token_cost),
    cacheWrite: usdPerMillion(mi.cache_creation_input_token_cost),
  };

  const thresholds = new Set<number>();
  for (const key of Object.keys(mi)) {
    const m = /_cost_per_token_above_(\d+)k_tokens(?:_|$)/.exec(key);
    if (m) {
      thresholds.add(Number(m[1]));
    }
  }
  if (thresholds.size > 0) {
    const tiers = [...thresholds]
      .sort((a, b) => a - b)
      .map((k) => ({
        input: usdPerMillion(mi[`input_cost_per_token_above_${k}k_tokens`]) || base.input,
        output: usdPerMillion(mi[`output_cost_per_token_above_${k}k_tokens`]) || base.output,
        cacheRead:
          usdPerMillion(mi[`cache_read_input_token_cost_above_${k}k_tokens`]) || base.cacheRead,
        cacheWrite:
          usdPerMillion(mi[`cache_creation_input_token_cost_above_${k}k_tokens`]) ||
          base.cacheWrite,
        inputTokensAbove: k * 1000,
      }));
    return { ...base, tiers };
  }
  return base;
}

// Output budget: caps max_tokens so pi's clamp doesn't fill the whole context window
// (token-estimate drift would tip requests over the limit). Keep below the proxy's max_model_len.
const MODEL_OVERRIDES: Record<string, Partial<ProviderModelConfig>> = {
  "zai-org/GLM-5.3-verda": { maxTokens: 65000 },
  "sipgate-coding-pro": { maxTokens: 65000 },
  "zai-org/GLM-5.2-FP8": { maxTokens: 65000 },
};

// pi's thinking levels, mapped onto the nearest advertised reasoning_effort level
// (next deeper level first, then shallower). The proxy enforces reasoning_effort
// against the model's reasoning_effort_levels (e.g. GLM-5.3: none/low/high/max) and
// rejects everything else with 400; models without the field accept the full set.
const REASONING_EFFORT_ORDER: readonly string[] = [
  "none",
  "minimal",
  "low",
  "medium",
  "high",
  "xhigh",
  "max",
];

function thinkingLevelMapFor(
  levels: readonly string[] | undefined,
): ProviderModelConfig["thinkingLevelMap"] {
  if (!levels || levels.length === 0) {
    return {
      off: "none",
      minimal: "minimal",
      low: "low",
      medium: "medium",
      high: "high",
      xhigh: "xhigh",
      max: "max",
    };
  }
  const nearest = (level: string): string | null => {
    const idx = REASONING_EFFORT_ORDER.indexOf(level);
    for (let i = idx; i < REASONING_EFFORT_ORDER.length; i++) {
      if (levels.includes(REASONING_EFFORT_ORDER[i])) return REASONING_EFFORT_ORDER[i];
    }
    for (let i = idx; i >= 0; i--) {
      if (levels.includes(REASONING_EFFORT_ORDER[i])) return REASONING_EFFORT_ORDER[i];
    }
    return null;
  };
  return {
    off: levels.includes("none") ? "none" : null,
    minimal: nearest("minimal"),
    low: nearest("low"),
    medium: nearest("medium"),
    high: nearest("high"),
    xhigh: nearest("xhigh"),
    max: nearest("max"),
  };
}

function mapModel(entry: LitellmModelEntry): ProviderModelConfig {
  const mi = entry.model_info;
  const reasoning = mi.supports_reasoning === true;
  const supportsReasoningEffort = mi.supported_openai_params?.includes("reasoning_effort") === true;
  const model: ProviderModelConfig = {
    id: entry.model_name,
    name: entry.model_name,
    reasoning,
    input: mi.supports_vision === true ? ["text", "image"] : ["text"],
    cost: tieredCosts(mi),
    contextWindow: mi.max_input_tokens ?? mi.max_tokens ?? 128_000,
    maxTokens: mi.max_output_tokens ?? mi.max_tokens ?? 16_384,
  };
  if (reasoning && supportsReasoningEffort) {
    model.thinkingLevelMap = thinkingLevelMapFor(mi.reasoning_effort_levels);
    // LiteLLM's anthropic route rejects unknown params (e.g. the default store: false).
    model.compat = { supportsReasoningEffort: true, supportsStore: false };
  }
  return { ...model, ...MODEL_OVERRIDES[model.id] };
}

async function fetchJson(path: string, signal: AbortSignal): Promise<unknown> {
  const response = await fetch(`${BASE_URL}${path}`, {
    headers: { Authorization: `Bearer ${process.env.CODING_PROXY_LLM_KEY ?? ""}` },
    signal: AbortSignal.any([signal, AbortSignal.timeout(REQUEST_TIMEOUT_MS)]),
  });
  if (!response.ok) {
    throw new Error(`${path} responded ${response.status}`);
  }
  return response.json();
}

async function discover(signal: AbortSignal): Promise<ProviderModelConfig[]> {
  const [models, info] = await Promise.all([
    fetchJson("/models", signal) as Promise<{ data: Array<{ id: string }> }>,
    fetchJson("/model/info", signal) as Promise<{ data: LitellmModelEntry[] }>,
  ]);
  const liveIds = new Set(models.data.map((entry) => entry.id));
  const discovered = info.data.filter((entry) => liveIds.has(entry.model_name)).map(mapModel);
  if (discovered.length === 0) {
    throw new Error("proxy reported no models");
  }
  return discovered;
}

export default function (pi: ExtensionAPI) {
  pi.registerProvider(PROVIDER_ID, {
    name: "sipgate coding proxy",
    baseUrl: BASE_URL,
    apiKey: "$CODING_PROXY_LLM_KEY",
    api: "openai-completions",
    models: [],
    refreshModels: async (context) => {
      const storedModels =
        context.stored?.models.filter(
          (model) => !model.provider || model.provider === PROVIDER_ID,
        ) ?? [];
      // Offline phase (pi startup): restore the persisted snapshot, no network —
      // except once on the very first run when no snapshot exists yet.
      if (
        !context.allowNetwork &&
        (storedModels.length > 0 ||
          process.env.PI_OFFLINE !== undefined ||
          !process.env.CODING_PROXY_LLM_KEY)
      ) {
        return storedModels;
      }
      const refreshed = await discover(context.signal);
      await context.publish({
        // Persist the full model shape (api/provider/baseUrl included) so store
        // entries match the core providers' entries; the composer re-derives those
        // fields anyway when the snapshot is restored.
        persist: {
          models: refreshed.map((model) => ({
            ...model,
            api: "openai-completions",
            provider: PROVIDER_ID,
            baseUrl: BASE_URL,
          })),
          checkedAt: Date.now(),
        },
      });
      return refreshed;
    },
  });

  async function refresh(ctx: ExtensionContext): Promise<void> {
    try {
      const result = await ctx.modelRegistry.refresh({
        providers: [PROVIDER_ID],
        allowNetwork: true,
        signal: AbortSignal.timeout(REFRESH_TIMEOUT_MS),
      });
      const error = result.errors.get(PROVIDER_ID);
      if (error) {
        throw error;
      }
      if (result.aborted) {
        throw new Error("refresh timed out");
      }
      const count = ctx.modelRegistry.getProvider(PROVIDER_ID)?.getModels().length ?? 0;
      ctx.ui.notify(`sipgate proxy: ${count} models discovered`, "info");
    } catch (error) {
      ctx.ui.notify(
        `sipgate proxy refresh failed: ${error instanceof Error ? error.message : String(error)}`,
        "error",
      );
    }
  }

  pi.registerCommand("sipgate-refresh", {
    description: "Re-discover models from the sipgate coding proxy",
    handler: async (_args, ctx) => {
      await refresh(ctx);
    },
  });

  pi.on("session_start", async (_event, ctx) => {
    // Bootstrap only: fetch once when no snapshot exists yet. Later startups
    // restore from models-store.json during the offline refresh phase.
    const provider = ctx.modelRegistry.getProvider(PROVIDER_ID);
    if ((provider?.getModels().length ?? 0) === 0) {
      await refresh(ctx);
    }
  });
}

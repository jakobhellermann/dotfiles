// Auto-discovers models from the sipgate coding proxy (LiteLLM)
// Updates on first run an /sipgate-refresh.

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

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
		input_cost_per_token?: number;
		output_cost_per_token?: number;
		cache_read_input_token_cost?: number;
		cache_creation_input_token_cost?: number;
		[key: string]: unknown;
	};
}

interface DiscoveredModel {
	id: string;
	name: string;
	reasoning: boolean;
	thinkingLevelMap?: Record<string, string | null>;
	compat?: { supportsReasoningEffort: boolean };
	input: Array<"text" | "image">;
	cost: { input: number; output: number; cacheRead: number; cacheWrite: number };
	contextWindow: number;
	maxTokens: number;
}

function usdPerMillion(costPerToken: unknown): number {
	return typeof costPerToken === "number" ? costPerToken * 1_000_000 : 0;
}

function tieredCosts(mi: LitellmModelEntry["model_info"]): DiscoveredModel["cost"] {
	const base: DiscoveredModel["cost"] = {
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
				cacheRead: usdPerMillion(mi[`cache_read_input_token_cost_above_${k}k_tokens`]) || base.cacheRead,
				cacheWrite: usdPerMillion(mi[`cache_creation_input_token_cost_above_${k}k_tokens`]) || base.cacheWrite,
				inputTokensAbove: k * 1000,
			}));
		return { ...base, tiers };
	}
	return base;
}

// TODO: remove once coding-proxy advertises output caps that fit its own max_model_len
// (litellm rejects max_completion_tokens > max_model_len; /model/info still says 1M/1048576, see Slack #sipgateos-support 2026-09-09)
const MODEL_OVERRIDES: Record<string, Partial<DiscoveredModel>> = {
	"zai-org/GLM-5.3-verda": { maxTokens: 256000 },
	"sipgate-coding-pro": { maxTokens: 256000 },
	"zai-org/GLM-5.2-FP8": { maxTokens: 131072 },
};

function mapModel(entry: LitellmModelEntry): DiscoveredModel {
	const mi = entry.model_info;
	const reasoning = mi.supports_reasoning === true;
	const supportsReasoningEffort = (mi.supported_openai_params as string[] | undefined)?.includes("reasoning_effort") === true;
	const model: DiscoveredModel = {
		id: entry.model_name,
		name: entry.model_name,
		reasoning,
		input: mi.supports_vision === true ? ["text", "image"] : ["text"],
		cost: tieredCosts(mi),
		contextWindow: mi.max_input_tokens ?? mi.max_tokens ?? 128_000,
		maxTokens: mi.max_output_tokens ?? mi.max_tokens ?? 16_384,
	};
	// LiteLLM validates reasoning_effort against: minimal low medium high xhigh max none
	if (reasoning && supportsReasoningEffort) {
		model.thinkingLevelMap = { off: "none", minimal: "minimal", low: "low", medium: "medium", high: "high", xhigh: "xhigh", max: "max" };
		// LiteLLM's anthropic route rejects unknown params (e.g. the default store: false).
		model.compat = { supportsReasoningEffort: true, supportsStore: false };
	}
	return { ...model, ...MODEL_OVERRIDES[model.id] };
}

async function fetchJson(path: string, signal: AbortSignal): Promise<unknown> {
	const response = await fetch(`${BASE_URL}${path}`, {
		headers: { Authorization: `Bearer ${process.env.SIPGATE_CODING_PROXY_KEY ?? ""}` },
		signal: AbortSignal.any([signal, AbortSignal.timeout(REQUEST_TIMEOUT_MS)]),
	});
	if (!response.ok) {
		throw new Error(`${path} responded ${response.status}`);
	}
	return response.json();
}

async function discover(signal: AbortSignal): Promise<DiscoveredModel[]> {
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
		apiKey: "$SIPGATE_CODING_PROXY_KEY",
		api: "openai-completions",
		models: [],
		refreshModels: async (context) => {
			const storedModels = context.stored?.models.filter((model) => !model.provider || model.provider === PROVIDER_ID) ?? [];
			// Offline phase (pi startup): restore the persisted snapshot, no network —
			// except once on the very first run when no snapshot exists yet.
			if (!context.allowNetwork && (storedModels.length > 0 || process.env.PI_OFFLINE !== undefined || !process.env.SIPGATE_CODING_PROXY_KEY)) {
				return storedModels;
			}
			const refreshed = await discover(context.signal);
			await context.publish({
				persist: { models: refreshed, checkedAt: Date.now() },
			});
			return refreshed;
		},
	});

	async function refresh(ctx: { modelRegistry: { refresh: (options: object) => Promise<{ aborted: boolean; errors: Map<string, Error> }> }; ui: { notify: (message: string, level?: string) => void } }): Promise<void> {
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
			ctx.ui.notify(`sipgate proxy refresh failed: ${error instanceof Error ? error.message : String(error)}`, "error");
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

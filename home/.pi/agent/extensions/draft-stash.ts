import { mkdir, readFile, rename, unlink, writeFile } from "node:fs/promises";
import { homedir } from "node:os";
import { dirname, join } from "node:path";
import { CustomEditor, type ExtensionAPI, type ExtensionContext } from "@earendil-works/pi-coding-agent";
import { matchesKey } from "@earendil-works/pi-tui";

const agentDir = process.env.PI_CODING_AGENT_DIR ?? join(homedir(), ".pi", "agent");
const draftPath = join(agentDir, "drafts", "current.md");

function notify(ctx: ExtensionContext, message: string, level: "info" | "warning" | "error" = "info") {
	ctx.ui.notify(message, level);
}

function isTui(ctx: ExtensionContext): boolean {
	if (ctx.mode === "tui") return true;
	notify(ctx, "Draft stash shortcuts are only available in Pi's interactive TUI.", "warning");
	return false;
}

async function writeDraft(text: string): Promise<void> {
	const directory = dirname(draftPath);
	await mkdir(directory, { recursive: true });

	const temporaryPath = join(
		directory,
		`.current-${process.pid}-${Date.now()}.tmp`,
	);

	try {
		await writeFile(temporaryPath, text, "utf8");
		await rename(temporaryPath, draftPath);
	} finally {
		await unlink(temporaryPath).catch(() => undefined);
	}
}

async function stashDraft(ctx: ExtensionContext): Promise<void> {
	if (!isTui(ctx)) return;

	const text = ctx.ui.getEditorText();
	if (!text.trim()) {
		notify(ctx, "The prompt editor is empty; nothing to stash.", "warning");
		return;
	}

	try {
		await writeDraft(text);
		ctx.ui.setEditorText("");
		notify(ctx, "Draft stashed and editor cleared.");
	} catch (error) {
		const message = error instanceof Error ? error.message : String(error);
		notify(ctx, `Could not stash draft: ${message}`, "error");
	}
}

async function restoreDraft(ctx: ExtensionContext): Promise<void> {
	if (!isTui(ctx)) return;

	if (ctx.ui.getEditorText().trim()) {
		notify(ctx, "The prompt editor is not empty; stash or clear it before restoring.", "warning");
		return;
	}

	try {
		const text = await readFile(draftPath, "utf8");
		if (!text.trim()) {
			notify(ctx, "The stashed draft is empty.", "warning");
			return;
		}

		ctx.ui.setEditorText(text);
		notify(ctx, "Stashed draft restored.");
	} catch (error) {
		const code = error && typeof error === "object" && "code" in error ? error.code : undefined;
		if (code === "ENOENT") {
			notify(ctx, "No stashed draft found.", "warning");
			return;
		}

		const message = error instanceof Error ? error.message : String(error);
		notify(ctx, `Could not restore draft: ${message}`, "error");
	}
}

type ChordAction = "app.model.select" | "app.session.resume" | "app.session.new";

const CHORD_ACTIONS: Record<string, ChordAction> = {
	m: "app.model.select",
	l: "app.session.resume",
	n: "app.session.new",
};

class ChordEditor extends CustomEditor {
	private chordExpiresAt = 0;

	handleInput(data: string): void {
		if (matchesKey(data, "ctrl+x")) {
			this.chordExpiresAt = Date.now() + 1500;
			return;
		}

		if (this.chordExpiresAt !== 0) {
			const isActive = Date.now() <= this.chordExpiresAt;
			this.chordExpiresAt = 0;

			const action = isActive ? CHORD_ACTIONS[data.toLowerCase()] : undefined;
			if (action) {
				this.actionHandlers.get(action)?.();
				return;
			}
		}

		super.handleInput(data);
	}
}

export default function (pi: ExtensionAPI) {
	pi.on("session_start", (_event, ctx) => {
		if (ctx.mode !== "tui") return;

		ctx.ui.setEditorComponent((tui, theme, keybindings) =>
			new ChordEditor(tui, theme, keybindings),
		);
	});

	pi.registerShortcut("ctrl+s", {
		description: "Stash the current prompt and clear the editor",
		handler: async (ctx) => {
			await stashDraft(ctx);
		},
	});

	pi.registerShortcut("ctrl+r", {
		description: "Restore the stashed prompt",
		handler: async (ctx) => {
			await restoreDraft(ctx);
		},
	});

	pi.registerCommand("stash", {
		description: "Stash the current prompt and clear the editor",
		handler: async (_args, ctx) => {
			await stashDraft(ctx);
		},
	});

	pi.registerCommand("restore", {
		description: "Restore the stashed prompt",
		handler: async (_args, ctx) => {
			await restoreDraft(ctx);
		},
	});

	pi.registerCommand("exit", {
		description: "Exit pi cleanly",
		handler: async (_args, ctx) => {
			ctx.shutdown();
		},
	});
}

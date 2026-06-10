#!/usr/bin/env node
import { runMcpServer } from "./mcpServer.js";
import { parseMode } from "./toolRegistry.js";

const port = Number(process.env.GODOT_MCP_PORT ?? getFlagValue("--port") ?? 6505);
const host = process.env.GODOT_MCP_HOST ?? getFlagValue("--host") ?? "127.0.0.1";
const mode = parseMode(process.argv.slice(2));

runMcpServer({ mode, port, host }).catch((error) => {
  console.error(error instanceof Error ? error.message : String(error));
  process.exit(1);
});

function getFlagValue(flag: string): string | undefined {
  const index = process.argv.indexOf(flag);
  if (index === -1) return undefined;
  return process.argv[index + 1];
}

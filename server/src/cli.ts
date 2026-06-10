#!/usr/bin/env node
import { GodotClient } from "./godotClient.js";
import {
  getCliAlias,
  getToolsForMode,
  parseMode,
  resolveCliTool,
  toolsByGroup
} from "./toolRegistry.js";

const args = process.argv.slice(2);
const mode = parseMode(args);
const port = Number(process.env.GODOT_MCP_CLI_PORT ?? process.env.GODOT_MCP_PORT ?? getFlagValue("--port") ?? 6510);
const host = process.env.GODOT_MCP_HOST ?? getFlagValue("--host") ?? "127.0.0.1";

if (args.includes("--help") || args.includes("-h") || args.length === 0) {
  printHelp();
  process.exit(0);
}

if (args.includes("--list")) {
  printGroups();
  process.exit(0);
}

const tool = resolveCliTool(args);
if (!tool) {
  console.error("Unknown command. Run with --help or --list.");
  process.exit(2);
}

const params = parseParams(args);
const client = new GodotClient({ port, host });

try {
  await client.start();
  const result = await client.call(tool.name, params);
  console.log(JSON.stringify(result, null, 2));
} finally {
  await client.close();
}

function printHelp(): void {
  console.log(`Godot MCP Pro CLI

Usage:
  node build/cli.js --list
  node build/cli.js <tool_name> [--json '{"key":"value"}']
  node build/cli.js <group> <command> [--key value]

Examples:
  node build/cli.js project info
  node build/cli.js scene play --mode current
  node build/cli.js node add --type CharacterBody3D --name Player
  node build/cli.js get_project_info

Options:
  --port <number>     WebSocket port. Defaults to 6510 for CLI.
  --host <host>       WebSocket host. Defaults to 127.0.0.1.
  --json <object>     JSON object forwarded as command params.
  --minimal           Use the minimal tool set in help/list output.
  --lite              Use the lite tool set in help/list output.
  --3d                Use the 3D-oriented tool set in help/list output.
`);
}

function printGroups(): void {
  for (const [group, tools] of toolsByGroup(getToolsForMode(mode))) {
    console.log(`\n${group}`);
    for (const tool of tools) {
      console.log(`  ${getCliAlias(group, tool.name).padEnd(28)} ${tool.name}`);
    }
  }
}

function parseParams(argv: string[]): Record<string, unknown> {
  const json = getFlagValue("--json");
  if (json) {
    const parsed = JSON.parse(json);
    if (!isObject(parsed)) throw new Error("--json must be a JSON object");
    return parsed;
  }

  const params: Record<string, unknown> = {};
  const positional = new Set(resolveCliTool(argv) ? argv.slice(0, resolveCliTool(argv)?.name === argv[0] ? 1 : 2) : []);
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    if (positional.has(arg) || !arg.startsWith("--")) continue;
    if (["--port", "--host", "--minimal", "--lite", "--3d"].includes(arg)) {
      if (arg === "--port" || arg === "--host") i++;
      continue;
    }
    const key = arg.slice(2).replaceAll("-", "_");
    const value = argv[i + 1];
    if (value === undefined || value.startsWith("--")) {
      params[key] = true;
      continue;
    }
    params[key] = parseScalar(value);
    i++;
  }
  return params;
}

function parseScalar(value: string): unknown {
  if (value === "true") return true;
  if (value === "false") return false;
  if (/^-?\d+$/.test(value)) return Number(value);
  if (/^-?\d+\.\d+$/.test(value)) return Number(value);
  if ((value.startsWith("{") && value.endsWith("}")) || (value.startsWith("[") && value.endsWith("]"))) {
    return JSON.parse(value);
  }
  return value;
}

function getFlagValue(flag: string): string | undefined {
  const index = args.indexOf(flag);
  if (index === -1) return undefined;
  return args[index + 1];
}

function isObject(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

import { existsSync, readdirSync, readFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

export type ToolMode = "full" | "3d" | "lite" | "minimal";

export interface ToolDefinition {
  name: string;
  group: string;
  description: string;
  inputSchema: {
    type: "object";
    properties: Record<string, unknown>;
    additionalProperties: boolean;
  };
}

const GROUP_LABELS: Record<string, string> = {
  analysis: "analysis and project health",
  android: "Android deployment",
  animation: "AnimationPlayer editing",
  animation_tree: "AnimationTree and state machine editing",
  audio: "audio bus and player editing",
  batch: "batch scene and refactoring operations",
  editor: "Godot editor automation",
  export: "export preset inspection",
  input: "runtime input simulation",
  input_map: "InputMap configuration",
  navigation: "navigation mesh and agent setup",
  node: "node tree editing",
  particle: "particle system editing",
  physics: "physics body and collision setup",
  profiling: "performance and profiling inspection",
  project: "project inspection and settings",
  resource: "resource file editing",
  runtime: "running game inspection and control",
  scene: "scene file and editor scene management",
  scene_3d: "3D scene construction",
  script: "GDScript file editing",
  shader: "shader resource editing",
  test: "automated playtest and assertions",
  theme: "theme and UI styling",
  tilemap: "TileMap editing"
};

const MINIMAL_TOOLS = new Set([
  "get_project_info",
  "get_filesystem_tree",
  "search_files",
  "get_scene_tree",
  "create_scene",
  "open_scene",
  "play_scene",
  "stop_scene",
  "save_scene",
  "add_node",
  "delete_node",
  "duplicate_node",
  "move_node",
  "update_property",
  "get_node_properties",
  "rename_node",
  "add_resource",
  "read_script",
  "create_script",
  "edit_script",
  "attach_script",
  "validate_script",
  "get_editor_errors",
  "get_output_log",
  "reload_project",
  "get_game_screenshot",
  "simulate_key",
  "simulate_mouse_click",
  "simulate_mouse_move",
  "simulate_action",
  "get_game_scene_tree",
  "get_game_node_properties",
  "set_game_node_property",
  "execute_game_script",
  "wait_for_node"
]);

const LITE_GROUPS = new Set([
  "project",
  "scene",
  "node",
  "script",
  "editor",
  "input",
  "runtime",
  "input_map"
]);

const THREE_D_GROUPS = new Set([
  ...LITE_GROUPS,
  "scene_3d",
  "physics",
  "navigation",
  "shader",
  "resource",
  "profiling"
]);

const COMMAND_RE = /"([a-z][a-z0-9_]*)"\s*:\s*_[a-zA-Z0-9_]+/g;

export const TOOL_DEFINITIONS: ToolDefinition[] = loadToolDefinitions();

export function getToolsForMode(mode: ToolMode): ToolDefinition[] {
  switch (mode) {
    case "minimal":
      return TOOL_DEFINITIONS.filter((tool) => MINIMAL_TOOLS.has(tool.name));
    case "lite":
      return TOOL_DEFINITIONS.filter((tool) => LITE_GROUPS.has(tool.group));
    case "3d":
      return TOOL_DEFINITIONS.filter((tool) => THREE_D_GROUPS.has(tool.group));
    case "full":
    default:
      return TOOL_DEFINITIONS;
  }
}

export function parseMode(argv: string[]): ToolMode {
  if (argv.includes("--minimal")) return "minimal";
  if (argv.includes("--lite")) return "lite";
  if (argv.includes("--3d")) return "3d";
  return "full";
}

export function getCliAlias(group: string, toolName: string): string {
  const prefixes = [
    `get_${group}_`,
    `set_${group}_`,
    `create_${group}_`,
    `delete_${group}_`,
    `read_${group}_`,
    `edit_${group}_`,
    `list_${group}_`,
    `add_${group}_`,
    `setup_${group}_`,
    `${group}_get_`,
    `${group}_set_`,
    `${group}_`
  ];

  for (const prefix of prefixes) {
    if (toolName.startsWith(prefix)) return toCliName(toolName.slice(prefix.length));
  }

  const suffixes = [`_${group}`, "_3d"];
  for (const suffix of suffixes) {
    if (toolName.endsWith(suffix)) return toCliName(toolName.slice(0, -suffix.length));
  }

  for (const prefix of [
    "get_",
    "set_",
    "create_",
    "delete_",
    "read_",
    "edit_",
    "list_",
    "add_",
    "setup_",
    "run_",
    "assert_",
    "compare_",
    "capture_",
    "monitor_",
    "start_",
    "stop_",
    "replay_",
    "find_",
    "analyze_",
    "detect_",
    "execute_",
    "validate_",
    "attach_",
    "open_",
    "save_"
  ]) {
    if (toolName.startsWith(prefix)) return toCliName(toolName.slice(prefix.length));
  }

  return toCliName(toolName);
}

export function resolveCliTool(args: string[]): ToolDefinition | undefined {
  const positional = args.filter((arg) => !arg.startsWith("--"));
  if (positional.length === 0) return undefined;

  if (positional.length === 1) {
    return TOOL_DEFINITIONS.find((tool) => tool.name === positional[0]);
  }

  const [group, command] = positional;
  return TOOL_DEFINITIONS.find((tool) => {
    return tool.group === group && getCliAlias(tool.group, tool.name) === command;
  });
}

export function toolsByGroup(tools = TOOL_DEFINITIONS): Map<string, ToolDefinition[]> {
  const grouped = new Map<string, ToolDefinition[]>();
  for (const tool of tools) {
    grouped.set(tool.group, [...(grouped.get(tool.group) ?? []), tool]);
  }
  return grouped;
}

function loadToolDefinitions(): ToolDefinition[] {
  const addonPath = resolveAddonPath();
  const commandsPath = join(addonPath, "commands");
  const files = readdirSync(commandsPath)
    .filter((file) => file.endsWith("_commands.gd"))
    .sort();

  const definitions: ToolDefinition[] = [];
  for (const file of files) {
    const group = file.replace(/_commands\.gd$/, "");
    const source = readFileSync(join(commandsPath, file), "utf8");
    for (const name of extractCommandNames(source)) {
      definitions.push({
        name,
        group,
        description: describeTool(name, group),
        inputSchema: {
          type: "object",
          properties: {},
          additionalProperties: true
        }
      });
    }
  }

  return definitions.sort((a, b) => a.group.localeCompare(b.group) || a.name.localeCompare(b.name));
}

function extractCommandNames(source: string): string[] {
  const start = source.indexOf("func get_commands()");
  if (start === -1) return [];
  const returnStart = source.indexOf("return {", start);
  if (returnStart === -1) return [];
  const blockEnd = source.indexOf("\n\t}", returnStart);
  const commandBlock = blockEnd === -1 ? source.slice(returnStart) : source.slice(returnStart, blockEnd);

  const names: string[] = [];
  for (const match of commandBlock.matchAll(COMMAND_RE)) {
    names.push(match[1]);
  }
  return names;
}

function describeTool(name: string, group: string): string {
  const label = GROUP_LABELS[group] ?? `${group} operations`;
  return `Run the Godot MCP Pro ${label} command '${name}'. Parameters are forwarded to the Godot editor addon as JSON.`;
}

function resolveAddonPath(): string {
  const envPath = process.env.GODOT_MCP_ADDON_PATH;
  const buildDir = dirname(fileURLToPath(import.meta.url));
  const serverRoot = resolve(buildDir, "..");
  const candidates = [
    envPath,
    join(process.cwd(), "addons", "godot_mcp"),
    join(process.cwd(), "hacker-quest", "addons", "godot_mcp"),
    join(serverRoot, "..", "addons", "godot_mcp"),
    join(serverRoot, "..", "hacker-quest", "addons", "godot_mcp")
  ].filter((candidate): candidate is string => Boolean(candidate));

  for (const candidate of candidates) {
    const absolute = resolve(candidate);
    if (existsSync(join(absolute, "commands"))) return absolute;
  }

  throw new Error(
    "Could not find addons/godot_mcp. Set GODOT_MCP_ADDON_PATH to the installed addon directory."
  );
}

function toCliName(name: string): string {
  return name.replaceAll("_", "-");
}

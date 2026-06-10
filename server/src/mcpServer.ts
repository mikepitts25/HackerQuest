import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema
} from "@modelcontextprotocol/sdk/types.js";
import { GodotClient, GodotRpcError } from "./godotClient.js";
import { getToolsForMode, ToolMode } from "./toolRegistry.js";

export interface McpServerOptions {
  mode: ToolMode;
  port: number;
  host?: string;
}

export async function runMcpServer(options: McpServerOptions): Promise<void> {
  const godot = new GodotClient({
    port: options.port,
    host: options.host,
    requestTimeoutMs: Number(process.env.GODOT_MCP_REQUEST_TIMEOUT_MS ?? 120_000),
    connectionTimeoutMs: Number(process.env.GODOT_MCP_CONNECTION_TIMEOUT_MS ?? 30_000)
  });
  await godot.start();

  const server = new Server(
    {
      name: "godot-mcp-pro",
      version: "0.1.0"
    },
    {
      capabilities: {
        tools: {}
      }
    }
  );

  const tools = getToolsForMode(options.mode);

  server.setRequestHandler(ListToolsRequestSchema, async () => ({
    tools: tools.map((tool) => ({
      name: tool.name,
      description: tool.description,
      inputSchema: tool.inputSchema
    }))
  }));

  server.setRequestHandler(CallToolRequestSchema, async (request) => {
    const tool = tools.find((candidate) => candidate.name === request.params.name);
    if (!tool) {
      return {
        isError: true,
        content: [{
          type: "text",
          text: `Tool '${request.params.name}' is not enabled in ${options.mode} mode.`
        }]
      };
    }

    try {
      const result = await godot.call(tool.name, toObject(request.params.arguments));
      return {
        content: [{
          type: "text",
          text: JSON.stringify(result, null, 2)
        }],
        structuredContent: isObject(result) ? result : { value: result }
      };
    } catch (error) {
      return {
        isError: true,
        content: [{
          type: "text",
          text: formatError(error)
        }]
      };
    }
  });

  process.on("SIGINT", async () => {
    await godot.close();
    process.exit(0);
  });
  process.on("SIGTERM", async () => {
    await godot.close();
    process.exit(0);
  });

  const transport = new StdioServerTransport();
  await server.connect(transport);
}

function toObject(value: unknown): Record<string, unknown> {
  return isObject(value) ? value : {};
}

function isObject(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function formatError(error: unknown): string {
  if (error instanceof GodotRpcError) {
    const suffix = error.data === undefined ? "" : `\n${JSON.stringify(error.data, null, 2)}`;
    return `Godot RPC error ${error.code}: ${error.message}${suffix}`;
  }
  if (error instanceof Error) return error.message;
  return String(error);
}

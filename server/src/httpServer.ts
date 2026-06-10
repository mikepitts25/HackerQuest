#!/usr/bin/env node
import { createServer } from "node:http";
import { StreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/streamableHttp.js";
import { createMcpExpressApp } from "@modelcontextprotocol/sdk/server/express.js";
import type { Request, Response } from "express";
import { GodotClient } from "./godotClient.js";
import { createMcpServer } from "./mcpServer.js";
import { parseMode, ToolMode } from "./toolRegistry.js";

export interface HttpAppOptions {
  mode: ToolMode;
  godot: GodotClient;
  allowedHosts?: string[];
}

export function createHttpApp(options: HttpAppOptions) {
  const app = createMcpExpressApp({
    host: "0.0.0.0",
    allowedHosts: options.allowedHosts
  });

  app.get("/health", (_req: Request, res: Response) => {
    res.json({ ok: true, name: "godot-mcp-pro" });
  });

  app.post("/mcp", async (req: Request, res: Response) => {
    const server = createMcpServer({ mode: options.mode, godot: options.godot });
    const transport = new StreamableHTTPServerTransport({
      sessionIdGenerator: undefined,
      enableJsonResponse: true
    });

    try {
      await server.connect(transport);
      await transport.handleRequest(req, res, req.body);
      res.on("close", () => {
        transport.close().catch(() => undefined);
        server.close().catch(() => undefined);
      });
    } catch (error) {
      if (!res.headersSent) {
        res.status(500).json({
          jsonrpc: "2.0",
          error: {
            code: -32603,
            message: error instanceof Error ? error.message : "Internal server error"
          },
          id: null
        });
      }
    }
  });

  app.get("/mcp", (_req: Request, res: Response) => {
    res.status(405).json({
      jsonrpc: "2.0",
      error: { code: -32000, message: "Method not allowed. Use POST for Streamable HTTP." },
      id: null
    });
  });

  app.delete("/mcp", (_req: Request, res: Response) => {
    res.status(405).json({
      jsonrpc: "2.0",
      error: { code: -32000, message: "Method not allowed." },
      id: null
    });
  });

  return app;
}

export async function runHttpServer(): Promise<void> {
  const args = process.argv.slice(2);
  const mode = parseMode(args);
  const httpPort = Number(process.env.GODOT_MCP_HTTP_PORT ?? getFlagValue(args, "--http-port") ?? 3000);
  const httpHost = process.env.GODOT_MCP_HTTP_HOST ?? getFlagValue(args, "--http-host") ?? "127.0.0.1";
  const godotPort = Number(process.env.GODOT_MCP_PORT ?? getFlagValue(args, "--godot-port") ?? 6505);
  const godotHost = process.env.GODOT_MCP_HOST ?? getFlagValue(args, "--godot-host") ?? "127.0.0.1";
  const allowedHosts = (process.env.GODOT_MCP_ALLOWED_HOSTS ?? getFlagValue(args, "--allowed-hosts") ?? "")
    .split(",")
    .map((host) => host.trim())
    .filter(Boolean);

  const godot = new GodotClient({
    port: godotPort,
    host: godotHost,
    requestTimeoutMs: Number(process.env.GODOT_MCP_REQUEST_TIMEOUT_MS ?? 120_000),
    connectionTimeoutMs: Number(process.env.GODOT_MCP_CONNECTION_TIMEOUT_MS ?? 30_000)
  });
  await godot.start();

  const app = createHttpApp({ mode, godot, allowedHosts: allowedHosts.length ? allowedHosts : undefined });
  const server = createServer(app);

  await new Promise<void>((resolve, reject) => {
    server.once("error", reject);
    server.listen(httpPort, httpHost, resolve);
  });

  console.error(`Godot MCP Pro HTTP server listening at http://${httpHost}:${httpPort}/mcp`);
  console.error(`Waiting for Godot addon WebSocket connection on ws://${godotHost}:${godotPort}`);

  const shutdown = async () => {
    await godot.close();
    await new Promise<void>((resolve, reject) => {
      server.close((error) => (error ? reject(error) : resolve()));
    });
    process.exit(0);
  };
  process.on("SIGINT", shutdown);
  process.on("SIGTERM", shutdown);
}

if (import.meta.url === `file://${process.argv[1]}`) {
  runHttpServer().catch((error) => {
    console.error(error instanceof Error ? error.message : String(error));
    process.exit(1);
  });
}

function getFlagValue(args: string[], flag: string): string | undefined {
  const index = args.indexOf(flag);
  if (index === -1) return undefined;
  return args[index + 1];
}

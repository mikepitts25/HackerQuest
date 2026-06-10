import { createServer, Server } from "node:http";
import { AddressInfo } from "node:net";
import WebSocket from "ws";
import { afterEach, describe, expect, it } from "vitest";
import { GodotClient } from "./godotClient.js";
import { createHttpApp } from "./httpServer.js";

describe("HTTP MCP server", () => {
  let httpServer: Server | undefined;
  let godot: GodotClient | undefined;
  let godotSocket: WebSocket | undefined;

  afterEach(async () => {
    godotSocket?.close();
    await godot?.close();
    await new Promise<void>((resolve, reject) => {
      if (!httpServer?.listening) return resolve();
      httpServer.close((error) => (error ? reject(error) : resolve()));
    });
  });

  it("serves MCP tool listing over streamable HTTP", async () => {
    godot = new GodotClient({ port: 0, requestTimeoutMs: 1000, connectionTimeoutMs: 1000 });
    await godot.start();

    const wsPort = (godot.address() as AddressInfo).port;
    godotSocket = new WebSocket(`ws://127.0.0.1:${wsPort}`);
    await new Promise<void>((resolve, reject) => {
      godotSocket?.once("open", resolve);
      godotSocket?.once("error", reject);
    });

    const app = createHttpApp({ mode: "minimal", godot });
    httpServer = createServer(app);
    await new Promise<void>((resolve) => httpServer?.listen(0, "127.0.0.1", resolve));
    const httpPort = (httpServer.address() as AddressInfo).port;

    const initialize = await postJson(httpPort, {
      jsonrpc: "2.0",
      id: 1,
      method: "initialize",
      params: {
        protocolVersion: "2025-06-18",
        capabilities: {},
        clientInfo: { name: "test-client", version: "0.0.0" }
      }
    });

    expect(initialize.status).toBe(200);
    expect(initialize.body.result.serverInfo.name).toBe("godot-mcp-pro");

    const tools = await postJson(httpPort, {
      jsonrpc: "2.0",
      id: 2,
      method: "tools/list",
      params: {}
    });

    expect(tools.status).toBe(200);
    expect(tools.body.result.tools.map((tool: { name: string }) => tool.name)).toContain("get_project_info");
  });
});

async function postJson(port: number, body: unknown): Promise<{ status: number; body: any }> {
  const response = await fetch(`http://127.0.0.1:${port}/mcp`, {
    method: "POST",
    headers: {
      "content-type": "application/json",
      accept: "application/json, text/event-stream"
    },
    body: JSON.stringify(body)
  });
  return { status: response.status, body: await response.json() };
}

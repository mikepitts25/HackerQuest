import { AddressInfo } from "node:net";
import WebSocket from "ws";
import { afterEach, describe, expect, it } from "vitest";
import { GodotClient, GodotRpcError } from "./godotClient.js";

const open = (socket: WebSocket) =>
  new Promise<void>((resolve, reject) => {
    socket.once("open", () => resolve());
    socket.once("error", reject);
  });

describe("GodotClient", () => {
  let client: GodotClient | undefined;
  let godotSocket: WebSocket | undefined;

  afterEach(async () => {
    godotSocket?.close();
    await client?.close();
  });

  it("forwards JSON-RPC calls to the connected Godot plugin", async () => {
    client = new GodotClient({ port: 0, requestTimeoutMs: 1000, connectionTimeoutMs: 1000 });
    await client.start();
    const port = (client.address() as AddressInfo).port;
    godotSocket = new WebSocket(`ws://127.0.0.1:${port}`);

    godotSocket.on("message", (raw) => {
      const request = JSON.parse(raw.toString());
      godotSocket?.send(JSON.stringify({
        jsonrpc: "2.0",
        id: request.id,
        result: { ok: true, method: request.method, params: request.params }
      }));
    });

    await open(godotSocket);
    const result = await client.call("get_project_info", { verbose: true });

    expect(result).toEqual({
      ok: true,
      method: "get_project_info",
      params: { verbose: true }
    });
  });

  it("maps Godot JSON-RPC errors to typed errors", async () => {
    client = new GodotClient({ port: 0, requestTimeoutMs: 1000, connectionTimeoutMs: 1000 });
    await client.start();
    const port = (client.address() as AddressInfo).port;
    godotSocket = new WebSocket(`ws://127.0.0.1:${port}`);

    godotSocket.on("message", (raw) => {
      const request = JSON.parse(raw.toString());
      godotSocket?.send(JSON.stringify({
        jsonrpc: "2.0",
        id: request.id,
        error: { code: -32601, message: `Method not found: ${request.method}` }
      }));
    });

    await open(godotSocket);

    await expect(client.call("missing_tool", {})).rejects.toMatchObject({
      code: -32601,
      message: "Method not found: missing_tool"
    } satisfies Partial<GodotRpcError>);
  });
});

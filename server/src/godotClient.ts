import { AddressInfo } from "node:net";
import { WebSocketServer, WebSocket } from "ws";

export interface GodotClientOptions {
  port: number;
  host?: string;
  requestTimeoutMs?: number;
  connectionTimeoutMs?: number;
  heartbeatIntervalMs?: number;
}

export class GodotRpcError extends Error {
  readonly code: number;
  readonly data?: unknown;

  constructor(code: number, message: string, data?: unknown) {
    super(message);
    this.name = "GodotRpcError";
    this.code = code;
    this.data = data;
  }
}

interface PendingRequest {
  resolve: (value: unknown) => void;
  reject: (error: Error) => void;
  timer: NodeJS.Timeout;
}

export class GodotClient {
  private readonly host: string;
  private readonly port: number;
  private readonly requestTimeoutMs: number;
  private readonly connectionTimeoutMs: number;
  private readonly heartbeatIntervalMs: number;
  private server?: WebSocketServer;
  private socket?: WebSocket;
  private nextId = 1;
  private pending = new Map<number, PendingRequest>();
  private heartbeat?: NodeJS.Timeout;

  constructor(options: GodotClientOptions) {
    this.host = options.host ?? "127.0.0.1";
    this.port = options.port;
    this.requestTimeoutMs = options.requestTimeoutMs ?? 120_000;
    this.connectionTimeoutMs = options.connectionTimeoutMs ?? 30_000;
    this.heartbeatIntervalMs = options.heartbeatIntervalMs ?? 10_000;
  }

  async start(): Promise<void> {
    if (this.server) return;
    this.server = new WebSocketServer({ host: this.host, port: this.port });
    this.server.on("connection", (socket) => this.accept(socket));
    await new Promise<void>((resolve, reject) => {
      this.server?.once("listening", resolve);
      this.server?.once("error", reject);
    });
  }

  address(): AddressInfo | string | null {
    return this.server?.address() ?? null;
  }

  async call(method: string, params: Record<string, unknown>): Promise<unknown> {
    const socket = await this.waitForConnection();
    const id = this.nextId++;
    const request = { jsonrpc: "2.0", id, method, params };

    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => {
        this.pending.delete(id);
        reject(new Error(`Timed out waiting for Godot response to '${method}'`));
      }, this.requestTimeoutMs);

      this.pending.set(id, { resolve, reject, timer });
      socket.send(JSON.stringify(request), (error) => {
        if (error) {
          clearTimeout(timer);
          this.pending.delete(id);
          reject(error);
        }
      });
    });
  }

  async close(): Promise<void> {
    if (this.heartbeat) {
      clearInterval(this.heartbeat);
      this.heartbeat = undefined;
    }

    for (const [id, pending] of this.pending.entries()) {
      clearTimeout(pending.timer);
      pending.reject(new Error(`Connection closed before response ${id}`));
    }
    this.pending.clear();

    this.socket?.close();
    this.socket = undefined;

    if (!this.server) return;
    const server = this.server;
    this.server = undefined;
    await new Promise<void>((resolve, reject) => {
      server.close((error) => (error ? reject(error) : resolve()));
    });
  }

  private accept(socket: WebSocket): void {
    this.socket?.close(1000, "New Godot MCP connection accepted");
    this.socket = socket;

    socket.on("message", (raw) => this.handleMessage(raw.toString()));
    socket.on("close", () => {
      if (this.socket === socket) this.socket = undefined;
    });
    socket.on("error", (error) => {
      for (const pending of this.pending.values()) {
        clearTimeout(pending.timer);
        pending.reject(error);
      }
      this.pending.clear();
    });

    this.startHeartbeat();
  }

  private handleMessage(text: string): void {
    let message: Record<string, unknown>;
    try {
      message = JSON.parse(text) as Record<string, unknown>;
    } catch {
      return;
    }

    if (message.method === "ping") {
      this.socket?.send(JSON.stringify({ jsonrpc: "2.0", method: "pong", params: {} }));
      return;
    }
    if (message.method === "pong") return;

    const id = typeof message.id === "number" ? message.id : undefined;
    if (id === undefined) return;

    const pending = this.pending.get(id);
    if (!pending) return;
    this.pending.delete(id);
    clearTimeout(pending.timer);

    if (message.error && typeof message.error === "object") {
      const error = message.error as { code?: unknown; message?: unknown; data?: unknown };
      pending.reject(new GodotRpcError(
        typeof error.code === "number" ? error.code : -32603,
        typeof error.message === "string" ? error.message : "Godot MCP command failed",
        error.data
      ));
      return;
    }

    pending.resolve(message.result ?? {});
  }

  private waitForConnection(): Promise<WebSocket> {
    if (this.socket?.readyState === WebSocket.OPEN) return Promise.resolve(this.socket);

    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => {
        cleanup();
        reject(new Error(
          `Godot editor is not connected. Start Godot with the MCP plugin enabled; it should connect to ws://${this.host}:${this.port}.`
        ));
      }, this.connectionTimeoutMs);

      const onConnection = (socket: WebSocket) => {
        cleanup();
        resolve(socket);
      };
      const onError = (error: Error) => {
        cleanup();
        reject(error);
      };
      const cleanup = () => {
        clearTimeout(timer);
        this.server?.off("connection", onConnection);
        this.server?.off("error", onError);
      };

      this.server?.on("connection", onConnection);
      this.server?.on("error", onError);
    });
  }

  private startHeartbeat(): void {
    if (this.heartbeat) clearInterval(this.heartbeat);
    this.heartbeat = setInterval(() => {
      if (this.socket?.readyState === WebSocket.OPEN) {
        this.socket.send(JSON.stringify({ jsonrpc: "2.0", method: "ping", params: {} }));
      }
    }, this.heartbeatIntervalMs);
  }
}

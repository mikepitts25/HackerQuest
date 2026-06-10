# Godot MCP Pro Server

Node.js MCP server for the installed `addons/godot_mcp` Godot editor addon.

The addon is a WebSocket client. This server listens on a port, accepts the Godot editor connection, and exposes the addon's commands as MCP tools over stdio.

## Install

```sh
cd server
npm install
npm run build
```

## Configure an MCP Client

```json
{
  "mcpServers": {
    "godot-mcp-pro": {
      "command": "node",
      "args": ["/Users/mike/AppIdeas/HackerQuest/hacker-quest/server/build/index.js"],
      "env": {
        "GODOT_MCP_PORT": "6505"
      }
    }
  }
}
```

Open the Godot project, enable the Godot MCP Pro plugin, then start the MCP client. The plugin connects to ports `6505-6514`.

## Remote Connector URL

Claude's "Add custom connector" screen needs a public HTTPS URL for a remote MCP server. Start the optional Streamable HTTP transport, then expose it with a tunnel:

```sh
cd server
npm run build
node build/httpServer.js --http-port 3000 --godot-port 6505
```

The local MCP endpoint is:

```text
http://127.0.0.1:3000/mcp
```

For Claude's remote connector field, expose that endpoint with a trusted tunnel and use the public HTTPS URL ending in `/mcp`, for example:

```text
https://your-tunnel-host.example/mcp
```

Do not expose this without understanding the risk: these tools can modify your Godot project and control the running editor.

## Modes

Pass one of these flags in `args` after `build/index.js`:

- `--minimal`: 35 essential tools.
- `--lite`: project, scene, node, script, editor, input, runtime, and input map tools.
- `--3d`: lite plus core 3D, physics, navigation, shader, resource, and profiling tools.
- no flag: all tools discovered from the installed addon.

## CLI

The CLI is useful for clients without MCP support. It defaults to port `6510`.

```sh
node build/cli.js --list
node build/cli.js project info
node build/cli.js scene play --mode current
node build/cli.js node add --type CharacterBody3D --name Player
node build/cli.js get_project_info
```

If the server is moved away from this project layout, set `GODOT_MCP_ADDON_PATH` to the absolute `addons/godot_mcp` directory.

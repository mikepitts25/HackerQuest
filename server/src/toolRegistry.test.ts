import { describe, expect, it } from "vitest";
import {
  getCliAlias,
  getToolsForMode,
  resolveCliTool,
  TOOL_DEFINITIONS
} from "./toolRegistry.js";

describe("tool registry", () => {
  it("loads the full addon command surface", () => {
    expect(TOOL_DEFINITIONS).toHaveLength(171);
    expect(TOOL_DEFINITIONS.map((tool) => tool.name)).toContain("get_project_info");
    expect(TOOL_DEFINITIONS.map((tool) => tool.name)).toContain("deploy_to_android");
  });

  it("filters tools by client mode", () => {
    expect(getToolsForMode("full")).toHaveLength(171);
    expect(getToolsForMode("minimal")).toHaveLength(35);
    expect(getToolsForMode("lite").length).toBeLessThan(getToolsForMode("full").length);
    expect(getToolsForMode("lite").map((tool) => tool.name)).toContain("get_game_scene_tree");
    expect(getToolsForMode("lite").map((tool) => tool.name)).not.toContain("deploy_to_android");
    expect(getToolsForMode("3d").map((tool) => tool.name)).toContain("add_mesh_instance");
  });

  it("resolves ergonomic CLI aliases", () => {
    expect(getCliAlias("project", "get_project_info")).toBe("info");
    expect(resolveCliTool(["project", "info"])?.name).toBe("get_project_info");
    expect(resolveCliTool(["node", "add"])?.name).toBe("add_node");
    expect(resolveCliTool(["get_project_info"])?.name).toBe("get_project_info");
  });
});

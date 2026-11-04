extends RefCounted
## Authored clusters leave exits, quest targets, caches, and combat spawns free.
const ROOT := "res://assets/iso/props/city/prop_"
const PLACEMENTS := {
	"plaza": [
		["transit_shelter", Vector2(30, 42), 0],
		["vending_machine", Vector2(32.5, 41.5), -20],
		["vending_machine", Vector2(21, 12), 0],
		["arcade_cabinet", Vector2(49, 38), -20],
		["utility_cabinet", Vector2(4, 10), 90],
	],
	"market": [
		["repair_bench", Vector2(18, 12), -15],
		["cargo_stack", Vector2(19, 9), 10],
		["vending_machine", Vector2(11, 12), 15],
		["cargo_stack", Vector2(42, 35), -20],
		["repair_bench", Vector2(44, 37), 0],
		["utility_cabinet", Vector2(56, 10), 90],
	],
	"underpass": [
		["repair_bench", Vector2(11, 8), 0],
		["cargo_stack", Vector2(13, 7), -15],
		["utility_cabinet", Vector2(14, 20), 0],
		["rooftop_aircon", Vector2(15.5, 20), 0],
		["vending_machine", Vector2(22.5, 24), 0],
	],
	"corp_row": [
		["transit_shelter", Vector2(8, 24), 90],
		["vending_machine", Vector2(24.5, 24), 0],
		["utility_cabinet", Vector2(55, 39), 180],
		["cargo_stack", Vector2(57, 39), -15],
	],
	"darknet": [
		["arcade_cabinet", Vector2(18, 10), 0],
		["arcade_cabinet", Vector2(19.2, 10), 0],
		["repair_bench", Vector2(45, 36), 0],
		["cargo_stack", Vector2(48, 37), 15],
		["utility_cabinet", Vector2(54, 32), -90],
	],
}

static func populate(district: Node3D, district_id: String) -> void:
	for entry in PLACEMENTS.get(district_id, []):
		district._prop(ROOT + entry[0] + ".tscn", entry[1], float(entry[2]))
	# Roof details use the actual shop asset height; towers retain their skyline.
	var index := 0
	for building in district._buildings:
		var node: Node3D = building.node
		if not str(node.scene_file_path).ends_with("bldg_shop.tscn"):
			continue
		if index % 3 == 0:
			var unit: Node3D = load(ROOT + "rooftop_aircon.tscn").instantiate()
			node.add_child(unit)
			unit.position = Vector3(0, 1.8, -0.15)
		index += 1

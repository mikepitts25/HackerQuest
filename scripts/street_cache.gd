extends RefCounted
## Daily exploration rewards reuse the existing saved, sleep-reset search ledger.
## No save migration: namespaced IDs cannot collide with existing scrap piles.

const LOCATIONS := {
	"plaza": Vector2(22, 38),
	"market": Vector2(8, 25),
	"underpass": Vector2(8, 12),
}
const REWARD := 18

static func claim(state: Node, district_id: String) -> bool:
	if not LOCATIONS.has(district_id):
		return false
	var id := "signal_cache:" + district_id
	if state.trash_searched.has(id):
		state.notify("Signal downloaded. New packets arrive after sleep.", state.COL_INFO)
		return false
	if not state.use_energy(1):
		return false
	state.trash_searched[id] = true
	state.add_cash(REWARD)
	state.notify("SIGNAL FOUND  +$%d · new cache tomorrow" % REWARD, state.COL_GOOD)
	state.save_game()
	return true

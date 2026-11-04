extends Label3D
## Use a bound method so GameState drops the connection when this sign is freed.

func refresh() -> void:
	visible = not GameState.has_computer

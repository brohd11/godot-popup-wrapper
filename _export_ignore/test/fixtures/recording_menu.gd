extends "res://addons/_lib/popup_wrapper/src/context_menu.gd"
## Records each _get_menu_options call, so the suite can see what the adapter forwards.

const SLOT = CONTEXT_SLOT_FILESYSTEM

var calls: Array = []


func _get_menu_options(data) -> void:
	calls.append(data)

#! namespace PopupWrapper class ContextMenu
extends EditorContextMenuPlugin
## Base for context menu plugins: implement `_get_menu_options(data)` once and it runs on every
## version. 4.8 calls it itself; before 4.8 the engine only calls `_popup_menu`, which rebuilds the
## same `data` (see Slots). Subclasses define `const SLOT`, keep `data` untyped (4.8's virtual takes
## a typed Dictionary), and pass `data` to create_items so callbacks receive it too.

const Slots = preload("res://addons/_lib/popup_wrapper/src/context_slots.gd")


func _popup_menu(paths:PackedStringArray) -> void:
	# 4.8 still runs this deprecated pass after _get_menu_options; adding here would duplicate.
	if Slots.uses_new_api():
		return
	_get_menu_options(Slots.from_legacy(get("SLOT"), paths))


## Override to add items. `data` per SLOT (same shape on every version):
## [codeblock]
## SCRIPT_EDITOR_CODE   code_edit: CodeEdit, file_path: String
## SCRIPT_EDITOR        selected_resource: Resource (null for docs), path: String (docs: "help:<Class>" on 4.8, "" before)
## FILESYSTEM           selected_files: PackedStringArray (folders end in "/")
## FILESYSTEM_CREATE    base_directory: String, needs_prefix: bool (true in the top-level New menu)
## SCENE_TREE           selected_nodes: Array[Node]
## SCENE_TABS           selected_scene: String ("" when not on a tab)
## 2D_EDITOR            hovered_nodes: Array[CanvasItem], mouse_position: Vector2 (canvas space)
## INSPECTOR_PROPERTY   property, object, property_name (4.6+; 4.8 only, no pre-4.8 adapter)
## [/codeblock]
## Read keys through Slots (its consts and typed getters) rather than spelling them.
func _get_menu_options(_data) -> void:
	pass

@tool
extends RefCounted
## Slots.from_legacy builds the documented 4.8 `data` shape for every slot, the getters read it
## back, and ContextMenu's _popup_menu forwards to _get_menu_options only before 4.8 (on 4.8 the
## engine calls it, and forwarding from the deprecated pass would add every item twice).

const Slots = preload("res://addons/_lib/popup_wrapper/src/context_slots.gd")
const RecordingMenu = preload("res://addons/_lib/popup_wrapper/_export_ignore/test/fixtures/recording_menu.gd")


static func run_tests() -> Dictionary:
	var out: Array = []
	var failures = 0
	failures += _check(out, "FILESYSTEM", _legacy(EditorContextMenuPlugin.CONTEXT_SLOT_FILESYSTEM, ["res://a.gd", "res://dir/"]),
		{Slots.SELECTED_FILES: PackedStringArray(["res://a.gd", "res://dir/"])})
	failures += _check(out, "FILESYSTEM_CREATE folder", _legacy(EditorContextMenuPlugin.CONTEXT_SLOT_FILESYSTEM_CREATE, ["res://dir/"]),
		{Slots.BASE_DIRECTORY: "res://dir/", Slots.NEEDS_PREFIX: false})
	failures += _check(out, "FILESYSTEM_CREATE top-level", _legacy(EditorContextMenuPlugin.CONTEXT_SLOT_FILESYSTEM_CREATE, []),
		{Slots.BASE_DIRECTORY: "res://", Slots.NEEDS_PREFIX: true})
	failures += _check(out, "SCENE_TABS", _legacy(EditorContextMenuPlugin.CONTEXT_SLOT_SCENE_TABS, ["res://s.tscn"]),
		{Slots.SELECTED_SCENE: "res://s.tscn"})
	failures += _check(out, "SCENE_TABS no tab", _legacy(EditorContextMenuPlugin.CONTEXT_SLOT_SCENE_TABS, []),
		{Slots.SELECTED_SCENE: ""})
	var self_path = "res://addons/_lib/popup_wrapper/_export_ignore/test/context_slots_test.gd"
	var script_data = _legacy(EditorContextMenuPlugin.CONTEXT_SLOT_SCRIPT_EDITOR, [self_path])
	failures += _expect(out, "SCRIPT_EDITOR resource", Slots.selected_resource(script_data) is Script and Slots.path(script_data) == self_path)
	failures += _check(out, "SCRIPT_EDITOR docs", _legacy(EditorContextMenuPlugin.CONTEXT_SLOT_SCRIPT_EDITOR, []),
		{Slots.SELECTED_RESOURCE: null, Slots.PATH: ""})
	failures += _expect(out, "unknown slot is empty", Slots.from_legacy(-1, PackedStringArray(["x"])).is_empty())

	if Engine.is_editor_hint():
		# Node-backed slots need the editor; with no scene open they must come back empty, not crash.
		var tree_data = _legacy(EditorContextMenuPlugin.CONTEXT_SLOT_SCENE_TREE, ["Missing"])
		failures += _expect(out, "SCENE_TREE unresolved paths dropped", Slots.selected_nodes(tree_data).is_empty())
		var ed_data = _legacy(EditorContextMenuPlugin.CONTEXT_SLOT_2D_EDITOR, ["/root/Missing"])
		failures += _expect(out, "2D_EDITOR keys", Slots.hovered_nodes(ed_data).is_empty() and ed_data.has(Slots.MOUSE_POSITION))
		var code_data = _legacy(EditorContextMenuPlugin.CONTEXT_SLOT_SCRIPT_EDITOR_CODE, [])
		failures += _expect(out, "SCRIPT_EDITOR_CODE keys", code_data.has(Slots.CODE_EDIT) and code_data.has(Slots.FILE_PATH))
	else:
		out.append("skip node-backed slots: needs the editor")

	var menu = RecordingMenu.new()
	menu._popup_menu(PackedStringArray(["res://a.gd"]))
	if Slots.uses_new_api():
		failures += _expect(out, "4.8+: _popup_menu adds nothing", menu.calls.is_empty())
	else:
		failures += _expect(out, "<4.8: _popup_menu forwards data", menu.calls.size() == 1
			and Slots.selected_files(menu.calls[0]) == PackedStringArray(["res://a.gd"]))

	out.push_front("popup_wrapper context slots on %s: %d failure(s)" % [Engine.get_version_info().string, failures])
	return {"result": failures, "output": out}


static func _legacy(slot:int, paths:Array) -> Dictionary:
	return Slots.from_legacy(slot, PackedStringArray(paths))


static func _check(out:Array, label:String, got:Dictionary, expected:Dictionary) -> int:
	return _expect(out, label, got == expected, "got %s, expected %s" % [got, expected])


static func _expect(out:Array, label:String, ok:bool, detail:="") -> int:
	out.append(("ok   " if ok else "FAIL ") + label + ("" if ok or detail == "" else ": " + detail))
	return 0 if ok else 1

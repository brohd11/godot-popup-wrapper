#! namespace PopupWrapper class Slots
extends RefCounted
## What each EditorContextMenuPlugin slot passes as `data`: 4.8's `_get_menu_options(data)` and
## the item callbacks get this dictionary, and ContextMenu rebuilds it from `_popup_menu` paths
## before 4.8, so plugins see one shape everywhere. Godot doesn't document the keys; these are
## read from the 4.8 call sites. Read them through the getters rather than spelling keys.

## The keys per slot are tabled on ContextMenu._get_menu_options.
const CODE_EDIT = &"code_edit"
const FILE_PATH = &"file_path"
const SELECTED_RESOURCE = &"selected_resource"
const PATH = &"path"
const SELECTED_FILES = &"selected_files"
const BASE_DIRECTORY = &"base_directory"
const NEEDS_PREFIX = &"needs_prefix"
const SELECTED_NODES = &"selected_nodes"
const SELECTED_SCENE = &"selected_scene"
const HOVERED_NODES = &"hovered_nodes"
const MOUSE_POSITION = &"mouse_position"


## 4.8 calls _get_menu_options itself; before that only _popup_menu exists.
static func uses_new_api() -> bool:
	return Engine.get_version_info().hex >= 0x040800


static func code_edit(data:Dictionary) -> CodeEdit:
	return data.get(CODE_EDIT)

static func file_path(data:Dictionary) -> String:
	return data.get(FILE_PATH, "")

static func selected_resource(data:Dictionary) -> Resource:
	return data.get(SELECTED_RESOURCE)

static func path(data:Dictionary) -> String:
	return data.get(PATH, "")

static func selected_files(data:Dictionary) -> PackedStringArray:
	return data.get(SELECTED_FILES, PackedStringArray())

static func base_directory(data:Dictionary) -> String:
	return data.get(BASE_DIRECTORY, "res://")

static func needs_prefix(data:Dictionary) -> bool:
	return data.get(NEEDS_PREFIX, false)

static func selected_nodes(data:Dictionary) -> Array:
	return data.get(SELECTED_NODES, [])

## The selected nodes as paths relative to the edited scene root, the pre-4.8 `paths` form.
static func selected_node_paths(data:Dictionary) -> PackedStringArray:
	var root = EditorInterface.get_edited_scene_root()
	var out = PackedStringArray()
	for node in selected_nodes(data):
		if is_instance_valid(node) and is_instance_valid(root):
			out.append(String(root.get_path_to(node)))
	return out

static func selected_scene(data:Dictionary) -> String:
	return data.get(SELECTED_SCENE, "")

static func hovered_nodes(data:Dictionary) -> Array:
	return data.get(HOVERED_NODES, [])

## The hovered nodes as absolute node paths, the pre-4.8 `paths` form.
static func hovered_node_paths(data:Dictionary) -> PackedStringArray:
	var out = PackedStringArray()
	for node in hovered_nodes(data):
		if is_instance_valid(node):
			out.append(String(node.get_path()))
	return out

static func mouse_position(data:Dictionary) -> Vector2:
	return data.get(MOUSE_POSITION, Vector2.ZERO)


## Builds `data` from a pre-4.8 `_popup_menu(paths)` call, following what 4.7 passed per slot.
static func from_legacy(slot:int, paths:PackedStringArray) -> Dictionary:
	var first = paths[0] if not paths.is_empty() else ""
	match slot:
		EditorContextMenuPlugin.CONTEXT_SLOT_SCRIPT_EDITOR_CODE:
			var script = EditorInterface.get_script_editor().get_current_script()
			return {
				CODE_EDIT: Engine.get_main_loop().root.get_node_or_null(first) if first != "" else null,
				FILE_PATH: script.resource_path if script != null else "",
			}
		EditorContextMenuPlugin.CONTEXT_SLOT_SCRIPT_EDITOR:
			# The resource is open in the script editor, so load() returns the cached instance.
			var res = load(first) if first != "" and ResourceLoader.exists(first) else null
			return {SELECTED_RESOURCE: res, PATH: first}
		EditorContextMenuPlugin.CONTEXT_SLOT_FILESYSTEM:
			return {SELECTED_FILES: paths}
		EditorContextMenuPlugin.CONTEXT_SLOT_FILESYSTEM_CREATE:
			return {BASE_DIRECTORY: first if first != "" else "res://", NEEDS_PREFIX: first == ""}
		EditorContextMenuPlugin.CONTEXT_SLOT_SCENE_TREE:
			var root = EditorInterface.get_edited_scene_root()
			var nodes = []
			for p in paths:
				var node = root.get_node_or_null(p) if is_instance_valid(root) else null
				if node != null:
					nodes.append(node)
			return {SELECTED_NODES: nodes}
		EditorContextMenuPlugin.CONTEXT_SLOT_SCENE_TABS:
			return {SELECTED_SCENE: first}
		EditorContextMenuPlugin.CONTEXT_SLOT_2D_EDITOR:
			var nodes = []
			for p in paths:
				var node = Engine.get_main_loop().root.get_node_or_null(p)
				if node != null:
					nodes.append(node)
			# 4.8 sends the mouse in canvas space; the 2D viewport carries the editor's canvas transform.
			var viewport = EditorInterface.get_editor_viewport_2d()
			var mouse = viewport.global_canvas_transform.affine_inverse() * viewport.get_mouse_position()
			return {HOVERED_NODES: nodes, MOUSE_POSITION: mouse}
	return {}

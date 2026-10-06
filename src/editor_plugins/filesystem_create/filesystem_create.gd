extends EditorContextMenuPlugin

var enabled:bool = true

func _popup_menu(paths: PackedStringArray) -> void:
	return #^r this clashes with filesystem slot
	
	await Engine.get_main_loop().root.get_tree().process_frame
	if not enabled:
		return
	var fs_popup = EditorNodeRef.get_registered(EditorNodeRef.Nodes.FILESYSTEM_CREATE_POPUP)
	
	var wrapper_params = PopupWrapperSingleton.ContextPlugin.WrapperParams.new()
	wrapper_params.show_shortcuts = true
	PopupWrapperSingleton.wrap_popup(fs_popup, wrapper_params)

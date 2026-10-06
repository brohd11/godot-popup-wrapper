extends EditorContextMenuPlugin

var enabled:bool = true

func _popup_menu(paths: PackedStringArray) -> void:
	#await Engine.get_main_loop().root.get_tree().process_frame
	if not enabled:
		return
	_deferred_popup_menu.call_deferred()

func _deferred_popup_menu():
	var fs_popup = EditorNodeRef.get_registered(EditorNodeRef.Nodes.SCRIPT_EDITOR_CODE_POPUP)
	
	var wrapper_params = PopupWrapperSingleton.ContextPlugin.WrapperParams.new()
	wrapper_params.show_shortcuts = true
	
	PopupWrapperSingleton.wrap_popup(fs_popup, wrapper_params)

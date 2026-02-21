extends Control

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	pass

func _on_mouse_entered():
	get_child(0).visible = true
	pass
	
func _on_mouse_exited():
	get_child(0).visible = false
	pass

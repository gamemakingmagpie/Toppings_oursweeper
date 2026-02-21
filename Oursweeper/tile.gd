extends Button

var Number = 0
var IsHidden = false
var Link:Node = null
var IsFlagged = false
var IsHovered = false
var IsMineStepped = false
var IsExploded = false

signal Triggered
signal Exploded
signal Flagged
signal Unflagged

const EXPLOSION_TIME = 0.2
const EXPLOSION_SIZE = 30.0

func Explode():
		%AudioStreamPlayer.volume_db = -20
		%AudioStreamPlayer.stream = load("uid://drv5a4ljbxi8w")
		%AudioStreamPlayer.play()
		IsExploded = true
		icon = load("uid://dmrxdr6d5g2ti")
		text=""
		spawn_8_way_burst(size/2.0)
		_on_pressed()
		

func _on_gui_input(event: InputEvent) -> void:
	if IsExploded:return

	if IsMineStepped:
		Explode()
		Exploded.emit()
			
	if text!="":return
	if event is InputEventMouseButton:
		if event.button_index == 1 and Number==-1:
			if  event.pressed:
				if disabled:return
				IsMineStepped = true
				Triggered.emit()
				%AudioStreamPlayer.volume_db = 0
				%AudioStreamPlayer.stream = load("uid://wkfxp2nf1q6")
				%AudioStreamPlayer.play()
		if event.button_index == 2 and event.pressed:
			#Flag
			if IsFlagged:_unflag()
			else:_flag()
			pass
	pass # Replace with function body.

func _unflag():
	Unflagged.emit()
	disabled = false
	IsFlagged = false
	icon = null
	Link.disabled = false
	Link.IsFlagged = false
	Link.icon = null
	pass
	
func _flag():
	Flagged.emit()
	disabled = true
	IsFlagged = true
	icon = load("res://Flag.png")
	Link.disabled = true
	Link.IsFlagged = true
	Link.icon = load("res://Flag.png")
	pass

func _on_pressed() -> void:
	disabled = true
	if IsFlagged:return
	if IsHidden:
		text = "?"
	else:
		text = str(Number)
	if Number==-1:
		icon = load("uid://dmrxdr6d5g2ti")
		text=""
	if Link!=null:Link._on_pressed()
	pass # Replace with function body.


func _on_mouse_entered() -> void:
	#%AudioStreamPlayer.stream = load("uid://cqxj4glv8wan0")
	#%AudioStreamPlayer.play()
	IsHovered = true
	pass # Replace with function body.


func _on_mouse_exited() -> void:
	IsHovered = false
	pass # Replace with function body.
	
func _input(event: InputEvent) -> void:
	if not IsHovered:return
	if not text.ends_with("?"):return
	if event is InputEventKey:
		if event.as_text().is_valid_int():
			if event.as_text()=="9":text="?"
			else:text = event.as_text()+"?"
		pass
	pass

func spawn_8_way_burst(center_pos: Vector2):
	for i in range(8):
		var sprite = Sprite2D.new()
		sprite.texture = preload("uid://bpe0gnckr7c1s")
		sprite.position = center_pos
		sprite.scale = Vector2(0.3, 0.3) # Start tiny!
		sprite.z_index = 100
		add_child(sprite)

		# --- 1. MOVEMENT TWEEN (Physics) ---
		# Explosions start fast and slow down (Drag).
		# We use EASE_OUT with TRANS_EXPO for that "Violent" pop.
		
		var angle = i * (PI / 4.0)
		var direction = Vector2.from_angle(angle)
		var target_pos = center_pos + (direction * EXPLOSION_SIZE) # Move 120px
		
		var move_tween = create_tween()
		move_tween.set_trans(Tween.TRANS_EXPO) # Violent curve
		move_tween.set_ease(Tween.EASE_OUT)    # Fast start, slow end
		move_tween.tween_property(sprite, "position", target_pos, 0.6)
		
		# Also scale up rapidly to simulate expansion
		move_tween.parallel().tween_property(sprite, "scale", Vector2(0.6,0.6), 0.3)
		# Then shrink slightly as it turns to smoke
		move_tween.chain().tween_property(sprite, "scale", Vector2(0.5, 0.5), 0.3)

		# --- 2. COLOR TWEEN (Chemistry) ---
		# This runs independently of the movement.
		# Note: We use values > 1 for HDR Glow (Requires WorldEnvironment).
		
		var color_tween = create_tween()
		sprite.modulate = Color(4, 4, 4) # Start SUPER bright white
		
		# Sequence: White -> Yellow -> Orange -> Dark Red -> Fade
		color_tween.tween_property(sprite, "modulate", Color(1.5, 1.5, 0), 0.1) # Yellow
		color_tween.tween_property(sprite, "modulate", Color(1.0, 0.4, 0), 0.2) # Orange
		color_tween.tween_property(sprite, "modulate", Color(0.3, 0.05, 0.05), 0.2) # Dark Red/Smoke
		color_tween.tween_property(sprite, "modulate", Color(0, 0, 0, 0), 0.3) # Fade to transparent
		
		# Cleanup when the color animation is done
		color_tween.chain().tween_callback(sprite.queue_free)

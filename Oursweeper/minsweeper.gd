
class_name MinesweeperBoard
extends Node

# The 1D array holding all data
# -1 = Mine
# 0-8 = Number of adjacent mines
var tile_data: Array[int] = []

@export var width: int = 0
@export var height: int = 0
@export var total_mines: int = 0
@export var hidden_rate = 0.4
#@export_enum("Chat","Donation","Donation_Hard")

var flag_count = 0

var IsStart = false
var IsEnd = false
var tmpTriggered = null
var DefuseCondition:Dictionary ={
	"IsDonation":false,#Chat, Donation, Price
	"Value":"괴둘타"
}

const RESET_TIME = 1.0
const EXPLOSION_INTERVAL = 0.1



func _ready() -> void:
	
	%Window.position = Vector2i(-10000,-10000)
	#get_window().exclude_from_capture=true
	#%Window.render_target_update_mode
	pass
# 1. Initialization Function
# Resets the board, places mines randomly, and calculates numbers

func initialize(x:int, y:int) -> void:
	check_victory()
	if IsStart:return
	# Clear and resize the array to fit the grid
	tile_data.clear()
	tile_data.resize(width * height)
	tile_data.fill(0) # Reset all to 0 (Empty)
	# --- Step A: Place Mines ---
	var mines_placed = 0
	while mines_placed < total_mines:
		var random_index = randi() % tile_data.size()
		if random_index == y * width + x:continue
		# Only place if there isn't one there already
		if tile_data[random_index] != -1 :
			tile_data[random_index] = -1
			mines_placed += 1
	for j in range(height):
		for i in range(width):
			if get_cell(i,j)!=-1:	set_cell(i,j,count_surrounding_mines(i,j))
	for i in tile_data.size():
		%TileGrid_Player.get_child(i).Number = tile_data[i]
		%TileGrid_Viewer.get_child(i).Number = tile_data[i]
		if i!=y*width+x:
			if randf()<hidden_rate:
				%TileGrid_Player.get_child(i).IsHidden = true
	
	%TileGrid_Player.get_child(y*width + x).text = str(tile_data[y*width + x])
	%TileGrid_Viewer.get_child(y*width + x).text = str(tile_data[y*width + x])
	IsStart = true
	
	%TimerLabel.start()
	%FlagLabel.text = str(total_mines)
	flag_count = 0
	cascade_reveal(x,y)
	# --- Step B: Calculate Numbers ---
	# We loop through every cell. If it's NOT a mine, we count its neighbors.

func Build():
	
	%TileGrid_Player.columns = width
	%TileGrid_Viewer.columns = width
	
	for y in range(height):
		for x in range(width):
			var newTile_Player = load("res://tile.tscn").instantiate()
			var newTile_Viewer = load("res://tile.tscn").instantiate()
			%TileGrid_Player.add_child(newTile_Player)
			%TileGrid_Viewer.add_child(newTile_Viewer)
			newTile_Player.Link = newTile_Viewer
			newTile_Player.pressed.connect(_on_tile_pressed.bind(x, y))
			newTile_Player.Triggered.connect(_on_triggered.bind(newTile_Player))
			newTile_Player.Exploded.connect(_explode.bind(x,y))
			newTile_Player.Flagged.connect(_flagged)
			newTile_Player.Unflagged.connect(_unflagged)

	pass
	
func _on_tile_pressed(x: int, y: int) -> void:
	# 1. First Click Handling
	if not IsStart:
		initialize(x, y)
	
	# 2. Get the tile that was just pressed
	var tile = %TileGrid_Player.get_child(y * width + x)
	
	# 3. If we just opened a 0, trigger the cascade!
	if tile.Number == 0:
		cascade_reveal(x, y)
	
	# 4. Check for victory after every move
	check_victory()
		
func TransferData():
	pass

# 2. Check if location has a bomb
func has_bomb(column: int, row: int) -> bool:
	return get_cell(column, row) == -1

# --- HELPER FUNCTIONS (Essential) ---

# Safe way to read data. Returns 0 if out of bounds (safe default).
func get_cell(x: int, y: int) -> int:
	if not is_valid(x, y): return 0
	return tile_data[y * width + x]

# Safe way to write data.
func set_cell(x: int, y: int, value: int) -> void:
	if is_valid(x, y):
		tile_data[y * width + x] = value

# Checks if coordinates are inside the grid
func is_valid(x: int, y: int) -> bool:
	return x >= 0 and x < width and y >= 0 and y < height

# Counts mines in the 8 cells around (x, y)
func count_surrounding_mines(cx: int, cy: int) -> int:
	var mine_count = 0
	
	# Loop from -1 to +1 on both axes (3x3 grid centered on cx, cy)
	for y_offset in range(-1, 2):
		for x_offset in range(-1, 2):
			# Skip the center cell itself
			if x_offset == 0 and y_offset == 0:
				continue
			
			var check_x = cx + x_offset
			var check_y = cy + y_offset
			
			# Check neighbor (only if valid bounds)
			if is_valid(check_x, check_y):
				if get_cell(check_x, check_y) == -1:
					mine_count += 1
					
	return mine_count


func _on_window_close_requested() -> void:
	get_tree().quit()
	pass # Replace with function body.

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		%Cursor2.position = %Cursor.position
	pass


# Debug: Prints the board to the output console
func debug_print():
	print("--- Minesweeper Board ---")
	for y in range(height):
		var row_str = ""
		for x in range(width):
			var val = get_cell(x, y)
			if val == -1:
				row_str += "[X] "
			else:
				row_str += "[%d] " % val
		print(row_str)
	print("-------------------------")
	
func _on_start_pressed() -> void:
	
	width = %Width.value
	height = %Height.value
	total_mines = %Bomb.value
	if total_mines>width*height:return
	hidden_rate = %Hidden.value
	%StartPanel.visible = false
	Build()
	pass # Replace with function body.


func _on_easy_pressed() -> void:
	%Width.value = 9
	%Height.value = 9
	%Bomb.value = 10
	%Hidden.value = 0.2
	pass # Replace with function body.


func _on_middle_pressed() -> void:
	%Width.value = 16
	%Height.value = 16
	%Bomb.value = 40
	%Hidden.value = 0.2
	pass # Replace with function body.


func _on_hard_pressed() -> void:
	%Width.value = 30
	%Height.value = 16
	%Bomb.value = 99
	%Hidden.value = 0.2
	pass # Replace with function body.

func _explode(start_x: int, start_y: int) -> void:
	if IsEnd:return
	var mines_to_explode = []
	var epicenter = Vector2(start_x, start_y)
	%TimerLabel.stop()
	# Return Triggered Panel back to place
	_hide_defuse_panel()
	# 1. Gather all mines and measure their distance
	for i in %TileGrid_Player.get_child_count():
		var tile = %TileGrid_Player.get_child(i)
		var tile_viewer = %TileGrid_Viewer.get_child(i)
		# Check if it is a mine (-1) and hasn't exploded yet
		if tile.Number == -1 and not tile.IsExploded:
			# Calculate grid X and Y from the index (i)
			var tx = i % width
			var ty = i / width
			var current_pos = Vector2(tx, ty)
			
			# Store the tile AND its distance in a little dictionary
			mines_to_explode.append({
				"node": tile,
				"node_viewer": tile_viewer,
				"distance": epicenter.distance_to(current_pos)
			})

	# 2. Sort the array based on distance (Smallest distance first)
	mines_to_explode.sort_custom(func(a, b): return a.distance < b.distance)
	IsEnd = true
	# 3. Explode them in order!
	for item in mines_to_explode:
		item.node.Explode()
		item.node_viewer.Explode()
		# Wait a tiny bit between each explosion to create the "Wave" visual
		# 0.02 is fast and smooth. 0.1 is slow and dramatic.
		await get_tree().create_timer(EXPLOSION_INTERVAL).timeout
	await get_tree().create_timer(RESET_TIME).timeout
	%GameEndPanel.visible = true
	%GameEndLabel.text = '패배'
	%GameEndPanel2.visible = true
	%GameEndLabel2.text = '패배'

func check_victory() -> void:
	# 1. Loop through all tiles
	if not IsStart:return
	for tile in %TileGrid_Player.get_children():
		# 2. We only care about SAFE tiles (Number != -1)
		if tile.Number != -1:
			# 3. If a safe tile is still HIDDEN, we haven't won yet.
			# (Assuming IsHidden is your variable for un-clicked state)
			if not tile.disabled:
				return # Game continues...

	# 4. If the loop finishes, it means NO safe tiles are hidden.
	IsEnd = true
	# Stop the timer, play sound, show 'You Win' screen, etc.
	# If we finish the loop, it means every remaining hidden tile is a mine.
	# VICTORY!
	print("VICTORY! All safe tiles are pressed.")
	%TimerLabel.stop()
	await get_tree().create_timer(RESET_TIME).timeout
	%GameEndPanel.visible = true
	%GameEndLabel.text = '승리'
	%GameEndPanel2.visible = true
	%GameEndLabel2.text = '승리'
		
	
func reset():
	for eachTile in %TileGrid_Player.get_children():eachTile.queue_free()
	for eachTile in %TileGrid_Viewer.get_children():eachTile.queue_free()
	width = 0
	height = 0
	total_mines = 0
	hidden_rate = 0.4
	IsStart = false
	IsEnd = false
	%TimerLabel.reset()
	%FlagLabel.text = '0'
	%StartPanel.visible = true
	%GameEndPanel.visible = false
	%GameEndPanel2.visible = false
	pass
	
# The recursive flood-fill function
func cascade_reveal(x: int, y: int) -> void:
	# 1. Get the current tile to check if we should even start
	var current_tile = %TileGrid_Player.get_child(y * width + x)
	
	# Safety: If this tile is NOT a 0, we don't cascade from it.
	if current_tile.Number != 0:	return
	if current_tile.IsHidden:return
	# 2. Loop through all 8 neighbors
	for j in range(-1, 2):
		for i in range(-1, 2):
			if i == 0 and j == 0: continue # Skip self
			
			var nx = x + i
			var ny = y + j
			
			if is_valid(nx, ny):
				var neighbor_index = ny * width + nx
				var neighbor_tile = %TileGrid_Player.get_child(neighbor_index)
				if neighbor_tile.button_pressed:continue
				if neighbor_tile.IsFlagged:continue
				if neighbor_tile.disabled:continue
				neighbor_tile._on_pressed()
				cascade_reveal(nx,ny)
				check_victory()


func _on_chat_receiver_channel_connected(Name: String, Thumbnail: Texture2D) -> void:
	
	%ChannelName.visible = true
	%ChannelImage.visible = true
	%ChannelConfirmLabel.visible = true
	%ChannelHBoxContainer.visible = true
	%ChannelName.text = Name
	%ChannelImage.texture = Thumbnail
	%ParallaxTextureRect.texture = Thumbnail
	%ParallaxTextureRect_Viewer.texture = Thumbnail
	pass # Replace with function body.


func _on_channel_input_button_pressed() -> void:
	var ChannelID_Raw:String = %ChannelIDLineEdit.text
	if ChannelID_Raw.length()<32:return
	%ChatReceiver.ChannelID = ChannelID_Raw.right(32)
	%ChatReceiver.Start()
	%ChannelInputButtonContainer.visible = false
	%ChannelInputHBoxContainer.visible = false
	pass # Replace with function body.


func _on_chat_receiver_channel_not_exist() -> void:
	%ChannelInputHBoxContainer.visible = true
	%ChannelInputButtonContainer.visible = true
	pass # Replace with function body.


func _on_chat_receiver_channel_not_live() -> void:
	_on_chat_receiver_channel_not_exist()
	pass # Replace with function body.


func _on_channel_cancel_button_pressed() -> void:
	get_tree().reload_current_scene()
	%ChannelName.visible = false
	%ChannelImage.visible = false
	%ChannelConfirmLabel.visible = false
	%ChannelHBoxContainer.visible = false
	%ChannelInputButtonContainer.visible = true
	%ChannelInputHBoxContainer.visible = true
	pass # Replace with function body.


func _on_channel_confirm_button_pressed() -> void:
	%ChatSettingsPanel.visible = false
	pass # Replace with function body.


func _on_chat_receiver_chat_received(Nickname: Variant, Msg: Variant, IsSubscriber: Variant, RoleCode: Variant, emojis: Variant) -> void:
	_check_defuse(0,Msg)
	pass # Replace with function body.


func _on_chat_receiver_donation(Amount: Variant, Msg: Variant) -> void:
	_check_defuse(int(Amount),Msg)
	pass # Replace with function body.


func _on_audio_h_slider_drag_ended(value_changed: bool) -> void:	
	if value_changed:
		
		AudioServer.set_bus_volume_db(0,linear_to_db(%AudioHSlider.value/%AudioHSlider.max_value))
	pass # Replace with function body.


func _on_audio_button_pressed() -> void:
	%AudioPanel.visible = false
	pass # Replace with function body.


func _on_settings_button_pressed() -> void:
	%AudioPanel.visible = true
	pass # Replace with function body.

func _flagged():
	flag_count+=1
	%FlagLabel.text = str(total_mines-flag_count)
	pass

func _unflagged():
	flag_count-=1
	%FlagLabel.text = str(total_mines-flag_count)
	pass

func _on_triggered(TriggeredTile:Node):
	

	tmpTriggered = TriggeredTile
	if not %ChatReceiver.IsRunning:return
	var tween = create_tween()
	tween.tween_property(%DefusePanel, "position", Vector2(15, 262.5), 0.5) \
		.set_trans(Tween.TRANS_CUBIC) \
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(%DisarmRichTextLabel, "visible_ratio", 1.0, 1.0)
	
	%DisarmRichTextLabel.visible_ratio = 0.0
	#TODO:Donation Condition
	DefuseCondition.IsDonation = true if randf()<0.2 else false
	#TODO: Defuse Condition
	var word_list = [
	"낫다", "낮다", "낳다", "났다",
	"맞다", "맡다", "맏다", "마따",
	"닫다", "닿다", "닷다", "다따",
	"밭다", "받다", "바따", "발다",
	"빗다", "빚다", "비따", "빌다",
	"잊다", "잃다", "읽다", "일다",
	"묻다", "물다", "무따", "묵다",
	"볶다", "복다", "복타", "봉다",
	"섞다", "석다", "썩다", "섟다",
	"깎다", "깍다", "깍타", "깡다",
	"덮다", "덥다", "더파", "덤다",
	"읊다", "읍다", "을파", "음다",
	"같이", "가치", "갇히", "가지",
	"굳이", "구지", "국이", "굴이",
	"닫히다", "다치다", "닿이다", "단이다",
	"묻히다", "무치다", "물이다", "문이다",
	"맞히다", "마치다", "맛이다", "만이다",
	"얹히다", "언치다", "얻히다", "얼이다",
	"넓히다", "널피다", "넙히다", "널이다",
	"베다", "배다", "빼다", "뻬다",
	"게시", "개시", "계시", "괘시",
	"결제", "결재", "겔제", "겔재",
	"체험", "채험", "최험", "추험",
	"의의", "의이", "이의", "이이",
	"희망", "히망", "허망", "하망",
	"무늬", "무니", "문희", "문이",
	"부치다", "붙이다", "뿌치다",
	"안치다", "앉히다", "않이다",
	"벌이다", "벌리다", "버리다",
	"늘이다", "늘리다", "느리다",
	"반드시", "반듯이", "반듣이",
	"거치다", "걷히다", "걷치다",
	"지그시", "지긋이", "지극이",
	"바치다", "받치다", "받히다"
]
	var tongue_twisters = [
	"경찰청 철창살은 외철창살",
	"검찰청 철창살은 쌍철창살",
	"내가 그린 기린 그림은 잘 그린 기린 그림",
	"네가 그린 기린 그림은 못 그린 기린 그림",
	"안촉촉한 초코칩 나라에 살던 안촉촉한 초코칩",
	"촉촉한 초코칩 나라에 살던 촉촉한 초코칩",
	"서울특별시 특허허가과 허가과장 허과장",
	"들의 콩깍지는 깐 콩깍지인가 안 깐 콩깍지인가",
	"작은 토끼 토끼통 옆에는 큰 토끼 토끼통",
	"저기 저 뜀틀이 내가 뛸 뜀틀인가",
	"내가 안 뛸 뜀틀인가",
	"고려고 교복은 고급 교복",
	"저기 계신 저분이 박 법학박사님이신가",
	"앞집 팥죽은 붉은 팥 풋팥죽",
	"뒷집 콩죽은 햇콩 단콩 콩죽",
	"상표 붙인 큰 깡통은 깐 깡통인가 안 깐 깡통인가",
	"신진 샹송가수의 신춘 샹송쇼",
	"철수 책상 철책상",
	"칠월 칠일은 평창친구 친정 칠순 잔칫날",
	"대우 로얄 뉴로얄",
	"스위스에서 오신 스미스씨",
	"체다치즈를 체친 치즈",
	"단산 단무지 공장 단무지 장수 단 장수",
	"백 법학박사님 댁 밥은 백보리 밥",
	"청단풍잎 홍단풍잎 흑단풍잎 백단풍잎",
	"저기 있는 말뚝이 말 맬 말뚝이냐",
	"창경원 창살은 쌍창살",
	"한국관광공사 곽진광 관광과장",
	"김해 김씨 귀고리 고리 귀고리",
	"생각이란 생각하면 생각할수록 생각나는 것",
	"육통 통장 적금통장은 황색 적금통장",
	"팔통 통장 적금통장은 녹색 적금통장",
	"멍멍이네 꿀꿀이는 멍멍해도 꿀꿀하고",
	"꿀꿀이네 멍멍이는 꿀꿀해도 멍멍하네",
	"밤벚꽃놀이를 가고 낮벚꽃놀이를 간다"
	]
	var alien_words = [
	"꿿", "뽧", "쓓", "쀏", "쨟",
	"뛟", "쬲", "쀍", "궯", "믩",
	"췗", "퀧", "휽", "딻", "뺩",
	"뾿", "쫋", "뗣", "뀶", "퐯",
	"땛찌", "쀍뜳", "훫쀼", "뀰꿿", "쫧뺩",
	"쒧쓓", "뽧뾿", "퀧믩", "췗딻", "뛟쨟"
	]
	var word_selector = randf()
	
	if word_selector < 0.5:DefuseCondition.Value = word_list.pick_random()
	elif word_selector<0.9: DefuseCondition.Value = tongue_twisters.pick_random()
	else: DefuseCondition.Value = alien_words.pick_random()
	
	if DefuseCondition.IsDonation:
		DefuseCondition.Value = randi_range(1000,3000)
		%DisarmRichTextLabel.text = "%d 치즈 후원하기"%DefuseCondition.Value
		#if DefuseCondition.Value.is_valid_int():
			#%DisarmRichTextLabel.text = "%s치즈 후원하기"%DefuseCondition.Value
		#else:
			#%DisarmRichTextLabel.text = "\"%s\"를 넣어 후원하기"%DefuseCondition.Value
	else:
		%DisarmRichTextLabel.text = "채팅에 \"%s\" 치기"%DefuseCondition.Value

	pass
	
func _hide_defuse_panel():
	if not %ChatReceiver.IsRunning:return
	
	var tween = create_tween()
	tween.tween_property(%DefusePanel, "position", Vector2(-352.0, 262.5), 0.5) \
	.set_trans(Tween.TRANS_CUBIC) \
	.set_ease(Tween.EASE_OUT)
		
	pass
	
func _check_defuse(Donation:int,Msg:String):
	if tmpTriggered==null:return
	if (not DefuseCondition.IsDonation) and Donation==0:#If defuse method is chat
		if Msg.contains(DefuseCondition.Value):
			_defuse()
			return
	if DefuseCondition.IsDonation and Donation>0:#If defuse method is donation
		#if DefuseCondition.Value.is_valid_int():
		if DefuseCondition.Value==Donation:
			_defuse()
			return
		else:
			if Msg.contains(DefuseCondition.Value):
				_defuse()
				return
		return

func _defuse():
	if IsEnd:return
	_hide_defuse_panel()
	%AudioStreamPlayer.play()
	tmpTriggered.IsMineStepped = false
	tmpTriggered._flag()
	tmpTriggered = null
	pass


func _on_no_channel_button_pressed() -> void:
	
	%ChatSettingsPanel.visible = false
	
	pass # Replace with function body.


func _on_game_end_button_pressed() -> void:
	reset()
	pass # Replace with function body.

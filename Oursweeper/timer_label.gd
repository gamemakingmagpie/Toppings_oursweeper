extends Label
var time_elapsed: float = 0.0
var is_running: bool = false

	
func _process(delta: float) -> void:
	if is_running:
		time_elapsed += delta
		update_time()

## Starts the timer from its current position
func start() -> void:
	is_running = true

## Pauses the timer without clearing the time
func stop() -> void:
	is_running = false

## Stops the timer and sets the time back to zero
func reset() -> void:
	is_running = false
	time_elapsed = 0.0
	text = "00:00:00.00"

## Formats the current time into a string: hh:mm:ss.ms
func update_time() -> void:
	var total_seconds = int(time_elapsed)
	
	# Extract milliseconds (3 digits for true .ms format)
	var msecs = int((time_elapsed - total_seconds) * 100)
	
	var seconds = total_seconds % 60
	var minutes = (total_seconds / 60) % 60
	var hours = (total_seconds / 3600)
	
	# Format: %02d (2 digits, zero-padded), %03d (3 digits, zero-padded)
	
	# 2. Format as a string with leading zeros
	# %02d ensures it's 2 digits with a leading zero
	text = "%02d:%02d:%02d.%02d" % [hours, minutes, seconds, msecs]

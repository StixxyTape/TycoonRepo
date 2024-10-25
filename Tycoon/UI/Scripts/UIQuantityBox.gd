extends Button

var defaultText : String = "Custom..."

var hoveringOverButton : bool = false

signal valueChanged(newValue)

func _ready() -> void:
	text = defaultText
	focus_mode = FOCUS_NONE
	
	mouse_entered.connect(HoverCheck.bind(
		true
	))
	mouse_exited.connect(HoverCheck.bind(
		false
	))
	
func _process(delta: float) -> void:
	if button_pressed:
		# For being able to click off of the button 
		#DisableFocusCheck()
		InputCheck()
		
#func DisableFocusCheck():
	#if !Global.mouseHover and Input.is_action_just_pressed("Place"):
		#button_pressed = false
		
func InputCheck():
	if Input.is_action_just_pressed("Backspace"):
		if text == defaultText:
			text = ""
		text = text.erase(text.length() - 1)
		valueChanged.emit(int(text))
		return
	for x in 10:
		if Input.is_action_just_pressed(str("Number" + str(x))):
			if text == defaultText:
				text = ""
			text += str(x)
			valueChanged.emit(int(text))
			return
		
func HoverCheck(hovering):
	if hovering:
		hoveringOverButton = true
	else:
		hoveringOverButton = false

extends Node3D

@export var scanTime : float = 1.5

@onready var startPoint : Vector3 = $ConveyorPoints/StartPoint.position
@onready var endPoint : Vector3 = $ConveyorPoints/EndPoint.position

var itemTween : Tween

# When an item finishes scanning, emit this signal
signal scanned

func Scan(stockType : int):
	var itemMesh : PackedScene = Global.stockSys.stockInventory[stockType]["prefab"]
	
	var newItem : Node3D = itemMesh.instantiate()
	add_child(newItem)
	newItem.position = startPoint
	
	if is_instance_valid(itemTween):
		itemTween.stop()
	itemTween = get_tree().create_tween()
	itemTween.set_ease(Tween.EASE_IN_OUT)
	itemTween.set_trans(Tween.TRANS_QUAD)
	
	itemTween.tween_property(newItem, "position", endPoint, scanTime)
	await itemTween.finished
	
	newItem.queue_free()
	scanned.emit()

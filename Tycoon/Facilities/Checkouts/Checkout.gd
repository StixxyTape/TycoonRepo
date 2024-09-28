extends Node3D

@export var scanTime : float = .3
@export var queueGap : float = .4

@onready var startPoint : Vector3 = $ConveyorPoints/StartPoint.position
@onready var endPoint : Vector3 = $ConveyorPoints/EndPoint.position

var itemTween : Tween

var customerQueueList : Array = []
var queueSpotList : Array = []

# When an item finishes scanning, emit this signal
signal scanned

# When the queue moves, update each customer's position
signal queueUpdated

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

func UpdateQueue():
	queueSpotList.clear()
	var queueCount : int = 1
	for customer in customerQueueList:
		if queueSpotList.size() <= 0:
			queueSpotList.append(Vector2($FrontQueueSpot.global_position.x, $FrontQueueSpot.global_position.z))
			continue
		
		var queueDirection : Vector2 = (
			Vector2($QueueDirectionSpot.global_position.x, $QueueDirectionSpot.global_position.z)
			- Vector2($FrontQueueSpot.global_position.x, $FrontQueueSpot.global_position.z)).normalized()
		
			
		var gapBuffer : Vector2 
		gapBuffer.x = (queueGap * queueCount) * queueDirection.x
		gapBuffer.y = (queueGap * queueCount) * queueDirection.y
	
		print("\n", queueDirection.x)
		print(ceil(queueDirection.x))
		print(queueDirection.normalized())
		
		queueSpotList.append(Vector2(queueSpotList[0].x, queueSpotList[0].y) + gapBuffer)
			
		queueCount += 1
	
	queueUpdated.emit()
	
func MoveQueue():
	customerQueueList.remove_at(0)
	UpdateQueue()

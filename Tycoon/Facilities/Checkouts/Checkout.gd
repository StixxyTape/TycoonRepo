extends Node3D

@export var scanTime : float = 50
@export var queueGap : float = .7

@onready var startPoint : Vector3 = $ConveyorPoints/StartPoint.position
@onready var endPoint : Vector3 = $ConveyorPoints/EndPoint.position

var itemTween : Tween

var customerQueueList : Array = []
var queueSpotList : Array = []
var queueCellsList : Array = []

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
	queueCellsList.clear()
	
	for customer in customerQueueList:
		if queueSpotList.size() <= 0:
			queueSpotList.append(Vector2($FrontQueueSpot.global_position.x, $FrontQueueSpot.global_position.z))
			queueCellsList.append(round(
				Vector2($FrontQueueSpot.global_position.x, $FrontQueueSpot.global_position.z)))
			continue
		
		var baseQueueDirection : Vector2 = (
			Vector2($QueueDirectionSpot.global_position.x, $QueueDirectionSpot.global_position.z)
			- Vector2($FrontQueueSpot.global_position.x, $FrontQueueSpot.global_position.z)).normalized()
		
		var queueDirection : Vector2 = baseQueueDirection
	
		if queueSpotList.size() >= 2:
			queueDirection = (
			queueSpotList[queueSpotList.size() - 1] - queueSpotList[queueSpotList.size() - 2]
			).normalized()
		
		var gapBuffer : Vector2 
		gapBuffer.x = queueGap * queueDirection.x
		gapBuffer.y = queueGap * queueDirection.y
	
		#print("\n", queueDirection.x)
		#print(ceil(queueDirection.x))
		#print(queueDirection.normalized())
		
		var newSpot : Vector2 = Vector2(
			queueSpotList[queueSpotList.size() - 1].x, 
			queueSpotList[queueSpotList.size() - 1].y) + gapBuffer
		
		var neighbourOffsets = [queueDirection,
						Vector2(queueDirection.y, -queueDirection.x),
						Vector2(-queueDirection.y, queueDirection.x),
						-queueDirection
						]
			
		var unavailableSpot : bool = false
		
		if round(newSpot) not in queueCellsList:
			if round(newSpot) not in Global.gridSys.gridDic:
				unavailableSpot = true
			elif (round(newSpot) in Global.gridSys.gridDic
			and (Global.gridSys.gridDic[round(newSpot)]["floorData"] == null
			or Global.gridSys.gridDic[round(newSpot)]["cellData"] != null)):
				unavailableSpot = true
			
			var edgeToCheck : Vector2 = (round(newSpot) + queueCellsList[queueCellsList.size() - 1]) / 2
			
			if edgeToCheck not in Global.gridSys.edgeDic:
				unavailableSpot = true
			elif (edgeToCheck in Global.gridSys.edgeDic #
			and Global.gridSys.edgeDic[edgeToCheck]["edgeData"] != null):
				unavailableSpot = true
			if !unavailableSpot:
				queueSpotList.append(newSpot)
				queueCellsList.append(round(newSpot))
		else:
			queueSpotList.append(newSpot)
		
		if unavailableSpot:
			newSpot -= gapBuffer
			var spotFound : bool = false
			for offset in neighbourOffsets:
				var spotToCheck : Vector2 = newSpot + (offset * queueGap)
				var newAvailableSpot : bool = true
				if offset == queueDirection or offset == -queueDirection:
					continue
				if round(spotToCheck) in queueCellsList:
					queueSpotList.append(spotToCheck)
					spotFound = true
					break
				else:
					if round(spotToCheck) not in Global.gridSys.gridDic:
						newAvailableSpot = false
					elif (round(spotToCheck) in Global.gridSys.gridDic
					and (Global.gridSys.gridDic[round(spotToCheck)]["floorData"] == null
					or Global.gridSys.gridDic[round(spotToCheck)]["cellData"] != null)):
						newAvailableSpot = false
					
					var edgeToCheck : Vector2 = (
						round(spotToCheck) + queueCellsList[queueCellsList.size() - 1]
						) / 2
					
					if edgeToCheck not in Global.gridSys.edgeDic:
						newAvailableSpot = false
					elif (edgeToCheck in Global.gridSys.edgeDic #
					and Global.gridSys.edgeDic[edgeToCheck]["edgeData"] != null):
						newAvailableSpot = false
				
				if newAvailableSpot:
					spotFound = true
					queueCellsList.append(round(spotToCheck))
					queueSpotList.append(spotToCheck)
					break
			
			if !spotFound:
				queueCellsList.append(round(newSpot + gapBuffer))
				queueSpotList.append(newSpot + gapBuffer)
		
	
	queueUpdated.emit()
	
func MoveQueue():
	customerQueueList.remove_at(0)
	UpdateQueue()

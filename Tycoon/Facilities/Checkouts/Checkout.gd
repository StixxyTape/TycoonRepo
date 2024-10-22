extends Node3D

@export var scanTime : float = 1
@export var queueGap : float = .7
@export var queueDistFromWall : float = .2

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

	Global.playerMoney += Global.stockSys.stockInventory[stockType]["sellPrice"]
	Global.UpdateUI()

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
		
		var checkQueueDirection : Vector2 = baseQueueDirection
		
		# We prevent customers from being on the edge of tiles
		if queueSpotList.size() >= 2:
			checkQueueDirection = (
			queueSpotList[queueSpotList.size() - 1] - queueSpotList[queueSpotList.size() - 2]
			).normalized()
		
		var checkGapBuffer : Vector2 
		checkGapBuffer.x = queueGap * checkQueueDirection.x
		checkGapBuffer.y = queueGap * checkQueueDirection.y
		
		var newCheckSpot : Vector2 = Vector2(
			queueSpotList[queueSpotList.size() - 1].x, 
			queueSpotList[queueSpotList.size() - 1].y) + checkGapBuffer
		
		var newCheckBufferSpot : Vector2 = newCheckSpot + (checkQueueDirection * queueDistFromWall)
		
		var checkNeighbourOffsets = [checkQueueDirection,
						Vector2(checkQueueDirection.y, -checkQueueDirection.x),
						Vector2(-checkQueueDirection.y, checkQueueDirection.x),
						-checkQueueDirection
						]
						
		var unavailableCheckSpot : bool = false	
		var spotToSkip : Vector2
		
		if round(newCheckBufferSpot) not in Global.gridSys.gridDic:
			unavailableCheckSpot = true
		elif (round(newCheckBufferSpot) in Global.gridSys.gridDic
		and (Global.gridSys.gridDic[round(newCheckBufferSpot)]["floorData"] == null
		or Global.gridSys.gridDic[round(newCheckBufferSpot)]["cellData"] != null)):
			unavailableCheckSpot = true
		
		if (round(newCheckBufferSpot) + round(newCheckSpot)) / 2 in Global.gridSys.edgeDic:
			var edgeToCheck : Vector2 = (round(newCheckBufferSpot) + round(newCheckSpot)) / 2
			if (Global.gridSys.edgeDic[edgeToCheck]["edgeData"] != null):
				unavailableCheckSpot = true
		
		if unavailableCheckSpot:
				spotToSkip = newCheckSpot
				
		# Here we add the actual spot, accounting for the edge fix 
		var queueDirection : Vector2 = baseQueueDirection
		
		if queueSpotList.size() >= 2:
			queueDirection = (
			queueSpotList[queueSpotList.size() - 1] - queueSpotList[queueSpotList.size() - 2]
			).normalized()
		
		var gapBuffer : Vector2 
		gapBuffer.x = queueGap * queueDirection.x
		gapBuffer.y = queueGap * queueDirection.y
		
		var newSpot : Vector2 = Vector2(
			queueSpotList[queueSpotList.size() - 1].x, 
			queueSpotList[queueSpotList.size() - 1].y) + gapBuffer

		var neighbourOffsets = [queueDirection,
						Vector2(queueDirection.y, -queueDirection.x),
						Vector2(-queueDirection.y, queueDirection.x),
						-queueDirection
						]
						
		gapBuffer.x = queueGap * queueDirection.x
		gapBuffer.y = queueGap * queueDirection.y
	
		#print("\n", queueSpotList[queueSpotList.size() - 2])
		#print(queueSpotList[queueSpotList.size() - 1])
		#print(queueDirection)
			
		var unavailableSpot : bool = false
		
		if newSpot != spotToSkip:
			if round(newSpot) not in queueCellsList:
				if round(newSpot) not in Global.gridSys.gridDic:
					unavailableSpot = true
				elif (round(newSpot) in Global.gridSys.gridDic
				and (Global.gridSys.gridDic[round(newSpot)]["floorData"] == null
				or Global.gridSys.gridDic[round(newSpot)]["cellData"] != null)):
					unavailableSpot = true
				
				var edgeToCheck : Vector2 = (round(newSpot) + round(queueSpotList[queueSpotList.size() - 1])) / 2
				
				if edgeToCheck not in Global.gridSys.edgeDic:
					unavailableSpot = true
				elif (edgeToCheck in Global.gridSys.edgeDic 
				and Global.gridSys.edgeDic[edgeToCheck]["edgeData"] != null):
					unavailableSpot = true
					
				if !unavailableSpot:
					queueSpotList.append(newSpot)
					queueCellsList.append(round(newSpot))
			else:
				queueSpotList.append(newSpot)
		
		if unavailableSpot or newSpot == spotToSkip:
			newSpot -= gapBuffer
			var spotFound : bool = false
			for offset in neighbourOffsets:
				var spotToCheck : Vector2 = newSpot + (offset * queueGap)
				var newAvailableSpot : bool = true
				if offset == queueDirection or offset == -queueDirection:
					continue
				if spotToCheck == spotToSkip:
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

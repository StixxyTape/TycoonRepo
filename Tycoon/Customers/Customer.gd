extends Node3D

#region Pathfinding
@export var movementSpeed : float = 0
@export var pathfindRange : float = 0
@export var pathfindEffort : int = 0

var movingAlongPath : bool = false
var movingAlongQueuePath : bool = false
var movingToShelf : bool = false
var movingToCheckout : bool = false

var queueTargetPos : Vector2
var movingToQueueSpace : bool = false

var currentPathList : Array = []
var nextPath : int = 0
var movementDir : Vector2 

var shelfInteractionSpots : Node3D
var interactionSpot : Node3D

var lookingForShelf : bool = false
var lookingForCheckout : bool = false

#endregion

#region Shopping
@export var shoppingCategories : Dictionary 

var currentShelf : Node3D
var currentCheckout : Node3D

var basket : Array = []

#endregion

func _ready() -> void:
	get_parent().spotOpenedUp.connect(OpenedShelfSpot)
	AssignShoppingList()
	ChooseShelf()

func _process(delta: float) -> void:
	if movingAlongPath:
		MoveToPath(delta)
	elif movingAlongQueuePath:
		QueueMoveToPath(delta)
	elif movingToQueueSpace:
		MoveToQueueSpace(delta)
		
func AssignShoppingList():
	var categoryAmount : int = randi_range(2, 2)
	var stockInventory : Dictionary = Global.stockSys.stockInventory
	while categoryAmount > 0:
		var randCategory : String = stockInventory[randi_range(1, stockInventory.size() - 1)]["category"]
		if  randCategory not in shoppingCategories:
			shoppingCategories[randCategory] = {
				"addedToBasket" : false,
				"amountToAdd" : randi_range(1, 8)
			}
			categoryAmount -= 1
	
func OpenedShelfSpot():
	if lookingForShelf:
		ChooseShelf()
		
func ChooseShelf():
	lookingForShelf = true
	var shelfArray = Global.buildSys.get_node("Shelves").get_children()
	if shelfArray.size() > 0:
		var availableShelves : Array = []
		for shelf in shelfArray:
			var matchingCategories : bool = false
			for key in shoppingCategories.keys():
				if (key in shelf.categories and !shoppingCategories[key]["addedToBasket"]
				and shelf.categories[key]["currentStock"] > 0):
					matchingCategories = true
					break
			if matchingCategories:
				var interactionSpotsDic = shelf.get_node("InteractionSpots").interactionDic
				for spot in interactionSpotsDic:
					if interactionSpotsDic[spot]["Occupied"] == false:
						availableShelves.append(shelf)
						break
						
		if availableShelves.size() <= 0:
			return
			
		var shelfTarget : Node3D
		
		while true:
			shelfTarget = availableShelves[randi_range(0, availableShelves.size() - 1)]
			shelfInteractionSpots = shelfTarget.get_node("InteractionSpots")
			interactionSpot = shelfInteractionSpots.get_child(
				randi_range(0, shelfInteractionSpots.get_child_count() - 1)
			)
			if !shelfInteractionSpots.interactionDic[interactionSpot]["Occupied"]:
				currentShelf = shelfTarget
				break
		movingToShelf = true
		PathFind(Vector2(
			round(interactionSpot.global_position.x), round(interactionSpot.global_position.z)
			))
		
	
func PathFind(targetPos : Vector2):
	# Reset these variables
	currentPathList.clear()
	nextPath = 0
	movementDir = Vector2.ZERO
	
	var gridDic = Global.gridSys.gridDic
	var edgeDic = Global.gridSys.edgeDic
	
	var xDist : float = abs(targetPos.x - position.x)
	var zDist : float = abs(targetPos.y - position.y)
	
	var xDir : int = xDist/-xDist
	var zDir : int = zDist/-zDist
	
	var neighbourOffsets = [Vector2(1, 0),
							Vector2(0, 1),
							Vector2(-1, 0),
							Vector2(0, -1)
							]
	
	var startingPos : Vector2 = Vector2(round(position.x), round(position.z))
	var currentTile = Vector2(round(position.x), round(position.z))
	
	var checkedTiles : Array = []
	var priorityQueue : Array = []
	var priorityDic : Dictionary = {}
	var directionDic : Dictionary = {}
	
	var effort : int = pathfindEffort
		
	if gridDic[targetPos]["cellData"] != null or gridDic[targetPos]["floorData"] == null:
		# If we can't reach the checkout, erase ourselves from it's list
		if movingToCheckout:
			currentCheckout.customerQueueList.erase(self)
		return
	if startingPos == targetPos:
		movingAlongPath = true
		currentPathList = []
		
		if movingToShelf:
			lookingForShelf = false
			shelfInteractionSpots.SetInteractionSpot(interactionSpot, true)
		if movingToCheckout:
			lookingForCheckout = false
			movingAlongPath = false
			movingAlongQueuePath = true
			
		return
		
	# A* from currentPos to target
	while true:
		for offset in neighbourOffsets:
			var offsetTile = currentTile + offset
			
			if offsetTile not in checkedTiles:
				if offsetTile in gridDic:
					if gridDic[offsetTile]["floorData"] == null or gridDic[offsetTile]["cellData"] != null:
						continue
				if (offsetTile + currentTile) / 2 in edgeDic:
					if edgeDic[(offsetTile + currentTile) / 2]["edgeData"] != null:
						continue
				var newDist = sqrt(
					(targetPos.x - offsetTile.x)**2 + (targetPos.y - offsetTile.y)**2)
				priorityQueue.append(newDist)
				checkedTiles.append(offsetTile)
				if newDist not in priorityDic:
					priorityDic[newDist] = {
						"Tiles" : [offsetTile]
					}
				else:
					priorityDic[newDist]["Tiles"].append(offsetTile)
				directionDic[offsetTile] = {
					"Direction" : -offset
				}
		
		# To prevent infinite path searching
		effort -= 1
		if effort <= 0:
			return
		# If an interaction spot is available but blocked, prevents game from crashing
		if priorityQueue.min() == null:
			return
		currentTile = priorityDic[priorityQueue.min()]["Tiles"][0]
		priorityDic[priorityQueue.min()]["Tiles"].remove_at(0)
		if priorityDic[priorityQueue.min()]["Tiles"].size() <= 0:
			priorityDic.erase(priorityQueue.min())
		priorityQueue.erase(priorityQueue.min())
		if abs(targetPos - currentTile) == Vector2.ZERO:
			break
		
	# Set these spots to occupied because we now know we can reach them
	if movingToShelf:
		lookingForShelf = false
		shelfInteractionSpots.SetInteractionSpot(interactionSpot, true)
	if movingToCheckout:
		lookingForCheckout = false
		
	var pathList : Array = [currentTile]
	
	var diagonalWallNeighbours : Array = [
		Vector2(.5, 0),
		Vector2(-.5, 0),
		Vector2(0, .5),
		Vector2(0, -.5)
	]
	while true:
		if (currentTile + directionDic[currentTile]["Direction"] in directionDic
			and ((abs(directionDic[currentTile]["Direction"]) == Vector2(1, 0)
			and abs(directionDic[currentTile + directionDic[currentTile]["Direction"]]["Direction"]) == Vector2(0, 1))
			or (abs(directionDic[currentTile]["Direction"]) == Vector2(0, 1)
			and abs(directionDic[currentTile + directionDic[currentTile]["Direction"]]["Direction"]) == Vector2(1, 0)))):
				# For checking if there is a wall, so that the customer doesn't clip through it
				var edgeCenter : Vector2 = ((currentTile + (
					(currentTile
					+ directionDic[currentTile]["Direction"] 
					+ directionDic[currentTile + directionDic[currentTile]["Direction"]]["Direction"])
				)) / 2)
				var blockedByWall : bool = false
				for neighbour in diagonalWallNeighbours:
					if edgeCenter + neighbour in edgeDic:
						if edgeDic[edgeCenter + neighbour]["edgeData"] != null:
							blockedByWall = true
				if blockedByWall:
					currentTile += directionDic[currentTile]["Direction"]
				else:
					currentTile += directionDic[currentTile]["Direction"] + directionDic[currentTile + directionDic[currentTile]["Direction"]]["Direction"]
		else:
			currentTile += directionDic[currentTile]["Direction"]
		pathList.append(currentTile)
		if abs(startingPos - currentTile) == Vector2.ZERO:
			break
			
	pathList.reverse()
	
	if movingToCheckout:
		movingAlongQueuePath = true
	else:
		movingAlongPath = true
	
	currentPathList = pathList
	
func MoveToPath(delta : float):
	if (nextPath == currentPathList.size()
	or Vector2(position.x, position.z).distance_to(currentPathList[currentPathList.size() - 1]) <= pathfindRange):
		movingAlongPath = false
		if movingToShelf:
			rotation_degrees.y = -currentShelf.rotation_degrees.y + 90
			AddToBasket()
		movingToShelf = false
		return
	if Vector2(position.x, position.z).distance_to(currentPathList[nextPath]) <= pathfindRange:
		nextPath += 1
		movementDir = (currentPathList[nextPath] - Vector2(position.x, position.z)).normalized()
		look_at(Vector3(currentPathList[nextPath].x, 0, currentPathList[nextPath].y))
	else:
		position += Vector3(movementDir.x, 0, movementDir.y) * movementSpeed * delta

func AddToBasket():
	var availableShelfLevels : Array = currentShelf.get_node("ShelfLevels").get_children()
	var pickedShelfLevels : Array = []
	for child in availableShelfLevels:
		
		#Picks a random shelflevel
		child = availableShelfLevels[randi_range(0, availableShelfLevels.size() - 1)]
		while child in pickedShelfLevels:
			child = availableShelfLevels[randi_range(0, availableShelfLevels.size() - 1)]
		pickedShelfLevels.append(child)
		if child.stockType == 000:
			continue
			
		var category = Global.stockSys.stockInventory[child.stockType]["category"]
		if category in shoppingCategories:
			if child.GetShelfState().currentStock > 0 and !shoppingCategories[category]["addedToBasket"]:
				#print("What I want: ", shoppingCategories[category]["amountToAdd"])
				#print("Stock left: ", child.GetShelfState().currentStock)
				if child.GetShelfState().currentStock >= shoppingCategories[category]["amountToAdd"]:
					child.GetShelfState().currentStock -= shoppingCategories[category]["amountToAdd"]
					for x in shoppingCategories[category]["amountToAdd"]:
						await get_tree().create_timer(.1).timeout
						child.CustomerUpdate(1)
						basket.append(child.stockType)
					#print("What I got when it had more: ", shoppingCategories[category]["amountToAdd"])
				else:
					var oldStockAmount : int = child.GetShelfState().currentStock
					child.GetShelfState().currentStock = 0
					for x in oldStockAmount:
						await get_tree().create_timer(.1).timeout
						child.CustomerUpdate(1)
						basket.append(child.stockType)
					#print("What I got when it had less: ", oldStockAmount)
				shoppingCategories[category]["addedToBasket"] = true
		
		child.CustomerUpdate(0)
		
	shelfInteractionSpots.SetInteractionSpot(interactionSpot, false)
	get_parent().spotOpenedUp.emit()
	
	for category in shoppingCategories:
		if !shoppingCategories[category]["addedToBasket"]:
			ChooseShelf()
			return
			
	ChooseCheckout()
	
func ChooseCheckout():
	lookingForCheckout = true
	var checkoutArray = Global.buildSys.get_node("Checkouts").get_children()
	if checkoutArray.size() > 0:
		var availableCheckouts : Array = []
		for checkout in checkoutArray:
			availableCheckouts.append(checkout)
						
		if availableCheckouts.size() <= 0:
			return
		
		currentCheckout = availableCheckouts[randi_range(0, availableCheckouts.size() - 1)]
		currentCheckout.customerQueueList.append(self)
		currentCheckout.UpdateQueue()
		
		#print(currentCheckout.customerQueueList)
		#print(currentCheckout.queueSpotList)
		#print(currentCheckout.queueCellsList)
		
		var checkoutTarget : Vector2 = currentCheckout.queueSpotList[
			currentCheckout.customerQueueList.find(self)
		]
		
		movingToCheckout = true
		
		queueTargetPos = checkoutTarget
		PathFind(round(queueTargetPos))

func QueueMoveToPath(delta : float):
	if (nextPath == currentPathList.size() - 1 or currentPathList.size() == 0
	or Vector2(position.x, position.z).distance_to(currentPathList[currentPathList.size() - 1]) <= pathfindRange):
		movingAlongQueuePath = false
		movingToCheckout = false
		currentCheckout.queueUpdated.connect(WaitInQueue)
		WaitInQueue()
		return
	if Vector2(position.x, position.z).distance_to(currentPathList[nextPath]) <= pathfindRange:
		nextPath += 1
		movementDir = (currentPathList[nextPath] - Vector2(position.x, position.z)).normalized()
		look_at(Vector3(currentPathList[nextPath].x, 0, currentPathList[nextPath].y))
	else:
		position += Vector3(movementDir.x, 0, movementDir.y) * movementSpeed * delta
		
func WaitInQueue():
	var checkoutTarget : Vector2 = currentCheckout.queueSpotList[
			currentCheckout.customerQueueList.find(self)
		]
	queueTargetPos = checkoutTarget
	
	var lookSpot : Vector3 = Vector3(queueTargetPos.x, 0, queueTargetPos.y)
	if currentCheckout.queueSpotList.size() >= 1:
		var nextQueuePos : Vector2 = currentCheckout.queueSpotList[
			currentCheckout.queueSpotList.find(queueTargetPos) - 1
		]
		lookSpot = Vector3(nextQueuePos.x, 0, nextQueuePos.y)
		
	look_at(lookSpot)
	movementDir = (queueTargetPos - Vector2(position.x, position.z)).normalized()
	movingToQueueSpace = true
	
func MoveToQueueSpace(delta : float):
	if Vector2(position.x, position.z).distance_to(queueTargetPos) <= pathfindRange:
		movingToQueueSpace = false
		if queueTargetPos == currentCheckout.queueSpotList[0]:
			currentCheckout.queueUpdated.disconnect(WaitInQueue)
			rotation_degrees.y = -currentCheckout.rotation_degrees.y + 90
			Checkout()
		return
	else:
		position += Vector3(movementDir.x, 0, movementDir.y) * movementSpeed * delta
	
func Checkout():
	while basket.size() > 0:
		var checkoutItem = basket[randi_range(0, basket.size() - 1)]
		basket.erase(checkoutItem)
		
		currentCheckout.Scan(checkoutItem)
		
		await currentCheckout.scanned
	
	currentCheckout.MoveQueue()
	queue_free()

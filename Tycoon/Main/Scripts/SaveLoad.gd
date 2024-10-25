extends Node

var savePath : String = "user://gameData.save"

func LoadGame():
	var saveNodes = get_tree().get_nodes_in_group("Persist")
	for node in saveNodes:
		for floor in Global.gridSys.maxFloor + 1:
			if node in Global.buildSys.floorObjects[floor]:
				Global.buildSys.floorObjects[floor].erase(node)
				node.queue_free()
			elif node in Global.buildSys.floorEdges[floor]:
				Global.buildSys.floorEdges[floor].erase(node)
				node.queue_free()
			elif node in Global.buildSys.floorFloors[floor]:
				Global.buildSys.floorFloors[floor].erase(node)
				node.queue_free()
			
	if FileAccess.file_exists(savePath):
		var saveFile = FileAccess.open(savePath, FileAccess.READ)
		var loadingPlayerData : bool = true
		var loadingStockData : bool = true
		var loadingGridData : bool = true
		var loadingBuildData : bool = true
		while saveFile.get_position() < saveFile.get_length():
			var json = JSON.new()
			var parseResult = json.parse(saveFile.get_line())
			var dicData = json.data
			if "PlayerData" in dicData:
				loadingPlayerData = true
				continue
			elif "StockData" in dicData:
				loadingPlayerData = false
				continue
			elif "GridData" in dicData:
				loadingStockData = false
				continue
			elif "BuildData" in dicData:
				loadingGridData = false
				continue
			
			if loadingPlayerData:
				Global.playerMoney = dicData["Money"]
			elif loadingStockData:
				if dicData["stockType"] == 000:
					continue
				Global.stockSys.stockInventory[int(dicData["stockType"])]["amount"] = int(dicData["amount"])
			elif loadingGridData:
				var currentFloor : int = 0
				if "CurrentFloor" in dicData:
					currentFloor = int(dicData["CurrentFloor"])
				if "dicEntry" in dicData:
					var dicEntry = StrToVec2(dicData["dicEntry"])
					var edge : bool = false
					if "edgeData" in dicData:
						edge = true
					if !edge:
						var convertedCells : Array = []
						if dicData["cells"].size() > 0:
							for cell in dicData["cells"]:
								convertedCells.append(StrToVec2(cell))
						var newStorageEdge = null
						if dicData["storageEdge"]:
							newStorageEdge = StrToVec2(dicData["storageEdge"])
						Global.gridSys.floorGridDics[currentFloor][dicEntry] = {
							"floorData" : null,
							"cellData" : null,
							"cells" : convertedCells,
							"storageEdge" : newStorageEdge,
							"interactionSpot" : int(dicData["interactionSpot"])
						}
						#for x in Global.gridSys.floorGridDics[currentFloor][dicEntry]:
							#print(Global.gridSys.floorGridDics[currentFloor][dicEntry][x])
							
					elif edge:
						var convertedEdges : Array = []
						var convertedInteractionEdges : Array = []
						if dicData["edges"].size() > 0:
							for edgePos in dicData["edges"]:
								convertedEdges.append(StrToVec2(edgePos))
						if dicData["interactionEdges"].size() > 0:
							for edgePos in dicData["interactionEdges"]:
								convertedInteractionEdges.append(StrToVec2(edgePos))
						Global.gridSys.floorEdgeDics[currentFloor][dicEntry] = {
							"scale" : StrToVec3(dicData["scale"]),
							"edgeData" : null,
							"cellData" : null,
							"edges" : convertedEdges,
							"interactionEdges" : convertedInteractionEdges,
							"interactionEdge" : int(dicData["interactionEdge"])
						}
			
			elif loadingBuildData:
				var currentFloor : int = int(dicData["currentFloor"])
				var newObj = load(dicData["fileName"]).instantiate()
				newObj.position = Vector3(float(dicData["posX"]), float(dicData["posY"]), float(dicData["posZ"]))
				newObj.rotation = StrToVec3(dicData["rotation"])
				newObj.set_meta("currentFloor", currentFloor)
				for group in dicData["groups"]:
					newObj.add_to_group(group, true)
				if newObj.is_in_group("Edge"):
					Global.buildSys.floorEdges[currentFloor].append(newObj)
				elif newObj.is_in_group("Floor"):
					Global.buildSys.floorFloors[currentFloor].append(newObj)
				else:
					Global.buildSys.floorObjects[currentFloor].append(newObj)
				get_node(dicData["parent"]).add_child(newObj)
				Global.gridSys.DuplicateMaterial(newObj)
				if "edges" in dicData and "cells" in dicData:
					var newCells : Array = []
					for cell in dicData["cells"]:
						cell = StrToVec2(cell)
						newCells.append(cell)
						Global.gridSys.floorGridDics[currentFloor][cell]["cellData"] = newObj
					newObj.set_meta("cells", newCells)
					var newEdges : Array = []
					for edge in dicData["edges"]:
						edge = StrToVec2(edge)
						newEdges.append(edge)
						Global.gridSys.floorEdgeDics[currentFloor][edge]["cellData"] = newObj
					newObj.set_meta("edges", newEdges)
				elif "edges" in dicData and "cells" not in dicData:
					var newEdges : Array = []
					for edge in dicData["edges"]:
						edge = StrToVec2(edge)
						newEdges.append(edge)
						Global.gridSys.floorEdgeDics[currentFloor][edge]["edgeData"] = newObj
					newObj.set_meta("edges", newEdges)
				elif "edges" not in dicData and "cells" in dicData:
					newObj.set_meta("cells", StrToVec2(dicData["cells"]))
					var cell : Vector2 = StrToVec2(dicData["cells"])
					Global.gridSys.floorGridDics[currentFloor][cell]["floorData"] = newObj
				
				if newObj.is_in_group("Shelf"):
					var indexCount : int = 0
					for shelfLevel in newObj.get_node("ShelfLevels").get_children():
						shelfLevel.stockType = int(dicData["stockTypes"][indexCount])
						shelfLevel.get_node("ShelfState").currentStock = int(dicData["currentStocks"][indexCount])
						shelfLevel.AutoStockCheck()
						shelfLevel.ChangeStock()
						indexCount += 1
		
	Global.UpdateUI()
	
func SaveGame():
	var saveFile = FileAccess.open(savePath, FileAccess.WRITE)
	
	SavePlayerData(saveFile)
	SaveStockData(saveFile)
	SaveGrid(saveFile)
	SaveBuilding(saveFile)

func SavePlayerData(saveFile):
	saveFile.store_line(JSON.stringify("PlayerData"))
	var playerDataDic : Dictionary = {
		"Money" : Global.playerMoney
	}
	saveFile.store_line(JSON.stringify(playerDataDic))
	
func SaveStockData(saveFile):
	saveFile.store_line(JSON.stringify("StockData"))
	var stockDataDic : Dictionary = Global.stockSys.stockInventory.duplicate(true)
	for stockType in stockDataDic:
		stockDataDic[stockType]["stockType"] = stockType
		saveFile.store_line(JSON.stringify(stockDataDic[stockType]))
	
func SaveGrid(saveFile):
	saveFile.store_line(JSON.stringify("GridData"))
	for floor in Global.gridSys.maxFloor + 1:
		var floorDic : Dictionary = {
			"CurrentFloor" : str(floor)
		}
		saveFile.store_line(JSON.stringify(floorDic))
		var saveGridDic : Dictionary = Global.gridSys.floorGridDics[floor].duplicate(true)
		for entry in saveGridDic:
			saveGridDic[entry]["dicEntry"] = entry
			saveFile.store_line(JSON.stringify(saveGridDic[entry]))
		var saveEdgeDic : Dictionary = Global.gridSys.floorEdgeDics[floor].duplicate(true)
		for entry in saveEdgeDic:
			saveEdgeDic[entry]["dicEntry"] = entry
			saveFile.store_line(JSON.stringify(saveEdgeDic[entry]))
		
func SaveBuilding(saveFile):
	saveFile.store_line(JSON.stringify("BuildData"))
	var saveNodes = get_tree().get_nodes_in_group("Persist")
	for object in saveNodes:
		var objDic : Dictionary
		objDic[object.get_scene_file_path()] = {
			"fileName" : object.get_scene_file_path(),
			"parent" : object.get_parent().get_path(),
			"groups" : object.get_groups(),
			"posX" : object.global_position.x,
			"posY" : object.global_position.y,
			"posZ" : object.global_position.z,
			"rotation" : object.rotation,
			"currentFloor" : object.get_meta("currentFloor")
		}
		if object.is_in_group("Shelf"):
			var stockTypes : Array
			var currentStocks : Array 
			for shelfLevel in object.get_node("ShelfLevels").get_children():
				stockTypes.append(shelfLevel.stockType)
				currentStocks.append(shelfLevel.get_node("ShelfState").currentStock)
			objDic[object.get_scene_file_path()]["stockTypes"] = stockTypes
			objDic[object.get_scene_file_path()]["currentStocks"] = currentStocks
			
		if object.has_meta("cells"):
			objDic[object.get_scene_file_path()]["cells"] = object.get_meta("cells")
		if object.has_meta("edges"):
			objDic[object.get_scene_file_path()]["edges"] = object.get_meta("edges")
		
		saveFile.store_line(JSON.stringify(objDic[object.get_scene_file_path()]))

func StrToVec2(string := "") -> Vector2:
	if string:
		var newStr: String = string
		newStr = newStr.erase(0, 1)
		newStr = newStr.erase(newStr.length() - 1, 1)
		var array: Array = newStr.split(", ")

		return Vector2(float(array[0]), float(array[1]))

	return Vector2.ZERO

func StrToVec3(string := "") -> Vector3:
	if string:
		var newStr: String = string
		newStr = newStr.erase(0, 1)
		newStr = newStr.erase(newStr.length() - 1, 1)
		var array: Array = newStr.split(", ")
		return Vector3(float(array[0]), float(array[1]), float(array[2]))

	return Vector3.ZERO

func SetPackedSceneOwnership(parent : Node3D, recursiveChild):
	for child in recursiveChild.get_children():
		child.set_owner(parent)
		SetPackedSceneOwnership(parent, child)
		

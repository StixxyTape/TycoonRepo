extends Node3D

var activeWall : Node3D

func _process(delta: float) -> void:
	if get_children().size() <= 0:
		return
	if !is_instance_valid(activeWall) or activeWall == null:
		activeWall = get_child(0)
	
	var cam : Camera3D = Global.camController.get_node("Camera3D")
	var camPos : Vector2 = Vector2(cam.global_position.x, cam.global_position.z)
	var camDir = camPos.direction_to(Vector2(activeWall.global_position.x, activeWall.global_position.z))
	var forwardDir : Vector2 = Vector2(
		activeWall.get_global_transform().basis.z.normalized().z,
		activeWall.get_global_transform().basis.z.normalized().x)
	
	if camDir.dot(forwardDir) > 0:
		if round(activeWall.global_position.x) - activeWall.global_position.x != 0:
			var cellToCheck : Vector2 = Vector2(activeWall.global_position.x + (forwardDir.x/2), activeWall.global_position.z)
			if cellToCheck not in Global.landSys.ownedCells:
				scale.y = 1
				return
			if Global.gridSys.floorGridDics[Global.buildSys.currentFloor][cellToCheck]["inside"]:
				scale.y = .1
				return
			else:
				scale.y = 1
		elif round(activeWall.global_position.z) - activeWall.global_position.z != 0:
			var cellToCheck : Vector2 = Vector2(activeWall.global_position.x, activeWall.global_position.z + (forwardDir.y/2))
			if cellToCheck not in Global.landSys.ownedCells:
				scale.y = 1
				return
			if Global.gridSys.floorGridDics[Global.buildSys.currentFloor][cellToCheck]["inside"]:
				scale.y = .1
				return
			else:
				scale.y = 1
		#if Global.gridSys.floorGridDics[Global.buildSys.currentFloor]
	elif camDir.dot(forwardDir) < 0:
		if round(activeWall.global_position.x) - activeWall.global_position.x != 0:
			var cellToCheck : Vector2 = Vector2(activeWall.global_position.x + (-forwardDir.x/2), activeWall.global_position.z)
			if cellToCheck not in Global.landSys.ownedCells:
				scale.y = 1
				return
			if Global.gridSys.floorGridDics[Global.buildSys.currentFloor][cellToCheck]["inside"]:
				scale.y = .1
				return
			else:
				scale.y = 1
		elif round(activeWall.global_position.z) - activeWall.global_position.z != 0:
			var cellToCheck : Vector2 = Vector2(activeWall.global_position.x, activeWall.global_position.z + (-forwardDir.y/2))
			if cellToCheck not in Global.landSys.ownedCells:
				scale.y = 1
				return
			if Global.gridSys.floorGridDics[Global.buildSys.currentFloor][cellToCheck]["inside"]:
				scale.y = .1
				return
			else:
				scale.y = 1
		#scale.y = .1
	#else:
		#
	
	
	#if camDir.dot()

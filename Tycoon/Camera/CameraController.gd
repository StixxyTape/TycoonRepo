extends Camera3D

var camInput : Vector2
var rotationVel : Vector2
var smoothness : float = 30
var speed : float = 6

var frozen : bool = false

var camTween : Tween

# for resetting the camera after exiting the tween
var ogTweenPos : Vector3
var ogTweenRot : Vector3

var intersectionRIDs : Array 
var transparentMatDic : Dictionary 

var fuck

func _input(event):
	if event is InputEventMouseMotion:
		camInput = event.relative

func _physics_process(delta):
	if Global.camCanMove:
		MovementManager(delta)
	if Input.is_action_just_released("CameraRotate"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			
func MovementManager(delta):
	if Input.is_action_pressed("CameraRotate"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		rotationVel = rotationVel.lerp(camInput * 0.08, delta * smoothness)
		get_parent().rotate_y(-rotationVel.x * 0.08)
		rotate_x(-rotationVel.y * 0.08)
		
		rotation.x = clampf(rotation.x, -PI/2, PI/2)
		
		camInput = Vector2.ZERO
	
	if Input.is_action_pressed("Run"):
		speed = 15
	else:
		speed = 6
	
		
	var input_dir = Input.get_vector("Left", "Right", "Forward", "Backward")
	var direction = (get_parent().transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		direction.y = -input_dir.y * rotation_degrees.x / 90
		get_parent().global_position += direction * speed * delta

func TweenCamera(object : Node3D, distance : float, time : float):	
	for child in get_children():
		if child.is_in_group("Temp"):
			child.queue_free()
			
	if is_instance_valid(camTween):
		camTween.stop()
	camTween = get_tree().create_tween()
	camTween.set_parallel(true)
	camTween.set_ease(Tween.EASE_IN_OUT)
	camTween.set_trans(Tween.TRANS_QUAD)
	
	if !ogTweenPos:
		ogTweenPos = get_parent().global_position
		ogTweenRot = Vector3(rotation.x, get_parent().rotation.y, 0)
		
	var posOffset : Vector3 = object.get_transform().basis.x * distance
	posOffset += object.get_transform().basis.z * (distance * .7)
	posOffset.y = object.global_position.y + 1.3
	
	var tweenPos = posOffset + object.global_position
	
	camTween.tween_property(
		get_parent(), "global_position", tweenPos, time
		)
	
	var tempRotObj = Node3D.new()
	add_child(tempRotObj)
	tempRotObj.top_level = true
	tempRotObj.add_to_group("Temp")
	tempRotObj.global_position = tweenPos
	tempRotObj.look_at(object.global_position)
	
	var tweenRot = lerp_angle(get_parent().rotation.y, tempRotObj.rotation.y, 1)
	
	camTween.tween_property(
		get_parent(), "rotation", Vector3(0, tweenRot, 0), time
		)
	# The downwards look angle
	var downPan : float = -20
	camTween.tween_property(
		self, "rotation_degrees", Vector3(downPan, 0, 0), time
		)
	

	RayCastCheck(object, tweenPos)
	
	
func RayCastCheck(object : Node3D, rayCastPos : Vector3):
	ClearRayCastIntersections()
	
	# To prevent the object we zoom in on from going transparent
	intersectionRIDs.append(object.get_child(0).get_node("StaticBody3D").get_rid())
	while true:
		var spaceState = get_world_3d().direct_space_state
		var query : PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
			object.global_position, rayCastPos, 1);

		query.exclude = intersectionRIDs.duplicate()
		
		var intersection = spaceState.intersect_ray(query)
		print(query)
		if !intersection.is_empty():
			intersectionRIDs.append(intersection["rid"])
			var objMesh : MeshInstance3D = SearchForMesh(intersection["collider"].get_parent())
			var objMat : StandardMaterial3D = objMesh.get_active_material(0)
			var objCollider : CollisionObject3D = intersection["collider"]
			transparentMatDic[objMat] = {
				"OriginalValues" : [objMat.get_transparency(),
									objMat.get_cull_mode(), 
									objMat.get_depth_draw_mode(),
									objMat.albedo_color.a],
				"Collider" : objCollider
			}
			objMat.set_transparency(1)
			objMat.set_cull_mode(0)
			objMat.set_depth_draw_mode(1)
			objMat.albedo_color.a = .4
			
			objCollider.set_collision_layer_value(1, false)
			
		else:
			intersectionRIDs.clear()
			break

func SearchForMesh(currentLayer):
	# Assuming that the mesh instance isn't buried under another node, this should always find it
	while true:
		if currentLayer is MeshInstance3D:
			return currentLayer
		for child in currentLayer.get_children():
			if child is MeshInstance3D:
				return child
		currentLayer = currentLayer.get_parent()
			
func ExitTween():
	ClearRayCastIntersections()
	
	for child in get_children():
		if child.is_in_group("Temp"):
			child.queue_free()
			
	if is_instance_valid(camTween):
		camTween.stop()
	camTween = get_tree().create_tween()
	camTween.set_parallel(true)
	camTween.set_ease(Tween.EASE_IN_OUT)
	camTween.set_trans(Tween.TRANS_QUAD)
	
	camTween.tween_property(
		get_parent(), "global_position", ogTweenPos, .8
		)
	
	var tweenRotY = lerp_angle(get_parent().rotation.y, ogTweenRot.y, 1)
	var tweenRotX = lerp_angle(rotation.x, ogTweenRot.x, 1)
	
	camTween.tween_property(
		get_parent(), "rotation", Vector3(0, tweenRotY, 0), .8
		)
	camTween.tween_property(
		self, "rotation", Vector3(tweenRotX, 0, 0), .8
		)
	
	ogTweenPos = Vector3.ZERO
	ogTweenRot = Vector3.ZERO
	
func ClearRayCastIntersections():
	intersectionRIDs.clear()
	
	for mat in transparentMatDic:
		transparentMatDic[mat]["Collider"].set_collision_layer_value(1, true)
		
		mat.set_transparency(transparentMatDic[mat]["OriginalValues"][0])
		mat.set_cull_mode(transparentMatDic[mat]["OriginalValues"][1])
		mat.set_depth_draw_mode(transparentMatDic[mat]["OriginalValues"][2])
		mat.albedo_color.a = transparentMatDic[mat]["OriginalValues"][3]
	transparentMatDic.clear()

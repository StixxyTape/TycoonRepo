extends Node3D

var objectsDic : Dictionary
var customerPref : PackedScene = preload("res://Customers/Customer.tscn")

func _ready() -> void:
	Global.spawnCustomerSignal.connect(SpawnCustomer)
	
func SpawnCustomer():
	var newCustomer = customerPref.instantiate()
	newCustomer.position = Vector3(5, 0, 5)
	add_child(newCustomer)

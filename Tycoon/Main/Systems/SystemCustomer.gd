extends Node3D

var objectsDic : Dictionary
var customerPref : PackedScene = preload("res://Customers/Customer.tscn")

# For customers to check if there's an available spot everytime one opens up
signal spotOpenedUp 

func _ready() -> void:
	Global.spawnCustomerSignal.connect(SpawnCustomer)
	
func SpawnCustomer():
	var newCustomer = customerPref.instantiate()
	newCustomer.position = Vector3(2, 0, 7)
	Global.gridSys.DuplicateMaterial(newCustomer)
	add_child(newCustomer)

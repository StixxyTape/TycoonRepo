extends Node3D

var customerPref : PackedScene = preload("res://Customers/Customer.tscn")

var doneSpawningCustomers : bool = false

var baseCustomerSpawnTime : float
var customerSpawnTime : float 

# For customers to check if there's an available spot everytime one opens up
signal spotOpenedUp 

func _ready() -> void:
	Global.actionTimeSignal.connect(UpdateTimeScale)

func UpdateTimeScale():
	var newSpawnTime : float = baseCustomerSpawnTime / Global.actionPhaseTimeScale
	if customerSpawnTime != newSpawnTime and baseCustomerSpawnTime >= 1:
		var newTimerTime = $SpawnTimer.time_left * (newSpawnTime / customerSpawnTime)
		$SpawnTimer.start(newTimerTime)
		customerSpawnTime = newSpawnTime

func BeginCustomerSpawn(amountToSpawn : int, spawnTime : float, spawnTimeVariance : float):
	baseCustomerSpawnTime = spawnTime
	customerSpawnTime = spawnTime
	SpawnCustomers(amountToSpawn, spawnTimeVariance)
	
func SpawnCustomers(amountToSpawn : int, spawnTimeVariance : float):
	if amountToSpawn > 0:
		$SpawnTimer.start(randf_range(
			customerSpawnTime - spawnTimeVariance / Global.actionPhaseTimeScale, 
			customerSpawnTime + spawnTimeVariance / Global.actionPhaseTimeScale)
			)
		await $SpawnTimer.timeout
		
		var newCustomer = customerPref.instantiate()
		newCustomer.position = Vector3(2, 0, 3)
		Global.gridSys.DuplicateMaterial(newCustomer)
		
		if amountToSpawn == 1:
			doneSpawningCustomers = true
			
		add_child(newCustomer)
		SpawnCustomers(amountToSpawn - 1, spawnTimeVariance)
		
		
	
func MoveToPrepPhaseCheck():
	# We set it to 2 to account for the timer and last customer calling the function before leaving
	if get_children().size() <= 2 and doneSpawningCustomers:
		doneSpawningCustomers = false
		baseCustomerSpawnTime = 0
		Global.ChangePhase(false)

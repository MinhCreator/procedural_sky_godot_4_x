@tool
extends Node

#có, ví dụ trên godot 3: get_node("Node").material.set("shader_param/value",0). Còn trên godot 4 thì đổi shader_param thành shader_parameter.
# moon system is unused by default because of this main cause issue for day and night cycle system 

@export_category("Light")
@export var sun: DirectionalLight3D
@export var isNight: bool
@export var day_light_intensity: Curve

@export_category("Time")
@export var Time_Simulation: bool
@export_range(0, 100) var orbitSpeed: float = 0.4

@export_category("Calendar")
@export var Day: int
@export var Month: int
@export var Year: int
@export_category("Environment")
@export var env := WorldEnvironment
@export_range(0, 24) var Time_of_day: float
@export var day_lenght: float = 24.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

#random number
var rng = RandomNumberGenerator.new()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:

	if Time_Simulation:
		_Time(delta)
	
	# print(cal_calendar(delta))
		
# Time Simulation 	
func _Time(delta: float) -> void:
	
	Time_of_day += delta * orbitSpeed

	if Time_of_day > 24.0:
		Time_of_day = 0
		Day += 1

		if Day == 30:
			Month += 1
			Day = 0

		if Month == 12:
			Year += 1
			Month = 0
	_updateTime()

# Update Time and light rotation
func _updateTime() -> void:
	var alpha = Time_of_day / day_lenght
	var sunRotation = alpha * 360
	#var moonRotation = alpha * 360 + 270
	
	sun.rotation_degrees = Vector3(sunRotation, -150.0, 0)

	sun.light_energy = day_light_intensity.sample(alpha)

	var sun_light = sun.light_energy > 0

	if sun_light:
		isNight = false
	else:
		isNight = true

	CheckNightDayTransition()

# day and night transition
func CheckNightDayTransition() -> void:

	if isNight == false: StartDay()
	
	else: StartNight()

func StartDay() -> void:
	isNight = false

func StartNight() -> void:
	isNight = true

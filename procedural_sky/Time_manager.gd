@tool
extends Node


#Ví dụ trên godot 3: get_node("Node").material.set("shader_param/value",0). Còn trên godot 4 thì đổi shader_param thành shader_parameter.
# moon system is unused by default because of this main cause issue for day and night cycle system
@export_group("Lighting")
@export var light_source: DirectionalLight3D
@export var rotationOffset: Vector3
@export var dayStarIntensity: float = 0.0
@export var nightStarIntensity: float = 0.5
@export var dayshootStarsIntensity: float = 0.0
@export var nightshootStarsIntensity: float = 1.2

@export_category("Environment")
@export var worldEnvironment: WorldEnvironment
var sky: ShaderMaterial

#@export var moon: DirectionalLight3D
@export_category("Time")
@export var TimeSimulation: bool
@export var currentTime: float = 480.0
@export var speedMultiplier: float = 1.0
@export var secondsPerMinute: float = 1.0
@export var dayLengthHours: int = 24
@export var dayLengthMinutes: int
@export var sunriseHour: int = 6
@export var sunsetHour: int = 18
@export var isDay: bool
@export var isNight: bool

@export_category("Calendar")
@export_subgroup("date")
@export var Day: int
@export var Month: int
@export var Year: int
@export_subgroup("Clock")
@export var hours: int
@export var minutes: int

@export_subgroup("date format")
@export var date_format = formats
@export var FormatSymbol: String = "/"
@export var DateFormatDisplay: String
## Use these to determine in-game time

@export_group("moon Phase")
@export var moonPhase: bool
@export var moonPhaseCalc: float

enum formats {Date_Month_Year = 0, Month_Date_Year = 1, Year_Month_Date = 2}

# Called when the node enters the scene tree for the first time.

@export_category("Colors")
@export var transitionSpeed: float = 0.001
@export_subgroup("Clouds")
@export var dayCloudColor := Color("e0e0e0")
@export var nightCloudColor := Color("3c3c3c")
@export var dayLightScatter: Color = Color("4c4c4c")
@export var nightLightScatter: Color = Color("0e0929")
var daylightDuration: float
var totalGameMinutes: float
var myRotation: float


func _ready():
	# References
	sky = worldEnvironment.environment.sky.sky_material
	
	# Time and rotation
	totalGameMinutes = dayLengthHours * 60.0 + dayLengthMinutes
	daylightDuration = (sunsetHour - sunriseHour) * 60.0
	myRotation = 180.0 / daylightDuration

func _process(delta):
	if TimeSimulation:
		# Sun and moon rotation
		obj_rotation(delta)
		update_clock()
	if moonPhase: moonPhaseCalc = moonPhase_calculator()
	DateFormatDisplay = dateFormat()
	update_sky()
	"""run debug"""
	# print(date_format)
	# Debug shader
	#print(sky.get_shader_parameter("stars_intensity"))
	# print(sky.get_shader_parameter("shooting_stars_intensity"))
func obj_rotation(delta: float):
	currentTime += delta / secondsPerMinute * speedMultiplier
	if currentTime >= totalGameMinutes: currentTime = 0.0

	var timeSinceSunrise: float = currentTime - sunriseHour * 60.0
	
	light_source.rotation_degrees = Vector3(timeSinceSunrise * myRotation + 180.0, 0.0, 0.0) + rotationOffset

func update_sky():
	var lerpSpeed: float = transitionSpeed * speedMultiplier

	# make smooth transition between day and night with lerp
	var stars = sky.get_shader_parameter("stars_intensity")
	var shooting_stars = sky.get_shader_parameter("shooting_stars_intensity")

	if hours >= sunriseHour && hours <= sunsetHour - 1:
		# Lerp transition day 
		# Stars
			# sky.set_shader_parameter("stars_intensity", lerp(sky.get_shader_parameter("stars_intensity"), dayStarIntensity, lerpSpeed))
			sky.set_shader_parameter("stars_intensity", lerp(stars, dayStarIntensity, lerpSpeed))

		# shooting stars
			# sky.set_shader_parameter("shooting_stars_intensity", lerp(sky.get_shader_parameter("shooting_stars_intensity"), dayshootStarsIntensity, lerpSpeed))
			sky.set_shader_parameter("shooting_stars_intensity", lerp(shooting_stars, dayshootStarsIntensity, lerpSpeed))
		# Cloud color
			var cloudLerp: Color = sky.get_shader_parameter("clouds_light_color")
			cloudLerp = cloudLerp.lerp(dayCloudColor, lerpSpeed)
			sky.set_shader_parameter("clouds_light_color", cloudLerp)
		
		# Light scatter
			var lightLerp: Color = sky.get_shader_parameter("light_scatter")
			lightLerp = lightLerp.lerp(dayLightScatter, lerpSpeed)
			sky.set_shader_parameter("light_scatter", lightLerp)

	else:
		# Lerp transition night		
		# Stars
			# sky.set_shader_parameter("stars_intensity", lerp(sky.get_shader_parameter("stars_intensity"), nightStarIntensity, lerpSpeed))
			sky.set_shader_parameter("stars_intensity", lerp(stars, nightStarIntensity, lerpSpeed))

		# shooting stars
			sky.set_shader_parameter("shooting_stars_intensity", lerp(shooting_stars, nightshootStarsIntensity, lerpSpeed))
		# Cloud color
			var cloudLerp: Color = sky.get_shader_parameter("clouds_light_color")
			cloudLerp = cloudLerp.lerp(nightCloudColor, lerpSpeed)
			sky.set_shader_parameter("clouds_light_color", cloudLerp)

		# Light scatter
			var lightLerp: Color = sky.get_shader_parameter("light_scatter")
			lightLerp = lightLerp.lerp(nightLightScatter, lerpSpeed)
			sky.set_shader_parameter("light_scatter", lightLerp)


func update_clock():
	hours = int(currentTime / 60) + 1
	minutes = int(currentTime) % 61
	# print("hours:" + str(hours))
	# print("minutes:" + str(minutes))
	update_calendar()
	stateTransition()
	updateMoonPhase()

func update_calendar():
	# Update calendar
	if hours == 24:
		Day += 1
	if Day == 30:
			Month += 1
			# Month -= 1
			Day = 0
	if Month == 12:
				Year += 1
				Month = 0

func updateMoonPhase():
	var moon_phase: float = moonPhase_calculator()
	var lerpSpeedChange = sky.get_shader_parameter("moon_crescent_offset")
	var lerpSpeed: float = transitionSpeed * speedMultiplier
	sky.set_shader_parameter("moon_crescent_offset", lerp(lerpSpeedChange, moon_phase, lerpSpeed))
		
		
func moonPhase_calculator() -> float:
	"""
	1. express the date as year, month, day
	2. if month == 1 or 2, subtract 1 from the year and add 12 to the month
	3. with a calculator, do the following calculations:
		- A = year / 100
		- B = A / 4
		- C = 2 - (A + B)
		- D = 365.25 * (year + 4716)
		- E = 30.6001 * (month + 1)
		- JD = C + day + D + E - 1524.5
		
	Now that we have the Julian Day, we can calculate the days since the last new moon:
		- DaySinceNew = JD - 2451549.5
		
	if divided this by the period, will have how many new moons have been:
		- NewMoons = DaySinceNew / 29.53

	Now we can calculate the phase of the moon:
		- Phase = NewMoons - int(NewMoons)
		get phase range in abs(0.0 to 1.0) because if years started from 0 or 1 this func returned to negative value
		
	"""
	
	const moon_constant: float = 2451549.5
	const amountDayInYear: float = 365.25
	const amountDaysInMonth: float = 30.6001

	var alpha = Year / 100

	var beta = alpha / 4

	var c = 2 - (alpha + beta)

	var e = amountDayInYear * (Year + 4716)

	var f = amountDaysInMonth * (Month + 1)

	var jd = c + Day + e + f - 1524.5

	var DaySinceNew = jd - moon_constant

	var NewMoons = DaySinceNew / 29.53

	var Phase = NewMoons - int(NewMoons)

	return Phase

func dateFormat():
	# DD_MM_YYYY, MM_DD_YYYY, YYYY_MM_DD
	var day: String = str(Day)
	var month: String = str(Month)
	var year: String = str(Year)
	if date_format == 0:
		return day + FormatSymbol + month + FormatSymbol + year
	
	if date_format == 1:
		return month + FormatSymbol + day + FormatSymbol + year

	if date_format == 2:
		return year + FormatSymbol + month + FormatSymbol + day

func stateTransition():
	# tracking Day and night
	if hours >= sunriseHour && hours <= sunsetHour - 1:
		isDay = true
		isNight = false
	else:
		isDay = false
		isNight = true
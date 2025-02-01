@tool
extends Node3D


@export var simulationTime: bool
@export var worldEnvironment: WorldEnvironment
@export var nightLight: DirectionalLight3D
@export var dayLight: DirectionalLight3D
@export var rotationOffset: Vector3
var sky: ShaderMaterial

@export_group("Time")
@export var currentTime: float = 480.0
@export var speedMultiplier: float = 1.0
@export var secondsPerMinute: float = 1.0
@export var dayLengthHours: int = 24
@export var dayLengthMinutes: int
@export var sunriseHour: int = 6
@export var sunsetHour: int = 18

@export_group("Lighting")
@export var dayLightEnergy: float = 1.0
@export var nightLightEnergy: float = 0.1

@export var dayStarIntensity: float
@export var nightStarIntensity: float = 0.5

@export_group("Colors")
@export var transitionSpeed: float = 0.001
@export_subgroup("Sky")
@export var sunriseColor := Color("ffa052")
@export var dayColor := Color("037dff")
@export var sunsetColor := Color("ffa052")
@export var nightColor := Color("000214")
@export var daySunScatter := Color("4c4c4c")
@export var nightSunScatter := Color("0e0929")
var currentColor: Color
var colorToLerp: Color

@export_subgroup("Clouds")
@export var dayCloudColor := Color("ffffff")
@export var nightCloudColor := Color("0a0b18")

var daylightDuration: float
var totalGameMinutes: float
var myRotation: float
var light_energy: float
## Use these to determine in-game time
var hours: int
var minutes: int

func _ready():
	# References
	sky = worldEnvironment.environment.sky.sky_material

	# Time and rotation
	totalGameMinutes = dayLengthHours * 60.0 + dayLengthMinutes
	daylightDuration = (sunsetHour - sunriseHour) * 60.0
	myRotation = 180.0 / daylightDuration

	update_clock()

	# Start settings
	if hours == sunriseHour: currentColor = sunriseColor
	elif hours > sunriseHour && hours < sunsetHour: currentColor = dayColor
	elif hours == sunsetHour: currentColor = sunsetColor
	elif (hours > sunsetHour && hours <= dayLengthHours) || (hours >= 0 && hours < sunriseHour): currentColor = nightColor
	colorToLerp = currentColor

	if hours >= sunriseHour && hours <= sunsetHour:
		light_energy = dayLightEnergy
		nightLight.light_energy = 0.0
		nightLight.visible = false
		dayLight.visible = true
		sky.set_shader_parameter("stars_intensity", dayStarIntensity)
		sky.set_shader_parameter("clouds_light_color", dayCloudColor)
		sky.set_shader_parameter("sun_scatter", daySunScatter)
	else:
		light_energy = 0.0
		nightLight.light_energy = nightLightEnergy
		nightLight.visible = true
		dayLight.visible = false
		sky.set_shader_parameter("stars_intensity", nightStarIntensity)
		sky.set_shader_parameter("clouds_light_color", nightCloudColor)
		sky.set_shader_parameter("sun_scatter", nightSunScatter)

func _process(delta):

	if simulationTime != false:

	# Sun and moon rotation
		currentTime += delta / secondsPerMinute * speedMultiplier
		if currentTime >= totalGameMinutes: currentTime = 0.0

		var timeSinceSunrise: float = currentTime - sunriseHour * 60.0
		rotation_degrees = Vector3(timeSinceSunrise * myRotation + 180.0, 0.0, 0.0) + rotationOffset

		update_clock()

	# Sky color
	if hours == sunriseHour: currentColor = sunriseColor
	elif hours == sunriseHour + 1: currentColor = dayColor
	elif hours == sunsetHour - 1: currentColor = sunsetColor
	elif hours == sunsetHour: currentColor = nightColor

	var lerpSpeed: float = transitionSpeed * speedMultiplier
	colorToLerp = colorToLerp.lerp(currentColor, lerpSpeed)
	sky.set_shader_parameter("top_color", colorToLerp)
	sky.set_shader_parameter("bottom_color", colorToLerp)

	if hours >= sunriseHour && hours <= sunsetHour - 1:
		# Lighting
		light_energy = lerp(light_energy, dayLightEnergy, lerpSpeed)
		nightLight.light_energy = lerp(nightLight.light_energy, 0.0, lerpSpeed)

		# Stars
		sky.set_shader_parameter("stars_intensity", lerp(sky.get_shader_parameter("stars_intensity"), dayStarIntensity, lerpSpeed))

		# Cloud color
		var cloudLerp: Color = sky.get_shader_parameter("clouds_light_color")
		cloudLerp = cloudLerp.lerp(dayCloudColor, lerpSpeed)
		sky.set_shader_parameter("clouds_light_color", cloudLerp)

		# Sun scatter
		var sunLerp: Color = sky.get_shader_parameter("sun_scatter")
		sunLerp = sunLerp.lerp(daySunScatter, lerpSpeed)
		sky.set_shader_parameter("sun_scatter", sunLerp)
	else:
		# Lighting
		light_energy = lerp(light_energy, 0.0, lerpSpeed)
		nightLight.light_energy = lerp(nightLight.light_energy, nightLightEnergy, lerpSpeed)

		# Stars
		sky.set_shader_parameter("stars_intensity", lerp(sky.get_shader_parameter("stars_intensity"), nightStarIntensity, lerpSpeed))

		# Cloud color
		var cloudLerp: Color = sky.get_shader_parameter("clouds_light_color")
		cloudLerp = cloudLerp.lerp(nightCloudColor, lerpSpeed)
		sky.set_shader_parameter("clouds_light_color", cloudLerp)

		# Sun scatter
		var sunLerp: Color = sky.get_shader_parameter("sun_scatter")
		sunLerp = sunLerp.lerp(nightSunScatter, lerpSpeed)
		sky.set_shader_parameter("sun_scatter", sunLerp)

func update_clock():
	hours = int(currentTime / 60)
	minutes = int(currentTime) % 60

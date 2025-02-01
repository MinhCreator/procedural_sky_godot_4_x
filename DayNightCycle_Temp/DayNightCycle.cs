using Godot;

public partial class DayNightCycle : DirectionalLight3D
{
    [Export] private WorldEnvironment worldEnvironment;
    [Export] private DirectionalLight3D nightLight;
    [Export] private Vector3 rotationOffset;
    private ShaderMaterial sky;
    
    [ExportGroup("Time")]
    [Export] private float currentTime = 480f; // In minutes, 480 is 8 AM
    [Export] private float speedMultiplier = 1f;
    [Export] private float secondsPerMinute = 1f;
    [Export] private int dayLengthHours = 24;
    [Export] private int dayLengthMinutes;
    [Export] private int sunriseHour = 6;
    [Export] private int sunsetHour = 18;
    
    [ExportGroup("Lighting")]
    [Export] private float dayLightEnergy = 1f;
    [Export] private float nightLightEnergy = 0.1f;

    [Export] private float dayStarIntensity;
    [Export] private float nightStarIntensity = 0.5f;
    
    [ExportGroup("Colors")]
    [Export] private float transitionSpeed = 0.001f;
    [ExportSubgroup("Sky")]
    [Export] private Color sunriseColor = new("ffa052");
    [Export] private Color dayColor = new("037dff");
    [Export] private Color sunsetColor = new("ffa052");
    [Export] private Color nightColor = new("000214");
    [Export] private Color daySunScatter = new("4c4c4c");
    [Export] private Color nightSunScatter = new("0e0929");
    private Color currentColor;
    private Color colorToLerp;
    
    [ExportSubgroup("Clouds")]
    [Export] private Color dayCloudColor = new("ffffff");
    [Export] private Color nightCloudColor = new("0a0b18");
    
    private float daylightDuration;
    private float totalGameMinutes;
    private float rotation;
    
    // Use these to determine in-game time
    public int hours;
    public int minutes;
    
    public override void _Ready()
    {
        // References
        sky = worldEnvironment.Environment.Sky.SkyMaterial as ShaderMaterial;
        
        // Time and rotation
        totalGameMinutes = dayLengthHours * 60f + dayLengthMinutes;
        daylightDuration = (sunsetHour - sunriseHour) * 60f;
        rotation = 180.0f / daylightDuration;
        
        UpdateClock();
        
        // Start settings
        if (hours == sunriseHour) currentColor = sunriseColor;
        else if (hours > sunriseHour && hours < sunsetHour) currentColor = dayColor;
        else if (hours == sunsetHour) currentColor = sunsetColor;
        else if ((hours > sunsetHour && hours <= dayLengthHours) || (hours >= 0 && hours < sunriseHour)) currentColor = nightColor;
        colorToLerp = currentColor;
        
        if (hours >= sunriseHour && hours <= sunsetHour)
        {
            LightEnergy = dayLightEnergy;
            nightLight.LightEnergy = 0f;
            
            sky!.SetShaderParameter("stars_intensity", dayStarIntensity);
            sky.SetShaderParameter("clouds_light_color", dayCloudColor);
            sky.SetShaderParameter("sun_scatter", daySunScatter);
        }
        else
        {
            LightEnergy = 0f;
            nightLight.LightEnergy = nightLightEnergy;
            
            sky!.SetShaderParameter("stars_intensity", nightStarIntensity);
            sky.SetShaderParameter("clouds_light_color", nightCloudColor);
            sky.SetShaderParameter("sun_scatter", nightSunScatter);
        }
    }
    
    public override void _PhysicsProcess(double delta)
    {
        // Sun and moon rotation
        currentTime += (float)delta / secondsPerMinute * speedMultiplier;
        if (currentTime >= totalGameMinutes) currentTime = 0f;
        
        var timeSinceSunrise = currentTime - sunriseHour * 60f;
        RotationDegrees = new Vector3(timeSinceSunrise * rotation + 180f, 0f, 0f) + rotationOffset;
        
        UpdateClock();
        
        // Sky color
        if (hours == sunriseHour) currentColor = sunriseColor;
        else if (hours == sunriseHour + 1) currentColor = dayColor;
        else if (hours == sunsetHour - 1) currentColor = sunsetColor;
        else if (hours == sunsetHour) currentColor = nightColor;
        
        var lerpSpeed = transitionSpeed * speedMultiplier;
        colorToLerp = colorToLerp.Lerp(currentColor, lerpSpeed);
        sky.SetShaderParameter("top_color", colorToLerp);
        sky.SetShaderParameter("bottom_color", colorToLerp);
        
        if (hours >= sunriseHour && hours <= sunsetHour - 1)
        {
            // Lighting
            LightEnergy = Mathf.Lerp(LightEnergy, dayLightEnergy, lerpSpeed);
            nightLight.LightEnergy = Mathf.Lerp(nightLight.LightEnergy, 0f, lerpSpeed);
            
            // Stars
            sky.SetShaderParameter("stars_intensity", Mathf.Lerp((float)sky.GetShaderParameter("stars_intensity"), dayStarIntensity, lerpSpeed));
            
            // Cloud color
            var cloudLerp = (Color)sky.GetShaderParameter("clouds_light_color");
            cloudLerp = cloudLerp.Lerp(dayCloudColor, lerpSpeed);
            sky.SetShaderParameter("clouds_light_color", cloudLerp);
            
            // Sun scatter
            var sunLerp = (Color)sky.GetShaderParameter("sun_scatter");
            sunLerp = sunLerp.Lerp(daySunScatter, lerpSpeed);
            sky.SetShaderParameter("sun_scatter", sunLerp);
        }
        else
        {
            // Lighting
            LightEnergy = Mathf.Lerp(LightEnergy, 0f, lerpSpeed);
            nightLight.LightEnergy = Mathf.Lerp(nightLight.LightEnergy, nightLightEnergy, lerpSpeed);
            
            // Stars
            sky.SetShaderParameter("stars_intensity", Mathf.Lerp((float)sky.GetShaderParameter("stars_intensity"), nightStarIntensity, lerpSpeed));
            
            // Cloud color
            var cloudLerp = (Color)sky.GetShaderParameter("clouds_light_color");
            cloudLerp = cloudLerp.Lerp(nightCloudColor, lerpSpeed);
            sky.SetShaderParameter("clouds_light_color", cloudLerp);
            
            // Sun scatter
            var sunLerp = (Color)sky.GetShaderParameter("sun_scatter");
            sunLerp = sunLerp.Lerp(nightSunScatter, lerpSpeed);
            sky.SetShaderParameter("sun_scatter", sunLerp);
        }
    }

    private void UpdateClock()
    {
        hours = (int)(currentTime / 60);
        minutes = (int)(currentTime % 60);
    }
}

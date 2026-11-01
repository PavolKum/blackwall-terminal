// Blackwall: a faint curtain of red LED dots behind your terminal text, drawn by the GPU.
//
// A Windows Terminal pixel shader (the profile setting experimental.pixelShaderPath).
// Vertical strands of dots, each with its own brightness; a slow band of light sweeping
// across; a glow rising from the bottom edge; and, now and then, a magenta shape swelling
// behind the wall for a few seconds. Each dot has a fixed threshold, so it fades on and
// off as the light passes - no sparkle.
//
// Only pixels that still show the terminal's own background are touched. Text, cursor,
// selection and anything an app paints in another colour stay exactly as drawn.
//
// Palette: deep red #7A1320, barrier red #FF2A3D, magenta #FF2E7E for the rogue shape,
// over the Blackwall scheme's ground #1B1617.

Texture2D shaderTexture;
SamplerState samplerState;

cbuffer PixelShaderSettings
{
    float  Time;        // seconds since the shader was loaded
    float  Scale;       // DPI scale
    float2 Resolution;  // pixels
    float4 Background;  // the profile's background colour
};

static const float3 RED_DEEP = float3(0.478, 0.075, 0.125);
static const float3 RED      = float3(1.000, 0.165, 0.239);
static const float3 MAGENTA  = float3(1.000, 0.180, 0.494);

// Knobs. How loud the wall is: the most a dot mixes toward its colour.
static const float DOT_STRENGTH   = 0.60;
static const float GHOST_STRENGTH = 0.38;
static const float GHOST_EVERY    = 14.0; // seconds between rogue shapes
static const float GHOST_LASTS    = 5.0;  // seconds each one lasts
static const float2 DOT_PITCH     = float2(8.0, 6.0); // px between strands, between dots

float hash11(float n)
{
    return frac(sin(n * 127.1) * 43758.5453);
}

float hash21(float2 p)
{
    return frac(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}

// Smooth 1-D value noise, 0..1.
float vnoise(float x, float seed)
{
    float i = floor(x);
    float f = frac(x);
    float u = f * f * (3.0 - 2.0 * f);
    return lerp(hash11(i + seed * 17.3), hash11(i + 1.0 + seed * 17.3), u);
}

float4 main(float4 pos : SV_POSITION, float2 tex : TEXCOORD) : SV_TARGET
{
    float4 color = shaderTexture.Sample(samplerState, tex);

    // Draw only on the plain background: a pixel within 2% of the profile's background
    // colour on every channel. Everything else - text above all - is left alone.
    float3 diff = abs(color.rgb - Background.rgb);
    if (max(diff.r, max(diff.g, diff.b)) > 0.02)
        return color;

    // The dot lattice, scaled with the display's DPI.
    float2 pitch = DOT_PITCH * Scale;
    float2 px = tex * Resolution;
    float2 cell = floor(px / pitch);
    float2 inCell = frac(px / pitch) - 0.5;
    float dotShape = 1.0 - smoothstep(0.16, 0.30, length(inCell * pitch / pitch.y));
    if (dotShape <= 0.0)
        return color;

    float t = Time;
    float x = cell.x;
    float y = cell.y;
    float rows = Resolution.y / pitch.y;
    float up = 1.0 - y / max(1.0, rows); // 0 at the bottom, 1 at the top

    // Brightness: each strand its own level, a band of light sweeping across, and the
    // bottom edge glowing up the strands.
    float strand = 0.25 + 0.55 * vnoise(x * 0.33 + t * 0.35, 1.0);
    float sweep = 0.5 + 0.5 * sin(x * 0.11 - t * 1.4 + sin(y * 0.05 + t * 0.5) * 0.8);
    float rise = exp(-up * 3.0) * 0.55;
    float v = strand * (0.35 + 0.65 * sweep) * (1.0 - 0.5 * up) + rise;

    // The rogue shape: for a few seconds in every GHOST_EVERY, a soft magenta swell.
    float n = floor(t / GHOST_EVERY);
    float age = t - n * GHOST_EVERY;
    float ghost = 0.0;
    if (age < GHOST_LASTS)
    {
        float env = sin(age / GHOST_LASTS * 3.14159);
        float2 centre = float2(0.25 + 0.5 * hash11(n * 3.7 + 1.0), 0.25 + 0.4 * hash11(n * 5.3 + 2.0)) * Resolution;
        float radius = (0.16 + 0.06 * vnoise(atan2(px.y - centre.y, px.x - centre.x) * 2.0 + t, 3.0)) * Resolution.y;
        float d = length(px - centre) / radius;
        ghost = env * saturate(1.0 - d);
    }

    // A dot lights when the light passing it beats its own fixed threshold.
    if (hash21(cell * 1.17) > v + ghost * 0.8)
        return color;

    float heat = saturate((v - 0.35) * 1.4);
    float3 glow = lerp(RED_DEEP, RED, heat);
    glow = lerp(glow, MAGENTA, saturate(ghost * 1.5));
    float strength = DOT_STRENGTH * dotShape * saturate(0.45 + 0.55 * v) + GHOST_STRENGTH * ghost * dotShape;

    return float4(lerp(color.rgb, glow, saturate(strength)), color.a);
}

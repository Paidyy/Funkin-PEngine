import flixel.system.FlxAssets.FlxShader;

class ColorShader extends FlxShader {
	@:glFragmentSource('
    #pragma header

    const float Epsilon = 1e-10;

    void main () {
        vec4 color  = flixel_texture2D(bitmap, openfl_TextureCoordv);

        vec3 col_hsv = RGBtoHSV(texColor.rgb);
        col_hsv.y *= (u_saturate * 2.0);
        vec3 col_rgb = HSVtoRGB(col_hsv.rgb);

        gl_FragColor = vec4(col_rgb.rgb, color.a);
    }

    vec3 HSVtoRGB(in vec3 HSV) {
        float H   = HSV.x;
        float R   = abs(H * 6.0 - 3.0) - 1.0;
        float G   = 2.0 - abs(H * 6.0 - 2.0);
        float B   = 2.0 - abs(H * 6.0 - 4.0);
        vec3  RGB = clamp( vec3(R,G,B), 0.0, 1.0 );
        return ((RGB - 1.0) * HSV.y + 1.0) * HSV.z;
    }

    vec3 RGBtoHSV(in vec3 RGB) {
        vec4  P   = (RGB.g < RGB.b) ? vec4(RGB.bg, -1.0, 2.0/3.0) : vec4(RGB.gb, 0.0, -1.0/3.0);
        vec4  Q   = (RGB.r < P.x) ? vec4(P.xyw, RGB.r) : vec4(RGB.r, P.yzx);
        float C   = Q.x - min(Q.w, Q.y);
        float H   = abs((Q.w - Q.y) / (6.0 * C + Epsilon) + Q.z);
        vec3  HCV = vec3(H, C, Q.x);
        float S   = HCV.y / (HCV.z + Epsilon);
        return vec3(HCV.x, S, HCV.z);
    }
    ')
    public function new() {
        super();
    }
}
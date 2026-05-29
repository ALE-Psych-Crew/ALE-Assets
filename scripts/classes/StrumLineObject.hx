package;

import funkin.visuals.shaders.RGBShader;

class StrumLineObject extends scripting.haxe.ScriptedFunkinSprite
{
    public var strumLine:StrumLine;
    public var strumLineConfig:JsonStrumLineConfig;

    public var data:Int;

    public function new(id:String, strlData:JsonStrumLineConfig, data:Int, ?rgb:RGBShader)
    {
        super();

        this.data = data;

        fromJson(Paths.json('data/' + pathPrefix + id));

        strumLineConfig = Reflect.copy(strlData);

        shader = rgb ?? new RGBShader();

        if (strlData.shader != null)
        {
            final castShader:RGBShader = cast shader;

            castShader.r = CoolUtil.colorFromString(strlData.shader[0]);
            castShader.g = CoolUtil.colorFromString(strlData.shader[1]);
            castShader.b = CoolUtil.colorFromString(strlData.shader[2]);
        }
    }
}
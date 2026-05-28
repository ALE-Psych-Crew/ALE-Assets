package;

class StrumLineObject extends scripting.haxe.ScriptedFunkinSprite
{
    public var strumLine:StrumLine;
    public var strumLineConfig:JsonStrumLineConfig;

    public var data:Int = 0;

    public function new(id:String, strlData:JsonStrumLineConfig)
    {
        super();

        fromJson(Paths.json('data/' + pathPrefix + id));

        strumLineConfig = Reflect.copy(strlData);
    }
}
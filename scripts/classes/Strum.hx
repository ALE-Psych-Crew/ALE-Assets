package;

class Strum extends StrumLineObject
{
    public var children:Array<Note> = [];

    public var direction:Float = 0;

    public function new(id:String, strlData:JsonStrumLineConfig)
    {
        allowOffset = false;

        pathPrefix = 'notes/';

        super(id, strlData);

        playAnim(strumLineConfig.idle);
    }
}
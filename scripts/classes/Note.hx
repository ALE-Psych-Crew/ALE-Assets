package;

import flixel.math.FlxAngle;
import flixel.math.FlxRect;

class Note extends StrumLineObject
{
    public final type:NoteType;

    public var strum:Strum;

    public var parent:Note;

    public var time:Float;
    public var length:Float;
    public var noteType:String;
    public var character:Array<Int>;

    public var crochet:Float;

    public var sustainHeightFactor:Float = 1.0285;

    public var speed(default, set):Float;
    function set_speed(value:Float):Float
    {
        speed = value;

        if (type == 'sustain' && animation.curAnim != null)
        {
            setGraphicSize(width, sustainHeightFactor * speedMultiplier * crochet * speed);

            updateHitbox();
        }

        return speed;
    }

    public function new(id:String, strlData:JsonStrumLineConfig, type:NoteType)
    {
        allowOffset = false;

        pathPrefix = 'notes/';

        super(id, strlData);

        this.type = type;

        playAnim(type == 'arrow' ? strumLineConfig.note : type == 'sustain' ? strumLineConfig.sustain : strumLineConfig.end);

        y = FlxG.height * 2;

        updateHitbox();
    }

    public var timeDistance:Float = 0;

    var speedMultiplier:Float = 0.45;

    var direction:Float = 0;

    var copyAngle:Bool = true;
    var angleOffset:Float = 0;

    var copyDirection:Bool = true;
    var directionOffset:Float = 90;

    var copyAlpha:Bool = true;
    public var alphaMultiplier:Float = 1;

    var copyX:Bool = true;
    public var xOffset:Float = 0;

    var copyY:Bool = true;
    public var yOffset:Float = 0;

    var sustainClipping:Bool = true;

    public function followStrum()
    {
        speed ??= 1;

        final distance:Float = timeDistance * speed * speedMultiplier * (strumLine.downScroll ? -1 : 1) - (strumLine.downScroll && type != 'arrow' ? height : 0);

        if (copyAngle)
            angle = strum.angle + angleOffset;

        if (copyAlpha)
            alpha = strum.alpha * alphaMultiplier;

        if (copyX || copyY)
        {
            final rawDirection:Float = ((copyDirection ? strum.direction : direction) + directionOffset) * FlxAngle.TO_RAD;

            if (copyX)
                x = strum.x + distance * FlxMath.fastCos(rawDirection) + xOffset;

            if (copyY)
                y = strum.y + distance * FlxMath.fastSin(rawDirection) + yOffset;
        }

        if (sustainClipping && type != 'arrow')
        {
            if (hit)
            {
                this.clipRect ??= FlxRect.get();

                final time:Float = FlxMath.bound((Conductor.songPosition - time) / height * speedMultiplier * speed, 0, 1);

                this.clipRect.set(0, frameHeight * time, frameWidth, frameHeight * (1 - time));
            } else {
                this.clipRect?.put();
            }
        }
    }

    public var hit:Bool = false;
    public var miss:Bool = false;

    public var ignore:Bool = false;

    public var botplayMiss:Bool = false;
}
package;

import flixel.graphics.FlxGraphic;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;

class Bar extends scripting.haxe.ScriptedFlxSpriteGroup
{
    public final border:FlxSprite;
    public final fillBack:FlxSprite;
    public final fillFront:FlxSprite;

    public var leftToRight(default, set):Bool;
    function set_leftToRight(value:Bool):Bool
    {
        leftToRight = value;

        if (percent != null)
            percent = percent;

        return leftToRight;
    }

    public var percent(default, set):Float;
    function set_percent(value:Float):Float
    {
        value = FlxMath.bound(value, 0, 100);

        fillFront.clipRect ??= FlxRect.get();

        final factor:Float = fillFront.width * (value / 100);

        fillFront.clipRect.set(leftToRight ? 0 : fillFront.width - factor, 0, leftToRight ? factor : fillFront.width, fillFront.height);

        return percent = value;
    }

    public function new(main:String, fill:String, ?leftToRight:Bool, ?percent:Float)
    {
        super();

        fillBack = new FlxSprite(0, 0, Paths.image(fill));
        fillBack.color = FlxColor.RED;
        add(fillBack);

        fillFront = new FlxSprite(0, 0, Paths.image(fill));
        fillFront.color = FlxColor.LIME;
        add(fillFront);

        border = new FlxSprite(0, 0, Paths.image(main));
        add(border);

        for (spr in [fillFront, fillBack])
        {
            spr.x = border.x + border.width / 2 - spr.width / 2;
            spr.y = border.y + border.height / 2 - spr.height / 2;
        }

        this.leftToRight = leftToRight ?? true;

        this.percent = percent ?? 50;
    }

    public function getMiddle():FlxPoint
    {
        return FlxPoint.get(fillFront.x + (leftToRight ? fillFront.clipRect.width : fillFront.clipRect.x), fillFront.y + fillFront.height / 2);
    }
}
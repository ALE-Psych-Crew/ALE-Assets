import funkin.visuals.objects.FunkinSprite;

import utils.cool.ReflectUtil;
import utils.cool.StringUtil;

import flixel.math.FlxPoint;

using StringTools;

HotReloading.add('data/huds/default.json');

public var comboGroup:FlxTypedSpriteGroup<FunkinSprite>;

public var ratingSprite:FunkinSprite;
public var comboNumbers:FlxTypedSpriteGroup<FunkinSprite>;

public function initCombo()
{
    if (scriptsManager.callback(ON, 'CombosInit'))
    {
        add(comboGroup = new FlxTypedSpriteGroup<FunkinSprite>());
        comboGroup.camera = camHUD;

        ReflectUtil.setProperties(comboGroup, hud.combo.properties);

        comboGroup.y = ClientPrefs.data.downScroll ? FlxG.height - comboGroup.y : comboGroup.y;

        comboGroup.add(ratingSprite = new FunkinSprite());
        ratingSprite.visible = false;

        ReflectUtil.setProperties(ratingSprite, hud.combo.rating.properties);

        // FIX

        for (rating in hud.ratings)
            Paths.image(get_hudRoute() + '/combo/' + rating.id);

        comboGroup.add(comboNumbers = new FlxTypedSpriteGroup<FunkinSprite>());

        for (i in 0...10)
            Paths.image(get_hudRoute() + '/combo/' + i);
    }

    scriptsManager.callback(POST, 'CombosInit');
}

public function displayCombo(rating:String)
{
    if (scriptsManager.callback(ON, 'ComboDisplay'))
    {
        FlxTween.cancelTweensOf(ratingSprite);

        ratingSprite.loadGraphic(Paths.image(get_hudRoute() + '/combo/' + rating.id));

        final basePosition:FlxPoint = FlxPoint.get(comboGroup.x - ratingSprite.width / 2, comboGroup.y - ratingSprite.height / 2);

        ratingSprite.x = basePosition.x + hud.combo.rating.start.x;
        ratingSprite.y = basePosition.y + hud.combo.rating.start.y;
        ratingSprite.alpha = hud.combo.rating.start.alpha;
        ratingSprite.visible = true;

        FlxTween.tween(ratingSprite, {
            x: basePosition.x + hud.combo.rating.end.x,
            y: basePosition.y + hud.combo.rating.end.y,
            alpha: hud.combo.rating.end.alpha
        }, hud.combo.rating.duration, {
            ease: StringUtil.easeFromString(hud.combo.rating.ease),
            onComplete: _ -> ratingSprite.visible = false
        });

        final comboString:String = Std.string(combo).trim().lpad('0', 3);
        
        while (comboString.length > comboNumbers.members.length)
        {
            final number:FunkinSprite = new FunkinSprite();

            ReflectUtil.setProperties(number, hud.combo.number.properties);

            comboNumbers.add(number);
        }

        basePosition.set(-hud.combo.number.spacing * (comboNumbers.members.length - 1) / 2);

        for (i => number in comboNumbers.members)
        {
            FlxTween.cancelTweensOf(number);

            number.loadGraphic(Paths.image(get_hudRoute() + '/combo/' + comboString.charAt(i)));

            final baseNumberPosition:FlxPoint = FlxPoint.get(basePosition.x + comboGroup.x - number.width / 2 + hud.combo.number.spacing * i, comboGroup.y - number.width / 2);

            number.x = baseNumberPosition.x + hud.combo.number.start.x;
            number.y = baseNumberPosition.y + hud.combo.number.start.y;
            number.alpha = hud.combo.number.start.alpha;
            number.visible = true;

            FlxTween.tween(number, {
                x: baseNumberPosition.x + hud.combo.number.end.x,
                y: baseNumberPosition.y + hud.combo.number.end.y,
                alpha: hud.combo.number.end.alpha
            }, hud.combo.number.duration, {
                ease: StringUtil.easeFromString(hud.combo.number.ease),
                onComplete: _ -> number.visible = false
            });

            baseNumberPosition.put();
        }

        basePosition.put();
    }

    scriptsManager.callback(POST, 'ComboDisplay');
}
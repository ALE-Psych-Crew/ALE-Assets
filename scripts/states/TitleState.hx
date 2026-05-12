import funkin.visuals.objects.Bopper;

core.debug.HotReloading.add('data/menus/title.json');

final config:JsonTitle = Paths.json('data/menus/title');

var logo:Bopper;
var gf:Bopper;
var enter:Bopper;

var skippedIntro:Bool = false;

function onCreate()
{
    // if (Conductor.music == null)
        Conductor.play(Paths.music('freakyMenu'), CoolVars.meta.bpm);

    final path:String = 'menus/' + config.directory + '/';

    logo = new Bopper();
    logo.fromJson(config.logo, path);

    gf = new Bopper();
    gf.fromJson(config.gf, path);

    enter = new Bopper();
    enter.fromJson(config.enter, path);

    FlxTween.tween(enter, {alpha: 0.25}, 4 * Conductor.secCrochet, {ease: FlxEase.quadInOut, type: FlxTweenType.PINGPONG});

    for (spr in [logo, gf, enter])
    {
        spr.configBeatHitAnimations();
        spr.exists = false;
        
        add(spr);
    }
}

var canSelect:Bool = false;

function onUpdate(elapsed:Float)
{
    if (canSelect && Controls.ACCEPT)
    {
        
    }
}
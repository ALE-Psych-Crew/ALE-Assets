var strikeBeat:Int = 0;
var strikeOffset:Int = 8;

function onBeatHit(curBeat:Int)
{
    if (FlxG.random.bool(10) && curBeat > strikeBeat + strikeOffset)
    {
        strikeBeat = curBeat;
        strikeOffset = FlxG.random.int(8, 24);

        if (!ClientPrefs.data.lowQuality)
            stage.get('bg').playAnim('strike');

        CoolUtil.playSound(stageRoute + '/thunder' + FlxG.random.int(0, 1));

        for (char in characters)
            char?.playSpecialAnim('scared');

        FlxTimer.wait(Conductor.secCrochet * 2, () -> for (char in characters) char.resetBlockers());
    }
}
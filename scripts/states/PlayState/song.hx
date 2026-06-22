import funkin.visuals.objects.FunkinSprite;

import utils.cool.ReflectUtil;
import utils.cool.StringUtil;

import flixel.graphics.FlxGraphic;
import flixel.math.FlxPoint;

import openfl.media.Sound as OpenFLSound;

public function initSong()
{
    if (scriptsManager.callback(ON, 'SongInit'))
    {
        if (skipCountdown || startTime > 0)
            FlxTimer.wait(0.001, startSong);
        else
            startCountdown();
    }

    scriptsManager.callback(POST, 'SongInit');
}

var countdownSprite:FunkinSprite;

public function startCountdown()
{
    if (scriptsManager.callback(ON, 'CountdownStart'))
    {
        add(countdownSprite = new FunkinSprite());
        countdownSprite.camera = camOther;
        countdownSprite.visible = false;

        ReflectUtil.setProperties(countdownSprite, hud.countdown.properties);

        for (count in hud.countdown.list)
        {
            // FIX
     
            final route:String = get_hudRoute() + '/countdown/' + count;

            Paths.image(route, false, false);
            Paths.sound(route, false, false);
        }

        tickCountdown(0);

        FlxTimer.loop(Conductor.secCrochet, index -> tickCountdown(index), hud.countdown.list.length - 1);

        Conductor.time = -Conductor.crochet * hud.countdown.list.length;

        FlxTween.tween(Conductor, {time: 0}, -Conductor.time / 1000, { onComplete: _ -> startSong() });
    }

    scriptsManager.callback(POST, 'CountdownStart');
}

public function tickCountdown(index:Int)
{
    if (scriptsManager.callback(ON, 'CountdownTick', [index]))
    {
        // FIX

        final route:String = get_hudRoute() + '/countdown/' + hud.countdown.list[index];

        final graphic:FlxGraphic = Paths.image(route, false, false);

        if (graphic != null)
        {
            FlxTween.cancelTweensOf(countdownSprite);
            FlxTween.cancelTweensOf(countdownSprite.scale);

            countdownSprite.loadGraphic(graphic);

            countdownSprite.scale.x = hud.countdown.start.scale.x;
            countdownSprite.scale.y = hud.countdown.start.scale.y;

            countdownSprite.updateHitbox();

            final basePosition:FlxPoint = FlxPoint.get(FlxG.width / 2 - countdownSprite.width / 2, FlxG.height / 2 - countdownSprite.height / 2);

            countdownSprite.visible = true;

            countdownSprite.x = basePosition.x + hud.countdown.start.x;
            countdownSprite.y = basePosition.y + hud.countdown.start.y;
            countdownSprite.alpha = hud.countdown.start.alpha;

            FlxTween.tween(countdownSprite, {x: basePosition.x + hud.countdown.end.x, y: basePosition.y + hud.countdown.end.y, alpha: hud.countdown.end.alpha}, Conductor.secCrochet * hud.countdown.beats, { ease: StringUtil.easeFromString(hud.countdown.ease), onComplete: _ -> countdownSprite.visible = false });
            FlxTween.tween(countdownSprite.scale, {x: hud.countdown.end.scale.x, y: hud.countdown.end.scale.y}, Conductor.secCrochet * hud.countdown.beats, { ease: StringUtil.easeFromString(hud.countdown.ease)});

            basePosition.put();
        }

        final sound:OpenFLSound = Paths.sound(route, false, false);

        if (sound != null)
            CoolUtil.playSound(route);
    }

    scriptsManager.callback(POST, 'CountdownTick', [index]);
}

public function startSong()
{
    if (scriptsManager.callback(ON, 'SongStart'))
    {
        Conductor.play(soundsCache.get('::MUSIC'), chart.bpm, chart.stepsPerBeat, chart.beatsPerSection, false, 0.85);

        Conductor.music.time = startTime;

        var voices:Null<Sound> = null;

        if (soundsCache.exists('::VOICES'))
            voices = new Sound().loadEmbedded(soundsCache.get('::VOICES'));

        var playersVoices:Null<Sound> = null;

        if (soundsCache.exists('::PLAYER'))
            playersVoices = new Sound().loadEmbedded(soundsCache.get('::PLAYER'));

        var opponentsVoices:Null<Sound> = null;

        if (soundsCache.exists('::OPPONENT'))
            opponentsVoices = new Sound().loadEmbedded(soundsCache.get('::OPPONENT'));

        var extrasVoices:Null<Sound> = null;

        if (soundsCache.exists('::EXTRA'))
            extrasVoices = new Sound().loadEmbedded(soundsCache.get('::EXTRA'));

        for (sound in [voices, playersVoices, opponentsVoices, extrasVoices])
            if (sound != null)
                addVocal(sound);

        final charVocals = new Map<String, Sound>();

        for (char in characters)
        {
            if (voices != null)
                char.vocals.push(voices);

            final defaultVoice:Null<Sound> = switch (cast char.type)
            {
                case 'player':
                    playersVoices;

                case 'opponent':
                    opponentsVoices;

                case 'extra':
                    extrasVoices;
            }

            if (defaultVoice != null)
                char.vocals.push(defaultVoice);

            final voice:Null<Sound> = null;

            if (charVocals.exists(char.id))
            {
                voice = charVocals.get(char.id);
            } else if (soundsCache.exists(char.id)) {
                voice = new Sound().loadEmbedded(soundsCache.get(char.id));

                addVocal(voice);

                charVocals.set(char.id, voice);
            }

            if (voice != null)
                char.vocals.push(voice);
        }

        for (voice in vocals)
        {
            voice.play();

            voice.time = startTime;
        }
    }

    scriptsManager.callback(POST, 'SongStart');
}
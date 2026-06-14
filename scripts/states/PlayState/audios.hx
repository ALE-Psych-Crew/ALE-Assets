final soundsCache:Map<String, Sound> = new Map<String, Sound>();

public function initSounds()
{
    if (scriptsManager.callback(ON, 'SoundsInit'))
    {
        soundsCache.set('::MUSIC', Paths.inst(songRoute));

        for (postfix in [null, 'Player', 'Opponent', 'Extra'])
        {
            final audio:Sound = Paths.voices(songRoute, postfix, false, false);

            if (audio != null)
                soundsCache.set('::' + (postfix == null ? 'VOICES' : postfix.toUpperCase()), audio);

            for (char in characters)
            {
                final audio:Sound = Paths.voices(songRoute, char.id, false, false);

                if (audio != null)
                    soundsCache.set(char.id, audio);
            }
        }
    }

    scriptsManager.callback(POST, 'SoundsInit');
}

public var vocals:Array<Sound> = [];

public function startSong()
{
    if (scriptsManager.callback(ON, 'SongInit'))
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

    scriptsManager.callback(POST, 'SongInit');
}

function addVocal(sound:Sound)
{
    if (scriptsManager.callback(ON, 'VocalAdd', null, [sound], []))
    {
        if (sound != null)
        {
            vocals.push(sound);

            Conductor.synchronizedSounds.push(sound);

            FlxG.sound.list.add(sound);
        }
    }

    scriptsManager.callback(POST, 'VocalAdd', null, [sound], []);
}
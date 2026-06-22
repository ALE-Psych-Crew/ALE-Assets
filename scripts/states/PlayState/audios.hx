public final soundsCache:Map<String, Sound> = new Map<String, Sound>();

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

public function addVocal(sound:Sound)
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
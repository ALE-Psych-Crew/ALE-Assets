package;

import flixel.text.FlxText.FlxTextBorderStyle;
import flixel.FlxObject;

import utils.Formatter;


ClientPrefs.data.downScroll = false;
ClientPrefs.data.botplay = true;


for (file in Paths.readDirectory('scripts/classes'))
    HotReloading.add('scripts/classes/' + file);

// enum ahh shit

final ON:String = 'on';
final POST:String = 'post';

function scriptCallbackCall(type:String, name:String, ?globalArgs:Array<Dynamic>, ?hxArgs:Array<Dynamic>, ?luaArgs:Array<Dynamic>):Bool
    return true;

// ñam

final song:String;
final difficulty:String;
final chart:JsonChart;
final songRoute:String;
final hud:JsonHud = {
    directory: 'default',
};

var startTime:Float = 0;

public function new(?newSong:String = 'bopeebo', ?newDifficulty:String = 'hard')
{
    // SUPER CALL

    Conductor.stop();

    song = newSong;
    difficulty = newDifficulty;

    songRoute = CoolUtil.searchComplexFile('songs/' + song);

    chart = Formatter.getChart(song, difficulty);
}

var totalNoteTypes:Array<String> = [];

var allowNotesSpawning:Bool = false;

function onCreate()
{
    // SUPER CALL
    
    if (scriptCallbackCall(ON, 'Create'))
    {
        initStrumLines();

        initControls();

        initHud();

        initSounds();

        initSong();
    }

    scriptCallbackCall(POST, 'Create');
}

// StrumLines & Characters

var strumLines:FlxTypedGroup<StrumLine>;

var characters:FlxTypedGroup<Character>;
var charactersArray:Array<Array<Character>> = [];

var strums:FlxTypedGroup<Strum>;

var characterFactory:String -> CharacterType -> StrumLine = (id, type) -> new Character(id, type);

function initStrumLines()
{
    if (scriptCallbackCall(ON, 'StrumLinesInit'))
    {
        add(strumLines = new FlxTypedGroup<StrumLine>());
        strumLines.camera = camHUD;

        characters = new FlxTypedGroup<Character>();

        strums = new FlxTypedGroup<Strum>();

        final notesArray:Array<Array<Note>> = [];

        Conductor.bpm = chart.bpm;

        if (allowNotesSpawning)
        {
            for (section in chart.sections)
            {
                if (section.changeBPM)
                    Conductor.bpm = section.bpm;

                for (note in section.notes)
                {
                    if (note[0] <= startTime)
                        continue;

                    notesArray[note[4]] ??= [];

                    notesArray[note[4]].push([
                        note[0],
                        note[1],
                        note[2],
                        note[3],
                        note[5],
                        Conductor.stepCrochet
                    ]);
                }
            }
        }

        Conductor.bpm = chart.bpm;

        for (index => strl in chart.strumLines)
        {
            for (charIndex => char in strl.characters)
            {
                final character:Character = characterFactory(char, strl.type);
                characters.add(character);
                add(character);

                charactersArray[index] ??= [];

                charactersArray[index][charIndex] = character;
            }

            final strumLine:StrumLine = new StrumLine(strl.file, strl.type, index, notesArray[index], stackNote);
            strumLine.noteSpawnCallback = spawnNote;
            strumLine.noteHitCallback = hitNote;
            strumLine.noteMissCallback = missNote;

            var strumHeight:Float = 0;

            for (strum in strumLine.strums)
            {
                strums.add(strum);

                strumHeight = Math.max(strumHeight, strum.height);
            }

            strumLine.x = strumLine.type == 'opponent' ? strl.position.x : FlxG.width - strl.position.x - (strumLine.config.config.length - 1) * strumLine.config.spacing - strumLine.strums.members[strumLine.strums.members.length - 1].width;
            strumLine.y = ClientPrefs.data.downScroll ? FlxG.height - strl.position.y - strumHeight : strl.position.y;
            
            strumLines.add(strumLine);
        }
    }

    scriptCallbackCall(POST, 'StrumLinesInit');
}

var lastStackedNote:Note = null;

function stackNote(note:Note):Bool
{
    lastStackedNote = note;

    final result:Bool = scriptCallbackCall(ON, 'NoteStack', null, [note], []);

    if (result)
        if (totalNoteTypes.contains(note.noteType))
            totalNoteTypes.push(note.noteType);

    scriptCallbackCall(POST, 'NoteStack', null, [note], []);

    return result;
}

var lastSpawnedNote:Note = null;

function spawnNote(note:Note):Bool
{
    lastSpawnedNote = note;

    final result:Bool = scriptCallbackCall(ON, 'NoteSpawn', null, [note], []);

    scriptCallbackCall(POST, 'NoteSpawn', null, [note], []);

    return result;
}

var lastHitNote:Note = null;
var lastHitNoteCharacter:Note = null;

function hitNote(note:Note, timeDistance:Float, removeNote:Bool):Bool
{
    lastHitNote = note;
    lastHitNoteCharacter = characterFromNote(note);

    final rating:String = judgeNote(note.timeDistance);

    final result:Bool = scriptCallbackCall(ON, 'NoteHit', null, [note, rating, lastHitNoteCharacter, removeNote], [rating, removeNote]);

    if (result)
    {
        lastHitNoteCharacter.sing(note.type != 'arrow' && !lastHitNoteCharacter._castConfig.sustainAnimation ? null : note.strumLineConfig.sing);
    }

    scriptCallbackCall(POST, 'NoteHit', null, [note, rating, lastHitNoteCharacter, removeNote], [rating, removeNote]);

    return result;
}

var lastMissNote:Note = null;
var lastMissNoteCharacter:Note = null;

function missNote(note:Note):Bool
{
    lastMissNote = note;
    lastMissNoteCharacter = characterFromNote(note);

    final result:Bool = scriptCallbackCall(ON, 'NoteMiss', null, [note, lastMissNoteCharacter], []);

    if (result)
    {
        lastMissNoteCharacter.miss(note.type != 'arrow' && !lastMissNoteCharacter._castConfig.sustainAnimation ? null : note.strumLineConfig.miss);
    }

    scriptCallbackCall(POST, 'NoteMiss', null, [note, lastMissNoteCharacter], []);
    
    return result;
}

function judgeNote(distance:Float):String
{
    return 'UNKNOWN';
}

function characterFromNote(note:Note):Character
    return charactersArray[note.character[0]][note.character[1]];

function initControls()
{
    if (scriptCallbackCall(ON, 'ControlsInit'))
    {
        FlxG.stage.addEventListener('keyDown', justPressedKey);
        FlxG.stage.addEventListener('keyUp', justReleasedKey);
    }

    scriptCallbackCall(POST, 'ControlsInit');
}

function justPressedKey(event:KeyboardEvent)
{
    if (!updating)
        return;

    if (scriptCallbackCall(ON, 'JustPressedKey', null, [event], [event.keyCode]))
        if (Controls.anyJustPressed([event.keyCode]))
            strumLines.forEachAlive(strl -> strl.justPressedKey(event.keyCode));

    scriptCallbackCall(POST, 'JustPressedKey', null, [event], [event.keyCode]);
}

function justReleasedKey(event:KeyboardEvent)
{
    if (!updating)
        return;

    if (scriptCallbackCall(ON, 'JustReleasedKey', null, [event], [event.keyCode]))
        if (Controls.anyJustReleased([event.keyCode]))
            strumLines.forEachAlive(strl -> strl.justReleasedKey(event.keyCode));

    scriptCallbackCall(POST, 'JustReleasedKey', null, [event], [event.keyCode]);
}

// Hud

var uiGroup:FlxTypedGroup<FlxObject>;
var healthBar:Bar;

camGame.bgColor = FlxColor.GRAY;

function initHud()
{
    if (scriptCallbackCall(ON, 'HudInit'))
    {
        uiGroup = new FlxTypedGroup<FlxObject>();
        uiGroup.camera = camHUD;
        add(uiGroup);

        healthBar = new Bar('hud/' + hud.directory + '/bar', 'hud/' + hud.directory + '/barFill');
        healthBar.x = FlxG.width / 2 - healthBar.width / 2;
        healthBar.y = FlxG.height * (ClientPrefs.data.downScroll ? 0.1 : 0.9);
        uiGroup.add(healthBar);
    }

    scriptCallbackCall(POST, 'HudInit');
}

// Audios

final soundsMap:Map<String, Sound> = new Map<String, Sound>();

function initSounds()
{
    if (scriptCallbackCall(ON, 'SoundsInit'))
    {
        soundsMap.set('::MUSIC', Paths.inst(songRoute));

        for (postfix in [null, 'Player', 'Opponent', 'Extra'])
        {
            final audio:Sound = Paths.voices(songRoute, postfix, false, false);

            if (audio != null)
                soundsMap.set('::' + (postfix == null ? 'VOICES' : postfix.toUpperCase()), audio);
        }

        for (char in characters)
        {
            final audio:Sound = Paths.voices(songRoute, char.id, false, false);

            if (audio != null)
                soundsMap.set(char.id, audio);
        }
    }

    scriptCallbackCall(POST, 'SoundsInit');
}

var vocals:Array<Sound> = [];

function initSong()
{
    if (scriptCallbackCall(ON, 'SongInit'))
    {
        Conductor.play(soundsMap.get('::MUSIC'), chart.bpm, chart.stepsPerBeat, chart.beatsPerSection, false, 0.85);

        Conductor.music.time = startTime;

        var voices:Null<Sound> = null;

        if (soundsMap.exists('::VOICES'))
            voices = new Sound().loadEmbedded(soundsMap.get('::VOICES'));

        var playersVoices:Null<Sound> = null;

        if (soundsMap.exists('::PLAYER'))
            playersVoices = new Sound().loadEmbedded(soundsMap.get('::PLAYER'));

        var opponentsVoices:Null<Sound> = null;

        if (soundsMap.exists('::OPPONENT'))
            opponentsVoices = new Sound().loadEmbedded(soundsMap.get('::OPPONENT'));

        var extrasVoices:Null<Sound> = null;

        if (soundsMap.exists('::EXTRA'))
            extrasVoices = new Sound().loadEmbedded(soundsMap.get('::EXTRA'));

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
            } else if (soundsMap.exists(char.id)) {
                voice = new Sound().loadEmbedded(soundsMap.get(char.id));

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

    scriptCallbackCall(POST, 'SongInit');
}

function addVocal(sound:Sound)
{
    if (scriptCallbackCall(ON, 'VocalAdd', null, [sound], []))
    {
        if (sound != null)
        {
            vocals.push(sound);

            Conductor.synchronizedSounds.push(sound);

            FlxG.sound.list.add(sound);
        }
    }

    scriptCallbackCall(POST, 'VocalAdd', null, [sound], []);
}

// Story

function exit()
{
    if (scriptCallbackCall(ON, 'Exit'))
    {
    }

    scriptCallbackCall(POST, 'Exit');
}

// ScriptedState Callbacks

function onMusicComplete()
{
    exit();
}

function onDestroy()
{
    // SUPER CALL

    FlxG.stage.removeEventListener('keyDown', justPressedKey);
    FlxG.stage.removeEventListener('keyUp', justReleasedKey);

    for (vocal in vocals.copy())
        Conductor.synchronizedSounds.remove(vocal);

    characters?.destroy();

    strums?.destroy();
}
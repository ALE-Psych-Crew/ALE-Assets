package;

import flixel.text.FlxText.FlxTextBorderStyle;
import flixel.FlxObject;

import funkin.visuals.FXCamera;

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

var allowNotesSpawning:Bool = true;

function postCreate()
{
    // SUPER CALL
    
    if (scriptCallbackCall(ON, 'Create'))
    {
        initCharacters();

        initStrumLines();

        initControls();

        initHud();

        initSounds();

        initSong();

        moveCamera(0);
    }

    scriptCallbackCall(POST, 'Create');
}

// Characters

var characters:FlxTypedGroup<Character>;
var charactersArray:Array<Array<Character>> = [];

var playerCharacters:FlxTypedGroup<Character>;
var opponentCharacters:FlxTypedGroup<Character>;
var extraCharacters:FlxTypedGroup<Character>;

var characterFactory:String -> CharacterType -> StrumLine = (id, type) -> new Character(id, type);

function initCharacters()
{
    if (scriptCallbackCall(ON, 'CharactersInit'))
    {
        characters = new FlxTypedGroup<Character>();

        playerCharacters = new FlxTypedGroup<Character>();
        opponentCharacters = new FlxTypedGroup<Character>();
        extraCharacters = new FlxTypedGroup<Character>();
        
        for (index => strl in chart.strumLines)
        {
            for (charIndex => char in strl.characters)
            {
                final character:Character = characterFactory(char, strl.type);
                addCharacter(character);

                charactersArray[index] ??= [];

                charactersArray[index][charIndex] = character;
            }
        }
    }

    scriptCallbackCall(POST, 'CharactersInit');
}

function addCharacter(char:Character)
{
    if (scriptCallbackCall(ON, 'CharacterAdd', null, [char], []))
    {
        switch (char.type)
        {
            case 'player':
                playerCharacters?.add(char);

            case 'opponent':
                opponentCharacters?.add(char);

            case 'extra':
                extraCharacters?.add(char);
        }

        characters?.add(char);

        add(char);
    }

    scriptCallbackCall(POST, 'CharacterAdd', null, [char], []);
}

// StrumLines

var strumLines:FlxTypedGroup<StrumLine>;

var playerStrumLines:FlxTypedGroup<StrumLine>;
var opponentStrumLines:FlxTypedGroup<StrumLine>;
var extraStrumLines:FlxTypedGroup<StrumLine>;

var strums:FlxTypedGroup<Strum>;

function initStrumLines()
{
    if (scriptCallbackCall(ON, 'StrumLinesInit'))
    {
        add(strumLines = new FlxTypedGroup<StrumLine>());
        strumLines.camera = camHUD;

        playerStrumLines = new FlxTypedGroup<StrumLine>();
        opponentStrumLines = new FlxTypedGroup<StrumLine>();
        extraStrumLines = new FlxTypedGroup<StrumLine>();

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
            final strumLine:StrumLine = new StrumLine(strl.file, strl.type, index, notesArray[index], stackNote);
            strumLine.noteSpawnCallback = spawnNote;
            strumLine.noteHitCallback = hitNote;
            strumLine.noteMissCallback = missNote;

            var strumHeight:Float = 0;

            for (strum in strumLine.strums)
                strumHeight = Math.max(strumHeight, strum.height);

            strumLine.x = strumLine.type == 'opponent' ? strl.position.x : FlxG.width - strl.position.x - (strumLine.config.config.length - 1) * strumLine.config.spacing - strumLine.strums.members[strumLine.strums.members.length - 1].width;
            strumLine.y = ClientPrefs.data.downScroll ? FlxG.height - strl.position.y - strumHeight : strl.position.y;
            
            addStrumLine(strumLine);
        }
    }

    scriptCallbackCall(POST, 'StrumLinesInit');
}

function addStrumLine(strl:StrumLine)
{
    switch (strl.type)
    {
        case 'player':
            playerStrumLines?.add(strl);

        case 'opponent':
            opponentStrumLines?.add(strl);

        case 'extra':
            extraStrumLines?.add(strl);
    }

    strumLines?.add(strl);

    for (strum in strl.strums)
        strums?.add(strum);
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
        if (note.type == 'arrow')
            note.strumLine.splashes.members[note.data].splash();

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
var scoreText:FlxText;

var icons:FlxTypedGroup<Icon>;

var playerIcons:FlxTypedGroup<Icon>;
var opponentIcons:FlxTypedGroup<Icon>;
var extraIcons:FlxTypedGroup<Icon>;

var iconP1(get, never):Icon;
function get_iconP1():Icon
    return playerIcons.members[0];

var iconP2(get, never):Icon;
function get_iconP2():Icon
    return opponentIcons.members[0];

var iconP3(get, never):Icon;
function get_iconP3():Icon
    return extraIcons.members[0];

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

        scoreText = new FlxText(0, healthBar.y + 40, FlxG.width, 'Score      Misses      Rating');
        scoreText.setFormat(Paths.font('vcr.ttf'), 17, FlxColor.WHITE, 'center', FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        scoreText.borderSize = 1.25;
        uiGroup.add(scoreText);
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

// Camera

function onCamerasInit()
{
    if (scriptCallbackCall(ON, 'CamerasInit'))
    {
		game.camGame = new FXCamera();

        final camGame:FXCamera = cast camGame;
		
        camGame.speed = 1;
        camGame.zoomSpeed = 1;
        camGame.bopModulo = 4;
        // camGame.zoom = camGame.targetZoom = stage.config.zoom;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.setDefaultDrawTarget(camGame, true);
        
		game.camHUD = new FXCamera();

		FlxG.cameras.add(camHUD, false);
    }

    scriptCallbackCall(POST, 'CamerasInit');

    return Function_Stop;
}

var allowCameraMoving:Bool = true;

var cameraTarget:Character;

function moveCamera(?char:OneOfTwo<Character, Int>, ?force:Bool = false)
{
    var character:Character = null;

    if (char is FlxSprite)
    {
        character = cast char;
    } else {
        final songSection = chart.sections[char];
        
        if (songSection != null)
            character = charactersArray[songSection.camera[0]][songSection.camera[1]];
    }

    if (character != null)
        cameraTarget = character;

    if (scriptCallbackCall(ON, 'CameraMove', null, [cameraTarget], []))
    {
        if ((allowCameraMoving || force) && character != null)
        {
            final pos:Point = getCharacterCamera(character);

            cast(camGame, FXCamera).position.set(pos.x, pos.y);
        }
    }

    scriptCallbackCall(POST, 'CameraMove', null, [cameraTarget], []);
}

function getCharacterCamera(character:Character):Point
{
    final result:Point = {x: character.getMidpoint().x + character._castConfig.cameraOffset.x * (character.type == 'player' ? -1 : 1), y: character.getMidpoint().y + character._castConfig.cameraOffset.y};

    /*
    if (stage.config.charactersCamera != null)
    {
        var offset:Point = null;

        if (stage.config.charactersCamera.type != null)
            offset = Reflect.getProperty(stage.config.charactersCamera.type, cast character.type);

        if (stage.config.charactersCamera.id != null)
            offset = Reflect.getProperty(stage.config.charactersCamera.id, character.id);

        if (offset != null)
        {
            result.x += offset.x ?? 0;
            result.y += offset.y ?? 0;
        }
    }
        */

    return result;
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

function onUpdate(elapsed:Float)
{
    if (FlxG.keys.justPressed.SPACE)
        if (Conductor.music.playing)
            Conductor.pause();
        else
            Conductor.resume();
}

function onSectionHit(curSection:Int)
{
    if (scriptCallbackCall(ON, 'SectionHit'))
    {
        // SUPER CALL

        moveCamera(curSection);
    }

    scriptCallbackCall(POST, 'SectionHit');
}

function onMusicComplete()
{
    if (scriptCallbackCall(ON, 'MusicComplete'))
    {
        // SUPER CALL

        exit();
    }

    scriptCallbackCall(POST, 'MusicComplete');
}

function onDestroy()
{
    if (scriptCallbackCall(ON, 'Destroy'))
    {
        // SUPER CALL

        FlxG.stage.removeEventListener('keyDown', justPressedKey);
        FlxG.stage.removeEventListener('keyUp', justReleasedKey);

        
        for (vocal in vocals.copy())
            Conductor.synchronizedSounds.remove(vocal);


        characters?.destroy();

        playerCharacters?.destroy();
        opponentCharacters?.destroy();
        extraCharacters?.destroy();


        playerStrumLines?.destroy();
        opponentStrumLines?.destroy();
        playerStrumLines?.destroy();

        strums?.destroy();
    }

    scriptCallbackCall(POST, 'Destroy');
}
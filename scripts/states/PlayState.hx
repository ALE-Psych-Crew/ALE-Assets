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

final stage:JsonStage;

var startTime:Float = 0;

public function new(?newSong:String = 'bopeebo', ?newDifficulty:String = 'hard')
{
    // SUPER CALL

    Conductor.stop();

    song = newSong;
    difficulty = newDifficulty;

    songRoute = CoolUtil.searchComplexFile('songs/' + song);

    chart = Formatter.getChart(song, difficulty);

    stage = new Stage(Formatter.getStage(chart.stage));
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

        stage.change(chart.stage);

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

var bf(get, never):Character;
function get_bf():Character
    return playerCharacters.members[0];

var boyfriend(get, never):Character;
function get_boyfriend():Character
    return playerCharacters.members[0];

var dad(get, never):Character;
function get_dad():Character
    return opponentCharacters.members[0];

var gf(get, never):Character;
function get_gf():Character
    return extraCharacters.members[0];

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

var lastAddedCharacter:Character = null;

function addCharacter(char:Character)
{
    lastAddedCharacter = char;

    if (scriptCallbackCall(ON, 'CharacterAdd', null, [char], []))
    {
        getCharacterGroup(char.type)?.add(char);

        characters?.add(char);

        add(char);

        resetCharacterPosition(char);
    }

    scriptCallbackCall(POST, 'CharacterAdd', null, [char], []);
}

var lastChangedCharacter:Character = null;

function changeCharacter(char:Character, newChar:String)
{
    lastChangedCharacter = char;

    if (scriptCallbackCall(ON, 'CharacterChange', null, [char, newChar], [newChar]))
    {
        final stateIndex = members?.indexOf(char);

        remove(char, true);
        
        final globalIndex = characters?.members?.indexOf(char);

        characters?.remove(char, true);

        final specificGroup = getCharacterGroup(char);

        final specificIndex = specificGroup?.members?.indexOf(char);

        specificGroup?.remove(char, true);

        char?.destroy();

        final newChar = new Character(newChar, char.type);

        characters?.insert(globalIndex, newChar);
        
        specificGroup?.insert(specificIndex, newChar);

        insert(stateIndex, newChar);
    }

    scriptCallbackCall(POST, 'CharacterChange', null, [char, newChar], [newChar]);
}

function getCharacterGroup(type:CharacterType)
{
    return switch (type)
    {
        case 'opponent':
            opponentCharacters;

        case 'player':
            playerCharacters;

        case 'extra':
            extraCharacters;
    }
}

var lastPositionResetCharacter:Character = null;

function resetCharacterPosition(character:Character)
{
    lastPositionResetCharacter = character;

    if (scriptCallbackCall(ON, 'CharacterPositionReset', null, [character], []))
    {
        character.x = character._castConfig.properties.x;
        character.y = character._castConfig.properties.y;

        if (stage.config.charactersOffset != null)
        {
            var offset:Point = null;

            if (stage.config.charactersOffset.type != null)
                offset = Reflect.getProperty(stage.config.charactersOffset.type, cast character.type);

            if (stage.config.charactersOffset.id != null)
                offset = Reflect.getProperty(stage.config.charactersOffset.id, character.id);

            if (offset != null)
            {
                character.x += offset.x ?? 0;
                character.y += offset.y ?? 0;
            }
        }
    }

    scriptCallbackCall(POST, 'CharacterPositionReset', null, [character], []);
}

function getCharacterCamera(character:Character):Point
{
    final result:Point = {x: character.getMidpoint().x + character._castConfig.cameraOffset.x * (character.type == 'player' ? -1 : 1), y: character.getMidpoint().y + character._castConfig.cameraOffset.y};

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

    return result;
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

var lastAddedStrumLine:StrumLine = null;

function addStrumLine(strl:StrumLine)
{
    lastAddedStrumLine = strl;

    if (scriptCallbackCall(ON, 'StrumLineAdd', null, [strl], []))
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

    scriptCallbackCall(POST, 'StrumLineAdd', null, [strl]);
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

        healthBar = new Bar('hud/' + hud.directory + '/bar', 'hud/' + hud.directory + '/barFill', false);
        healthBar.x = FlxG.width / 2 - healthBar.width / 2;
        healthBar.y = FlxG.height * (ClientPrefs.data.downScroll ? 0.1 : 0.9);
        uiGroup.add(healthBar);

        uiGroup.add(icons = new FlxTypedGroup<Icon>());
        icons.camera = camHUD;

        playerIcons = new FlxTypedGroup<Icon>();
        opponentIcons = new FlxTypedGroup<Icon>();
        extraIcons = new FlxTypedGroup<Icon>();

        scoreText = new FlxText(0, healthBar.y + 40, FlxG.width, 'Score      Misses      Rating');
        scoreText.setFormat(Paths.font('vcr.ttf'), 17, FlxColor.WHITE, 'center', FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        scoreText.borderSize = 1.25;
        uiGroup.add(scoreText);

        addIcon(new Icon(bf == null ? gf._castConfig.icon : bf._castConfig.icon, 'player'));
        addIcon(new Icon(dad == null ? gf._castConfig.icon : dad._castConfig.icon, 'opponent'));

        healthBar.fillFront.color = CoolUtil.colorFromString(bf == null ? gf._castConfig.barColor : bf._castConfig.barColor);
        healthBar.fillBack.color = CoolUtil.colorFromString(dad == null ? gf._castConfig.barColor : dad._castConfig.barColor);
    }

    scriptCallbackCall(POST, 'HudInit');
}

var lastAddedIcon:Icon = null;

function addIcon(icon:Icon)
{
    lastAddedIcon = icon;

    if (scriptCallbackCall(ON, 'IconAdd', null, [icon], []))
    {
        icon.bar = healthBar;

        switch (icon.type)
        {
            case 'opponent':
                opponentIcons.add(icon);
                
            case 'player':
                playerIcons.add(icon);

            case 'extra':
                extraIcons.add(icon);
        }

        icons.add(icon);
    }

    scriptCallbackCall(POST, 'IconAdd', null, [icon], []);
}

function changeIcon(icon:Icon, newIcon:String)
{
    final globalIndex = icons?.members?.indexOf(icon);

    icons?.remove(icon, true);

    final specificGroup = getIconGroup(icon.type);

    final specificIndex = specificGroup.members?.indexOf(icon);

    specificGroup?.remove(icon, true);

    icon?.destroy();

    final newIcon = new Icon(newIcon, icon.type);
    newIcon.bar = healthBar;

    icons?.insert(globalIndex, newIcon);

    specificGroup?.insert(specificIndex, newIcon);
}

function getIconGroup(type:CharacterType)
{
    return switch (type)
    {
        case 'opponent':
            opponentIcons;
            
        case 'player':
            playerIcons;

        case 'extra':
            extraIcons;
    }
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


        playerIcons?.destroy();
        opponentIcons?.destroy();
        extraIcons?.destroy();
    }

    scriptCallbackCall(POST, 'Destroy');
}
package;

import flixel.text.FlxText.FlxTextBorderStyle;

import utils.Formatter;


ClientPrefs.data.downScroll = false;
ClientPrefs.data.botplay = false;


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

public function new(?newSong:String = 'bopeebo', ?newDifficulty:String = 'hard')
{
    // SUPER CALL

    song = newSong;
    difficulty = newDifficulty;

    chart = Formatter.getChart(song, difficulty);
}

var totalNoteTypes:Array<String> = [];

var allowNotesSpawning:Bool = true;

function onCreate()
{
    // SUPER CALL
    
    if (scriptCallbackCall(ON, 'Create'))
    {
        initStrumLines();

        initControls();

        initSong();
    }

    scriptCallbackCall(POST, 'Create');
}

// StrumLines & Characters

var strumLines:FlxTypedGroup<StrumLine>;

var characters:FlxTypedGroup<Character>;
var charactersArray:Array<Array<Character>> = [];

var strums:FlxTypedGroup<Strum>;

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

        for (section in chart.sections)
        {
            if (section.changeBPM)
                Conductor.bpm = section.bpm;

            for (note in section.notes)
            {
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

        Conductor.bpm = chart.bpm;

        for (index => strl in chart.strumLines)
        {
            for (charIndex => char in strl.characters)
            {
                final character:Character = new Character(char, strl.type);
                characters.add(character);
                add(character);

                charactersArray[index] ??= [];

                charactersArray[index][charIndex] = character;
            }

            final strumLine:StrumLine = new StrumLine(strl.file, strl.type, index, allowNotesSpawning ? notesArray[index] : [], stackNote);
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

// Audios

function initSong()
{
    Conductor.play(Paths.inst('songs/' + song));
}

// ScriptedState Callbacks

function onDestroy()
{
    // SUPER CALL

    FlxG.stage.removeEventListener('keyDown', justPressedKey);
    FlxG.stage.removeEventListener('keyUp', justReleasedKey);

    characters?.destroy();

    strums?.destroy();
}
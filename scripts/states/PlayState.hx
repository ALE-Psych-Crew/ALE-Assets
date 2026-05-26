package;

import funkin.visuals.objects.Bar;
import funkin.visuals.game.*;

import utils.Formatter;

final song:String;
var difficulty:String;

final chart:JsonChart;

public function new(?newSong:String = 'bopeebo', ?newDifficulty:String = 'hard')
{
    song = newSong;
    difficulty = newDifficulty;

    chart = Formatter.getChart(song, difficulty);
}

function onCreate()
{
    initStrumLines();

    initControls();

    Conductor.play(Paths.inst('songs/' + song), chart.bpm, chart.stepsPerBeat, chart.beatsPerSection, false);
}

var spawnNotes:Bool = true;

var startTime:Float = 0;

var strumLines:FlxTypedGroup<StrumLine>;
var strums:FlxTypedGroup<Strum>;

var characters:FlxTypedGroup<Character>;
var players:FlxTypedGroup<Character>;
var opponents:FlxTypedGroup<Character>;
var extras:FlxTypedGroup<Character>;

var charactersArray:Array<Array<Character>> = [];

function initStrumLines()
{
    add(characters = new FlxTypedGroup<Character>());
    
    add(strumLines = new FlxTypedGroup<StrumLine>());
    strumLines.camera = camHUD;

    strums = new FlxTypedGroup<Strum>();

    players = new FlxTypedGroup<Character>();
    opponents = new FlxTypedGroup<Character>();
    extras = new FlxTypedGroup<Character>();

    final notes:Array<Array<Array<Dynamic>>> = [];
    
    if (spawnNotes)
    {
        for (section in chart.sections)
        {
            if (section.changeBPM)
                Conductor.bpm = section.bpm;

            for (note in section.notes)
            {
                if (note[0] < startTime)
                    continue;

                notes[note[4]] ??= [];

                notes[note[4]].push([
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
    
    for (strlIndex => jsonStrl in chart.strumLines)
    {
        for (charIndex => char in jsonStrl.characters)
        {
            final char:Character = new Character(char, jsonStrl.type);
            characters.add(char);

            charactersArray[strlIndex] ??= [];

            charactersArray[strlIndex][charIndex] = char;
        }

        final strl:StrumLine = new StrumLine(jsonStrl.file, jsonStrl.type, strlIndex, stackNote, notes[strlIndex] ?? []);

        var strumHeight:Float = 0;

        for (strum in strl.strums.members)
        {
            strums.add(strum);
            
            strumHeight = Math.max(strumHeight, strum.height);
        }

        strl.x = jsonStrl.leftToRight ? jsonStrl.position.x : FlxG.width - jsonStrl.position.x - (strl.config.config.length - 1) * strl.config.spacing - strl.strums.members[strl.strums.members.length - 1].width;
        strl.y = ClientPrefs.data.downScroll ? FlxG.height - jsonStrl.position.y - strumHeight : jsonStrl.position.y;

        strl.noteSpawnCallback = spawnNote;
        strl.noteHitCallback = hitNote;
        strl.noteMissCallback = missNote;

        strumLines.add(strl);
    }
}

function initControls()
{
    FlxG.stage.addEventListener('keyDown', justPressedKey);
    FlxG.stage.addEventListener('keyUp', justReleasedKey);
}

function justPressedKey(event:KeyboardEvent)
{
    if (!updating)
        return;
    
    if (Controls.anyJustPressed([event.keyCode]))
        strumLines.forEachAlive(strl -> strl.justPressedKey(event.keyCode));
}

function justReleasedKey(event:KeyboardEvent)
{
    if (!updating)
        return;

    strumLines.forEachAlive(strl -> strl.justReleasedKey(event.keyCode));
}

function stackNote(note:Note):Bool
{
    return true;
}

function spawnNote(note:Note)
{
    return true;
}

function hitNote(note:Note)
{
    charactersArray[note.character[0]][note.character[1]]?.sing(note.strumLineConfig.sing);

    return true;
}

function missNote(note:Note)
{
    charactersArray[note.character[0]][note.character[1]]?.miss(note.strumLineConfig.miss);

    return true;
}

function onDestroy()
{
    FlxG.stage.removeEventListener('keyDown', justPressedKey);
    FlxG.stage.removeEventListener('keyUp', justReleasedKey);

    strums.destroy();
    strums = null;

    players.destroy();
    players = null;

    opponents.destroy();
    opponents = null;

    extras.destroy();
    extras = null;

    charactersArray = null;
}
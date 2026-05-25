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

    Conductor.play(Paths.inst('songs/' + song), chart.bpm, chart.stepsPerBeat, chart.beatsPerSection, false);
}

var spawnNotes:Bool = true;

var startTime:Float = 0;

var strumLines:FlxTypedGroup<StrumLine>;

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

        final strl:StrumLine = new StrumLine(jsonStrl.file, jsonStrl.type, strlIndex, _ -> true, notes[strlIndex] ?? []);
        strl.x = jsonStrl.position.x;
        strl.y = jsonStrl.position.y;

        strumLines.add(strl);
    }
}

function onDestroy()
{
    players.destroy();
    players = null;

    opponents.destroy();
    opponents = null;

    extras.destroy();
    extras = null;
}
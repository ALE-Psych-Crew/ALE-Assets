package;

import flixel.text.FlxText.FlxTextBorderStyle;

import utils.Formatter;


ClientPrefs.data.downScroll = false;
ClientPrefs.data.botplay = false;


for (file in Paths.readDirectory('scripts/classes'))
    HotReloading.add('scripts/classes/' + file);

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

function onCreate()
{
    // SUPER CALL
    
    initStrumLines();

    initSong();
}

// StrumLines & Characters

var strumLines:FlxTypedGroup<StrumLine>;

var strums:FlxTypedGroup<Strum>;

function initStrumLines()
{
    add(strumLines = new FlxTypedGroup<StrumLine>());
    strumLines.camera = camHUD;

    strums = new FlxTypedGroup<Strum>();

    for (index => strl in chart.strumLines)
    {
        final strumLine:StrumLine = new StrumLine(strl.file, strl.type, index, chart.sections, chart.bpm);

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

function initSong()
{
    Conductor.play(Paths.inst('songs/' + song));
}

// Flixel

function onUpdate(elapsed:Float)
{
    for (strl in strumLines)
        for (strum in strl.strums)
            strum.angle = strum.direction = Math.sin(Conductor.secTime * 2) * 15;
}

function onDestroy()
{
    // SUPER CALL

    strums.destroy();
}
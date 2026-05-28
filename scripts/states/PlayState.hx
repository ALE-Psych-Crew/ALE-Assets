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

// enum ahh shit

final ON:String = 'on';
final POST:String = 'on';

function scriptCallbackCall(type:String, name:String, ?globalArgs:Array<Dynamic>, ?hxArgs:Array<Dynamic>, ?luaArgs:Array<Dynamic>):Bool
    return true;

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

var strums:FlxTypedGroup<Strum>;

function initStrumLines()
{
    if (scriptCallbackCall(ON, 'StrumLinesInit'))
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

    scriptCallbackCall(POST, 'StrumLinesInit');
}

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

function initSong()
{
    Conductor.play(Paths.inst('songs/' + song));
}

// Flixel

function onDestroy()
{
    // SUPER CALL

    FlxG.stage.removeEventListener('keyDown', justPressedKey);
    FlxG.stage.removeEventListener('keyUp', justReleasedKey);

    strums.destroy();
}
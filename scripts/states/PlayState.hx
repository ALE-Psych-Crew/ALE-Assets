import utils.Formatter;

static final scriptsManager = {
    callback:
        function (type, id, ?global, ?haxe, ?lua)
        {
            // debugTrace([Std.string(type) + id, 'Global: ' + global, 'Haxe: ' + haxe, 'Lua: ' + lua].join(' -> '));

            return true;
        }
};

static final superDuper = {
    create: () -> {},
    destroy: () -> {},
    update: (e) -> {},
};

static final ON:String = 'on';
static final POST:String = 'post';

static final FREEPLAY:String = 'freeplay';

static final PLAYER:String = 'player';
static final OPPONENT:String = 'opponent';
static final EXTRA:String = 'extra';

static final ARROW:String = 'arrow';

function postCreate()
{
    create();
}

function postDestroy()
{
    destroy();
}

function postUpdate(elapsed:Float)
{
    update(elapsed);
}

ClientPrefs.data.downScroll = false;
ClientPrefs.data.botplay = true;

// Real Shit

public var startTime:Float = 0;

public var spawnNotes:Bool = true;

public var chart:ALESong;
public var hud:ALEHud = {
    directory: 'default'
};

public final song:String;
public final week:String;
public final playlist:Array<String>;
public final difficulty:String;
public final songIndex:Int;
public final songRoute:String;

public final type:SongType;
public var weekScore:Float = 0;

public var score:Float = 0;
public var totalNotes:Int = 0;
public var accuracyMod:Float = 0;
public var misses:Int = 0;
public var combo:Int = 0;

public var stage:Stage;

public function get_accuracy():Float
    return totalNotes == 0 ? 0 : accuracyMod / totalNotes;
public var accuracy(get, never):Float;

public var botplay(default, set):Bool;
public function set_botplay(value:Bool):Bool
{
    botplay = value;

    return botplay;
}

public var health(default, set):Float;
public function set_health(value:Float):Float
{
    health = FlxMath.bound(value, 0, 100);

    return health;
}

function new(?newType:SongType, ?newPlaylist:Array<String>, ?newDifficulty:String, ?newWeek:String, ?newWeekScore:Float, ?newSongIndex:Int)
{
    newType ??= FREEPLAY;
    newPlaylist ??= ['Bopeebo'];
    newDifficulty ??= 'normal';
    newWeekScore ??= 0;
    newSongIndex ??= 0;

    type = newType;

    playlist = newPlaylist;
    difficulty = newDifficulty;
    songIndex = newSongIndex;
    song = playlist[songIndex];

    week = newWeek;
    weekScore = newWeekScore;

    songRoute = CoolUtil.searchComplexFile('songs/' + song);

    chart = Formatter.getChart(song, difficulty);

    stage = new Stage(Formatter.getStage(chart.stage));
}

function create()
{
    superDuper.create();

    if (scriptsManager.callback(ON, 'Create'))
    {
        initCharacters();

        initStrumLines();

        initControls();

        initSounds();

        startSong();
    }

    scriptsManager.callback(POST, 'Create');
}

function update(elapsed:Float)
{
    superDuper.update(elapsed);

    if (scriptsManager.callback(ON, 'Update', [elapsed]))
    {

    }

    scriptsManager.callback(POST, 'Update', [elapsed]);
}

function destroy()
{
    superDuper.destroy();

    if (scriptsManager.callback(ON, 'Destroy'))
    {
        FlxG.stage.removeEventListener('keyDown', justPressedKey);
        FlxG.stage.removeEventListener('keyUp', justReleasedKey);

        for (vocal in vocals.copy())
            Conductor.synchronizedSounds?.remove(vocal);

        characters?.destroy();

        playerCharacters?.destroy();
        opponentCharacters?.destroy();
        extraCharacters?.destroy();

        playerStrumLines?.destroy();
        opponentStrumLines?.destroy();
        extraStrumLines?.destroy();

        strums?.destroy();

        playerStrums?.destroy();
        opponentStrums?.destroy();
        extraStrums?.destroy();
    }

    scriptsManager.callback(POST, 'Destroy');
}
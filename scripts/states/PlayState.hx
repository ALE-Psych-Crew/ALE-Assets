import utils.Formatter;

public final scriptsManager = {
    callback: (_, __) -> true
};

public final superDuper = {
    create: () -> {}
};

public final ON:String = 'on';
public final POST:String = 'post';

public final FREEPLAY:String = 'freeplay';

function postCreate()
{
    create();
}

// Real Shit

public var chart:ALESong;

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

    stage = new Stage(super, Formatter.getStage(chart.stage));
}

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

function create()
{
    superDuper.create();

    if (scriptsManager.callback(ON, 'Create'))
    {
        initStrumLines();

        startSong();
    }
}
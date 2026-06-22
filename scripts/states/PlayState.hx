import funkin.visuals.FXCamera;

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
    sectionHit: (curSection) -> {},
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

function onSectionHit(curSection:Int)
{
    sectionHit(curSection);
}

function onCamerasInit()
{
    initCameras();

    return Function_Stop;
}

public var CONTEXT_VARIABLES = Reflect.getProperty(this, 'context').publicVariables;

ClientPrefs.data.downScroll = false;
ClientPrefs.data.botplay = true;

// Real Shit

public var startTime:Float = 0;

public var spawnNotes:Bool = true;
public var skipCountdown:Bool = false;

public var chart:ALESong;
public var hud:ALEHud;

// FIX

public function get_hudRoute():String
    return 'huds/' + hud.directory;
public var hudRoute:String;

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

// FIX

public var accuracy:Float;
public function get_accuracy():Float
{
    final totalNotes = CONTEXT_VARIABLES.get('totalNotes');
    final accuracyMod = CONTEXT_VARIABLES.get('accuracyMod');

    accuracy = totalNotes == 0 ? 100 : accuracyMod / totalNotes;

    return accuracy;
}

public var botplay(default, set):Bool;
public function set_botplay(value:Bool):Bool
{
    botplay = value;

    // FIX

    /*
    if (strumLines != null)
        for (strl in strumLines)
            strl.botplay = botplay;
    */

    return botplay;
}

public var health:Float = 50;

function new(?newType:SongType, ?newPlaylist:Array<String>, ?newDifficulty:String, ?newWeek:String, ?newWeekScore:Float, ?newSongIndex:Int)
{
    newType ??= FREEPLAY;
    newPlaylist ??= ['bopeebo'];
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

    hud = Paths.json('data/huds/' + stage.config.hud);

    hud.ratings.sort((a, b) -> Reflect.compare(a.time, b.time));
}

function create()
{
    superDuper.create();

    if (scriptsManager.callback(ON, 'Create'))
    {
        initCharacters();

        initCombo();
        
        initHud();

        initIcons();

        // FIX

        botplay = ClientPrefs.data.botplay;

        initStrumLines();

        initControls();

        stage.change(chart.stage);

        initSounds();

        initSong();

        moveCamera(0);

        camGame.snapToTarget();
    }

    scriptsManager.callback(POST, 'Create');
}

var _lastHealth:Float = -1;

function update(elapsed:Float)
{
    superDuper.update(elapsed);

    if (scriptsManager.callback(ON, 'Update', [elapsed]))
    {
        var health = CONTEXT_VARIABLES.get('health');
        
        health = FlxMath.bound(health, 0, 100);

        if (_lastHealth != health)
        {
            _lastHealth = health;

            updateHealth();
        }

        if (Controls.PAUSE)
            pause();
    }

    scriptsManager.callback(POST, 'Update', [elapsed]);
}

var allowPausing:Bool = true;

function pause(?force:Bool = false)
{
    if (scriptsManager.callback(ON, 'Pause'))
    {
        if (allowPausing || force)
        {
            FlxTimer.globalManager.forEach(tmr -> if (tmr != null && !tmr.finished) tmr.active = false);
            FlxTween.globalManager.forEach(twn ->  if (twn != null && !twn.finished) twn.active = false);

            CoolUtil.openSubState(new CustomSubState(CoolVars.meta.pauseSubState));
        }
    }

    scriptsManager.callback(POST, 'Pause');
}

function resume()
{
    if (scriptsManager.callback(ON, 'Resume'))
    {
        FlxTimer.globalManager.forEach(tmr -> if (tmr != null && !tmr.finished) tmr.active = true);
        FlxTween.globalManager.forEach(twn ->  if (twn != null && !twn.finished) twn.active = true);
    }

    scriptsManager.callback(POST, 'Resume');
}

function initCameras()
{
    if (scriptsManager.callback(ON, 'CamerasInit'))
    {
		game.camGame = new FXCamera();

        final camGame:FXCamera = cast camGame;
		
        camGame.speed = 1;
        camGame.zoomSpeed = 1;
        camGame.bopModulo = 4;
        camGame.zoom = camGame.targetZoom = stage.config.zoom;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.setDefaultDrawTarget(camGame, true);
        
		game.camHUD = new FXCamera();

		FlxG.cameras.add(camHUD, false);
            
        camOther = new FXCamera();

        FlxG.cameras.add(camOther, false);
    }

    scriptsManager.callback(POST, 'CamerasInit');
}

function sectionHit(curSection:Int)
{
    if (scriptsManager.callback(ON, 'SectionHit', [curSection]))
    {
        moveCamera(curSection);
    }

    scriptsManager.callback(POST, 'SectionHit', [curSection]);
}

function destroy()
{
    superDuper.destroy();

    if (scriptsManager.callback(ON, 'Destroy'))
    {
        Conductor.stop();

        FlxG.stage.removeEventListener('keyDown', justPressedKey);
        FlxG.stage.removeEventListener('keyUp', justReleasedKey);

        for (vocal in vocals.copy())
            Conductor.synchronizedSounds?.remove(vocal);

        characters?.destroy();

        playerCharacters?.destroy();
        opponentCharacters?.destroy();
        extraCharacters?.destroy();

        playerIcons?.destroy();
        opponentIcons?.destroy();
        extraIcons?.destroy();

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

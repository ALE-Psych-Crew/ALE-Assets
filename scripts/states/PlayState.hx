package;

import funkin.visuals.objects.Bar;
import funkin.visuals.game.*;

import flixel.text.FlxText.FlxTextBorderStyle;

import utils.Formatter;


ClientPrefs.data.downScroll = true;
ClientPrefs.data.botplay = false;


final song:String;
final difficulty:String;

final chart:JsonChart;

public function new(?newSong:String = 'bopeebo', ?newDifficulty:String = 'hard')
{
    song = newSong;
    difficulty = newDifficulty;

    chart = Formatter.getChart(song, difficulty);
}

var weekScore:Float = 0;

var score:Float = 0;
var totalNotes:Int = 0;
var accuracyMod:Float = 0;
var misses:Int = 0;
var combo:Int = 0;

var health(default, set):Float = 50;
var minHealth(default, set):Float = 0;
var maxHealth(default, set):Float = 100;
var healthFactor:Float = 1;

function set_health(value:Float):Float
    return health = FlxMath.bound(value, minHealth, maxHealth);

function set_minHealth(value:Float):Float
{
    health = health;

    return minHealth = value;
}

function set_maxHealth(value:Float):Float
{
    health = health;

    return maxHealth = value;
}

var startTime:Float = 0;
var spawnNotes:Bool = true;

function onCreate()
{
    initStrumLines();

    initControls();

    initHud();

    Conductor.play(Paths.inst('songs/' + song), chart.bpm, chart.stepsPerBeat, chart.beatsPerSection, false);

    Conductor.music.time = startTime;
}

// Characters and StrumLines

var strumLines:FlxTypedGroup<StrumLine>;

var botplay(default, set):Bool = ClientPrefs.data.botplay;
function set_botplay(value:Bool):Bool
{
    botplay = value;

    for (strl in strumLines)
        strl.botplay = strl.type != 'player' || botplay;

    return botplay;
}

var playerStrumLines:FlxTypedGroup<StrumLine>;
var opponentStrumLines:FlxTypedGroup<StrumLine>;
var extraStrumLines:FlxTypedGroup<StrumLine>;

var strums:FlxTypedGroup<Strum>;

var characters:FlxTypedGroup<Character>;

var playerCharacters:FlxTypedGroup<Character>;
var opponentCharacters:FlxTypedGroup<Character>;
var extraCharacters:FlxTypedGroup<Character>;

var bf(get, never):Character;
function get_bf():Character
    return playerCharacters.members[0];

var dad(get, never):Character;
function get_dad():Character
    return opponentCharacters.members[0];

var gf(get, never):Character;
function get_gf():Character
    return extraCharacters.members[0];

var charactersArray:Array<Array<Character>> = [];

function initStrumLines()
{
    characters = new FlxTypedGroup<Character>();
    
    add(strumLines = new FlxTypedGroup<StrumLine>());
    strumLines.camera = camHUD;

    strums = new FlxTypedGroup<Strum>();

    playerStrumLines = new FlxTypedGroup<Strum>();
    opponentStrumLines = new FlxTypedGroup<Strum>();
    extraStrumLines = new FlxTypedGroup<Strum>();

    playerCharacters = new FlxTypedGroup<Character>();
    opponentCharacters = new FlxTypedGroup<Character>();
    extraCharacters = new FlxTypedGroup<Character>();

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
        for (charIndex => jsonChar in jsonStrl.characters)
        {
            final char:Character = new Character(jsonChar, jsonStrl.type);

            addCharacter(char);

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

        addStrumLine(strl);
    }

    botplay = ClientPrefs.data.botplay;
}

function addStrumLine(strl:StrumLine)
{
    strumLines.add(strl);

    switch (strl.type)
    {
        case 'opponent':
            opponentStrumLines.add(strl);

        case 'player':
            playerStrumLines.add(strl);

        case 'extra':
            extraStrumLines.add(strl);
    }
}

function addCharacter(char:Character)
{
    characters.add(char);

    switch (char.type)
    {
        case 'opponent':
            opponentCharacters.add(char);

        case 'player':
            playerCharacters.add(char);

        case 'extra':
            extraCharacters.add(char);
    }

    add(char);
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
    note.hitHealth *= 50;
    note.missHealth *= 50;

    return true;
}

function spawnNote(note:Note)
    return true;

function hitNote(note:Note)
{
    final character:Character = characterFromNote(note);

    character?.sing(note.strumLineConfig.sing);

    if (note.strumLine.type == 'player')
    {
        health += note.hitHealth;

        if (note.type == 'arrow')
        {
            totalNotes++;

            combo++;

            updateScoreText();
        }
    }

    return true;
}

function missNote(note:Note)
{
    final character:Character = characterFromNote(note);

    character?.miss(note.strumLineConfig.miss);

    if (note.strumLine.type == 'player')
    {
        health -= note.missHealth;

        if (note.type == 'arrow')
        {
            misses++;

            totalNotes++;

            combo = 0;

            updateScoreText();
        }
    }

    return true;
}

function characterFromNote(note:Note):Character
    return charactersArray[note.character[0]][note.character[1]];

// HUD

var uiGroup:FlxTypedGroup<FlxBasic>;

var healthBar:Bar;
var scoreText:FlxText;

var icons:FlxTypedGroup<Icon>;

var opponentIcons:FlxTypedGroup<Icon>;
var playerIcons:FlxTypedGroup<Icon>;
var extraIcons:FlxTypedGroup<Icon>;

function initHud()
{
    add(uiGroup = new FlxTypedGroup<FlxBasic>());
    uiGroup.camera = camHUD;

    healthBar = new Bar('hud/default/bar', 0, FlxG.height * (ClientPrefs.data.downScroll ? 0.1 : 0.9), health, true);
    healthBar.x = FlxG.width / 2 - healthBar.width / 2;
    uiGroup.add(healthBar);

    icons = new FlxTypedGroup<Icon>();
    
    playerIcons = new FlxTypedGroup<Icon>();
    opponentIcons = new FlxTypedGroup<Icon>();
    extraIcons = new FlxTypedGroup<Icon>();

    var usedGF:Bool = false;

    function tryIconSetup(icon:Icon, target:Character, bar:FlxSprite)
    {
        target ??= gf;

        if (target != null && !(target == gf && usedGF))
        {
            bar.color = CoolUtil.colorFromString(target.config.barColor);

            icon.change(target.config.icon);
            
            if (target == gf)
                usedGF = true;
        } else {
            icon.change('bf');
            
            bar.color = FlxColor.BLACK;

            icon.visible = false;
        }
    }

    opponentIcon = new Icon('dad', gf != null && dad == null ? 'extra' : 'opponent');
    addIcon(opponentIcon);
    tryIconSetup(opponentIcon, dad, healthBar.rightBar);

    playerIcon = new Icon('bf', gf != null && bf == null ? 'extra' : 'player');
    addIcon(playerIcon);
    tryIconSetup(playerIcon, bf, healthBar.leftBar);

    scoreText = new FlxText(0, healthBar.y + 40, FlxG.width);
    scoreText.setFormat(Paths.font('vcr.ttf'), 17, FlxColor.WHITE, 'center', FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    scoreText.borderSize = 1.25;
    uiGroup.add(scoreText);

    updateScoreText();
}

function addIcon(icon:Icon)
{
    icons.add(icon);

    icon.bar = healthBar;

    switch (icon.type) {}

    uiGroup.add(icon);
}

// General

function updateScoreText()
{
    scoreText.text = botplay ? 'BOTPLAY' : 'Score: 0' + '    Misses: ' + misses + '    Accuracy: 0';
}

// Flixel Callbacks

var _lastHealth:Float = 50;

function onUpdate(elapsed:Float)
{
    if (health != _lastHealth)
    {
        _lastHealth = health;

        healthBar.percent = health * healthFactor;
    }
}

function onDestroy()
{
    FlxG.stage.removeEventListener('keyDown', justPressedKey);
    FlxG.stage.removeEventListener('keyUp', justReleasedKey);

    playerStrumLines.destroy();
    playerStrumLines = null;
    opponentStrumLines.destroy();
    opponentStrumLines = null;
    extraStrumLines.destroy();
    extraStrumLines = null;

    strums.destroy();
    strums = null;

    charactersArray = null;

    characters.destroy();
    characters = null;

    playerCharacters.destroy();
    playerCharacters = null;
    opponentCharacters.destroy();
    opponentCharacters = null;
    extraCharacters.destroy();
    extraCharacters = null;


    icons.destroy();
    icons = null;

    playerIcons.destroy();
    playerIcons = null;
    opponentIcons.destroy();
    opponentIcons = null;
    extraIcons.destroy();
    extraIcons = null;
}
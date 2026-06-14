package;

public var strumLines:FlxTypedGroup<StrumLine>;

public var playerStrumLines:FlxTypedGroup<StrumLine>;
public var opponentStrumLines:FlxTypedGroup<StrumLine>;
public var extraStrumLines:FlxTypedGroup<StrumLine>;

public var strums:FlxTypedGroup<Strum>;

public var playerStrums:FlxTypedGroup<StrumLine>;
public var opponentStrums:FlxTypedGroup<StrumLine>;
public var extraStrums:FlxTypedGroup<StrumLine>;

public function initStrumLines()
{
    if (scriptsManager.callback(ON, 'StrumLinesInit'))
    {
        add(strumLines = new FlxTypedGroup<StrumLine>());
        strumLines.camera = camHUD;
        
        playerStrumLines = new FlxTypedGroup<StrumLine>();
        opponentStrumLines = new FlxTypedGroup<StrumLine>();
        extraStrumLines = new FlxTypedGroup<StrumLine>();

        strums = new FlxTypedGroup<Strum>();
        
        playerStrums = new FlxTypedGroup<Strum>();
        opponentStrums = new FlxTypedGroup<Strum>();
        extraStrums = new FlxTypedGroup<Strum>();

        final notes = [];

        if (spawnNotes)
        {
            for (section in chart.sections)
            {
                if (section.changeBPM)
                    Conductor.bpm = section.bpm;

                for (note in section.notes)
                {
                    notes[note[4]] ??= [];

                    if (note[0] > Conductor.sectionCrochet * 2)
                        continue;

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

        for (index => strl in chart.strumLines)
        {
            final strumLine:StrumLine = new StrumLine(strl.file, strl.type, index, notes[index], stackNote);
            strumLine.noteSpawnCallback = spawnNote;
            strumLine.noteHitCallback = hitNote;
            strumLine.noteMissCallback = missNote;
            strumLine.visible = strl.visible;
            
            addStrumLine(strumLine);

            var strumsOffsetX:Float = 0;
            var strumsOffsetY:Float = 0;

            for (strumIndex => strum in strumLine.strums.members)
            {
                strumsOffsetX += strumIndex >= strumLine.strums.length - 1 ? strum.width : strumLine.config.spacing;

                strumsOffsetY = Math.max(strumsOffsetY, strum.height);
                
                addStrum(strum);
            }

            strumLine.x = strumLine.type == PLAYER ? FlxG.width - strl.position.x - strumsOffsetX : strl.position.x;
            strumLine.y = strumLine.downScroll ? FlxG.height - strl.position.y - strumsOffsetY : strl.position.y;
        }
    }

    scriptsManager.callback(POST, 'StrumLinesInit');
}

var nextNoteToStack:Note;

public function stackNote(note:Note):Bool
{
    nextNoteToStack = note;

    final result:Bool = scriptsManager.callback(ON, 'NoteStack', null, [nextNoteToStack]);

    scriptsManager.callback(POST, 'NoteStack', null, [nextNoteToStack]);

    return result;
}

var nextNoteToSpawn:Note;

public function spawnNote(note:Note):Bool
{
    nextNoteToSpawn = note;

    final result:Bool = scriptsManager.callback(ON, 'NoteSpawn', null, [nextNoteToSpawn]);

    scriptsManager.callback(POST, 'NoteSpawn', null, [nextNoteToSpawn]);

    return result;
}

var nextNoteToHit:Note;
var nextNoteToHitCharacter:Note;

public function hitNote(note:Note, timeDistance:Float, removeNote:Bool):Bool
{
    nextNoteToHit = note;
    nextNoteToHitCharacter = characterFromNote(nextNoteToHit);

    final result:Bool = scriptsManager.callback(ON, 'NoteHit', null, [nextNoteToHit, nextNoteToHitCharacter, timeDistance, removeNote], [timeDistance, removeNote]);

    if (result)
    {
        nextNoteToHitCharacter?.sing(note.type != ARROW && !nextNoteToHitCharacter._castConfig.sustainAnimation ? null : note.strumLineConfig.sing);
    }

    scriptsManager.callback(POST, 'NoteHit', null, [nextNoteToHit, nextNoteToHitCharacter, timeDistance, removeNote], [timeDistance, removeNote]);

    return result;
}

var nextNoteToMiss:Note;
var nextNoteToMissCharacter:Note;

public function missNote(note:Note):Bool
{
    nextNoteToMiss = note;
    nextNoteToMissCharacter = characterFromNote(nextNoteToMiss);

    final result:Bool = scriptsManager.callback(ON, 'NoteMiss', null, [nextNoteToMiss, nextNoteToMissCharacter]);

    if (result)
    {
        nextNoteToMissCharacter?.miss(note.type != ARROW && !nextNoteToMissCharacter._castConfig.sustainAnimation ? null : note.strumLineConfig.miss);
    }

    scriptsManager.callback(POST, 'NoteMiss', null, [nextNoteToMiss, nextNoteToMissCharacter]);

    return result;
}

public function characterFromNote(note:Note)
    return charactersArray[note.character[0]][note.character[1]];

var nextStrumLineToAdd:StrumLine;

function addStrumLine(strl:StrumLine)
{
    nextStrumLineToAdd = strl;

    if (scriptsManager.callback(ON, 'StrumLineAdd', null, [nextStrumLineToAdd]))
    {
        switch (nextStrumLineToAdd.type)
        {
            case PLAYER:
                playerStrumLines.add(nextStrumLineToAdd);

            case OPPONENT:
                opponentStrumLines.add(nextStrumLineToAdd);

            case EXTRA:
                extraStrumLines.add(nextStrumLineToAdd);
        }

        strumLines.add(nextStrumLineToAdd);
    }

    scriptsManager.callback(POST, 'StrumLineAdd', null, [nextStrumLineToAdd]);
}

var nextStrumToAdd:Strum;

function addStrum(strum:Strum)
{
    nextStrumToAdd = strum;

    if (scriptsManager.callback(ON, 'StrumAdd', null, [nextStrumToAdd]))
    {
        switch (nextStrumToAdd.strumLine.type)
        {
            case PLAYER:
                playerStrums.add(nextStrumToAdd);

            case OPPONENT:
                opponentStrums.add(nextStrumToAdd);

            case EXTRA:
                extraStrums.add(nextStrumToAdd);
        }

        strums.add(nextStrumToAdd);
    }

    scriptsManager.callback(POST, 'StrumAdd', null, [nextStrumToAdd]);
}
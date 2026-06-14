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

        for (section in chart.sections)
        {
            if (section.changeBPM)
                Conductor.bpm = section.bpm;

            for (note in section.notes)
            {
                notes[note[4]] ??= [];

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

        Conductor.bpm = chart.bpm;

        for (index => strl in chart.strumLines)
        {
            final strumLine:StrumLine = new StrumLine(strl.file, strl.type, index, notes[index]);
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
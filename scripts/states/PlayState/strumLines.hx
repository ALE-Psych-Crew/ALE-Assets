package;

public var strumLines:FlxTypedGroup<StrumLine>;

public function initStrumLines()
{
    if (scriptsManager.callback(ON, 'StrumLinesInit'))
    {
        add(strumLines = new FlxTypedGroup<StrumLine>());
        strumLines.camera = camHUD;

        final notes = [];

        for (section in chart.sections)
        {
            if (section.changeBPM)
                Conductor.bpm = section.bpm;

            for (note in section.notes)
            {
                notes[4] ??= [];

                notes[4].push([
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
            strumLines.add(strumLine);
        }
    }

    scriptsManager.callback(POST, 'StrumLinesInit');
}
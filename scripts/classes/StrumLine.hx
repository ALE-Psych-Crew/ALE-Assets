package;

import haxe.ds.GenericStack;

import utils.Formatter;

class StrumLine extends scripting.haxe.ScriptedFlxSpriteGroup
{
    public final type:CharacterType;

    public final config:JsonStrumLine;

    public final strumLineIndex:Int;

    var inputMap:Map<Int, Array<Int>>;

    public var strums:FlxTypedSpriteGroup<Strum>;
    public var notes:FlxTypedSpriteGroup<Note>;
    public var splashes:FlxTypedSpriteGroup<Splash>;

    public var downScroll:Bool = ClientPrefs.data.downScroll;

    var noteStack:GenericStack<Note>;

    public function new(id:String, type:CharacterType, strumLineIndex:Int, chartSections:Array<Array<Dynamic>>, ogBPM:Float, ?noteStackCallback:Note -> Bool)
    {
        super();

        this.strumLineIndex = strumLineIndex;

        this.type = type;

        botplay = type == 'opponent';

        config = Formatter.getStrumLine(id);

        inputMap = new Map<Int, Array<Int>>();

        add(strums = new FlxTypedSpriteGroup<Strum>());
        add(notes = new FlxTypedSpriteGroup<Note>());
        add(splashes = new FlxTypedSpriteGroup<Splash>());

        for (index => data in config.config)
        {
            for (key in Controls.getKeybind(data.keyBind.group, data.keyBind.id))
            {
                final list = inputMap.get(key);

                if (list == null)
                {
                    list = [];

                    inputMap.set(key, list);
                }

                list.push(index);
            }

            final strum:Strum = new Strum(config.strums, data);
            strum.strumLine = super;
            strum.x = index * config.spacing;

            strums.add(strum);
        }

        Conductor.bpm = ogBPM;

        var tempNotes:Array<Note> = [];

        for (section in chartSections)
        {
            if (section.changeBPM)
                Conductor.bpm = section.bpm;

            for (chartNote in section.notes)
            {
                if (chartNote[4] != strumLineIndex)
                    continue;

                final time:Float = chartNote[0];

                if (time > Conductor.sectionCrochet * 4)
                    continue;

                final data:Int = chartNote[1];
                final length:Float = chartNote[2];
                final type:String = chartNote[3];
                final character:Int = chartNote[5];

                final strumLineConfig:JsonStrumLineConfig = config.config[data];

                final crochet:Float = Conductor.stepCrochet;

                final strum:Strum = strums.members[data];
                
                final note:Note = new Note(config.notes, strumLineConfig, 'arrow');
                note.strumLine = super;
                note.crochet = crochet;
                note.strum = strum;
                note.time = time;
                note.data = data;
                note.length = length;
                note.noteType = type;
                note.character = [strumLineIndex, character];
                
                tempNotes.push(note);

                if (length > 0)
                {
                    final floorLength:Int = Math.floor(length / crochet) + 1;

                    var parent:Note = note;

                    for (i in 0...floorLength)
                    {
                        final sustain:Note = new Note(config.notes, strumLineConfig, i == floorLength - 1 ? 'end' : 'sustain');
                        sustain.strumLine = super;
                        sustain.crochet = crochet;
                        sustain.strum = strum;
                        sustain.time = time + i * crochet;
                        sustain.data = data;
                        sustain.noteType = type;
                        sustain.xOffset = strum.width / 2 - sustain.width / 2;
                        sustain.yOffset = strum.height / 2;
                        sustain.parent = parent;
                        sustain.alphaMultiplier = 0.5;
                        sustain.character = [strumLineIndex, character];
                        sustain.flipY = downScroll;

                        tempNotes.push(sustain);

                        parent = sustain;
                    }
                }
            }
        }

        Conductor.bpm = ogBPM;

        tempNotes.sort((a, b) -> {
            if (a.time == b.time)
                return a.type == b.type ? 0 : b.type == 'arrow' ? 1 : -1;

            return a.time > b.time ? -1 : 1;
        });

        noteStack = new GenericStack<Note>();

        noteStackCallback ??= _ -> true;

        for (note in tempNotes)
            if (noteStackCallback(note))
                noteStack.add(note);

        tempNotes = null;

        Conductor.bpm = ogBPM;
    }

    public var spawnWindow:Float = 2000;
    public var despawnWindow:Float = 1000;
    public var missWindow:Int = 180;

    public var speed:Float = 1;

    public var botplay:Bool = false;

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        while (!noteStack.isEmpty() && noteStack.first().time < Conductor.songPosition + spawnWindow / speed)
        {
            final note:Note = noteStack.pop();

            addNote(note);
        }

        var noteIndex:Int = 0;

        while (noteIndex < notes.members.length)
        {
            final note:Note = notes.members[noteIndex];

            if (note == null || !note.exists || !note.alive)
            {
                noteIndex++;

                continue;
            }

            note.timeDistance = note.time - Conductor.songPosition;

            if (botplay)
            {
                if (note.botplayMiss && note.timeDistance < -missWindow && !note.miss && !note.hit && note.ignore)
                    missNote(note);

                if (note.timeDistance <= 0 && !note.hit && !note.ignore)
                    hitNote(note, note.type == 'arrow');
            } else {
                if (note.type != 'arrow' && !note.miss && !note.hit && note.timeDistance <= 0 && keyPressed[note.data] && note.parent.hit)
                    hitNote(note, false);

                if (note.timeDistance < -missWindow && !note.miss && !note.hit && !note.ignore)
                    missNote(note);
            }

            if (note.exists)
            {
                if (note.speed != speed)
                    note.speed = speed;

                note.followStrum();

                if (note.timeDistance < -despawnWindow)
                    removeNote(note);
            }

            noteIndex++;
        }
    }

    var keyPressed:Array<Bool> = [];

    public function justPressedKey(key:Int)
    {
        if (botplay)
            return;

        final strumIndices:Null<Array<Null<Int>>> = inputMap.get(key);

        if (strumIndices != null)
        {
            for (strumIndex in strumIndices)
            {
                keyPressed[strumIndex] = true;

                var noteToHit:Null<Note> = null;

                for (note in notes)
                {
                    if (note == null || note.type != 'arrow' || note.data != strumIndex || note.timeDistance < -missWindow)
                        continue;

                    if (note.timeDistance > missWindow)
                        break;

                    if (noteToHit == null || noteToHit.timeDistance > note.timeDistance)
                        noteToHit = note;
                }

                if (noteToHit != null)
                    hitNote(noteToHit);
                else
                    strums.members[strumIndex].playAnim(config.config[strumIndex].press);
            }
        }
    }

    public function justReleasedKey(key:Int)
    {
        if (botplay)
            return;

        var strumIndices:Null<Array<Null<Int>>> = inputMap.get(key);

        if (strumIndices != null)
        {
            for (strumIndex in strumIndices)
            {
                keyPressed[strumIndex] = false;

                strums.members[strumIndex]?.playAnim(config.config[strumIndex].idle);
            }
        }
    }

    function addNote(note:Note)
    {
        notes.add(note);

        note.strum.children.push(note);
    }

    public var noteHitCallback:Note -> Float -> Bool -> Bool = (_, __, ___) -> true;

    function hitNote(note:Note, ?remove:Bool = true)
    {
        if (noteHitCallback(note, note.timeDistance, remove))
        {
            note.hit = true;

            note.strum.playAnim(note.strum.strumLineConfig.hit);
            
            if (remove)
                removeNote(note);
        }
    }

    public var noteMissCallback:Note -> Bool = _ -> true;

    function missNote(note:Note)
    {
        if (noteMissCallback(note))
            note.miss = true;
    }

    function removeNote(note:Note)
    {
        note.kill();

        note.strum.children.remove(note);

        notes.remove(note, true);

        note.destroy();
    }
}
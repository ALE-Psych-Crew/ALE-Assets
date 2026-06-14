public function initControls()
{
    if (scriptsManager.callback(ON, 'ControlsInit'))
    {
        FlxG.stage.addEventListener('keyDown', justPressedKey);
        FlxG.stage.addEventListener('keyUp', justReleasedKey);
    }

    scriptsManager.callback(POST, 'ControlsInit');
}

public function justPressedKey(event:KeyboardEvent)
{
    if (!updating)
        return;

    if (Controls.anyJustPressed([event.keyCode]))
    {
        if (scriptsManager.callback(ON, 'KeyJustPressed', null, [event], [event.keyCode]))
            strumLines.forEachAlive(strl -> strl.justPressedKey(event.keyCode));

        scriptsManager.callback(POST, 'KeyJustPressed', null, [event], [event.keyCode]);
    }
}

public function justReleasedKey(event:KeyboardEvent)
{
    if (!updating)
        return;

    if (Controls.anyJustReleased([event.keyCode]))
    {
        if (scriptsManager.callback(ON, 'KeyJustReleased', null, [event], [event.keyCode]))
            strumLines.forEachAlive(strl -> strl.justReleasedKey(event.keyCode));

        scriptsManager.callback(POST, 'KeyJustReleased', null, [event], [event.keyCode]);
    }

}
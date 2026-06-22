public var camOther:FXCamera;

public var allowCameraMoving:Bool = true;

public var cameraTarget:Character;

public function moveCamera(?char:OneOfTwo<Character, Int>, ?force:Bool = false)
{
    var character:Character = null;

    if (char is FlxSprite)
    {
        character = cast char;
    } else {
        final songSection = chart.sections[char];
        
        if (songSection != null)
            character = charactersArray[songSection.camera[0]][songSection.camera[1]];
    }

    if (character != null)
        cameraTarget = character;

    if (scriptsManager.callback(ON, 'CameraMove', null, [cameraTarget]))
    {
        if ((allowCameraMoving || force) && character != null)
        {
            final pos:Point = getCharacterCamera(character);

            cast(camGame, FXCamera).position.set(pos.x, pos.y);
        }
    }

    scriptsManager.callback(POST, 'CameraMove', null, [cameraTarget]);
}
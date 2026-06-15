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

function getCharacterCamera(character:Character):Point
{
    final result:Point = {x: character.getMidpoint().x + character._castConfig.cameraOffset.x * (character.type == 'player' ? -1 : 1), y: character.getMidpoint().y + character._castConfig.cameraOffset.y};

    if (stage.config.charactersCamera != null)
    {
        var offset:Point = null;

        if (stage.config.charactersCamera.type != null)
            offset = Reflect.getProperty(stage.config.charactersCamera.type, cast character.type);

        if (stage.config.charactersCamera.id != null)
            offset = Reflect.getProperty(stage.config.charactersCamera.id, character.id);

        if (offset != null)
        {
            result.x += offset.x ?? 0;
            result.y += offset.y ?? 0;
        }
    }

    return result;
}
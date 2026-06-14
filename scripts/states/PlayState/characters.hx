package;

public var characters:FlxTypedGroup<Character>;

public var charactersArray:Array<Array<Character>> = [];

public var playerCharacters:FlxTypedGroup<Character>;
public var opponentCharacters:FlxTypedGroup<Character>;
public var extraCharacters:FlxTypedGroup<Character>;

// FIX

public function get_bf():Character
    return playerCharacters.members[0];
public var bf:Character;

// FIX

public function get_dad():Character
    return opponentCharacters.members[0];
public var dad:Character;

// FIX

public function get_gf():Character
    return extraCharacters.members[0];
public var gf:Character;

public function initCharacters()
{
    if (scriptsManager.callback(ON, 'CharactersInit'))
    {
        characters = new FlxTypedGroup<Character>();

        playerCharacters = new FlxTypedGroup<Character>();
        opponentCharacters = new FlxTypedGroup<Character>();
        extraCharacters = new FlxTypedGroup<Character>();

        for (strlIndex => strl in chart.strumLines)
        {
            strlIndex ??= [];

            for (index => char in strl.characters)
            {
                final character:Character = new Character(char, strl.type);
                
                addCharacter(character);

                charactersArray[strlIndex] ??= [];

                charactersArray[strlIndex][index] = character;
            }
        }
    }

    scriptsManager.callback(POST, 'CharactersInit');
}

var nextCharacterToAdd:Character;

function addCharacter(char:Character)
{
    nextCharacterToAdd = char;

    if (scriptsManager.callback(ON, 'CharacterAdd', null, [nextCharacterToAdd]))
    {
        switch (nextCharacterToAdd.type)
        {
            case PLAYER:
                playerCharacters.add(nextCharacterToAdd);

            case OPPONENT:
                opponentCharacters.add(nextCharacterToAdd);

            case EXTRA:
                extraCharacters.add(nextCharacterToAdd);
        }

        characters.add(char);

        add(nextCharacterToAdd);

        resetCharacterPosition(nextCharacterToAdd);
    }

    scriptsManager.callback(POST, 'CharacterAdd', null, [nextCharacterToAdd]);
}

var nextCharacterToResetPosition:Character;

function resetCharacterPosition(char:Character)
{
    nextCharacterToResetPosition = char;

    if (scriptsManager.callback(ON, 'CharacterPositionReset', null, [nextCharacterToResetPosition]))
    {
        nextCharacterToResetPosition.x = nextCharacterToResetPosition._castConfig.properties.x;
        nextCharacterToResetPosition.y = nextCharacterToResetPosition._castConfig.properties.y;

        if (stage.config.charactersOffset != null)
        {
            var offset:Point = null;

            if (stage.config.charactersOffset.type != null)
                offset = Reflect.getProperty(stage.config.charactersOffset.type, cast char.type);

            if (stage.config.charactersOffset.id != null)
                offset = Reflect.getProperty(stage.config.charactersOffset.id, char.id);

            if (offset != null)
            {
                nextCharacterToResetPosition.x += offset.x ?? 0;
                nextCharacterToResetPosition.y += offset.y ?? 0;
            }
        }
    }

    scriptsManager.callback(POST, 'CharacterPositionReset', null, [nextCharacterToResetPosition]);
}
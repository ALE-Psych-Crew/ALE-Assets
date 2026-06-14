package;

public var icons:FlxTypedGroup<Icon>;

public var playerIcons:FlxTypedGroup<Icon>;
public var opponentIcons:FlxTypedGroup<Icon>;
public var extraIcons:FlxTypedGroup<Icon>;

// FIX

public function get_iconP1():Icon
    return playerIcons.members[0];
public var iconP1:Icon;

// FIX

public function get_iconP2():Icon
    return opponentIcons.members[0];
public var iconP2:Icon;

// FIX

public function get_iconP3():Icon
    return extraIcons.members[0];
public var iconP3:Icon;

public function initIcons()
{
    if (scriptsManager.callback(ON, 'IconsInit'))
    {
        uiGroup.insert(uiGroup.members.indexOf(scoreText), icons = new FlxTypedGroup<Icon>());

        playerIcons = new FlxTypedGroup<Icon>();
        opponentIcons = new FlxTypedGroup<Icon>();
        extraIcons = new FlxTypedGroup<Icon>();

        for (char in [get_dad(), get_bf()])
        {
            final icon:Icon = new Icon(char.config.icon, char.type);
            addIcon(icon);
        }
    }

    scriptsManager.callback(POST, 'IconsInit');
}

var nextIconToAdd:Icon;

function addIcon(icon:Icon)
{
    nextIconToAdd = icon;
    
    if (scriptsManager.callback(ON, 'IconAdd', null, [nextIconToAdd]))
    {
        nextIconToAdd.bar = healthBar;

        switch (nextIconToAdd.type)
        {
            case PLAYER:
                playerIcons.add(nextIconToAdd);

            case OPPONENT:
                opponentIcons.add(nextIconToAdd);

            case EXTRA:
                extraIcons.add(nextIconToAdd);
        }

        icons.add(nextIconToAdd);
    }

    scriptsManager.callback(POST, 'IconAdd', null, [nextIconToAdd]);
}

var nextIconToChange:Icon;

function changeIcon(icon:Icon, id:String)
{
    nextIconToChange = icon;

    if (scriptsManager.callback(ON, 'IconChange', null, [nextIconToChange]))
        icon?.change(id, type);

    scriptsManager.callback(POST, 'IconChange', null, [nextIconToChange]);
}
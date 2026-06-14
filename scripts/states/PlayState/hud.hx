package;

import flixel.group.FlxGroup;

import flixel.text.FlxText.FlxTextBorderStyle;

public var uiGroup:FlxGroup;

public var healthBar:Bar;
public var scoreText:FlxText;

public function initHud()
{
    if (scriptsManager.callback(ON, 'HudInit'))
    {
        add(uiGroup = new FlxGroup());
        uiGroup.camera = camHUD;

        // FIX

        healthBar = new Bar(get_hudRoute() + '/' + hud.bar, get_hudRoute() + '/' + hud.barFill, health);
        healthBar.x = FlxG.width / 2 - healthBar.width / 2;
        healthBar.y = FlxG.height * (ClientPrefs.data.downScroll ? 0.1 : 0.9);
        uiGroup.add(healthBar);

        scoreText = new FlxText(0, healthBar.y + 40, FlxG.width, '');
        scoreText.setFormat(Paths.font(hud.textFont), 17, FlxColor.WHITE, 'center', FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        scoreText.borderSize = 1.25;
        uiGroup.add(scoreText);

        updateScoreText();
    }

    scriptsManager.callback(POST, 'HudInit');
}

public function updateScoreText()
{
    if (scriptsManager.callback(ON, 'ScoreTextUpdate'))
        scoreText.text = 'Score: ' + score + hud.textSpacing + 'Misses: ' + misses + hud.textSpacing + 'Accuracy: ' + accuracy + '%';

    scriptsManager.callback(POST, 'ScoreTextUpdate');
}

public function updateHealth()
{
    if (scriptsManager.callback(ON, 'HealthUpdate'))
        healthBar.percent = health;

    scriptsManager.callback(POST, 'HealthUpdate');
}
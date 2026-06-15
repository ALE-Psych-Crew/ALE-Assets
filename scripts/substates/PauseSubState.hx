import funkin.visuals.objects.Alphabet;

@:typedef JsonPause = {
	var cameraOffset:Point;
	
	var optionsSpacing:Point;

	var cameraSpeed:Float;
	
	var infoCorner:String;
};

final config:JsonPause = Paths.json('data/menus/pause');

var options:FlxTypedGroup<Alphabet>;

var music:Sound;

function postCreate()
{
	final bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
	bg.scrollFactor.set();
	bg.alpha = 0;
	add(bg);

	FlxTween.tween(bg, {alpha: 0.5}, 0.5, {ease: FlxEase.cubeOut});

	add(options = new FlxTypedGroup<Alphabet>());

	for (index => opt in ['resume', 'restart', 'exit'])
	{
		final text:Alphabet = new Alphabet(0, 0, opt);
		options.add(text);

		FlxTween.tween(text, {x: index * config.optionsSpacing.x, y: index * config.optionsSpacing.y}, config.cameraSpeed, {ease: FlxEase.cubeOut});
	}

	for (obj in members)
		obj.camera = subCamera;

	Conductor.pause();

	changeOption();
}

var selInt:Int = 0;

function changeOption(?change:Int = 0)
{
	selInt += change;

	if (selInt < 0)
		selInt = options.members.length - 1;

	if (selInt > options.members.length - 1)
		selInt = 0;

	for (index => opt in options)
		opt.alpha = selInt == index ? 1 : 0.5;
}

function onUpdate(elapsed:Float)
{
	subCamera.scroll.x = CoolUtil.fpsLerp(subCamera.scroll.x, selInt * config.optionsSpacing.x + config.cameraOffset.x, config.cameraSpeed);
	subCamera.scroll.y = CoolUtil.fpsLerp(subCamera.scroll.y, selInt * config.optionsSpacing.y + config.cameraOffset.y, config.cameraSpeed);

	if (Controls.UI_DOWN_P || Controls.UI_UP_P)
	{
		changeOption(Controls.UI_DOWN_P ? 1 : -1);

		CoolUtil.playSound('scroll');
	}

	if (Controls.ACCEPT)
	{
		// FIX

		switch (options.members[selInt].text)
		{
			default:
				Conductor.resume();

				close();
		}
	}
}
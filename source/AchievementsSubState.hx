package;

import flixel.FlxObject;
import flixel.FlxG;
import flixel.util.FlxColor;
import OptionsSubState.Background;
import openfl.display.BitmapData;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import Achievement.AchievementObject;
import flixel.FlxSubState;

class AchievementsSubState extends FlxSubState {

    public var achievements:Array<AchievementObject>;
	public var items:FlxTypedGroup<AchievementSprite> = new FlxTypedGroup<AchievementSprite>();
	public var itemsIcons:FlxTypedGroup<FlxSprite> = new FlxTypedGroup<FlxSprite>();
	public var itemsDescriptions:FlxTypedGroup<Alphabet> = new FlxTypedGroup<Alphabet>();

    override public function create() {
        super.create();

		achievements = Achievement.getAchievements();

		var bg = new Background(FlxColor.fromString("#c79200"));
		var arrBgSize = [bg.width, bg.height];
		bg.setGraphicSize(Std.int(bg.width * (1 + (achievements.length * 0.01))), Std.int(bg.height * (1 + (achievements.length * 0.01))));
		bg.updateHitbox();
		bg.scrollFactor.y -= achievements.length * 0.006;
		if (bg.scrollFactor.y < 0) {
			bg.scrollFactor.y = 0;
			bg.setGraphicSize(Std.int(arrBgSize[0]), Std.int(arrBgSize[1]));
			bg.updateHitbox();
		}
		add(bg);
		
        for (index in 0...achievements.length) {
			var sprite = new AchievementSprite(achievements[index], 0.8);
            sprite.ID = index;
			sprite.y = 175 * index;
			sprite.y += 45;
            sprite.screenCenter(X);
            sprite.x += sprite.icon.height / 2;

			itemsIcons.add(sprite.icon);
            itemsDescriptions.add(sprite.description);
			items.add(sprite);
        }
        add(itemsIcons);
		add(itemsDescriptions);
        add(items);

        cameras = [PlayState.camStatic];
		camFollow = new FlxObject(FlxG.width / 2, 0, 0, 0);
		camera.follow(camFollow, LOCKON, 0.04);
    }
	override public function update(elapsed) {
		super.update(elapsed);

		if (Controls.check(UI_UP)) {
			FlxG.sound.play(Paths.sound('scrollMenu'));
			curSelected -= 1;
		}

		if (Controls.check(UI_DOWN)) {
			FlxG.sound.play(Paths.sound('scrollMenu'));
			curSelected += 1;
		}

		if (curSelected < 0)
			curSelected = items.length - 1;

		if (curSelected >= items.length)
			curSelected = 0;

		items.forEach(function(alphab:Alphabet) {
			alphab.alpha = 0.6;

			if (alphab.ID == curSelected) {
				alphab.alpha = 1;
				camFollow.y = alphab.y + 100;
			}
		});

		itemsDescriptions.forEach(function(alphab:Alphabet) {
			alphab.alpha = 0.6;

			if (alphab.ID == curSelected) {
				alphab.alpha = 1;
			}
		});

        if (Controls.check(BACK)) {
			camera.follow(null);
			camera.scroll.y = 0;
            PlayState.openAchievements = false;
			PlayState.cancelGameResume = true;
			close();
			PlayState.currentPlaystate.pauseGame(true, 2);
        }
	}

	var curSelected:Int = 0;

	var camFollow:FlxObject;
}

class AchievementSprite extends Alphabet {
    public var icon:FlxSprite;
    public var description:Alphabet;
    public function new(achie:AchievementObject, Size:Float) {
        size = Size;

        if (Achievement.isUnlocked(achie.id)) {
			icon = new FlxSprite().loadGraphic(BitmapData.fromFile(achie.iconPath));
        }
		else {
			icon = new FlxSprite().loadGraphic(Paths.image("lock"));
        }
        icon.antialiasing = true;
        
		super(icon.x + icon.width, icon.y, achie.displayName, false, false, Size);

		description = new Alphabet(x, y + height + 10, achie.description, false, false, Size - 0.2);
        
		icon.setGraphicSize(Std.int(icon.frameWidth * size), Std.int(icon.frameHeight * size));
        icon.updateHitbox();
    }

    override public function update(elapsed) {
        super.update(elapsed);
        
		icon.ID = ID;
        description.ID = ID;

        icon.x = (x - icon.width) - 20;
		icon.y = y - 10;
		description.x = x;
		description.y = y + height + 10;
    }
}
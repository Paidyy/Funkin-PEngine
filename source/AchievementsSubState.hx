package;

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

		var bg = new Background(FlxColor.YELLOW);
		add(bg);

		achievements = Achievement.getAchievements();
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
			}
		});

		itemsDescriptions.forEach(function(alphab:Alphabet) {
			alphab.alpha = 0.6;

			if (alphab.ID == curSelected) {
				alphab.alpha = 1;
			}
		});

        if (Controls.check(BACK)) {
            PlayState.openAchievements = false;
            close();
        }
	}

	var curSelected:Int = 0;
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
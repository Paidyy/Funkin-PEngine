package;

import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.FlxSubState;
import flixel.FlxSprite;

class ModifierImage extends FlxSprite {
	public var name:Modifiers;
}

@:enum
abstract Modifiers(String) {
	public static var activeModifiers:Array<Modifiers> = [];

	var NIGHTCORE = "nc";
	var FULLCOMBO = "fc";
	var NOFAIL = "nf";
	var OPPONENT = "op";
    var ROTATENOTES = "rn";

	public static function getTitle(mod:Modifiers):String {
		switch (mod) {
			case NIGHTCORE:
				return "Nightcore";
			case FULLCOMBO:
				return "Full Combo";
			case NOFAIL:
				return "No Fail";
			case OPPONENT:
				return "Play As Opponent";
            case ROTATENOTES:
                return "Rotating Notes";
		}
	}

	public static function getDescription(mod:Modifiers):String {
		switch (mod) {
			case NIGHTCORE:
				return "Pitches up the song";
			case FULLCOMBO:
				return "No more Skill Issues";
			case NOFAIL:
				return "Prevents boyfriend from getting blueballed";
			case OPPONENT:
				return "Self explanatory";
			case ROTATENOTES:
				return "Rotates game and strum notes";
		}
	}

	public static function calculateMultiplier():Float {
		var mult = 1.0;
		for (s in activeModifiers) {
			switch (s) {
				case NIGHTCORE:
					mult += 0.5;
				case FULLCOMBO:
					mult += 0;
				case NOFAIL:
					mult = 0;
				case OPPONENT:
					mult += 0;
                case ROTATENOTES:
                    mult += 0.1;
			}
		}
		if (activeModifiers.contains(NOFAIL)) {
			mult = 0;
		}
		return mult;
	}
}

class ModifierSubState extends FlxSubState {
	var modifierItems:FlxTypedSpriteGroup<ModifierImage> = new FlxTypedSpriteGroup<ModifierImage>();
	var curModifier:Int = 0;
	var title:FlxText = new FlxText(0, 0, 0, "", 20);
	var desc:FlxText = new FlxText(0, 0, 0, "", 26);
	var multInfo:FlxText = new FlxText(0, 0, 0, "", 24);

	override public function create() {
		super.create();

		FreeplayState.inSubState = true;

		var bg = new FlxSprite();
		bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0.6;
		add(bg);

		var nightcore = new ModifierImage();
		nightcore.loadGraphic(Paths.image("modifiers/nightcore"));
		nightcore.setGraphicSize(80, 80);
		nightcore.updateHitbox();
		nightcore.antialiasing = true;
		nightcore.name = Modifiers.NIGHTCORE;
		nightcore.ID = 0;
		if (!Modifiers.activeModifiers.contains(nightcore.name))
			nightcore.setColorTransform(0.3, 0.3, 0.3);

		var fullCombo = new ModifierImage(nightcore.x + nightcore.width + 20);
		fullCombo.loadGraphic(Paths.image("modifiers/full-combo"));
		fullCombo.setGraphicSize(80, 80);
		fullCombo.updateHitbox();
		fullCombo.antialiasing = true;
		fullCombo.name = Modifiers.FULLCOMBO;
		fullCombo.ID = 1;
		if (!Modifiers.activeModifiers.contains(fullCombo.name))
			fullCombo.setColorTransform(0.3, 0.3, 0.3);

		var noFail = new ModifierImage(fullCombo.x + fullCombo.width + 20);
		noFail.loadGraphic(Paths.image("modifiers/no-fail"));
		noFail.setGraphicSize(80, 80);
		noFail.updateHitbox();
		noFail.antialiasing = true;
		noFail.name = Modifiers.NOFAIL;
		noFail.ID = 2;
		if (!Modifiers.activeModifiers.contains(noFail.name))
			noFail.setColorTransform(0.3, 0.3, 0.3);

		var opponent = new ModifierImage(noFail.x + noFail.width + 20);
		opponent.loadGraphic(Paths.image("modifiers/opponent"));
		opponent.setGraphicSize(80, 80);
		opponent.updateHitbox();
		opponent.antialiasing = true;
		opponent.name = Modifiers.OPPONENT;
		opponent.ID = 3;
		if (!Modifiers.activeModifiers.contains(opponent.name))
			opponent.setColorTransform(0.3, 0.3, 0.3);

		modifierItems.add(nightcore);
		modifierItems.add(fullCombo);
		modifierItems.add(noFail);
		modifierItems.add(opponent);
		modifierItems.screenCenter();

		add(modifierItems);

		title.setFormat("VCR OSD Mono", title.size, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		desc.setFormat("VCR OSD Mono", desc.size, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		multInfo.setFormat("VCR OSD Mono", multInfo.size, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);

		add(title);
		add(desc);
		add(multInfo);
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		if (Controls.check(UI_LEFT))
			curModifier--;
		if (Controls.check(UI_RIGHT))
			curModifier++;

		if (curModifier > modifierItems.length - 1) {
			curModifier = 0;
		}
		if (curModifier < 0) {
			curModifier = modifierItems.length - 1;
		}

		for (item in modifierItems) {
			if (Modifiers.activeModifiers.contains(item.name))
				item.setColorTransform(1, 1, 1);
			else
				item.setColorTransform(0.3, 0.3, 0.3);
			item.alpha = 0.8;
			if (item.ID == curModifier) {
				item.alpha = 1;
				if (Controls.check(ACCEPT)) {
					if (Modifiers.activeModifiers.contains(item.name)) {
						Modifiers.activeModifiers.remove(item.name);
					}
					else {
						Modifiers.activeModifiers.push(item.name);
					}
				}

				title.text = Modifiers.getTitle(item.name);
				desc.text = Modifiers.getDescription(item.name);
				title.screenCenter();
				title.y -= 200;
				desc.screenCenter(X);
				desc.y = title.y + title.height + 10;

				multInfo.screenCenter(X);
				multInfo.y = 25;
				var multi = Modifiers.calculateMultiplier();
				multInfo.text = "Score Multiplier: " + multi + "x";
				if (multi > 1)
					multInfo.color = FlxColor.LIME;
				else if (multi < 1)
					multInfo.color = FlxColor.RED;
				else
					multInfo.color = FlxColor.WHITE;
			}
		}

		if (FlxG.keys.justPressed.SHIFT || Controls.check(BACK)) {
			FreeplayState.inSubState = false;
			close();
		}
	}
}
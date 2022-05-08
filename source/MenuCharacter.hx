package;

import sys.FileSystem;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;

class MenuCharacter extends FlxSprite {
	public var character:String;

	public function new(x:Float, character:String = 'bf') {
		super(x);

		setChar(character);
	}

	public function setChar(char:String) {
		if (char == character)
			return;

		character = char;

		scale.set(1, 1);

		if (FileSystem.exists(Paths.getCharacterPath(char))) {
			if (Paths.isCustomPath(Paths.getCharacterPath(char))) {
				frames = Paths.PEgetSparrowAtlas(Paths.modsLoc + '/characters/$char/story');
			}
			else {
				frames = Paths.getSparrowAtlas('characters/$char/story');
			}
		}
		animation.addByPrefix("idle", "idle", 24);
		animation.addByPrefix("confirm", "confirm", 24);
		animation.play("idle");

		updateHitbox();
	}
}

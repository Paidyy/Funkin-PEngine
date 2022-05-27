package;

import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.math.FlxRandom;
import flixel.FlxSprite;

class TankmanRun extends FlxSprite {
	var deathSpot:Float = 0;
	var gfMidpoint:Float = PlayState.gf.getMidpoint().x - 230;
	var isRightMove(get, null):Bool;
	
	function get_isRightMove():Bool {
		return flipX;
	}
    
    public function new() {
		super();
		frames = Paths.getWeekSparrowAtlas("tankmanKilled1", 7);
		animation.addByPrefix("death", "John Shot " + new FlxRandom().int(1, 2), 24, false);
		animation.addByPrefix("run", "tankman running", 24);
		flipX = new FlxRandom().int(0, 1) == 0 ? true : false;
		updateHitbox();
		x = isRightMove ? gfMidpoint - (700 + width) : gfMidpoint + 700;
		y = 200;

		//PlayState.currentPlaystate.add(new FlxSprite(gfMidpoint, PlayState.gf.getMidpoint().y).makeGraphic(10, 10, FlxColor.RED));

		deathSpot = isRightMove ? (gfMidpoint - new FlxRandom().int(100, 250)) + 400 : gfMidpoint + new FlxRandom().int(100, 250);

		animation.play("run");
		velocity.set(isRightMove ? new FlxRandom().int(500, 1000) : -(new FlxRandom().int(500, 1000)), 0);
    }

    override public function update(elapsed) {
        super.update(elapsed);

		if ((isRightMove ? (x + width) >= deathSpot : x <= deathSpot) && animation.name != "death") {
			animation.play("death");
			velocity.set(0, 0);
			offset.y = 200;
			if (isRightMove)
				offset.x = 300;
		}

		if (animation.finished) {
			kill();
		}
    }
}
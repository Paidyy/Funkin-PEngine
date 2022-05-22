package;

import Alphabet.AlphaCharacter;
import flixel.tweens.FlxTween;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxTimer;
import flixel.FlxBasic;

class Combo extends FlxBasic {
    public var clearComboTimer:FlxTimer = null;
    public var curCombo(default, set):Int = 0;
	public var staticCombo(default, set):Int = 0;

    public function new() {
        super();

		if (!Options.disableNewComboSystem) {
			initTimer();
			clearComboTimer.active = true;
		}
    }

	public function initTimer() {
		clearComboTimer = new FlxTimer();
		clearComboTimer.time = 1;
		clearComboTimer.onComplete = onComboJudge;
	}

	function onComboJudge(timer:FlxTimer) {
        if (curCombo >= 10) {
			var isPixelStage = PlayState.currentPlaystate.stage.name.startsWith("school");
			var pixelFolder = isPixelStage ? "pixelUI/" : "";
			var pixelSuffix = isPixelStage ? "-pixel" : "";

			var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelFolder + 'combo' + pixelSuffix));
			comboSpr.setGraphicSize(Std.int(comboSpr.width * (0.9 + (isPixelStage ? PlayState.daPixelZoom : 0))));
			comboSpr.updateHitbox();
			comboSpr.scrollFactor.set(0, 0);
			comboSpr.x = (FlxG.width / 2) - 200;
			comboSpr.y = (FlxG.height / 2) - 150;
			comboSpr.acceleration.y = 600;
			comboSpr.velocity.y -= 150;

			var x_:AlphaCharacter = new AlphaCharacter(comboSpr.x, comboSpr.y + comboSpr.height, 1);
			x_.scrollFactor.set(0, 0);
			x_.x += Std.int(comboSpr.width / 2.5);
			x_.createBold("x");
			x_.acceleration.y = 600;
			x_.velocity.y -= 150;
			x_.visible = !isPixelStage;

			var daLoop:Int = 0;
			var lastNum:FlxSprite = null;
			for (i in Std.string(curCombo).split("")) {
				var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelFolder + 'num$i' + pixelSuffix));
				numScore.scrollFactor.set(0, 0);
				numScore.screenCenter();
				numScore.x = x_.x + x_.width + ((lastNum != null ? lastNum.width : 0) * daLoop);
				numScore.y = x_.y;
				numScore.setGraphicSize(Std.int(numScore.width * (0.6 + (isPixelStage ? PlayState.daPixelZoom : 0))));
				numScore.updateHitbox();
				numScore.acceleration.y = 600;
				numScore.velocity.y -= FlxG.random.int(140, 150);
				numScore.velocity.x = FlxG.random.float(-5, 5);

				lastNum = numScore;
				
				PlayState.currentPlaystate.add(numScore);

				FlxTween.tween(numScore, {alpha: 0}, 0.1, {
					onComplete: function(tween:flixel.tweens.FlxTween) {
						numScore.destroy();
					},
					startDelay: Conductor.crochet * 0.002
				});

				daLoop++;
			}

			PlayState.currentPlaystate.add(x_);

			PlayState.currentPlaystate.add(comboSpr);

			FlxTween.tween(comboSpr, {alpha: 0}, 0.1, {
				onComplete: function(tween:flixel.tweens.FlxTween) {
					comboSpr.destroy();
				},
				startDelay: Conductor.crochet * 0.002
			});

			FlxTween.tween(x_, {alpha: 0}, 0.1, {
				onComplete: function(tween:flixel.tweens.FlxTween) {
					x_.destroy();
				},
				startDelay: Conductor.crochet * 0.002
			});
        }

        curCombo = 0;
    }

	public function failCombo() {
		staticCombo = 0;
        curCombo = 0;
		if (FreeplayState.modifiers.contains(FULLCOMBO))
			PlayState.currentPlaystate.health = 0;
    }

	function set_curCombo(value) {
		curCombo = value;
		if (clearComboTimer != null) {
			clearComboTimer.reset(clearComboTimer.time);
		}
		return curCombo;
	}

	function set_staticCombo(value:Int):Int {
		staticCombo = value;
		if (value != 0)
       		set_curCombo(curCombo + 1);
		else
			set_curCombo(0);
		return staticCombo;
	}
}
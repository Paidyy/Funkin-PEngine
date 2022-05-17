package;

import Main.Game;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

using StringTools;

class PauseSubState extends MusicBeatSubstate {
	var grpMenuShit:FlxTypedGroup<Alphabet>;

	var menuItems:Array<String> = ['Resume', 'Restart Song', 'Achievements', 'Options', 'Exit to menu'];
	public static var curSelected:Int = 0;

	//var pauseMusic:FlxSound;

	public function new(x:Float, y:Float, ?skipTween:Bool = false, ?popIndex:Int = 0) {
		super();
		
		PlayState.currentPlaystate.setPaused(true);

		/*
		pauseMusic = new FlxSound().loadEmbedded(Paths.music('breakfast'), true, true);
		pauseMusic.volume = 0;
		pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));

		FlxG.sound.list.add(pauseMusic);
		*/

		if (Game.pauseMusic == null || !Game.pauseMusic.playing)
			Game.playPauseMusic();

		var levelInfo:FlxText = new FlxText(0, 15, 0, "", 32);
		levelInfo.text += PlayState.SONG.song;
		levelInfo.scrollFactor.set();
		levelInfo.setFormat(Paths.font("vcr.ttf"), 32);
		levelInfo.updateHitbox();
		add(levelInfo);

		var levelDifficulty:FlxText = new FlxText(0, 15 + 32, 0, "", 32);
		levelDifficulty.text += CoolUtil.difficultyString();
		levelDifficulty.scrollFactor.set();
		levelDifficulty.setFormat(Paths.font('vcr.ttf'), 32);
		levelDifficulty.updateHitbox();
		if (levelDifficulty.text == "EASY")
			levelDifficulty.color = FlxColor.LIME;
		if (levelDifficulty.text == "NORMAL")
			levelDifficulty.color = FlxColor.YELLOW;
		if (levelDifficulty.text == "HARD")
			levelDifficulty.color = FlxColor.RED;
		add(levelDifficulty);

		levelDifficulty.alpha = 0;
		levelInfo.alpha = 0;

		levelInfo.x = FlxG.width - (levelInfo.width + 20);
		levelDifficulty.x = FlxG.width - (levelDifficulty.width + 20);

		PlayState.currentPlaystate.pauseBG.visible = true;
		PlayState.currentPlaystate.pauseBG.alpha = 0.0;

		if (!skipTween) {
			FlxTween.tween(PlayState.currentPlaystate.pauseBG, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});
			FlxTween.tween(levelInfo, {alpha: 1, y: 20}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3});
			FlxTween.tween(levelDifficulty, {alpha: 1, y: levelDifficulty.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.5});
		}
		else {
			PlayState.currentPlaystate.pauseBG.alpha = 0.6;
			levelInfo.alpha = 1;
			levelInfo.y = 20;
			levelDifficulty.alpha = 1;
			levelDifficulty.y = levelDifficulty.y + 5;
		}

		grpMenuShit = new FlxTypedGroup<Alphabet>();
		add(grpMenuShit);

		for (i in 0...menuItems.length) {
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, menuItems[i], true, false);
			songText.isMenuItem = true;
			songText.targetY = i;
			grpMenuShit.add(songText);
		}

		changeSelection(popIndex, true);

		cameras = [PlayState.camStatic];
	}

	override function update(elapsed:Float) {
		var daSelected:String = menuItems[curSelected];

		super.update(elapsed);

		var upP = Controls.check(UI_UP, JUST_PRESSED);
		var downP = Controls.check(UI_DOWN, JUST_PRESSED);
		var accepted = Controls.check(ACCEPT, JUST_PRESSED);

		if (upP) {
			changeSelection(-1);
		}
		if (downP) {
			changeSelection(1);
		}

		if (accepted) {
			switch (daSelected) {
				case "Resume":
					PlayState.cancelGameResume = false;
					close();
				case "Restart Song":
					FlxG.resetState();
				case "Achievements":
					PlayState.openAchievements = true;
					close();
				case "Options":
					PlayState.openSettings = true;
					close();
				case "Exit to menu":
					FlxG.switchState(new MainMenuState());
			}
		}

		if (FlxG.keys.justPressed.J) {
			// for reference later!
			// PlayerSettings.player1.controls.replaceBinding(Control.LEFT, Keys, FlxKey.J, null);
		}
	}

	function changeSelection(change:Int = 0, ?set:Bool = false):Void {
		if (set) {
			curSelected = change;
		}
		else {
			curSelected += change;
		}

		if (curSelected < 0)
			curSelected = menuItems.length - 1;
		if (curSelected >= menuItems.length)
			curSelected = 0;

		var bullShit:Int = 0;

		for (item in grpMenuShit.members) {
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			// item.setGraphicSize(Std.int(item.width * 0.8));

			if (item.targetY == 0) {
				item.alpha = 1;
				// item.setGraphicSize(Std.int(item.width));
			}
		}
	}
}

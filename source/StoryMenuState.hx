package;

import sys.io.File;
import sys.FileSystem;
import yaml.util.ObjectMap.AnyObjectMap;
import openfl.sensors.Accelerometer;
import yaml.util.ObjectMap.TObjectMap;
import yaml.Yaml;
import flixel.util.FlxStringUtil;
#if desktop
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.net.curl.CURLCode;

using StringTools;

class UnlockedAfterMap extends AnyObjectMap {
	public function new(weekID:String) {
		super();
		set("unlockedAfter", weekID);
	}
}

class StoryMenuState extends MusicBeatState {
	var scoreText:FlxText;

	var curDifficulty:Int = 1;

	var weeks:Array<Week> = new Array<Week>();

	/*
	var weekIDs:Array<String> = [
		'week0', 
		'week1', 
		'week2', 
		'week3', 
		'week4', 
		'week5', 
		'week6', 
		'week7'
	];
	var weekSongs:Array<Dynamic> = [
		['Tutorial'],
		['Bopeebo', 'Fresh', 'Dadbattle'],
		['Spookeez', 'South', "Monster"],
		['Pico', 'Philly', "Blammed"],
		['Satin-Panties', "High", "Milf"],
		['Cocoa', 'Eggnog', 'Winter-Horrorland'],
		['Senpai', 'Roses', 'Thorns'],
		['Ugh', 'Guns', 'Stress']
	];
	var weekCharacters:Array<Dynamic> = [
		['dad', 'bf', 'gf'],
		['dad', 'bf', 'gf'],
		['spooky', 'bf', 'gf'],
		['pico', 'bf', 'gf'],
		['mom', 'bf', 'gf'],
		['parents-christmas', 'bf', 'gf'],
		['senpai', 'bf', 'gf'],
		['tankman', 'bf', 'gf']
	];
	var weekNames:Array<String> = [
		"",
		"Daddy Dearest",
		"Spooky Month",
		"PICO",
		"MOMMY MUST MURDER",
		"RED SNOW",
		"hating simulator ft. moawling",
		"Tankman"
	];
	*/

	var txtWeekTitle:FlxText;

	var curWeek:Int = 0;

	var txtTracklist:FlxText;

	var grpWeekText:FlxTypedGroup<MenuItem>;
	var grpWeekCharacters:FlxTypedGroup<MenuCharacter>;

	var grpLocks:FlxTypedGroup<FlxSprite>;

	var difficultySelectors:FlxGroup;
	var sprDifficulty:FlxSprite;
	var leftArrow:FlxSprite;
	var rightArrow:FlxSprite;

	var unlockFeature:Bool = false;

	public static function isWeekUnlocked(weekID:String) {
		return Reflect.field(FlxG.save.data, '${weekID}Unlocked');
	}

	public static function setWeekUnlocked(weekID:String, unlocked:Bool = true) {
		if (unlocked)
			//trace("unlocking week " + weekID);
		Reflect.setField(FlxG.save.data, '${weekID}Unlocked', unlocked);
		FlxG.save.flush();
	}

	//don't set unlockFeature to true PLEASE
	override function create() {

		//add vanilla weeks
		weeks.push(new Week('week0', ['Tutorial'], ['dad', 'bf', 'gf'], ""));
		weeks.push(new Week('week1', ['Bopeebo', 'Fresh', 'Dadbattle'], ['dad', 'bf', 'gf'], "Daddy Dearest", new UnlockedAfterMap("week0")));
		weeks.push(new Week('week2', ['Spookeez', 'South', "Monster"], ['spooky', 'bf', 'gf'], "Spooky Month", new UnlockedAfterMap("week1")));
		weeks.push(new Week('week3', ['Pico', 'Philly', "Blammed"], ['pico', 'bf', 'gf'], "PICO", new UnlockedAfterMap("week2")));
		weeks.push(new Week('week4', ['Satin-Panties', "High", "Milf"], ['mom', 'bf', 'gf'], "MOMMY MUST MURDER", new UnlockedAfterMap("week3")));
		weeks.push(new Week('week5', ['Cocoa', 'Eggnog', 'Winter-Horrorland'], ['parents-christmas', 'bf', 'gf'], "RED SNOW", new UnlockedAfterMap("week4")));
		weeks.push(new Week('week6', ['Senpai', 'Roses', 'Thorns'], ['senpai', 'bf', 'gf'], "hating simulator ft. moawling", new UnlockedAfterMap("week5")));
		//weeks.push(new Week('week7', ['Ugh', 'Guns', 'Stress'], ['tankman', 'bf', 'gf'], "Tankman", new UnlockedAfterMap("week6")));

		var pengine_weeks_path = ${Paths.modsLoc} + "/weeks/";
		for (file in FileSystem.readDirectory(pengine_weeks_path)) {
			var path = haxe.io.Path.join([pengine_weeks_path, file]);
			if (FileSystem.isDirectory(path)) {
				var data = Yaml.parse(File.getContent(path + "/config.yml"));
				if (Std.string(data.get("onlyInFreeplay")) != "true") {
					var map:TObjectMap<Dynamic, Dynamic> = data.get('songs');
					var songs:Array<String> = [];
					var characters:Array<String> = [];
					for (song in map.keys()) {
						songs.push(song);
						characters.push(data.get("songs").get(song).get("character"));
					}
					weeks.push(new Week(file, songs, characters, Std.string(data.get('storyModeName')), data));
				}
			}
		}

		setWeekUnlocked("week0", true);

		if (unlockFeature) {
			for (week in weeks) {
				if (week.config != null) {
					if (isWeekUnlocked(Std.string(week.config.get("unlockedAfter"))))
						setWeekUnlocked(week.id, true);
					else
						setWeekUnlocked(week.id, false);
				}
			}
		} else {
			for (week in weeks) {
				setWeekUnlocked(week.id, true);
			}
		}

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		if (FlxG.sound.music != null) {
			if (!FlxG.sound.music.playing)
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
		}

		persistentUpdate = persistentDraw = true;

		scoreText = new FlxText(10, 10, 0, "SCORE: MISSINGNO", 36);
		scoreText.setFormat("VCR OSD Mono", 32);

		txtWeekTitle = new FlxText(FlxG.width * 0.7, 10, 0, "", 32);
		txtWeekTitle.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, RIGHT);
		txtWeekTitle.alpha = 0.7;

		var rankText:FlxText = new FlxText(0, 10);
		rankText.text = 'RANK: GREAT';
		rankText.setFormat(Paths.font("vcr.ttf"), 32);
		rankText.size = scoreText.size;
		rankText.screenCenter(X);

		var ui_tex = Paths.getSparrowAtlas('campaign_menu_UI_assets');
		var yellowBG:FlxSprite = new FlxSprite(0, 56).makeGraphic(FlxG.width, 400, 0xFFF9CF51);

		grpWeekText = new FlxTypedGroup<MenuItem>();
		add(grpWeekText);

		var blackBarThingie:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 56, FlxColor.BLACK);

		grpWeekCharacters = new FlxTypedGroup<MenuCharacter>();

		grpLocks = new FlxTypedGroup<FlxSprite>();

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		for (i in 0...weeks.length) {
			var weekThing:MenuItem = new MenuItem(0, yellowBG.y + yellowBG.height + 10, weeks[i].id);
			weekThing.y += ((weekThing.height + 20) * i);
			weekThing.targetY = i;
			grpWeekText.add(weekThing);

			weekThing.screenCenter(X);
			weekThing.antialiasing = true;
			// weekThing.updateHitbox();

			if (!isWeekUnlocked(weeks[i].id)) {
				var lock:FlxSprite = new FlxSprite(weekThing.width + 10 + weekThing.x);
				lock.frames = ui_tex;
				lock.animation.addByPrefix('lock', 'lock');
				lock.animation.play('lock');
				lock.ID = i;
				lock.antialiasing = true;
				grpLocks.add(lock);
			}
		}

		for (char in 0...3) {
			var weekCharacterThing:MenuCharacter = new MenuCharacter((FlxG.width * 0.25) * (1 + char) - 150, weeks[curWeek].characters[char]);
			weekCharacterThing.y += 70;
			weekCharacterThing.antialiasing = true;
			switch (weekCharacterThing.character) {
				case 'dad':
					weekCharacterThing.setGraphicSize(Std.int(weekCharacterThing.width * 0.5));
					weekCharacterThing.updateHitbox();
				case 'bf':
					weekCharacterThing.setGraphicSize(Std.int(weekCharacterThing.width * 0.9));
					weekCharacterThing.updateHitbox();
					weekCharacterThing.x -= 80;
				case 'gf':
					weekCharacterThing.setGraphicSize(Std.int(weekCharacterThing.width * 0.5));
					weekCharacterThing.updateHitbox();
				case 'pico':
					weekCharacterThing.flipX = true;
				case 'parents-christmas':
					weekCharacterThing.setGraphicSize(Std.int(weekCharacterThing.width * 0.9));
					weekCharacterThing.updateHitbox();
			}

			grpWeekCharacters.add(weekCharacterThing);
		}

		difficultySelectors = new FlxGroup();
		add(difficultySelectors);
		add(grpLocks);
		add(blackBarThingie);

		leftArrow = new FlxSprite(grpWeekText.members[0].x + grpWeekText.members[0].width + 10, grpWeekText.members[0].y + 10);
		leftArrow.frames = ui_tex;
		leftArrow.animation.addByPrefix('idle', "arrow left");
		leftArrow.animation.addByPrefix('press', "arrow push left");
		leftArrow.animation.play('idle');
		difficultySelectors.add(leftArrow);

		sprDifficulty = new FlxSprite(leftArrow.x + 130, leftArrow.y);
		sprDifficulty.frames = ui_tex;
		sprDifficulty.animation.addByPrefix('easy', 'EASY');
		sprDifficulty.animation.addByPrefix('normal', 'NORMAL');
		sprDifficulty.animation.addByPrefix('hard', 'HARD');
		sprDifficulty.animation.play('easy');
		changeDifficulty();

		difficultySelectors.add(sprDifficulty);

		rightArrow = new FlxSprite(sprDifficulty.x + sprDifficulty.width + 50, leftArrow.y);
		rightArrow.frames = ui_tex;
		rightArrow.animation.addByPrefix('idle', 'arrow right');
		rightArrow.animation.addByPrefix('press', "arrow push right", 24, false);
		rightArrow.animation.play('idle');
		difficultySelectors.add(rightArrow);

		add(yellowBG);
		add(grpWeekCharacters);

		txtTracklist = new FlxText(FlxG.width * 0.05, yellowBG.x + yellowBG.height + 100, 0, "Tracks", 32);
		txtTracklist.alignment = CENTER;
		txtTracklist.font = rankText.font;
		txtTracklist.color = 0xFFe55777;
		add(txtTracklist);
		// add(rankText);
		add(scoreText);
		add(txtWeekTitle);

		updateText();

		super.create();
		changeWeek(0);
	}

	override function update(elapsed:Float) {
		// scoreText.setFormat('VCR OSD Mono', 32);
		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, 0.5));

		scoreText.text = "WEEK SCORE:" + FlxStringUtil.formatMoney(lerpScore, false);

		txtWeekTitle.text = weeks[curWeek].storyModeName.toUpperCase();
		txtWeekTitle.x = FlxG.width - (txtWeekTitle.width + 10);

		// FlxG.watch.addQuick('font', scoreText.font);

		difficultySelectors.visible = isWeekUnlocked(weeks[curWeek].id);

		grpLocks.forEach(function(lock:FlxSprite) {
			lock.y = grpWeekText.members[lock.ID].y;
		});

		if (!movedBack) {
			if (!selectedWeek) {
				if (Controls.check(UI_UP, JUST_PRESSED)) {
					changeWeek(-1);
				}

				if (Controls.check(UI_DOWN, JUST_PRESSED)) {
					changeWeek(1);
				}

				if (Controls.check(UI_RIGHT, PRESSED))
					rightArrow.animation.play('press')
				else
					rightArrow.animation.play('idle');

				if (Controls.check(UI_LEFT, PRESSED))
					leftArrow.animation.play('press');
				else
					leftArrow.animation.play('idle');

				if (Controls.check(UI_RIGHT, JUST_PRESSED))
					changeDifficulty(1);
				if (Controls.check(UI_LEFT, JUST_PRESSED))
					changeDifficulty(-1);
			}

			if (Controls.check(ACCEPT, JUST_PRESSED)) {
				selectWeek();
			}
		}

		if (Controls.check(BACK, JUST_PRESSED) && !movedBack && !selectedWeek) {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			movedBack = true;
			FlxG.switchState(new MainMenuState());
		}

		super.update(elapsed);
	}

	var movedBack:Bool = false;
	var selectedWeek:Bool = false;
	var stopspamming:Bool = false;

	function selectWeek() {
		if (isWeekUnlocked(weeks[curWeek].id)) {
			if (stopspamming == false) {
				FlxG.sound.play(Paths.sound('confirmMenu'));

				grpWeekText.members[curWeek].startFlashing();
				grpWeekCharacters.members[1].animation.play('confirm');
				stopspamming = true;
			}
			
			PlayState.week = weeks[curWeek];
			PlayState.storyPlaylist = weeks[curWeek].songs;
			PlayState.isStoryMode = true;
			selectedWeek = true;

			var diffic = "";

			switch (curDifficulty) {
				case 0:
					diffic = '-easy';
				case 2:
					diffic = '-hard';
			}

			PlayState.storyDifficulty = curDifficulty;

			if (FileSystem.exists(Paths.instNoLib(PlayState.storyPlaylist[0].toLowerCase()))) {
				PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + diffic, PlayState.storyPlaylist[0].toLowerCase());
			} else {
				PlayState.SONG = Song.PEloadFromJson(PlayState.storyPlaylist[0].toLowerCase() + diffic, PlayState.storyPlaylist[0].toLowerCase());
			}
			PlayState.SONGglobalNotes = Song.parseGlobalNotesJSONshit(PlayState.storyPlaylist[0].toLowerCase());
			PlayState.storyWeek = weeks[curWeek].id;
			PlayState.campaignScore = 0;
			new FlxTimer().start(1, function(tmr:FlxTimer) {
				LoadingState.loadAndSwitchState(new PlayState(), true);
			});
		}
	}

	function changeDifficulty(change:Int = 0):Void {
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = 2;
		if (curDifficulty > 2)
			curDifficulty = 0;

		sprDifficulty.offset.x = 0;

		switch (curDifficulty) {
			case 0:
				sprDifficulty.animation.play('easy');
				sprDifficulty.offset.x = 20;
			case 1:
				sprDifficulty.animation.play('normal');
				sprDifficulty.offset.x = 70;
			case 2:
				sprDifficulty.animation.play('hard');
				sprDifficulty.offset.x = 20;
		}

		sprDifficulty.alpha = 0;

		// USING THESE WEIRD VALUES SO THAT IT DOESNT FLOAT UP
		sprDifficulty.y = leftArrow.y - 15;
		intendedScore = Highscore.getWeekScore(weeks[curWeek].id, curDifficulty);

		#if !switch
		intendedScore = Highscore.getWeekScore(weeks[curWeek].id, curDifficulty);
		#end

		FlxTween.tween(sprDifficulty, {y: leftArrow.y + 15, alpha: 1}, 0.07);
	}

	var lerpScore:Int = 0;
	var intendedScore:Int = 0;

	function changeWeek(change:Int = 0):Void {
		curWeek += change;

		if (curWeek >= weeks.length)
			curWeek = 0;
		if (curWeek < 0)
			curWeek = weeks.length - 1;

		if (curWeek == 0) {
			grpWeekCharacters.members[0].visible = false;
		} else {
			grpWeekCharacters.members[0].visible = true;
		}

		var bullShit:Int = 0;

		for (item in grpWeekText.members) {
			item.targetY = bullShit - curWeek;
			if (item.targetY == Std.int(0) && isWeekUnlocked(weeks[curWeek].id))
				item.alpha = 1;
			else
				item.alpha = 0.6;
			bullShit++;
		}

		FlxG.sound.play(Paths.sound('scrollMenu'));

		updateText();
	}

	function updateText() {
		
		for (i in 0...3) {
			/*
			if (Cache.menuCharacters.exists(weeks[curWeek].characters[i])) {
				trace(weeks[curWeek].characters[i], Cache.menuCharacters.get(weeks[curWeek].characters[i]).character);
				grpWeekCharacters.members[i] = Cache.menuCharacters.get(weeks[curWeek].characters[i]);
			}
			else
			*/
			if (FileSystem.exists(Paths.getCharacterPath(weeks[curWeek].characters[i]) + "story.png")) {
				grpWeekCharacters.members[i].setChar(weeks[curWeek].characters[i]);
			}
			else {
				//trace("no story menu character image: " + weeks[curWeek].characters[i]);
				grpWeekCharacters.members[i].visible = true;
			}
		}
		txtTracklist.text = "Tracks\n\n";

		switch (grpWeekCharacters.members[0].character) {
			case 'parents-christmas':
				grpWeekCharacters.members[0].offset.set(400, 220);
				grpWeekCharacters.members[0].scale.set(0.45, 0.45);

			case 'senpai':
				grpWeekCharacters.members[0].offset.set(130, -50);
				grpWeekCharacters.members[0].scale.set(0.8, 0.8);

			case 'mom':
				grpWeekCharacters.members[0].offset.set(100, 220);
				grpWeekCharacters.members[0].scale.set(0.45, 0.45);

			case 'dad':
				grpWeekCharacters.members[0].offset.set(150, 200);
				grpWeekCharacters.members[0].scale.set(0.5, 0.5);

			case "spooky":
				grpWeekCharacters.members[0].offset.set(200, 100);
				grpWeekCharacters.members[0].scale.set(0.6, 0.6);

			case "pico":
				grpWeekCharacters.members[0].offset.set(150, 50);
				grpWeekCharacters.members[0].scale.set(0.6, 0.6);

			default:
				grpWeekCharacters.members[0].offset.set(100, 100);
				grpWeekCharacters.members[0].scale.set(0.6, 0.6);
				// grpWeekCharacters.members[0].updateHitbox();
		}

		var stringThing:Array<String> = weeks[curWeek].songs;

		for (i in stringThing) {
			txtTracklist.text += i + "\n";
		}

		txtTracklist.text = txtTracklist.text.toUpperCase();

		txtTracklist.screenCenter(X);
		txtTracklist.x -= FlxG.width * 0.35;

		#if !switch
		intendedScore = Highscore.getWeekScore(weeks[curWeek].id, curDifficulty);
		#end
	}

	override public function onFocusLost():Void {
		super.onFocusLost();
		
		FlxG.autoPause = false;
	}
}

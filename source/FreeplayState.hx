package;

import flixel.group.FlxSpriteGroup;
import flixel.FlxSubState;
import flixel.system.FlxAssets.FlxSoundAsset;
import flixel.system.FlxSound;
import sys.io.File;
import sys.FileSystem;
import flixel.math.FlxRandom;
import yaml.util.ObjectMap.TObjectMap;
import yaml.Yaml;
import flixel.FlxCamera;
import Song.SwagSong;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import openfl.media.Sound;
import flixel.util.FlxStringUtil;
import haxe.io.Path;
#if desktop
import Discord.DiscordClient;
#end
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;

using StringTools;

class FreeplayState extends MusicBeatState {
	var songs:Array<SongMetadata> = [];

	public static var modifiers:Array<Modifiers> = [];

	var selector:FlxText;
	var curSelected:Int = 0;
	var curDifficulty:Int = 1;

	var scoreText:FlxText;
	var diffText:FlxText;
	var lerpScore:Int = 0;
	var intendedScore:Int = 0;

	var erectMode = false;

	var bg:FlxSprite;

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var curPlaying:Bool = false;

	private var iconArray:Array<HealthIcon> = [];

	public function new(?erectFreeplay:Bool = false) {
		erectMode = erectFreeplay;
		super();
	}

	var erectSongExists = false;

	override function create() {
		/* 
			if (FlxG.sound.music != null)
			{
				if (!FlxG.sound.music.playing)
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
			}
		 */

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In Freeplay", null);
		#end

		var isDebug:Bool = false;

		#if debug
		isDebug = true;
		#end
		
		for (index in 0...7) {
			StoryMenuState.setWeekUnlocked('week$index');
		}

		if (!erectMode) {
			songs.push(new SongMetadata("Tutorial", "week0", 'gf', "#ff82a5"));
			if (StoryMenuState.isWeekUnlocked("week0") || isDebug)
				addWeek(['Bopeebo', 'Fresh', 'Dadbattle'], "week1", ['dad'], "#9471e3");

			if (StoryMenuState.isWeekUnlocked("week1") || isDebug)
				addWeek(['Spookeez', 'South', 'Monster'], "week2", ['spooky', 'spooky', 'monster'], "#2a3d42");

			if (StoryMenuState.isWeekUnlocked("week2") || isDebug)
				addWeek(['Pico', 'Philly', 'Blammed'], "week3", ['pico'], "#b0284f");

			if (StoryMenuState.isWeekUnlocked("week3") || isDebug)
				addWeek(['Satin-Panties', 'High', 'Milf'], "week4", ['mom'], "#ff82a5");

			if (StoryMenuState.isWeekUnlocked("week4") || isDebug)
				addWeek(['Cocoa', 'Eggnog', 'Winter-Horrorland'], "week5", ['parents-christmas', 'parents-christmas', 'monster-christmas'], "#e3edff");

			if (StoryMenuState.isWeekUnlocked("week5") || isDebug)
				addWeek(['Senpai', 'Roses', 'Thorns'], "week6", ['senpai', 'senpai', 'spirit'], "#f593de");
		}
		else {
			//put erect songs here
		}

		/*
		if (StoryMenuState.isWeekUnlocked("week6") || isDebug)
			addWeek(['Ugh', 'Guns', 'Stress'], "week7", ['tankman'], "#ffb029");
		*/

		var otherSongsAdded = [];

		

		var pengine_weeks_path = ${Paths.modsLoc} + "/weeks/";
		weekModsFolderContent = FileSystem.readDirectory(pengine_weeks_path);
		for (file in weekModsFolderContent) {
			if (file.endsWith("-erect"))
				erectSongExists = true;
			if (erectMode ? file.endsWith("-erect") : !file.endsWith("-erect")) {
				var path = haxe.io.Path.join([pengine_weeks_path, file]);
				if (FileSystem.isDirectory(path)) {
					var data = Yaml.parse(File.getContent(path + "/config.yml"));
					if (StoryMenuState.isWeekUnlocked(Std.string(data.get('unlockedAfter')))) {
						var map:TObjectMap<Dynamic, Dynamic> = data.get('songs');
						var songs:Array<String> = [];
						var characters:Array<String> = [];
						for (song in map.keys()) {
							songs.push(song);
							otherSongsAdded.push(song.toLowerCase());
							characters.push(data.get("songs").get(song).get("character"));
						}
						addWeek(songs, Std.string(data.get('weekID')), characters, Std.string(data.get('color')));
					}
				}
			}
		}

		var pengine_song_path = ${Paths.modsLoc} + "/songs/";
		songModsFolderContent = FileSystem.readDirectory(pengine_song_path);
		for (file in songModsFolderContent) {
			if (file.endsWith("-erect"))
				erectSongExists = true;
			if (erectMode ? file.endsWith("-erect") : !file.endsWith("-erect")) {
				if (!otherSongsAdded.contains(file.toLowerCase())) {
					var path = haxe.io.Path.join([pengine_song_path, file]);
					if (FileSystem.isDirectory(path)) {
						var folder = path.split("/")[2];
						addWeek([folder], "week-1", null, null);
					}
				}
			}
		}

		// LOAD MUSIC

		// LOAD CHARACTERS

		camBG = new FlxCamera();
		camMain = new FlxCamera();
		camMain.bgColor.alpha = 0;

		// why no one uses this
		FlxG.cameras.add(camBG, false);
		FlxG.cameras.add(camMain, true);

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = FlxColor.fromString("#9471e3");
		add(bg);

		bg.cameras = [camBG];

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length) {
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, songs[i].songName, true, false);
			songText.isMenuItem = true;
			songText.targetY = i;
			grpSongs.add(songText);

			var iconChar = songs[i].songCharacter;

			if (iconChar == "face") {
				var json:SwagSong = Paths.getSongJson(songs[i].songName);
				if (json != null) {
					iconChar = json.player2;
				}
			}

			var icon:HealthIcon = new HealthIcon(iconChar);
			icon.sprTracker = songText;

			if (songs[i].freeplayColor == null) {
				songs[i].freeplayColor = CoolUtil.getDominantColor(icon).toWebString();
			}

			// using a FlxGroup is too much fuss!
			iconArray.push(icon);
			add(icon);

			// songText.x += 40;
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
			// songText.screenCenter(X);
		}

		scoreText = new FlxText(FlxG.width * 0.7 - 20, 5, 0, "", 32);
		// scoreText.autoSize = false;
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
		// scoreText.alignment = RIGHT;

		var scoreBG:FlxSprite = new FlxSprite(scoreText.x - 6, 0).makeGraphic(Std.int(FlxG.width * 0.35), 66, 0xFF000000);
		scoreBG.alpha = 0.6;

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;

		var downBarText:FlxText = new FlxText(0, 0, 0, "", 18);
		downBarText.setFormat(Paths.font("vcr.ttf"), downBarText.size, FlxColor.WHITE);
		downBarText.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 2);
		downBarText.text = "SPACE - Listen to song     R - Select Random Song     SHIFT - Open Gameplay Modifier" + (erectSongExists ?  "     E - Toggle Erect Mode" : "");
		downBarText.screenCenter(X);

		var downBarBG:FlxSprite = new FlxSprite(0, FlxG.height - downBarText.height - 5).makeGraphic(FlxG.width, Std.int(downBarText.height) + 6, 0xFF000000);
		downBarBG.alpha = 0.6;
		downBarText.y = downBarBG.y;

		add(downBarBG);
		add(downBarText);
		add(scoreBG);
		add(diffText);
		add(scoreText);

		changeSelection();
		changeDiff();

		// FlxG.sound.playMusic(Paths.music('title'), 0);
		// FlxG.sound.music.fadeIn(2, 0, 0.8);
		selector = new FlxText();

		selector.size = 40;
		selector.text = ">";
		// add(selector);

		var swag:Alphabet = new Alphabet(1, 0, "swag");

		// JUST DOIN THIS SHIT FOR TESTING!!!
		/*
		 what the fuck i literally came back from toilet and i was accidently on this line when testing the vocals
		 thanks ninjamuffin for this, will use this for update state lmfao
		*/
		/* 
			var md:String = Markdown.markdownToHtml(Assets.getText('CHANGELOG.md'));

			var texFel:TextField = new TextField();
			texFel.width = FlxG.width;
			texFel.height = FlxG.height;
			// texFel.
			texFel.htmlText = md;

			FlxG.stage.addChild(texFel);

			// scoreText.textField.htmlText = md;

			trace(md);
		 */

		vocals = new FlxSound();

		super.create();
	}

	override public function onFocus() {
		super.onFocus();
		
		if (songModsFolderContent.length != FileSystem.readDirectory(${Paths.modsLoc} + "/songs/").length) {
			FlxG.switchState(new FreeplayState());
		}
	}

	public function addSong(songName:String, week:String, songCharacter:String, freeplayColor:String) {
		songs.push(new SongMetadata(songName, week, songCharacter, freeplayColor));
	}

	public function addWeek(songs:Array<String>, week:String, ?songCharacters:Array<String>, freeplayColor:String) {
		if (songCharacters == null)
			songCharacters = ['face'];

		var num:Int = 0;
		for (song in songs) {
			addSong(song, week, songCharacters[num], freeplayColor);

			if (songCharacters.length != 1)
				num++;
		}
	}

	override function update(elapsed:Float) {
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

		super.update(elapsed);

		if (FlxG.sound.music.volume < 0.7) {
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}
		
		camBG.zoom = FlxMath.lerp(1, camBG.zoom, CoolUtil.bound(0.75));

		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, 0.4));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;

		scoreText.text = "PERSONAL BEST:" + FlxStringUtil.formatMoney(lerpScore, false);

		var upP = Controls.check(UI_UP, JUST_PRESSED);
		var downP = Controls.check(UI_DOWN, JUST_PRESSED);
		var accepted = Controls.check(ACCEPT, JUST_PRESSED);

		if (upP) {
			changeSelection(-1);
		}
		if (downP) {
			changeSelection(1);
		}

		if (FlxG.keys.justPressed.SHIFT) {
			openSubState(new ModifierSubState());
		}

		if (FlxG.keys.justPressed.R) {
			curSelected = new FlxRandom().int(0, songs.length);
			changeSelection(0);
		}

		if (Controls.check(UI_LEFT, JUST_PRESSED))
			changeDiff(-1);
		if (Controls.check(UI_RIGHT, JUST_PRESSED))
			changeDiff(1);

		if (Controls.check(BACK, JUST_PRESSED)) {
			vocals.stop();
			FlxG.sound.play(Paths.sound('cancelMenu'));
			FlxG.switchState(new MainMenuState());
		}


		if (FlxG.keys.justPressed.E && erectSongExists) {
			vocals.stop();
			FlxG.switchState(new FreeplayState(!erectMode));
		}

		if (FlxG.keys.justPressed.SPACE) {
			if (doubleSpace == 1) {
				goToSong();
			} else {
				FlxG.sound.music.stop();
				vocals.stop();
				
				var preloadInst:FlxSound = new FlxSound();
				var preloadVoices:FlxSound = new FlxSound();

				if (FileSystem.exists(Paths.instNoLib(songs[curSelected].songName))) {
					preloadInst = new FlxSound().loadEmbedded(Paths.inst(songs[curSelected].songName));
				} else {
					preloadInst = FlxG.sound.load(Sound.fromFile(Paths.PEinst(songs[curSelected].songName)));
				}

				if (Options.freeplayListenVocals) {
					if (FileSystem.exists(Paths.voicesNoLib(songs[curSelected].songName))) {
						preloadVoices = new FlxSound().loadEmbedded(Paths.voices(songs[curSelected].songName));
					}
					else if (FileSystem.exists(Paths.PEvoices(songs[curSelected].songName))) {
						preloadVoices = FlxG.sound.load(Sound.fromFile(Paths.PEvoices(songs[curSelected].songName)));
					}
				}

				vocals = preloadVoices;
				vocals.looped = true;
				vocals.persist = false;
				vocals.play();

				FlxG.sound.music = preloadInst;
				FlxG.sound.music.looped = true;
				FlxG.sound.music.persist = true;
				FlxG.sound.music.group = FlxG.sound.defaultMusicGroup;
				FlxG.sound.music.play();

				var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);
				var json:SwagSong;
				if (FileSystem.exists(Paths.instNoLib(songs[curSelected].songName))) {
					json = Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
				} else {
					json = Song.PEloadFromJson(poop, songs[curSelected].songName.toLowerCase());
				}

				if (json != null) {
					Conductor.mapBPMChanges(json);
					Conductor.changeBPM(json.bpm);
				} else {
					Conductor.bpmChangeMap = [];
					Conductor.changeBPM(102);
				}
			}
			doubleSpace = 1;
		}

		if (accepted) {
			if (!FlxG.keys.justPressed.SPACE) {
				goToSong();
			}
		}
	}

	override function beatHit() {
		super.beatHit();

		camBG.zoom += 0.02;
		
	}

	override function stepHit() {
		super.stepHit();

		if (vocals.time > Conductor.songPosition + 20 || vocals.time < Conductor.songPosition - 20) {
			vocals.time = Conductor.songPosition;
		}
	}

	function goToSong() {
		vocals.stop();
		switch (diffText.text.toLowerCase()) {
			case "easy":
				curDifficulty = 0;
			case "normal":
				curDifficulty = 1;
			case "hard":
				curDifficulty = 2;
			}
		var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);

		var customSong = false;
		
		if (FileSystem.exists(Paths.instNoLib(songs[curSelected].songName))) {
			PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
		} else {
			customSong = true;
			PlayState.SONG = Song.PEloadFromJson(poop, songs[curSelected].songName.toLowerCase());
		}
		PlayState.SONGglobalNotes = Song.parseGlobalNotesJSONshit(poop);

		PlayState.isStoryMode = false;
		PlayState.storyDifficulty = curDifficulty;
		switch (PlayState.storyDifficulty) {
			case 0:
				PlayState.dataFileDifficulty = '-easy';
			case 1:
				PlayState.dataFileDifficulty = "";
			case 2:
				PlayState.dataFileDifficulty = '-hard';
		}
		PlayState.storyWeek = songs[curSelected].week;
		trace('CUR WEEK ' + PlayState.storyWeek);

		if (customSong && Song.PEloadFromJson(poop, songs[curSelected].songName.toLowerCase()) == null) {
			trace("custom song is null, going to charting state");
			FlxG.switchState(new ChartingState(null, songs[curSelected].songName));
		} else {
			LoadingState.loadAndSwitchState(new PlayState());
		}
	}

	override public function onFocusLost():Void {
		super.onFocusLost();

		FlxG.autoPause = false;
	}

	function changeDiff(change:Int = 0, ?set:Bool = false) {
		if (!set) {
			curDifficulty += change;
		}
		else {
			curDifficulty = change;
		}

		if (curDifficulty < 0)
			curDifficulty = CoolUtil.difficultyArray.length - 1;
		if (curDifficulty > CoolUtil.difficultyArray.length - 1)
			curDifficulty = 0;

		if (songs[curSelected] != null) {
			#if !switch
			intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
			#end
		}

		diffText.text = CoolUtil.difficultyArray[curDifficulty];

		switch (diffText.text) {
			case "EASY":
				diffText.color = FlxColor.LIME;
			case "NORMAL":
				diffText.color = FlxColor.YELLOW;
			case "HARD":
				diffText.color = FlxColor.RED;
			default:
				diffText.color = FlxColor.WHITE;
		}
	}

	function changeSelection(change:Int = 0) {
		// NGio.logEvent('Fresh');
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = songs.length - 1;
		if (curSelected >= songs.length)
			curSelected = 0;

		// selector.y = (70 * curSelected) + 30;

		doubleSpace = 0;

		var bullShit:Int = 0;

		if (songs[curSelected] != null) {
			#if !switch
			intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
			// lerpScore = 0;
			#end

			for (i in 0...iconArray.length) {
				iconArray[i].alpha = 0.6;
			}

			iconArray[curSelected].alpha = 1;

			for (item in grpSongs.members) {
				item.targetY = bullShit - curSelected;
				bullShit++;

				item.alpha = 0.6;
				// item.setGraphicSize(Std.int(item.width * 0.8));

				if (item.targetY == 0) {
					item.alpha = 1;
					// item.setGraphicSize(Std.int(item.width));
				}
			}

			FlxTween.color(bg, 0.2, bg.color, FlxColor.fromString(songs[curSelected].freeplayColor));
		}
		CoolUtil.setDifficultyList(songs[curSelected].songName);
		if (CoolUtil.difficultyArray.length < prevDiffList.length || !CoolUtil.difficultyArray.contains(diffText.text)) {
			changeDiff(CoolUtil.difficultyArray.length - 1, true);
		}

		changeDiff();
		
		prevDiffList = CoolUtil.difficultyArray;
	}

	var prevDiffList:Array<String> = [];

	var doubleSpace:Int;

	var camBG:FlxCamera;

	var camMain:FlxCamera;

	var vocals:FlxSound;

	var weekModsFolderContent:Array<String>;

	var songModsFolderContent:Array<String>;

	public static var inSubState:Bool = false;
}

class SongMetadata {
	public var songName:String = "";
	public var week:String = "week0";
	public var songCharacter:String = "";
	public var freeplayColor:String = null;

	public function new(song:String, week:String, songCharacter:String, ?freeplayColor:String) {
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.freeplayColor = freeplayColor;
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
		nightcore.name = Modifiers.NIGHTCORE;
		nightcore.ID = 0;
		if (!FreeplayState.modifiers.contains(nightcore.name))
			nightcore.setColorTransform(0.3, 0.3, 0.3);

		var fullCombo = new ModifierImage(nightcore.x + nightcore.width + 20);
		fullCombo.loadGraphic(Paths.image("modifiers/full-combo"));
		fullCombo.setGraphicSize(80, 80);
		fullCombo.updateHitbox();
		fullCombo.name = Modifiers.FULLCOMBO;
		fullCombo.ID = 1;
		if (!FreeplayState.modifiers.contains(fullCombo.name))
			fullCombo.setColorTransform(0.3, 0.3, 0.3);

		modifierItems.add(nightcore);
		modifierItems.add(fullCombo);
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
			if (FreeplayState.modifiers.contains(item.name))
				item.setColorTransform(1, 1, 1);
			else
				item.setColorTransform(0.3, 0.3, 0.3);
			item.alpha = 0.8;
			if (item.ID == curModifier) {
				item.alpha = 1;
				if (Controls.check(ACCEPT)) {
					if (FreeplayState.modifiers.contains(item.name)) {
						FreeplayState.modifiers.remove(item.name);
					}
					else {
						FreeplayState.modifiers.push(item.name);
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

class ModifierImage extends FlxSprite {
	public var name:Modifiers;
}

@:enum
abstract Modifiers(String) {
	var NIGHTCORE = "nc";
	var FULLCOMBO = "fc";

	public static function getTitle(mod:Modifiers):String {
		switch(mod) {
			case NIGHTCORE:
				return "Nightcore";
			case FULLCOMBO:
				return "Full Combo";
		}
	}

	public static function getDescription(mod:Modifiers):String {
		switch (mod) {
			case NIGHTCORE:
				return "Pitches up the song.";
			case FULLCOMBO:
				return "No more Skill Issues";
		}
	}


	public static function calculateMultiplier():Float {
		var mult = 1.0;
		for (s in FreeplayState.modifiers) {
			switch (s) {
				case NIGHTCORE:
					mult += 0.5;
				case FULLCOMBO:
					mult += 0.0;
			}
		}
		return mult;
	}
}
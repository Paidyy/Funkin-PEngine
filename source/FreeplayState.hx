package;

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

	var selector:FlxText;
	var curSelected:Int = 0;
	var curDifficulty:Int = 1;

	var scoreText:FlxText;
	var diffText:FlxText;
	var lerpScore:Int = 0;
	var intendedScore:Int = 0;

	var bg:FlxSprite;

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var curPlaying:Bool = false;

	private var iconArray:Array<HealthIcon> = [];

	override function create() {
		var initSonglist = CoolUtil.coolTextFile(Paths.txt('freeplaySonglist'));

		for (i in 0...initSonglist.length) {
			songs.push(new SongMetadata(initSonglist[i], "week0", 'gf', "#ff82a5"));
		}

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

		if (StoryMenuState.isWeekUnlocked("week6") || isDebug)
			addWeek(['Ugh', 'Guns', 'Stress'], "week7", ['tankman'], "#ffb029");

		var otherSongsAdded = [];

		var pengine_weeks_path = "mods/weeks/";
		for (file in FileSystem.readDirectory(pengine_weeks_path)) {
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

		var pengine_song_path = "mods/songs/";
		for (file in FileSystem.readDirectory(pengine_song_path)) {
			if (!otherSongsAdded.contains(file.toLowerCase())) {
				var path = haxe.io.Path.join([pengine_song_path, file]);
				if (FileSystem.isDirectory(path)) {
					var folder = path.split("/")[2];
					addWeek([folder], "week-1", null, "#6bb580");
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

			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.sprTracker = songText;

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

		var downBarBG:FlxSprite = new FlxSprite(0, FlxG.height - 30).makeGraphic(FlxG.width, 30, 0xFF000000);
		downBarBG.alpha = 0.6;

		var downBarText:FlxText = new FlxText(0, downBarBG.y, 0, "", Std.int(downBarBG.height) - 5);
		downBarText.setFormat(Paths.font("vcr.ttf"), downBarText.size, FlxColor.WHITE);
		downBarText.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 2);
		downBarText.text = "SPACE to listen to the current song     R to select random song";
		downBarText.screenCenter(X);

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

		super.create();
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
		super.update(elapsed);

		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

		if (FlxG.sound.music.volume < 0.7) {
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}
		
		camBG.zoom = FlxMath.lerp(1, camBG.zoom, 0.8);

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

		if (FlxG.keys.justPressed.R) {
			curSelected = new FlxRandom().int(0, songs.length);
			changeSelection(0);
		}

		if (Controls.check(UI_LEFT, JUST_PRESSED))
			changeDiff(-1);
		if (Controls.check(UI_RIGHT, JUST_PRESSED))
			changeDiff(1);

		if (Controls.check(BACK, JUST_PRESSED)) {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			FlxG.switchState(new MainMenuState());
		}

		if (FlxG.keys.justPressed.SPACE) {
			if (doubleSpace == 1) {
				goToSong();
			} else {
				if (FileSystem.exists(Paths.instNoLib(songs[curSelected].songName))) {
					FlxG.sound.playMusic(Paths.inst(songs[curSelected].songName), 0.6);
				} else {
					FlxG.sound.playMusic(Sound.fromFile(Paths.PEinst(songs[curSelected].songName)));
				}

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

	function goToSong() {
		var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);

		trace(poop);

		var customSong = false;
		
		if (FileSystem.exists(Paths.instNoLib(songs[curSelected].songName))) {
			PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
		} else {
			customSong = true;
			PlayState.SONG = Song.PEloadFromJson(poop, songs[curSelected].songName.toLowerCase());
		}

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

	function changeDiff(change:Int = 0) {
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = 2;
		if (curDifficulty > 2)
			curDifficulty = 0;

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		#end

		switch (curDifficulty) {
			case 0:
				diffText.text = "EASY";
				diffText.color = FlxColor.LIME;
			case 1:
				diffText.text = 'NORMAL';
				diffText.color = FlxColor.YELLOW;
			case 2:
				diffText.text = "HARD";
				diffText.color = FlxColor.RED;
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

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		// lerpScore = 0;
		#end

		/*
		here check if it's a custom song

		if (!SysFile.exists(Paths.instNoLib(songs[curSelected].songName))) {
			trace("Custom song selected.");
		}
		*/

		doubleSpace = 0;

		var bullShit:Int = 0;

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

		FlxTween.color(bg,
			0.2,
			bg.color,
			FlxColor.fromString(songs[curSelected].freeplayColor)
		);
	}

	var doubleSpace:Int;

	var camBG:FlxCamera;

	var camMain:FlxCamera;
}

class SongMetadata {
	public var songName:String = "";
	public var week:String = "week0";
	public var songCharacter:String = "";
	public var freeplayColor:String = "#9471e3";

	public function new(song:String, week:String, songCharacter:String, ?freeplayColor:String) {
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.freeplayColor = freeplayColor;
	}
}

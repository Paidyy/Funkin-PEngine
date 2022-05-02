package;

import flixel.tweens.FlxTween;
import flixel.tweens.motion.QuadMotion;
import flixel.tweens.misc.AngleTween;
import flixel.tweens.FlxTween.FlxTweenManager;
import flixel.tweens.FlxTween.TweenOptions;
import Main.Notification;
import Splash.SplashColor;
import flixel.tweens.misc.NumTween;
import flixel.tweens.misc.VarTween;
import flixel.group.FlxSpriteGroup;
import sys.FileSystem;
import sys.io.File;
import yaml.util.ObjectMap.AnyObjectMap;
import flixel.input.FlxInput.FlxInputState;
import Controls.KeyType;
import OptionsSubState.Background;
import Stage.BackgroundDancer;
import haxe.io.Bytes;
import multiplayer.Lobby;
import flixel.math.FlxRandom;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.effects.FlxTrail;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import openfl.media.Sound;
import Section.SwagSection;
import Song.SwagSong;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import openfl.display.BlendMode;
import openfl.display.StageQuality;
import Discord.DiscordClient;

using StringTools;

class PlayState extends MusicBeatState {
	public static var SONG:SwagSong;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:String = "week0";
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;
	public static var dataFileDifficulty:String;
	public static var playAs:String = null;
	public static var whichCharacterToBotFC:String = "";

	private var vocals:FlxSound;

	public static var dad:Character;
	public static var gf:Character;
	public static var bf:Boyfriend;

	public static var gfLayer = new FlxGroup();
	public static var dadLayer = new FlxGroup();
	public static var bfLayer = new FlxGroup();

	private var notes:FlxTypedGroup<Note>;
	private var unspawnNotes:Array<Note> = [];

	public var dadStrumLine:Array<Array<Float>>;
	public var bfStrumLine:Array<Array<Float>>;

	public var strumLineNotes:FlxSpriteGroup;
	public var bfStrumLineNotes:FlxSpriteGroup;
	public var dadStrumLineNotes:FlxSpriteGroup;

	private var curSection:Int = 0;

	private var curSong:String = "";

	public var gfSpeed:Int = 1;

	public var health:Float = 1;
	public var combo:Int = 0;

	public var curSpeed:Float;

	public var bgDimness:FlxSprite;

	public var healthBarBG:FlxSprite;
	public var healthBar:FlxBar;

	private var generatedMusic:Bool = false;
	private var startingSong:Bool = false;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;

	public static var camHUD:FlxCamera;
	public static var camGame:FlxCamera;
	public static var camStatic:FlxCamera;
	public static var camOptions:FlxCamera;

	public static var camFollow:FlxObject;
	private static var prevCamFollow:FlxObject;

	public var camZooming:Bool = false;

	private static var sub:FlxText;
	private static var sub_bg:FlxSprite;

	public var stage:Stage;

	public var isMultiplayer:Bool = false;

	public var accuracy:Accuracy;

	public var downscroll:Bool = false;

	var dialogue:Array<String>;

	var wiggleShit:WiggleEffect = new WiggleEffect();

	public var talking:Bool = true;
	public var songScore:Int = 0;
	public var scoreTxt:FlxText;

	public static var campaignScore:Int = 0;

	public static var camZoom:Float = 1.05;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;

	public var inCutscene:Bool = false;

	public var pauseBG:Background;

	#if desktop
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var iconRPC:String = "";
	var songLength:Float = 0;
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	var selectedSongPosition:Bool = false;
	var songPositionCustom:Float;

	public static var currentPlaystate:PlayState;

	public var currentCameraTween:NumTween;
	public var currentHUDCameraTween:NumTween;

	public var luaSprites:Map<String, FlxSprite>;

	public var createNotif:Notification;

	public function addLuaSprite(name:String, sprite:FlxSprite) {
		luaSprites.set(name, sprite);
		add(luaSprites.get(name));
	}

	public static function thisWithNotification(notif:Notification):PlayState {
		var playstate = new PlayState();
		playstate.createNotif = notif;
		return playstate;
	}

	public function new(?isMultiplayer = false, ?songPosition:Float) {
		super();
		luaSprites = new Map<String, FlxSprite>();
		playAs = SONG.playAs;
		if (playAs == null) playAs = "bf";
		if (isMultiplayer == null) isMultiplayer = false;
		this.isMultiplayer = isMultiplayer;
		if (songPosition != null) {
			songPositionCustom = songPosition;
			selectedSongPosition = true;
		}
		if (!isMultiplayer) {
			if (playAs == "dad") {
				whichCharacterToBotFC = "bf";
			} else {
				whichCharacterToBotFC = "dad";
			}
		} else {
			whichCharacterToBotFC = "";
		}
	}

	/**
	 * Plays Animation on strum line
	 * 
	 * list of animations:
	 * 
	 * `pressed` - pressed key
	 * 
	 * `static` - idle animation
	 * 
	 * `confirm` - on pressed note
	 */
	public function strumPlayAnim(noteData:Int, as:String, animation:String = "static") {
		var sprite:FlxSprite = null;
		if (as == "dad") {
			dadStrumLineNotes.forEach(function(spr:FlxSprite) {
				if (Math.abs(noteData) == spr.ID) {
					sprite = spr;
				}
			});
		} 
		else {
			bfStrumLineNotes.forEach(function(spr:FlxSprite) {
				if (Math.abs(noteData) == spr.ID) {
					sprite = spr;
				}
			});
		}
		
		if (sprite != null) {
			
			var isThing = false;
			if (SONG.whichK == 5 && Math.abs(noteData) == 2 || SONG.whichK == 7 && Math.abs(noteData) == 3 || SONG.whichK == 9 && Math.abs(noteData) == 4) isThing = true;
			/* not using it because it fucking doesnt work
			var confirmOffset = (isThing ? 7 : sprite.width / 8) * (Note.sizeShit >= 0.7 ? 1 : Note.sizeShit + 0.3);
			*/
			var offset = 0.0;

			sprite.animation.play(animation, true);

			sprite.centerOffsets();

			if (isThing == false && (sprite.animation.curAnim.name == "confirm") && !stage.name.startsWith('school')) {
				switch (SONG.whichK) {
					case 4, 5:
						offset -= 4;
					case 6:
						offset += 0.5;
					case 7:
						offset += 4;
					case 8:
						offset += 4.5;
					case 9:
						offset += 8;
				}
			}
	
			if (sprite.animation.curAnim.name == "confirm" && !stage.name.startsWith('school')) {
				offset += 17;
			}

			sprite.offset.x -= offset;
			sprite.offset.y -= offset;
		}

	}

	/*
	function mustHitNote(note:Note) {
		if (note.mustPress) {
			if (playAs == "bf") {
				return true;
			}
			else {
				return false;
			}
		}
		else {
			if (playAs == "bf") {
				return false;
			}
			else {
				return true;
			}
		}
	}
	*/

	override public function create() {
		noteTimers = new Map<Int, FlxTimer>();
		currentPlaystate = this;

		if (Options.downscroll)
			downscroll = true;

		health = 1;

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		// to preload this shit before song
		new Splash();

		// var gameCam:FlxCamera = FlxG.camera;
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camStatic = new FlxCamera();
		camStatic.bgColor.alpha = 0;
		camOptions = new FlxCamera();
		camOptions.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camStatic, false);
		FlxG.cameras.add(camOptions, false);
		FlxG.cameras.setDefaultDrawTarget(camGame, true);
		persistentUpdate = true;
		persistentDraw = true;

		if (SONG == null)
			SONG = Song.loadFromJson('tutorial');

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		curSpeed = SONG.speed;

		trace("Current Week: " + storyWeek);
		trace("Current Mania Mode: " + SONG.whichK + "K");
		Note.setSizeVar();

		bfStrumLine = new Array<Array<Float>>();
		dadStrumLine = new Array<Array<Float>>();

		for (fopjnidsdjnifhsohipufuhiosfduhiojs in 0...SONG.whichK) {
			if (!downscroll) {
				bfStrumLine.push([50, 50]);
				dadStrumLine.push([50, 50]);
			}
			else {
				bfStrumLine.push([50, FlxG.height - ((Note.getSwagWidth(SONG.whichK) * 2) - 50)]);
				dadStrumLine.push([50, FlxG.height - ((Note.getSwagWidth(SONG.whichK) * 2) - 50)]);
			}
		}

		if (FileSystem.exists("mods/songs/" + SONG.song.toLowerCase() + "/dialogue.txt")) {
			dialogue = CoolUtil.coolTextFile("mods/songs/" + SONG.song.toLowerCase() + "/dialogue.txt");
		}
		else if (FileSystem.exists("assets/data/" + SONG.song.toLowerCase() + "/dialogue.txt")) {
			dialogue = CoolUtil.coolTextFile(Paths.txt(SONG.song.toLowerCase() + '/dialogue'));
		}
		else {
			dialogue = null;
		}

		#if desktop
		// Making difficulty text for Discord Rich Presence.
		switch (storyDifficulty) {
			case 0:
				storyDifficultyText = "Easy";
				dataFileDifficulty = '-easy';
			case 1:
				storyDifficultyText = "Normal";
			case 2:
				storyDifficultyText = "Hard";
				dataFileDifficulty = '-hard';
		}

		iconRPC = SONG.player2;

		// To avoid having duplicate images in Discord assets
		switch (iconRPC) {
			case 'senpai-angry':
				iconRPC = 'senpai';
			case 'monster-christmas':
				iconRPC = 'monster';
			case 'mom-car':
				iconRPC = 'mom';
		}

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		if (isStoryMode) {
			detailsText = "Story Mode: Week " + storyWeek;
		}
		if (isMultiplayer) {
			detailsText = "Multiplayer";
		}
		else {
			detailsText = "Freeplay";
		}

		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;

		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC);
		#end

		var tempStageName = "";

		if (SONG.stage == null) {
			switch (SONG.song.toLowerCase()) {
				case 'bopeebo', 'fresh', 'dadbattle':
					tempStageName = 'stage';
				case 'spookeez', 'monster', 'south':
					tempStageName = 'spooky';
				case 'pico', 'blammed', 'philly':
					tempStageName = 'philly';
				case 'milf', 'satin-panties', 'high':
					tempStageName = 'limo';
				case 'cocoa', 'eggnog':
					tempStageName = 'mall';
				case 'winter-horrorland':
					tempStageName = 'mallEvil';
				case 'senpai', 'roses':
					tempStageName = 'school';
				case 'thorns':
					tempStageName = 'schoolEvil';
				case 'ugh', 'stress', 'guns':
					tempStageName = 'tank';
				default:
					tempStageName = 'stage';
			}
		} else {
			tempStageName = SONG.stage;
		}

		Paths.setCurrentStage(tempStageName);
		
		try {
			stage = new Stage(tempStageName);
			add(stage);
		} catch (exc) {
			trace("Failed to load stage:" + tempStageName);
			new Notification("Failed to load stage:" + tempStageName).show();
		}

		stage.applyStageShitToPlayState();

		gfVersion = 'gf';

		switch (stage.name) {
			case 'limo':
				gfVersion = 'gf-car';
			case 'mall' | 'mallEvil':
				gfVersion = 'gf-christmas';
			case 'school':
				gfVersion = 'gf-pixel';
			case 'schoolEvil':
				gfVersion = 'gf-pixel';
			case 'tank':
				gfVersion = 'gf-tankmen';
		}

		if (SONG.song == "Stress") {
			gfVersion = "pico-speaker";
		}

		try {
			if (Options.customGf) {
				gf = new Character(stage.gfX, stage.gfY, 'gf-custom');
			} else {
				gf = new Character(stage.gfX, stage.gfY, gfVersion);
			}
		} catch (exc) {
			trace("Error when loading GF: " + gfVersion + " | Changing to default");
			new Notification("Error when loading GF: " + gfVersion + " | Changing to default").show();
			gfVersion = "gf";
			gf = new Character(stage.gfX, stage.gfY, gfVersion);
		}
		gf.scrollFactor.set(stage.gfScrollFactorX, stage.gfScrollFactorY);

		try {
			if (Options.customGf && SONG.player2.startsWith("gf")) {
				dad = new Character(stage.dadX, stage.dadY, "gf-custom");
			}
			else if (Options.customDad && !SONG.player2.startsWith("gf")) {
				dad = new Character(stage.dadX, stage.dadY, "dad-custom");
			}
			else if (!Options.customDad) {
				dad = new Character(stage.dadX, stage.dadY, SONG.player2);
			}
		} catch (exc) {
			trace("Error when loading DAD: " + SONG.player2 + " | Changing to default");
			new Notification("Error when loading DAD: " + SONG.player2 + " | Changing to default").show();
			SONG.player2 = "dad";
			dad = new Character(stage.dadX, stage.dadY, SONG.player2);
		}
		dad.scrollFactor.set(stage.dadScrollFactorX, stage.dadScrollFactorY);

		var camPos:FlxPoint = new FlxPoint(dad.getGraphicMidpoint().x, dad.getGraphicMidpoint().y);

		try {
			if (Options.customBf) {
				bf = new Boyfriend(stage.bfX, stage.bfY, "bf-custom");
			}
			else {
				bf = new Boyfriend(stage.bfX, stage.bfY, SONG.player1);
			}
		}
		catch (error) {
			trace("Error when loading BF: " + SONG.player1 + " | Changing to default");
			new Notification("Error when loading BF: " + SONG.player1 + " | Changing to default").show();
			SONG.player1 = "bf";
			bf = new Boyfriend(stage.bfX, stage.bfY, SONG.player1);
		}
		bf.scrollFactor.set(stage.bfScrollFactorX, stage.bfScrollFactorY);

		gfLayer = new FlxGroup();
		dadLayer = new FlxGroup();
		bfLayer = new FlxGroup();

		gfLayer.add(gf);
		dadLayer.add(dad);
		bfLayer.add(bf);

		updateCharPos("gf");
		updateCharPos("dad");
		updateCharPos("bf");

		switch (SONG.player2) {
			case 'gf':
				dad.setPosition(gf.x, gf.y);
				gf.visible = false;
				if (isStoryMode) {
					camPos.x += 600;
					tweenCamZoom(1.3);
				}
			case "spooky":
				dad.y += 200;
			case "monster":
				dad.y += 100;
			case 'monster-christmas':
				dad.y += 130;
			case 'dad':
				camPos.x += 400;
			case 'pico':
				camPos.x += 600;
				dad.y += 300;
			case 'parents-christmas':
				dad.x -= 500;
			case 'senpai':
				dad.x += 150;
				dad.y += 360;
				camPos.set(dad.getGraphicMidpoint().x + 300, dad.getGraphicMidpoint().y);
			case 'senpai-angry':
				dad.x += 150;
				dad.y += 360;
				camPos.set(dad.getGraphicMidpoint().x + 300, dad.getGraphicMidpoint().y);
			case 'spirit':
				dad.x -= 150;
				dad.y += 100;
				camPos.set(dad.getGraphicMidpoint().x + 300, dad.getGraphicMidpoint().y);
		}

		switch (stage.name) {
			case 'limo':
				resetFastCar();
				add(stage.fastCar);
			case 'tank':
				if (gfVersion == "pico-speaker") {
					gf.x = 300;
					gf.y = -50;
				}
		}
		
		add(gfLayer);
		// Shitty layering but whatev it works LOL
		if (stage.name == 'limo')
			add(stage.limo);

		
		add(dadLayer);
		add(bfLayer);

		if (stage.name == 'tank') {
			add(stage.bgTank0);
			add(stage.bgTank1);
			add(stage.bgTank2);
			add(stage.bgTank3);
			add(stage.bgTank4);
			add(stage.bgTank5);
		}

		bgDimness = new FlxSprite().makeGraphic(FlxG.width + 1000, FlxG.height + 1000, FlxColor.BLACK);
		bgDimness.alpha = Options.bgDimness;
		bgDimness.scrollFactor.set();
		bgDimness.screenCenter(XY);
		add(bgDimness);

		var doof = new DialogueBox(false, dialogue);
		// doof.x += 70;
		// doof.y = FlxG.height * 0.5;
		doof.scrollFactor.set();
		doof.finishThing = startCountdown;

		db = new DialogueBoxOg(dialogue);
		// db.x += 70;
		// db.y = FlxG.height * 0.5;
		db.scrollFactor.set();
		db.finishThing = startCountdown;

		Conductor.songPosition = -5000;

		/*
		strumLineDad = new FlxSprite(0, 50).makeGraphic(FlxG.width, 10);
		strumLineDad.scrollFactor.set();

		strumLineBf = new FlxSprite(0, 50).makeGraphic(FlxG.width, 10);
		strumLineBf.scrollFactor.set();
		*/

		strumLineNotes = new FlxSpriteGroup();
		add(strumLineNotes);

		bfStrumLineNotes = new FlxSpriteGroup();
		dadStrumLineNotes = new FlxSpriteGroup();

		// startCountdown();

		generateSong(SONG.song);

		// add(strumLine);

		camFollow = new FlxObject(0, 0, 1, 1);

		camFollow.setPosition(camPos.x, camPos.y);

		if (prevCamFollow != null) {
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}

		add(camFollow);

		FlxG.camera.follow(camFollow, LOCKON, 0.04);
		// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		FlxG.camera.zoom = camZoom;
		FlxG.camera.focusOn(camFollow.getPosition());

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		FlxG.fixedTimestep = false;

		timeLeftText = new FlxText(0, FlxG.height * 0.03, 0, "0:00", 69);
		if (stage.name.startsWith('school')) {
			timeLeftText.setFormat(Paths.font("pixel.otf"), 32 - 6, FlxColor.WHITE);
			timeLeftText.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.fromString("#404047"), 3);
		}
		else {
			timeLeftText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE);
			timeLeftText.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 3);
		}
		timeLeftText.antialiasing = true;
		timeLeftText.screenCenter(X);
		timeLeftText.scrollFactor.set();
		add(timeLeftText);

		sub_bg = new FlxSprite(0, 0);
		sub_bg.alpha = 0;
		add(sub_bg);

		sub = new FlxText(0, 0, 0, "", 26);
		add(sub);

		var healthBarY = FlxG.height * 0.9 - 5;
		if (downscroll) healthBarY = FlxG.height * 0.15 + 5;

		if (stage.name.startsWith('school'))
			healthBarBG = new FlxSprite(0, healthBarY).loadGraphic(Paths.image('pixelUI/healthBar-pixel'));
		else
			healthBarBG = new FlxSprite(0, healthBarY).loadGraphic(Paths.image('healthBar'));
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		add(healthBarBG);

		var healthBarStyle:FlxBarFillDirection = RIGHT_TO_LEFT;
		if (playAs == "dad") {
			healthBarStyle = LEFT_TO_RIGHT;
		}
		if (PlayState.SONG.swapBfGui) {
			if (healthBarStyle == RIGHT_TO_LEFT) {
				healthBarStyle = LEFT_TO_RIGHT;
			}
			else if (healthBarStyle == LEFT_TO_RIGHT) {
				healthBarStyle = RIGHT_TO_LEFT;
			}
		}

		if (stage.name.startsWith('school'))
			healthBar = new FlxBar(healthBarBG.x + 8, healthBarBG.y + 8, healthBarStyle, Std.int(healthBarBG.width - 16), Std.int(healthBarBG.height - 16), this, "health", 0, 2);
		else
			healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, healthBarStyle, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this, "health", 0, 2);
		healthBar.scrollFactor.set();
		add(healthBar);

		iconP1 = new HealthIcon(bf.curCharacter, PlayState.SONG.swapBfGui ? false : true);
		iconP2 = new HealthIcon(dad.curCharacter, PlayState.SONG.swapBfGui ? true : false);

		if (playAs == "dad")
			healthBar.createFilledBar(CoolUtil.getDominantColor(iconP1), CoolUtil.getDominantColor(iconP2));
		else
			healthBar.createFilledBar(CoolUtil.getDominantColor(iconP2), CoolUtil.getDominantColor(iconP1));
		
		iconP1.y = healthBar.y - (iconP1.height / 2);
		add(iconP1);

		iconP2.y = healthBar.y - (iconP2.height / 2);
		add(iconP2);

		if (isMultiplayer) {
			iconCrown = new FlxSprite(0, 0).loadGraphic(Paths.image('multi_crown'));
			iconCrown.setGraphicSize(Std.int(iconCrown.width * 0.7));
			iconCrown.updateHitbox();
			add(iconCrown);
			iconCrown.cameras = [camHUD];
		}

		scoreTxt = new FlxText(0, FlxG.height * 0.9 + 40, 0, "", 22);
		if (stage.name.startsWith('school')) {
			scoreTxt.setFormat(Paths.font("pixel.otf"), scoreTxt.size - 6, FlxColor.WHITE);
			scoreTxt.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.fromString("#404047"), 3);
		}
		else {
			scoreTxt.setFormat(Paths.font("vcr.ttf"), scoreTxt.size, FlxColor.WHITE);
			scoreTxt.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 2);
		}
		scoreTxt.antialiasing = true;
		scoreTxt.scrollFactor.set();
		scoreTxt.screenCenter(X);
		add(scoreTxt);

		pauseBG = new Background(FlxColor.BLACK, true);
		pauseBG.setGraphicSize(Std.int(pauseBG.width * 1.3)); 
		pauseBG.updateHitbox();
		pauseBG.screenCenter();
		pauseBG.alpha = 0.6;
		pauseBG.visible = false;
		add(pauseBG);

		if (Lobby.isHost && isMultiplayer) {
            var hostMode = new FlxText(10, 20, 0, 'HOST MODE', 16);
            hostMode.color = FlxColor.YELLOW;
            add(hostMode);
			hostMode.cameras = [camHUD];
        }

		timeLeftText.alpha = 0;
		healthBar.alpha = 0;
		healthBarBG.alpha = 0;
		iconP1.alpha = 0;
		iconP2.alpha = 0;
		scoreTxt.alpha = 0;

		strumLineNotes.cameras = [camHUD];
		notes.cameras = [camHUD];

		timeLeftText.cameras = [camHUD];
		healthBar.cameras = [camHUD];
		healthBarBG.cameras = [camHUD];
		iconP1.cameras = [camHUD];
		iconP2.cameras = [camHUD];
		scoreTxt.cameras = [camHUD];
		doof.cameras = [camHUD];
		sub.cameras = [camHUD];
		sub_bg.cameras = [camHUD];
		pauseBG.cameras = [camStatic];
		bgDimness.cameras = [camHUD];

		// if (SONG.song == 'South')
		// FlxG.camera.alpha = 0.7;
		// UI_camera.zoom = 1;

		// cameras = [FlxG.cameras.list[1]];
		startingSong = true;

		if (isStoryMode || forceDialogueBox) {
			switch (curSong.toLowerCase()) {
				case "winter-horrorland":
					var blackScreen:FlxSprite = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
					add(blackScreen);
					blackScreen.scrollFactor.set();
					camHUD.visible = false;

					new FlxTimer().start(0.1, function(tmr:FlxTimer) {
						iconP2.alpha = 0;
						remove(blackScreen);
						FlxG.sound.play(Paths.sound('Lights_Turn_On'));
						camFollow.y = -2050;
						camFollow.x += 200;
						FlxG.camera.focusOn(camFollow.getPosition());
						FlxG.camera.zoom = 1.5;

						new FlxTimer().start(0.8, function(tmr:FlxTimer) {
							camHUD.visible = true;
							remove(blackScreen);
							FlxTween.tween(FlxG.camera, {zoom: camZoom}, 2.5, {
								ease: FlxEase.quadInOut,
								onComplete: function(twn:flixel.tweens.FlxTween) {
									startCountdown();
								}
							});
						});
					});
				case 'senpai':
					schoolIntro(doof);
				case 'roses':
					FlxG.sound.play(Paths.sound('ANGRY'));
					schoolIntro(doof);
				case 'thorns':
					schoolIntro(doof);
				case 'ugh':
					camFollow.setPosition(dad.getMidpoint().x + 120, dad.getMidpoint().y - 70);
					playCutscene("ughCutscene");
				case 'guns':
					camFollow.setPosition(dad.getMidpoint().x + 120, dad.getMidpoint().y - 70);
					playCutscene("gunsCutscene");
				case 'stress':
					camFollow.setPosition(dad.getMidpoint().x + 120, dad.getMidpoint().y - 70);
					playCutscene("stressCutscene");
				default:
					if (FileSystem.exists(Paths.getSongFolder(SONG.song) + "cutscene.mp4")) {
						playCutscene(Paths.getSongFolder(SONG.song) + "cutscene.mp4");
					}
					else {
						if (dialogue != null) {
							normalDialogueIntro(db);
						}
						else {
							startCountdown();
						}
					}
			}
		}
		else {
			switch (curSong.toLowerCase()) {
				default:
					startCountdown();
			}
		}

		startDiscordRPCTimer();

		if (FileSystem.exists(Paths.getLuaPath(curSong.toLowerCase()))) {
			lua = new LuaShit(Paths.getLuaPath(curSong.toLowerCase()));
			
			luaSetVariable("curDifficulty", storyDifficulty);
			luaSetVariable("stageZoom", this.stage.camZoom);
		}

		super.create();

		if (createNotif != null) {
			createNotif.show();
		}
	}

	public function updateChar(char:Dynamic) {
		switch (char) {
			case 0, "gf":
				gfLayer.forEach(b -> gfLayer.remove(b));
				gfLayer.add(gf);
				/*
				commented because the pos can be inacurrate

				if (gf.config != null) {
					gf.x = Std.parseFloat(Std.string(gf.config.get("X")));
					gf.y = Std.parseFloat(Std.string(gf.config.get("Y")));
				}
				*/
			case 1, "bf":
				bfLayer.forEach(b -> bfLayer.remove(b));
				bfLayer.add(bf);
				if (playAs == "bf") {
					iconP1.setChar(bf.curCharacter, true);
				} else {
					iconP2.setChar(bf.curCharacter, false);
				}
				healthBar.createFilledBar(CoolUtil.getDominantColor(iconP2), CoolUtil.getDominantColor(iconP1));
				healthBar.value = health;
				/*
				if (bf.config != null) {
					bf.x = Std.parseFloat(Std.string(bf.config.get("X")));
					bf.y = Std.parseFloat(Std.string(bf.config.get("Y")));
				}
				*/
			case 2, "dad":
				dadLayer.forEach(b -> dadLayer.remove(b));
				dadLayer.add(dad);
				if (playAs == "bf") {
					iconP2.setChar(dad.curCharacter, false);
				} else {
					iconP1.setChar(dad.curCharacter, true);
				}
				healthBar.createFilledBar(CoolUtil.getDominantColor(iconP2), CoolUtil.getDominantColor(iconP1));
				healthBar.value = health;
				/*
				if (dad.config != null) {
					dad.x = Std.parseFloat(Std.string(dad.config.get("X")));
					dad.y = Std.parseFloat(Std.string(dad.config.get("Y")));
				}
				*/
		}
	}

	function playCutscene(path:String) {
		inCutscene = true;

		video = new MP4Handler();
		video.finishCallback = function() {
			if (dialogue != null) {
				normalDialogueIntro(db);
			}
			else {
				startCountdown();
			}
		}
		if (!path.contains("/"))
			video.playVideo(Paths.video(path));
		else
			video.playVideo(path);
	}

	function playOnEndCutscene(name:String) {
		inCutscene = true;

		video = new MP4Handler();
		video.finishCallback = function() {
			if (customSong == false)
				SONG = Song.loadFromJson(storyPlaylist[0].toLowerCase());
			else {
				SONG = Song.PEloadFromJson(storyPlaylist[0].toLowerCase() + dataFileDifficulty, storyPlaylist[0].toLowerCase());
			}
			LoadingState.loadAndSwitchState(new PlayState());
		}
		video.playVideo(Paths.video(name));
	}

	function schoolIntro(?dialogueBox:DialogueBox):Void {
		var black:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		black.scrollFactor.set();
		add(black);

		var red:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
		red.scrollFactor.set();
		
		var senpaiEvil:FlxSprite = new FlxSprite();
		if (stage.name == "schoolEvil") {
			senpaiEvil.frames = Paths.stageSparrow('senpaiCrazy');
			senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
			senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
			senpaiEvil.scrollFactor.set();
			senpaiEvil.updateHitbox();
			senpaiEvil.screenCenter();
		}

		if (SONG.song.toLowerCase() == 'roses' || SONG.song.toLowerCase() == 'thorns') {
			remove(black);

			if (SONG.song.toLowerCase() == 'thorns') {
				add(red);
			}
		}

		new FlxTimer().start(0.3, function(tmr:FlxTimer) {
			black.alpha -= 0.15;

			if (black.alpha > 0) {
				tmr.reset(0.3);
			}
			else {
				if (dialogueBox != null) {
					inCutscene = true;

					if (SONG.song.toLowerCase() == 'thorns') {
						add(senpaiEvil);
						senpaiEvil.alpha = 0;
						new FlxTimer().start(0.3, function(swagTimer:FlxTimer) {
							senpaiEvil.alpha += 0.15;
							if (senpaiEvil.alpha < 1) {
								swagTimer.reset();
							}
							else {
								senpaiEvil.animation.play('idle');
								FlxG.sound.play(Paths.sound('Senpai_Dies'), 1, false, null, true, function() {
									remove(senpaiEvil);
									remove(red);
									FlxG.camera.fade(FlxColor.WHITE, 0.01, true, function() {
										add(dialogueBox);
									}, true);
								});
								new FlxTimer().start(3.2, function(deadTime:FlxTimer) {
									FlxG.camera.fade(FlxColor.WHITE, 1.6, false);
								});
							}
						});
					}
					else {
						add(dialogueBox);
					}
				}
				else
					startCountdown();

				remove(black);
			}
		});
	}

	function normalDialogueIntro(?dialogueBox:DialogueBoxOg):Void {
		try {
			var black:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
			black.scrollFactor.set();
			add(black);

			new FlxTimer().start(0.3, function(tmr:FlxTimer) {
				black.alpha -= 0.15;

				if (black.alpha > 0) {
					tmr.reset(0.3);
				}
				else {
					if (dialogueBox != null) {
						inCutscene = true;
						add(dialogueBox);
					}
					else
						startCountdown();

					remove(black);
				}
			});
		}
		catch (err) {
			trace(err);
		}
	}

	var startTimer:FlxTimer;
	var perfectMode:Bool = false;

	function startCountdown():Void {
		inCutscene = false;

		generateStaticArrows(1); // bf
		generateStaticArrows(0); // dad

		talking = false;
		startedCountdown = true;
		Conductor.songPosition = 0;
		Conductor.songPosition -= Conductor.crochet * 5;

		var swagCounter:Int = 0;

		startTimer = new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer) {
			dad.dance();
			gf.dance();
			bf.playAnim('idle');

			var curNoteAsset:String = "default";

			var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
			introAssets.set('default', ['ready', "set", "go"]);
			introAssets.set('school', ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel']);
			introAssets.set('schoolEvil', ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel']);

			var introAlts:Array<String> = introAssets.get('default');
			var altSuffix:String = "";

			for (value in introAssets.keys()) {
				if (value == stage.name) {
					introAlts = introAssets.get(value);
					altSuffix = '-pixel';
				}
			}

			if (introAssets.exists(stage.name)) {
				curNoteAsset = stage.name;
			} 
			else {
				curNoteAsset = "default";
			}

			switch (swagCounter) {
				case 0:
					if (!selectedSongPosition) {
						healthBar.alpha = 1;
						healthBarBG.alpha = 1;
					}
					FlxG.sound.play(Paths.sound('intro3'), 0.6);
				case 1:
					if (curSong.toLowerCase() != "winter-horrorland") {
						if (!selectedSongPosition)
							iconP2.alpha = 1;
					}
					var ready:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[0], "shared"));
					ready.scrollFactor.set();
					ready.updateHitbox();

					if (stage.name.startsWith('school'))
						ready.setGraphicSize(Std.int(ready.width * daPixelZoom));

					ready.screenCenter();
					add(ready);
					FlxTween.tween(ready, {y: ready.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:flixel.tweens.FlxTween) {
							ready.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('intro2'), 0.6);
				case 2:
					if (!selectedSongPosition)
						iconP1.alpha = 1;
					var set:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[1], "shared"));
					set.scrollFactor.set();

					if (stage.name.startsWith('school'))
						set.setGraphicSize(Std.int(set.width * daPixelZoom));

					set.screenCenter();
					add(set);
					FlxTween.tween(set, {y: set.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:flixel.tweens.FlxTween) {
							set.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('intro1'), 0.6);
				case 3:
					if (!selectedSongPosition)
						scoreTxt.alpha = 1;
					var go:FlxSprite = new FlxSprite();
					trace(curNoteAsset);
					if (curNoteAsset == "default") {
						go.loadGraphic(Paths.image(introAlts[2], "shared"), true, 558, 430);
						go.animation.add("go", [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13], 48, false);
						go.animation.play("go");
						go.animation.finishCallback = function(h) {go.kill();};
					} else {
						go.loadGraphic(Paths.image(introAlts[2], "shared"));
					}
					go.scrollFactor.set();
					if (stage.name.startsWith('school'))
						go.setGraphicSize(Std.int(go.width * daPixelZoom));

					go.updateHitbox();
					go.screenCenter();
					add(go);

					if (curNoteAsset != "default") {
						FlxTween.tween(go, {y: go.y += 100, alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:flixel.tweens.FlxTween) {
								go.destroy();
							}
						});
					}
					
					FlxG.sound.play(Paths.sound('introGo'), 0.6);
				case 4:
					timeLeftText.alpha = 1;
			}

			swagCounter += 1;
			// generateSong('fresh');
		}, 5);
	}

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;
	static var customSong = false;

	function startSong():Void { 
		startingSong = false;

		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		if (!paused)
			if (FileSystem.exists(Paths.instNoLib(PlayState.SONG.song))) {
				FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 1, false);
			} else {
				FlxG.sound.playMusic(Sound.fromFile(Paths.PEinst(PlayState.SONG.song)), 1, false);
				customSong = true;
			}
		FlxG.sound.music.onComplete = endSong;
		vocals.play();

		#if desktop
		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;

		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC, true, songLength);
		#end

		if (selectedSongPosition) tp(songPositionCustom);
	}

	function tp(songPos:Float) {
		FlxG.sound.music.time = songPos;
		resyncVocals();
	}

	var debugNum:Int = 0;

	private function generateSong(dataPath:String):Void {
		// FlxG.log.add(ChartParser.parse());

		var songData = SONG;
		Conductor.changeBPM(songData.bpm);

		curSong = songData.song;

		if (SONG.needsVoices)
			if (FileSystem.exists(Paths.voicesNoLib(PlayState.SONG.song))) {
				vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
			} else {
				vocals = FlxG.sound.load(Sound.fromFile(Paths.PEvoices(PlayState.SONG.song)));
			}
		else
			vocals = new FlxSound();
		
		vocals.looped = false;

		FlxG.sound.list.add(vocals);

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		var playerCounter:Int = 0;

		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped

		accuracy = new Accuracy();
		
		for (section in noteData) {
			//var coolSection:Int = Std.int(section.lengthInSteps / 4);

			for (songNotes in section.sectionNotes) {
				var daNoteData:Int = Std.int(songNotes[1] % SONG.whichK);
				var daStrumTime:Float = songNotes[0];

				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes[1] >= SONG.whichK) {
					gottaHitNote = !section.mustHitSection;
				}

				var oldNote:Note;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;

				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote, false, songNotes[3], songNotes[4]);
				
				swagNote.sustainLength = songNotes[2];
				swagNote.scrollFactor.set(0, 0);

				var susLength:Float = swagNote.sustainLength;

				susLength = susLength / Conductor.stepCrochet;
				unspawnNotes.push(swagNote);

				for (susNote in 0...Math.floor(susLength)) {
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

					var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + Conductor.stepCrochet, daNoteData, oldNote, true);
					sustainNote.scrollFactor.set();
					unspawnNotes.push(sustainNote);

					sustainNote.mustPress = gottaHitNote;

					if (sustainNote.mustPress) sustainNote.x += FlxG.width / 2; // general offset

					if (sustainNote.isGoodNote) {
						if (sustainNote.mustPress) {
							if (playAs == "bf") {
								accuracy.addNote();
							}
						}
						else if (!sustainNote.mustPress && playAs == "dad") {
							accuracy.addNote();
						}
					}

					if (sustainNote.strumTime < songPositionCustom) {
						sustainNote.canBeMissed = true;
					}
				}

				swagNote.mustPress = gottaHitNote;

				if (swagNote.action.toLowerCase() == "change character") {
					var splicedValue = swagNote.actionValue.split(", ");
					Cache.cacheCharacter(splicedValue[0], splicedValue[1]);
				}
				if (swagNote.action.toLowerCase() == "change stage") {
					Cache.cacheStage(swagNote.actionValue);
				}

				if (swagNote.mustPress) swagNote.x += FlxG.width / 2; // general offset

				if (swagNote.isGoodNote) {
					if (swagNote.mustPress) {
						if (playAs == "bf") {
							accuracy.addNote();
						}
					}
					else if (!swagNote.mustPress && playAs == "dad") {
						accuracy.addNote();
					}
				}

				if (swagNote.strumTime < songPositionCustom) {
					swagNote.canBeMissed = true;
				}

			}
			daBeats += 1;
		}

		// trace(unspawnNotes.length);
		// playerCounter += 1;

		unspawnNotes.sort(sortByShit);

		generatedMusic = true;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int {
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	private function generateStaticArrows(player:Int):Void {
		for (i in 0...SONG.whichK) {
			var babyArrow:FlxSprite = new FlxSprite(0, 0);
			
			switch (SONG.whichK) {
				case 4:
					switch (stage.name) {
						case 'school' | 'schoolEvil':
							babyArrow.loadGraphic(Paths.image('pixelUI/arrows-pixels', "shared"), true, 17, 17);
							babyArrow.animation.add('green', [6]);
							babyArrow.animation.add('red', [7]);
							babyArrow.animation.add('blue', [5]);
							babyArrow.animation.add('purplel', [4]);
		
							babyArrow.setGraphicSize(Std.int(babyArrow.width * daPixelZoom));
							babyArrow.updateHitbox();
							babyArrow.antialiasing = false;
		
							switch (Math.abs(i)) {
								case 0:
									babyArrow.x += Note.getSwagWidth(SONG.whichK) * i;
									babyArrow.animation.add('static', [0]);
									babyArrow.animation.add('pressed', [4, 8], 12, false);
									babyArrow.animation.add('confirm', [12, 16], 24, false);
								case 1:
									babyArrow.x += Note.getSwagWidth(SONG.whichK) * i;
									babyArrow.animation.add('static', [1]);
									babyArrow.animation.add('pressed', [5, 9], 12, false);
									babyArrow.animation.add('confirm', [13, 17], 24, false);
								case 2:
									babyArrow.x += Note.getSwagWidth(SONG.whichK) * i;
									babyArrow.animation.add('static', [2]);
									babyArrow.animation.add('pressed', [6, 10], 12, false);
									babyArrow.animation.add('confirm', [14, 18], 12, false);
								case 3:
									babyArrow.x += Note.getSwagWidth(SONG.whichK) * i;
									babyArrow.animation.add('static', [3]);
									babyArrow.animation.add('pressed', [7, 11], 12, false);
									babyArrow.animation.add('confirm', [15, 19], 24, false);
							}
		
						default:
							babyArrow.frames = Paths.getSparrowAtlas('NOTE_assets');
							babyArrow.animation.addByPrefix('green', 'arrowUP');
							babyArrow.animation.addByPrefix('blue', 'arrowDOWN');
							babyArrow.animation.addByPrefix('purple', 'arrowLEFT');
							babyArrow.animation.addByPrefix('red', 'arrowRIGHT');
		
							babyArrow.antialiasing = true;
							babyArrow.setGraphicSize(Std.int(babyArrow.width * Note.sizeShit));
		
							switch (Math.abs(i)) {
								case 0:
									babyArrow.x += Note.getSwagWidth(SONG.whichK) * i;
									babyArrow.animation.addByPrefix('static', 'arrowLEFT');
									babyArrow.animation.addByPrefix('pressed', 'left press', 24, false);
									babyArrow.animation.addByPrefix('confirm', 'left confirm', 24, false);
								case 1:
									babyArrow.x += Note.getSwagWidth(SONG.whichK) * i;
									babyArrow.animation.addByPrefix('static', 'arrowDOWN');
									babyArrow.animation.addByPrefix('pressed', 'down press', 24, false);
									babyArrow.animation.addByPrefix('confirm', 'down confirm', 24, false);
								case 2:
									babyArrow.x += Note.getSwagWidth(SONG.whichK) * i;
									babyArrow.animation.addByPrefix('static', 'arrowUP');
									babyArrow.animation.addByPrefix('pressed', 'up press', 24, false);
									babyArrow.animation.addByPrefix('confirm', 'up confirm', 24, false);
								case 3:
									babyArrow.x += Note.getSwagWidth(SONG.whichK) * i;
									babyArrow.animation.addByPrefix('static', 'arrowRIGHT');
									babyArrow.animation.addByPrefix('pressed', 'right press', 24, false);
									babyArrow.animation.addByPrefix('confirm', 'right confirm', 24, false);
							}
					}
				case 5:
					switch (stage.name) {
						/*
						case 'school' | 'schoolEvil':
							babyArrow.loadGraphic(Paths.image('pixelUI/arrows-pixels', "shared"), true, 17, 17);
							babyArrow.animation.add('green', [6]);
							babyArrow.animation.add('red', [7]);
							babyArrow.animation.add('blue', [5]);
							babyArrow.animation.add('purplel', [4]);
		
							babyArrow.setGraphicSize(Std.int(babyArrow.width * daPixelZoom));
							babyArrow.updateHitbox();
							babyArrow.antialiasing = false;
		
							switch (Math.abs(i)) {
								case 0:
									babyArrow.x += Note.getSwagWidth(SONG.whichK) * 0;
									babyArrow.animation.add('static', [0]);
									babyArrow.animation.add('pressed', [4, 8], 12, false);
									babyArrow.animation.add('confirm', [12, 16], 24, false);
								case 1:
									babyArrow.x += Note.getSwagWidth(SONG.whichK) * 1;
									babyArrow.animation.add('static', [1]);
									babyArrow.animation.add('pressed', [5, 9], 12, false);
									babyArrow.animation.add('confirm', [13, 17], 24, false);
								case 2:
									babyArrow.x += Note.getSwagWidth(SONG.whichK) * 2;
									babyArrow.animation.add('static', [2]);
									babyArrow.animation.add('pressed', [6, 10], 12, false);
									babyArrow.animation.add('confirm', [14, 18], 12, false);
								case 3:
									babyArrow.x += Note.getSwagWidth(SONG.whichK) * 3;
									babyArrow.animation.add('static', [3]);
									babyArrow.animation.add('pressed', [7, 11], 12, false);
									babyArrow.animation.add('confirm', [15, 19], 24, false);
							}

						*/
		
						default:
							babyArrow.frames = Paths.getSparrowAtlas('NOTE_assets');
							babyArrow.animation.addByPrefix('green', 'arrowUP');
							babyArrow.animation.addByPrefix('blue', 'arrowDOWN');
							babyArrow.animation.addByPrefix('purple', 'arrowLEFT');
							babyArrow.animation.addByPrefix('red', 'arrowRIGHT');
							babyArrow.animation.addByPrefix('thing', 'arrowTHING');
		
							babyArrow.antialiasing = true;
							babyArrow.setGraphicSize(Std.int(babyArrow.width * Note.sizeShit));
		
							switch (Math.abs(i)) {
								case 0:
									babyArrow.x += Note.getSwagWidth(SONG.whichK) * Math.abs(i);
									babyArrow.animation.addByPrefix('static', 'arrowLEFT');
									babyArrow.animation.addByPrefix('pressed', 'left press', 24, false);
									babyArrow.animation.addByPrefix('confirm', 'left confirm', 24, false);
								case 1:
									babyArrow.x += Note.getSwagWidth(SONG.whichK) * Math.abs(i);
									babyArrow.animation.addByPrefix('static', 'arrowDOWN');
									babyArrow.animation.addByPrefix('pressed', 'down press', 24, false);
									babyArrow.animation.addByPrefix('confirm', 'down confirm', 24, false);
								case 2:
									babyArrow.x += Note.getSwagWidth(SONG.whichK) * Math.abs(i);
									babyArrow.animation.addByPrefix('static', 'arrowTHING');
									babyArrow.animation.addByPrefix('pressed', 'thing press', 24, false);
									babyArrow.animation.addByPrefix('confirm', 'thing confirm', 24, false);
								case 3:
									babyArrow.x += Note.getSwagWidth(SONG.whichK) * Math.abs(i);
									babyArrow.animation.addByPrefix('static', 'arrowUP');
									babyArrow.animation.addByPrefix('pressed', 'up press', 24, false);
									babyArrow.animation.addByPrefix('confirm', 'up confirm', 24, false);
								case 4:
									babyArrow.x += Note.getSwagWidth(SONG.whichK) * i;
									babyArrow.animation.addByPrefix('static', 'arrowRIGHT');
									babyArrow.animation.addByPrefix('pressed', 'right press', 24, false);
									babyArrow.animation.addByPrefix('confirm', 'right confirm', 24, false);
							}
					}
				case 6:
					switch (stage.name) {
						default:
							babyArrow.frames = Paths.getSparrowAtlas('NOTE_assets');
							babyArrow.animation.addByPrefix('green', 'arrowUP');
							babyArrow.animation.addByPrefix('blue', 'arrowDOWN');
							babyArrow.animation.addByPrefix('purple', 'arrowLEFT');
							babyArrow.animation.addByPrefix('red', 'arrowRIGHT');
		
							babyArrow.antialiasing = true;
							babyArrow.setGraphicSize(Std.int(babyArrow.width * Note.sizeShit));
		
							switch (Math.abs(i)) {
								case 0:
									babyArrow.x += Note.getSwagWidth(SONG.whichK) * i;
									babyArrow.animation.addByPrefix('static', 'arrowLEFT');
									babyArrow.animation.addByPrefix('pressed', 'left press', 24, false);
									babyArrow.animation.addByPrefix('confirm', 'left confirm', 24, false);
								case 1:
									babyArrow.x += Note.getSwagWidth(SONG.whichK) * i;
									babyArrow.animation.addByPrefix('static', 'arrowUP');
									babyArrow.animation.addByPrefix('pressed', 'up press', 24, false);
									babyArrow.animation.addByPrefix('confirm', 'up confirm', 24, false);
								case 2:
									babyArrow.x += Note.getSwagWidth(SONG.whichK) * i;
									babyArrow.animation.addByPrefix('static', 'arrowRIGHT');
									babyArrow.animation.addByPrefix('pressed', 'right press', 24, false);
									babyArrow.animation.addByPrefix('confirm', 'right confirm', 24, false);
								
								case 3:
									babyArrow.x += Note.getSwagWidth(SONG.whichK) * i;
									babyArrow.animation.addByPrefix('static', 'arrowLEFT');
									babyArrow.animation.addByPrefix('pressed', 'left press', 24, false);
									babyArrow.animation.addByPrefix('confirm', 'left confirm', 24, false);
								case 4:
									babyArrow.x += Note.getSwagWidth(SONG.whichK) * i;
									babyArrow.animation.addByPrefix('static', 'arrowDOWN');
									babyArrow.animation.addByPrefix('pressed', 'down press', 24, false);
									babyArrow.animation.addByPrefix('confirm', 'down confirm', 24, false);
								case 5:
									babyArrow.x += Note.getSwagWidth(SONG.whichK) * i;
									babyArrow.animation.addByPrefix('static', 'arrowRIGHT');
									babyArrow.animation.addByPrefix('pressed', 'right press', 24, false);
									babyArrow.animation.addByPrefix('confirm', 'right confirm', 24, false);
							}
					}
				case 7:
					switch (stage.name) {
						default:
							babyArrow.frames = Paths.getSparrowAtlas('NOTE_assets');
							babyArrow.animation.addByPrefix('green', 'arrowUP');
							babyArrow.animation.addByPrefix('blue', 'arrowDOWN');
							babyArrow.animation.addByPrefix('purple', 'arrowLEFT');
							babyArrow.animation.addByPrefix('red', 'arrowRIGHT');
							babyArrow.animation.addByPrefix('thing', 'arrowTHING');
		
							babyArrow.antialiasing = true;
							babyArrow.setGraphicSize(Std.int(babyArrow.width * Note.sizeShit));
		
							switch (Math.abs(i)) {
								case 0:
									babyArrow.x += Note.getSwagWidth(SONG.whichK) * i;
									babyArrow.animation.addByPrefix('static', 'arrowLEFT');
									babyArrow.animation.addByPrefix('pressed', 'left press', 24, false);
									babyArrow.animation.addByPrefix('confirm', 'left confirm', 24, false);
								case 1:
									babyArrow.x += Note.getSwagWidth(SONG.whichK) * i;
									babyArrow.animation.addByPrefix('static', 'arrowUP');
									babyArrow.animation.addByPrefix('pressed', 'up press', 24, false);
									babyArrow.animation.addByPrefix('confirm', 'up confirm', 24, false);
								case 2:
									babyArrow.x += Note.getSwagWidth(SONG.whichK) * i;
									babyArrow.animation.addByPrefix('static', 'arrowRIGHT');
									babyArrow.animation.addByPrefix('pressed', 'right press', 24, false);
									babyArrow.animation.addByPrefix('confirm', 'right confirm', 24, false);

								case 3:
									babyArrow.x += Note.getSwagWidth(SONG.whichK) * i;
									babyArrow.animation.addByPrefix('static', 'arrowTHING');
									babyArrow.animation.addByPrefix('pressed', 'thing press', 24, false);
									babyArrow.animation.addByPrefix('confirm', 'thing confirm', 24, false);
								
								case 4:
									babyArrow.x += Note.getSwagWidth(SONG.whichK) * i;
									babyArrow.animation.addByPrefix('static', 'arrowLEFT');
									babyArrow.animation.addByPrefix('pressed', 'left press', 24, false);
									babyArrow.animation.addByPrefix('confirm', 'left confirm', 24, false);
								case 5:
									babyArrow.x += Note.getSwagWidth(SONG.whichK) * i;
									babyArrow.animation.addByPrefix('static', 'arrowDOWN');
									babyArrow.animation.addByPrefix('pressed', 'down press', 24, false);
									babyArrow.animation.addByPrefix('confirm', 'down confirm', 24, false);
								case 6:
									babyArrow.x += Note.getSwagWidth(SONG.whichK) * i;
									babyArrow.animation.addByPrefix('static', 'arrowRIGHT');
									babyArrow.animation.addByPrefix('pressed', 'right press', 24, false);
									babyArrow.animation.addByPrefix('confirm', 'right confirm', 24, false);
							}
					}
				case 8:
					switch (stage.name) {
						default:
							babyArrow.frames = Paths.getSparrowAtlas('NOTE_assets');
							babyArrow.animation.addByPrefix('green', 'arrowUP');
							babyArrow.animation.addByPrefix('blue', 'arrowDOWN');
							babyArrow.animation.addByPrefix('purple', 'arrowLEFT');
							babyArrow.animation.addByPrefix('red', 'arrowRIGHT');
		
							babyArrow.antialiasing = true;
							babyArrow.setGraphicSize(Std.int(babyArrow.width * Note.sizeShit));
	
							switch (Math.abs(i)) {
								case 0:
									babyArrow.x += Note.getSwagWidth(SONG.whichK) * i;
									babyArrow.animation.addByPrefix('static', 'arrowLEFT');
									babyArrow.animation.addByPrefix('pressed', 'left press', 24, false);
									babyArrow.animation.addByPrefix('confirm', 'left confirm', 24, false);
								case 1:
									babyArrow.x += Note.getSwagWidth(SONG.whichK) * i;
									babyArrow.animation.addByPrefix('static', 'arrowDOWN');
									babyArrow.animation.addByPrefix('pressed', 'down press', 24, false);
									babyArrow.animation.addByPrefix('confirm', 'down confirm', 24, false);
								case 2:
									babyArrow.x += Note.getSwagWidth(SONG.whichK) * i;
									babyArrow.animation.addByPrefix('static', 'arrowUP');
									babyArrow.animation.addByPrefix('pressed', 'up press', 24, false);
									babyArrow.animation.addByPrefix('confirm', 'up confirm', 24, false);
								case 3:
									babyArrow.x += Note.getSwagWidth(SONG.whichK) * i;
									babyArrow.animation.addByPrefix('static', 'arrowRIGHT');
									babyArrow.animation.addByPrefix('pressed', 'right press', 24, false);
									babyArrow.animation.addByPrefix('confirm', 'right confirm', 24, false);
								case 4:
									babyArrow.x += Note.getSwagWidth(SONG.whichK) * i;
									babyArrow.animation.addByPrefix('static', 'arrowLEFT');
									babyArrow.animation.addByPrefix('pressed', 'left press', 24, false);
									babyArrow.animation.addByPrefix('confirm', 'left confirm', 24, false);
								case 5:
									babyArrow.x += Note.getSwagWidth(SONG.whichK) * i;
									babyArrow.animation.addByPrefix('static', 'arrowDOWN');
									babyArrow.animation.addByPrefix('pressed', 'down press', 24, false);
									babyArrow.animation.addByPrefix('confirm', 'down confirm', 24, false);
								case 6:
									babyArrow.x += Note.getSwagWidth(SONG.whichK) * i;
									babyArrow.animation.addByPrefix('static', 'arrowUP');
									babyArrow.animation.addByPrefix('pressed', 'up press', 24, false);
									babyArrow.animation.addByPrefix('confirm', 'up confirm', 24, false);
								case 7:
									babyArrow.x += Note.getSwagWidth(SONG.whichK) * i;
									babyArrow.animation.addByPrefix('static', 'arrowRIGHT');
									babyArrow.animation.addByPrefix('pressed', 'right press', 24, false);
									babyArrow.animation.addByPrefix('confirm', 'right confirm', 24, false);
							}
					}
				case 9:
					switch (stage.name) {
						default:
							babyArrow.frames = Paths.getSparrowAtlas('NOTE_assets');
							babyArrow.animation.addByPrefix('green', 'arrowUP');
							babyArrow.animation.addByPrefix('blue', 'arrowDOWN');
							babyArrow.animation.addByPrefix('purple', 'arrowLEFT');
							babyArrow.animation.addByPrefix('red', 'arrowRIGHT');
		
							babyArrow.antialiasing = true;
							babyArrow.setGraphicSize(Std.int(babyArrow.width * Note.sizeShit));
	
							switch (Math.abs(i)) {
								case 0:
									babyArrow.x += Note.getSwagWidth(SONG.whichK) * i;
									babyArrow.animation.addByPrefix('static', 'arrowLEFT');
									babyArrow.animation.addByPrefix('pressed', 'left press', 24, false);
									babyArrow.animation.addByPrefix('confirm', 'left confirm', 24, false);
								case 1:
									babyArrow.x += Note.getSwagWidth(SONG.whichK) * i;
									babyArrow.animation.addByPrefix('static', 'arrowDOWN');
									babyArrow.animation.addByPrefix('pressed', 'down press', 24, false);
									babyArrow.animation.addByPrefix('confirm', 'down confirm', 24, false);
								case 2:
									babyArrow.x += Note.getSwagWidth(SONG.whichK) * i;
									babyArrow.animation.addByPrefix('static', 'arrowUP');
									babyArrow.animation.addByPrefix('pressed', 'up press', 24, false);
									babyArrow.animation.addByPrefix('confirm', 'up confirm', 24, false);
								case 3:
									babyArrow.x += Note.getSwagWidth(SONG.whichK) * i;
									babyArrow.animation.addByPrefix('static', 'arrowRIGHT');
									babyArrow.animation.addByPrefix('pressed', 'right press', 24, false);
									babyArrow.animation.addByPrefix('confirm', 'right confirm', 24, false);
								case 4:
									babyArrow.x += Note.getSwagWidth(SONG.whichK) * i;
									babyArrow.animation.addByPrefix('static', 'arrowTHING');
									babyArrow.animation.addByPrefix('pressed', 'thing press', 24, false);
									babyArrow.animation.addByPrefix('confirm', 'thing confirm', 24, false);
								case 5:
									babyArrow.x += Note.getSwagWidth(SONG.whichK) * i;
									babyArrow.animation.addByPrefix('static', 'arrowLEFT');
									babyArrow.animation.addByPrefix('pressed', 'left press', 24, false);
									babyArrow.animation.addByPrefix('confirm', 'left confirm', 24, false);
								case 6:
									babyArrow.x += Note.getSwagWidth(SONG.whichK) * i;
									babyArrow.animation.addByPrefix('static', 'arrowDOWN');
									babyArrow.animation.addByPrefix('pressed', 'down press', 24, false);
									babyArrow.animation.addByPrefix('confirm', 'down confirm', 24, false);
								case 7:
									babyArrow.x += Note.getSwagWidth(SONG.whichK) * i;
									babyArrow.animation.addByPrefix('static', 'arrowUP');
									babyArrow.animation.addByPrefix('pressed', 'up press', 24, false);
									babyArrow.animation.addByPrefix('confirm', 'up confirm', 24, false);
								case 8:
									babyArrow.x += Note.getSwagWidth(SONG.whichK) * i;
									babyArrow.animation.addByPrefix('static', 'arrowRIGHT');
									babyArrow.animation.addByPrefix('pressed', 'right press', 24, false);
									babyArrow.animation.addByPrefix('confirm', 'right confirm', 24, false);
							}
					}
			}

			if (player == 1)
				babyArrow.y = bfStrumLine[i][1];
			else
				babyArrow.y = dadStrumLine[i][1];

			babyArrow.updateHitbox();
			babyArrow.scrollFactor.set();

			if (!isStoryMode) {
				babyArrow.y -= 10;
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			}

			babyArrow.ID = i;

			if (player == 1) {
				bfStrumLineNotes.add(babyArrow);
			} else {
				dadStrumLineNotes.add(babyArrow);
			}

			babyArrow.animation.play('static');
			babyArrow.x += 50;
			//babyArrow.x += ((FlxG.width / 2) * playerMultiplier);

			strumLineNotes.add(babyArrow);
		}
		var daCharStrumLineNotes = player == 1 ? bfStrumLineNotes : dadStrumLineNotes;
		var playerMultiplier = player;
		if (PlayState.SONG.swapBfGui) {
			if (player == 0) {
				playerMultiplier = 1;
			}
			else if (player == 1) {
				playerMultiplier = 0;
			}
		}
		var space = 25;
		if (playerMultiplier == 1) {
			daCharStrumLineNotes.x = ((FlxG.width - daCharStrumLineNotes.width) - 100) - space;
		}
		else if (playerMultiplier == 0) {
			daCharStrumLineNotes.x = space;
		}
	}

	public static function tweenCamZoom(z0om:Float, cam:String = "game"):Void {
		if (cam == "game") {
			FlxTween.num(camZoom, z0om, (Conductor.stepCrochet * 4 / 1000), null, f -> camZoom = f);
		}
		else if (cam == "hud") {
			FlxTween.num(camHUD.zoom, z0om, (Conductor.stepCrochet * 4 / 1000), null, f -> camHUD.zoom = f);
		}
	}

	public static function tweenCamPos(x:Float, y:Float):Void {
		FlxTween.num(camFollow.y, x, (Conductor.stepCrochet * 16 / 1000), null, f -> camFollow.x = f);
		FlxTween.num(camFollow.y, y, (Conductor.stepCrochet * 16 / 1000), null, f -> camFollow.y = f);
	}

	function spawnRollingTankmen() {
		if (!isTankRolling) {
			stage.tankRolling.revive();
			isTankRolling = true;
			stage.tankRolling.x = -390;
			stage.tankRolling.y = 500;
			stage.tankRolling.angle = 0;
			FlxTween.angle(stage.tankRolling, stage.tankRolling.angle, stage.tankRolling.angle + 35, 15);
			FlxTween.quadMotion(stage.tankRolling, stage.tankRolling.x, stage.tankRolling.y, 250, -5, 1520, stage.tankRolling.y - 100, 15, true, {
				onComplete: function(twn:flixel.tweens.FlxTween) {
					isTankRolling = false;
					stage.tankRolling.kill();
				}
			});
		}
	}

	override function closeSubState() {
		if (openSettings && canPause && startedCountdown) {
			persistentUpdate = false;
			persistentDraw = true;
			setPaused(true);
			openSubState(new OptionsSubState(true));
		}
		else if (openAchievements && canPause && startedCountdown) {
			persistentUpdate = false;
			persistentDraw = true;
			setPaused(true);
			openSubState(new AchievementsSubState());
		}
		else {
			if (paused) {
				if (FlxG.sound.music != null && !startingSong) {
					resyncVocals();
				}

				if (!startTimer.finished)
					startTimer.active = true;
				setPaused(false);

				#if cpp
				if (startTimer.finished) {
					DiscordClient.changePresence(detailsText
						+ " "
						+ SONG.song
						+ " ("
						+ storyDifficultyText
						+ ")",
						"Score: "
						+ songScore
						+ " | Misses: "
						+ misses, iconRPC, true, songLength
						- Conductor.songPosition);
				}
				else {
					DiscordClient.changePresence(detailsText + " " + SONG.song + " (" + storyDifficultyText + ")",
						"Score: " + songScore + " | Misses: " + misses, iconRPC);
				}
				#end
			}
		}

		super.closeSubState();
	}

	override public function onFocus():Void {
		#if cpp
		if (health > 0 && !paused) {
			if (Conductor.songPosition > 0.0) {
				DiscordClient.changePresence(detailsText
					+ " "
					+ SONG.song
					+ " ("
					+ storyDifficultyText
					+ ")", "Score: "
					+ songScore
					+ " | Misses: "
					+ misses,
					iconRPC, true, songLength
					- Conductor.songPosition);
			}
			else {
				DiscordClient.changePresence(detailsText + " " + SONG.song + " (" + storyDifficultyText + ")", "Score: " + songScore + " | Misses: " + misses,
					iconRPC);
			}
		}
		#end

		super.onFocus();
	}

	override public function onFocusLost():Void {
		/*

		wanted to use this but it gives null exceptions for some reason

		#if cpp
		if (health > 0 && !paused) {
			DiscordClient.changePresence(detailsPausedText + " " + SONG.song + " (" + storyDifficultyText + ")", "", iconRPC);
		}
		#end

		if (!inCutscene && !paused) {
			persistentUpdate = false;
			persistentDraw = true;
			paused = true;
	
			if (FlxG.random.bool(0.1)) {
				FlxG.switchState(new GitarooPause());
			}
			else
				openSubState(new PauseSubState(bf.getScreenPosition().x, bf.getScreenPosition().y));
	
			#if desktop
			DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconRPC);
			#end
		}
		*/

		super.onFocusLost();

		if (isMultiplayer)
			FlxG.autoPause = false;
		else
			FlxG.autoPause = true;
	}

	function resyncVocals():Void {
		vocals.pause();

		FlxG.sound.music.play();
		Conductor.songPosition = FlxG.sound.music.time;
		vocals.time = Conductor.songPosition;
		vocals.play();
	}

	private var paused:Bool = false;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;

	function camCenter():Void {
		camFollow.setPosition(gf.x + (gf.width / 2), gf.y + (gf.height / 2));
		FlxG.camera.zoom = camZoom - 0.2;
	}

	private var godMode = false;

	override public function update(elapsed:Float) {

		if (isMultiplayer) {
			if (Lobby.isHost) {
				if (songScore > Lobby.player2.score) {
					iconCrown.x = iconP1.x + (iconP1.width / 4);
					iconCrown.y = iconP1.y - 40;
				} else {
					iconCrown.x = iconP2.x + (iconP2.width / 4);
					iconCrown.y = iconP2.y - 40;
				}
			} else {
				if (songScore > Lobby.player1.score) {
					iconCrown.x = iconP1.x + (iconP1.width / 4);
					iconCrown.y = iconP1.y - 40;
				} else {
					iconCrown.x = iconP2.x + (iconP2.width / 4);
					iconCrown.y = iconP2.y - 40;
				}
			}
		}

		bgDimness.alpha = Options.bgDimness;

		#if debug
		if (FlxG.keys.justPressed.F6) {
			if (godMode == false) {
				godMode = true;
			} else {
				godMode = false;
			}
		}
		// useful for making custom stages, changed to stage editor
		if (debugStageAsset != null) {
			if (FlxG.keys.pressed.SHIFT) {
				if (FlxG.mouse.wheel > 0) {
					debugStageAssetSize += 0.05;
					debugStageAsset.setGraphicSize(Std.int(debugStageAsset.width * debugStageAssetSize));
				}
				else if (FlxG.mouse.wheel < 0) {
					debugStageAssetSize -= 0.05;
					debugStageAsset.setGraphicSize(Std.int(debugStageAsset.width * debugStageAssetSize));
				}
				if (FlxG.keys.justPressed.UP) {
					debugStageAsset.y -= 10;
				}
				else if (FlxG.keys.justPressed.DOWN) {
					debugStageAsset.y += 10;
				}
				else if (FlxG.keys.justPressed.LEFT) {
					debugStageAsset.x -= 10;
				}
				else if (FlxG.keys.justPressed.RIGHT) {
					debugStageAsset.x += 10;
				}
				health = 1.0;
				camHUD.visible = false;
				addSubtitle(debugStageAsset.x + " | " + debugStageAsset.y + " || " + debugStageAssetSize);
			}
			else {
				camHUD.visible = true;
			}
		}
		#end

		if (godMode == true) {
			health = 1.0;
		}

		if (FlxG.keys.justPressed.NINE) {
			if (iconP1.actualChar == 'bf-old')
				iconP1.setChar(SONG.player1, true);
			else
				iconP1.setChar('bf-old', true);
		}

		switch (stage.name) {
			case 'philly':
				if (trainMoving) {
					trainFrameTiming += elapsed;

					if (trainFrameTiming >= 1 / 24) {
						updateTrainPos();
						trainFrameTiming = 0;
					}
				}
				// phillyCityLights.members[curLight].alpha -= (Conductor.crochet / 1000) * FlxG.elapsed;
		}

		if (!paused) {
			pauseBG.visible = false;
		}
		
		super.update(elapsed);

		if (curBeat == 25 && curSong.toLowerCase() == "winter-horrorland")
			iconP2.alpha = 1;

		//TIME LEFT!
		if (FlxG.sound.music != null)
			timeLeftText.text = FlxStringUtil.formatTime(Math.round(FlxG.sound.music.length / 1000) - Math.round(FlxG.sound.music.time / 1000));

		if (!isMultiplayer) {
			if (songScore > Highscore.getScore(SONG.song, storyDifficulty) && Highscore.getScore(SONG.song, storyDifficulty) != 0) {
				scoreTxt.applyMarkup("$NEW Score:" + FlxStringUtil.formatMoney(songScore, false) + "$ | Accuracy:" + accuracy.getAccuracyPercent() + " | Misses:" + misses,
					[new FlxTextFormatMarkerPair(new FlxTextFormat(FlxColor.YELLOW), "$")]);
			}
			else {
				scoreTxt.text = "Score:" + FlxStringUtil.formatMoney(songScore, false) + " | Accuracy:" + accuracy.getAccuracyPercent() + " | Misses:" + misses;
			}
		} else {
			if (Lobby.isHost)
				scoreTxt.text = 
					"Score:" + FlxStringUtil.formatMoney(Lobby.player2.score, false) + " | Accuracy:" + Lobby.player2.accuracy + " | Misses:" + Lobby.player2.misses + "       " +
					"Score:" + FlxStringUtil.formatMoney(songScore, false) + " | Accuracy:" + accuracy.getAccuracyPercent() + " | Misses:" + misses
				;
			else {
				scoreTxt.text = 
					"Score:" + FlxStringUtil.formatMoney(songScore, false) + " | Accuracy:" + accuracy.getAccuracyPercent() + " | Misses:" + misses + "       " +
					"Score:" + FlxStringUtil.formatMoney(Lobby.player1.score, false) + " | Accuracy:" + Lobby.player1.accuracy + " | Misses:" + Lobby.player1.misses
				;
			}
		}

		try {
			scoreTxt.screenCenter(X);
		} catch (exc) {
			trace(exc);
			//how the fuck it throws exceptions
		}

		if (Controls.check(PAUSE, JUST_PRESSED) && startedCountdown && canPause && !isMultiplayer) {
			pauseGame();
		}

		if (FlxG.keys.justPressed.SEVEN) {
			FlxG.switchState(new EditorSelector());
		}

		// FlxG.watch.addQuick('VOL', vocals.amplitudeLeft);
		// FlxG.watch.addQuick('VOLRight', vocals.amplitudeRight);

		iconP1.setGraphicSize(Std.int(FlxMath.lerp(135, iconP1.width, 1 - elapsed * 23)));
		iconP2.setGraphicSize(Std.int(FlxMath.lerp(135, iconP2.width, 1 - elapsed * 23)));

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		var iconOffset:Int = 18;

		if (healthBar.fillDirection == LEFT_TO_RIGHT) {
			if (SONG.swapBfGui) {
				iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 0, 100) * 0.01) - iconOffset);
				iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 0, 100) * 0.01)) - (iconP2.width - iconOffset);
			}
			else {
				iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 0, 100) * 0.01) - iconOffset);
				iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 0, 100) * 0.01)) - (iconP2.width - iconOffset);
			}
		}
		else {
			if (SONG.swapBfGui) {
				iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01) - iconOffset);
				iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (iconP2.width - iconOffset);
			} else {
				iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01) - iconOffset);
				iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (iconP2.width - iconOffset);
			}
		}

		if (health > 2)
			health = 2;

		try {
			if (playAs == "bf") {
				if (healthBar.percent < 20)
					iconP1.animation.curAnim.curFrame = 1;
				else
					iconP1.animation.curAnim.curFrame = 0;
		
				if (healthBar.percent > 80)
					iconP2.animation.curAnim.curFrame = 1;
				else
					iconP2.animation.curAnim.curFrame = 0;
			} 
			else {
				if (healthBar.percent < 20)
					iconP2.animation.curAnim.curFrame = 1;
				else
					iconP2.animation.curAnim.curFrame = 0;
		
				if (healthBar.percent > 80)
					iconP1.animation.curAnim.curFrame = 1;
				else
					iconP1.animation.curAnim.curFrame = 0;
			}
		} catch (exc) {
			// trace(exc.details());
		}

		/* if (FlxG.keys.justPressed.NINE)
		    FlxG.switchState(new Charting()); */

		if (startingSong) {
			if (startedCountdown) {
				Conductor.songPosition += FlxG.elapsed * 1000;
				if (Conductor.songPosition >= 0)
					startSong();
			}
		}
		else {
			// Conductor.songPosition = FlxG.sound.music.time;
			Conductor.songPosition += FlxG.elapsed * 1000;

			if (!paused) {
				songTime += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;

				// Interpolation type beat
				if (Conductor.lastSongPos != Conductor.songPosition) {
					songTime = (songTime + Conductor.songPosition) / 2;
					Conductor.lastSongPos = Conductor.songPosition;
					// Conductor.songPosition += FlxG.elapsed * 1000;
					// trace('MISSED FRAME');
				}
			}

			// Conductor.lastSongPos = FlxG.sound.music.time;
		}

		luaSetVariable("curSection", PlayState.SONG.notes[Std.int(curStep / 16)]);

		var fixedCumSpeed = CoolUtil.bound(elapsed * 3.2);

		if (generatedMusic && PlayState.SONG.notes[Std.int(curStep / 16)] != null) {
			if (PlayState.SONG.notes[Std.int(curStep / 16)].centerCamera) {
				camCenter();
			}
			else {
				if (curBeat % 4 == 0) {
					// trace(PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection);
				}
	
				if (PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection) {
					//BF TURN
					var daNewCameraPos = [
						bf.getMidpoint().x - 100,
						bf.getMidpoint().y - 100
					];
					if (bf.config.get("camera_offset") != null) {
						var arr:Array<Int> = bf.config.get("camera_offset");
						daNewCameraPos[0] += arr[0];
						daNewCameraPos[1] += arr[1];
					}
	
					switch (stage.name) {
						case 'limo':
							daNewCameraPos[0] = bf.getMidpoint().x - 300;
						case 'mall':
							daNewCameraPos[1] = bf.getMidpoint().y - 200;
						case 'school':
							daNewCameraPos[0] = bf.getMidpoint().x - 200;
							daNewCameraPos[1] = bf.getMidpoint().y - 200;
						case 'schoolEvil':
							daNewCameraPos[0] = bf.getMidpoint().x - 200;
							daNewCameraPos[1] = bf.getMidpoint().y - 200;
					}

					if (camFollow.x != daNewCameraPos[0] && camFollow.y != daNewCameraPos[1]) {
						if (!(camZooming && curBeat >= 168 && curBeat < 200 && curSong.toLowerCase() == 'milf')) {
							FlxG.camera.zoom = camZoom;
						}

						camFollow.setPosition(FlxMath.lerp(camFollow.x, daNewCameraPos[0], fixedCumSpeed), FlxMath.lerp(camFollow.y, daNewCameraPos[1], fixedCumSpeed));
	
						if (SONG.song.toLowerCase() == 'tutorial') {
							tweenCamZoom(1);
						}

						luaCall("onCameraMove", ["bf"]);
					}
				}
				else {
					//DAD TURN
					var daNewCameraPos = [
						dad.getMidpoint().x + 150,
						dad.getMidpoint().y - 100
					];
					if (dad.config.get("camera_offset") != null) {
						var arr:Array<Int> = dad.config.get("camera_offset");
						daNewCameraPos[0] += arr[0];
						daNewCameraPos[1] += arr[1];
					}
					
					switch (dad.curCharacter) {
						case 'mom-car', 'mom':
							daNewCameraPos[1] = dad.getMidpoint().y + 40;
						case 'senpai':
							daNewCameraPos[0] = dad.getMidpoint().x - 100;
							daNewCameraPos[1] = dad.getMidpoint().y - 430;
						case 'senpai-angry':
							daNewCameraPos[0] = dad.getMidpoint().x - 100;
							daNewCameraPos[1] = dad.getMidpoint().y - 430;
					}

					if (camFollow.x != daNewCameraPos[0] && camFollow.y != daNewCameraPos[1]) {
						if (!(camZooming && curBeat >= 168 && curBeat < 200 && curSong.toLowerCase() == 'milf')) {
							FlxG.camera.zoom = camZoom;
						}

						camFollow.setPosition(FlxMath.lerp(camFollow.x, daNewCameraPos[0], fixedCumSpeed), FlxMath.lerp(camFollow.y, daNewCameraPos[1], fixedCumSpeed));
						// camFollow.setPosition(lucky.getMidpoint().x - 120, lucky.getMidpoint().y + 210);
		
						if (SONG.song.toLowerCase() == 'tutorial') {
							//idk how to fix tutorial camera
							tweenCamZoom(1.3);
						}

						luaCall("onCameraMove", ["dad"]);
					}
				}
			}
		}

		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);
		FlxG.watch.addQuick("notes", notes.length);

		luaSetVariable("curBeat", curBeat);
		luaSetVariable("curStep", curStep);

		switch (curSong) {
			case "Fresh":
				switch (curBeat) {
					case 16:
						camZooming = true;
						gfSpeed = 2;
					case 48:
						gfSpeed = 1;
					case 80:
						gfSpeed = 2;
					case 112:
						gfSpeed = 1;
					case 163:
						// FlxG.sound.music.stop();
						// FlxG.switchState(new TitleState());
				}
			case "Bopeebo":
				switch (curBeat) {
					case 128, 129, 130:
						vocals.volume = 0;
						// FlxG.sound.music.stop();
						// FlxG.switchState(new PlayState());
				}
		}
		// better streaming of shit

		/*
		// RESET = Quick Game Over Screen
		if (Controls.RESET) {
			health = 0;
			trace("RESET = True");
		}

		// CHEAT = brandon's a pussy
		if (Controls.CHEAT) {
			health += 1;
			trace("User is cheating!");
		}
		*/

		if (health <= 0 && !isMultiplayer && !selectedSongPosition) {
			if (playAs == "bf") {
				bf.stunned = true;
			}
			else {
				dad.stunned = true;
			}

			persistentUpdate = false;
			persistentDraw = false;
			setPaused(true);

			vocals.stop();
			FlxG.sound.music.stop();

			if (playAs == "bf") {
				openSubState(new GameOverSubstate(bf.getScreenPosition().x, bf.getScreenPosition().y));
			}
			else {
				openSubState(new GameOverSubstate(dad.getScreenPosition().x, dad.getScreenPosition().y));
			}

			#if desktop
			// Game Over doesn't get his own variable because it's only used here
			DiscordClient.changePresence("Game Over - " + detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC);
			#end
		}

		if (unspawnNotes[0] != null) {
			if (unspawnNotes[0].strumTime - Conductor.songPosition < 1500) {
				var dunceNote:Note = unspawnNotes[0];
				notes.add(dunceNote);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}
		
		if (generatedMusic) {
			notes.forEachAlive(function(daNote:Note) {
				if (daNote.noteData == -1) {
					daNote.alpha = 0;
				}

				if (daNote.wasInSongPosition) {
					if (daNote.action != null && daNote.noteData == -1) {
						ActionNoteOnGhostPressed(daNote);
						removeNote(daNote);
					}
				}
				if (daNote.noteData == -1) return;

				var strumNote:FlxSprite = new FlxSprite();
				if (daNote.mustPress) {
					bfStrumLineNotes.forEach(function(spr:FlxSprite) {
						if (Math.abs(daNote.noteData) == spr.ID) {
							bfStrumLine[daNote.noteData][1] = spr.y;
							strumNote = spr;
							return;
						}
					});
				}
				else {
					dadStrumLineNotes.forEach(function(spr:FlxSprite) {
						if (Math.abs(daNote.noteData) == spr.ID) {
							dadStrumLine[daNote.noteData][1] = spr.y;
							strumNote = spr;
							return;
						}
					});
				}

				var noteStrumLinePos:Array<Float>;
				if (daNote.mustPress)
					noteStrumLinePos = bfStrumLine[daNote.noteData];
				else
					noteStrumLinePos = dadStrumLine[daNote.noteData];

				if (daNote.y > FlxG.height) {
					daNote.active = false;
					daNote.visible = false;
				}
				else {
					daNote.visible = true;
					daNote.active = true;
				}

				daNote.x = strumNote.x;
				
				/*
				if (daNote.isSustainNote)
					daNote.x = strumNote.x + (strumNote.width / 2.9);
				*/

				if (downscroll)
					daNote.y = (noteStrumLinePos[1] + (Conductor.songPosition - daNote.strumTime) * (0.45 * FlxMath.roundDecimal(curSpeed, 2)));
				else
					daNote.y = (noteStrumLinePos[1] - (Conductor.songPosition - daNote.strumTime) * (0.45 * FlxMath.roundDecimal(curSpeed, 2)));

				if (daNote.isSustainNote) {
					if (daNote.y + daNote.offset.y <= noteStrumLinePos[1] + Note.getSwagWidth(SONG.whichK) / 2
						&& (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit)))) {

							if (downscroll) {
								var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
								swagRect.height = ((strumNote.y + (Note.getSwagWidth(SONG.whichK) / 2)) - daNote.y) / daNote.scale.y;
								swagRect.y = daNote.frameHeight - swagRect.height;
	
								daNote.clipRect = swagRect;
							}
							else {
								var swagRect = new FlxRect(0, noteStrumLinePos[1] + Note.getSwagWidth(SONG.whichK) / 2 - daNote.y, daNote.width * 2, daNote.height * 2);
								swagRect.height -= swagRect.y;
								swagRect.y /= daNote.scale.y;
			
								daNote.clipRect = swagRect;
							}
					}
				}

				if (!daNote.mustPress && daNote.wasGoodHit && whichCharacterToBotFC == "dad") {
					if (SONG.song != 'Tutorial')
						camZooming = true;

					var altAnim:Bool = false;

					if (SONG.notes[Math.floor(curStep / 16)] != null) {
						if (SONG.notes[Math.floor(curStep / 16)].altAnim)
							altAnim = true;
					}

					if (daNote.noteData != -1) {
						dad.playAnim(getAnimName(Std.int(Math.abs(daNote.noteData)), false, altAnim), true);
					}

					if (dad.curCharacter == "tankman") {
						if (curSong == "Ugh") {
							if (curStep == 60 || curStep == 444 || curStep == 524 || curStep == 828) {
								dad.playAnim("ugh");
							}
						}
					}

					dad.holdTimer = 0;

					if (SONG.needsVoices)
						vocals.volume = 1;

					luaCall("onNotePress", ["player2", daNote.toArray()]);

					strumPlayAnim(daNote.noteData, "dad", "confirm");
					
					if (noteTimers.exists(daNote.noteData)) {
						noteTimers.get(daNote.noteData).cancel();
					}
					var timer = new FlxTimer().start(0.3 / curSpeed, function(tmr:FlxTimer) {
						if (!paused) {
							strumPlayAnim(daNote.noteData, "dad", "static");
						}
					});
					noteTimers.set(daNote.noteData, timer);

					removeNote(daNote);
				}

				if (daNote.mustPress && daNote.wasInSongPosition && whichCharacterToBotFC == "bf") {
					if (SONG.song != 'Tutorial')
						camZooming = true;

					var altAnim:Bool = false;

					if (SONG.notes[Math.floor(curStep / 16)] != null) {
						if (SONG.notes[Math.floor(curStep / 16)].altAnim)
							altAnim = true;
					}

					if (daNote.noteData != -1) {
						bf.playAnim(getAnimName(Std.int(Math.abs(daNote.noteData)), false, altAnim), true);
					}

					luaCall("onNotePress", ["player2", daNote.toArray()]);

					bf.holdTimer = 0;

					if (SONG.needsVoices)
						vocals.volume = 1;

					strumPlayAnim(daNote.noteData, "bf", "confirm");
					
					if (noteTimers.exists(daNote.noteData)) {
						noteTimers.get(daNote.noteData).cancel();
					}
					var timer = new FlxTimer().start(0.3 / curSpeed, function(tmr:FlxTimer) {
						if (!paused) {
							strumPlayAnim(daNote.noteData, "bf", "static");
						}
					});
					noteTimers.set(daNote.noteData, timer);

					removeNote(daNote);
				}

				// WIP interpolation shit? Need to fix the pause issue
				// daNote.y = (strumLine.y - (songTime - daNote.strumTime) * (0.45 * curSpeed));

				var curStrumLine:Array<Float>;

				if (playAs == "bf")
					curStrumLine = bfStrumLine[daNote.noteData];
				else
					curStrumLine = dadStrumLine[daNote.noteData];

				var missZone = 520 / curSpeed;

				var isInMissZone = daNote.y <= curStrumLine[1] - missZone;
				if (downscroll) isInMissZone = daNote.y >= curStrumLine[1] + missZone;

				if (isInMissZone) {
					if (!daNote.wasGoodHit) {
						if (!daNote.canBeMissed) {
							vocals.volume = 0;
							noteMiss(daNote.noteData, true, daNote);
						}
						daNote.active = false;
						daNote.visible = false;
						removeNote(daNote);
					}
				}
				
				/*
				if (!(selectedSongPosition && daNote.strumTime < Conductor.songPosition - Conductor.safeZoneOffset)) {
					if (isInMissZone && daNote.tooLate && !daNote.wasGoodHit) {
						trace("missed a note");
						if (!daNote.canBeMissed) {
							vocals.volume = 0;
							noteMiss(daNote.noteData, true, daNote);
						}
						daNote.active = false;
						daNote.visible = false;
						removeNote(daNote);
					}
				}
				*/

				//added this statement because for some reason sustain notes were still in "notes" so it caused lag
				if (daNote.clipRect != null && daNote.clipRect.height < 0) {
					removeNote(daNote);
				}

				if (daNote.wasGoodHitButt && SONG.song == "Stress") {
					peecoStressOnArrowShoot(daNote);
				}
			});
		}

		if (!inCutscene) {
			keyShit();
		}

		if (camZooming) {
			FlxG.camera.zoom = FlxMath.lerp(camZoom, FlxG.camera.zoom, 0.95);
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, 0.95);
		}

		#if debug
		if (!isMultiplayer)
			if (FlxG.keys.justPressed.ONE)
				endSong();
		#end

		luaSetVariable("camFollowX", camFollow.x);
		luaSetVariable("camFollowY", camFollow.y);

		//can cause crashes
		luaCall("onUpdate", [elapsed]);
	}

	var noteTimers:Map<Int, FlxTimer>;

	public function removeNote(note:Note) {
		note.kill();
		notes.remove(note, true);
		note.destroy();
	}
	public static function addSubtitle(text:String) {
		if (text != "") {
			sub.alpha = 1;
			sub_bg.alpha = 0.5;

			sub.text = text;
			sub.scrollFactor.set();
			sub.screenCenter(X);
			sub.y = (FlxG.height * 0.9) - 135;

			sub_bg.scrollFactor.set();
			sub_bg.x = sub.x - 5;
			sub_bg.y = sub.y - 5;
			sub_bg.makeGraphic(sub.frameWidth + 10, sub.frameHeight + 10, FlxColor.BLACK);
		}
		else {
			sub.alpha = 0;
			sub_bg.alpha = 0;
		}
		// Timer.delay(sub.destroy, 5 * 1000);
	}

	function luaClose() {
		if (lua != null) {
			lua.close();
		}
	}

	function endSong():Void {
		luaCall("onEndSong");
		luaClose();
		canPause = false;

		timeLeftText.alpha = 0.0;

		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		
		if (SONG.validScore) {
			#if !switch
			Highscore.saveScore(SONG.song, songScore, storyDifficulty);
			#end
		}

		if (isMultiplayer) {
			FlxG.switchState(new Lobby());
		}
		else if (isStoryMode) {
			campaignScore += songScore;

			storyPlaylist.remove(storyPlaylist[0]);

			if (storyPlaylist.length <= 0) {
				FlxG.sound.playMusic(Paths.music('freakyMenu'));

				transIn = FlxTransitionableState.defaultTransIn;
				transOut = FlxTransitionableState.defaultTransOut;
				
				StoryMenuState.setWeekUnlocked(storyWeek, true);

				if (SONG.validScore) {
					Highscore.saveWeekScore(storyWeek, campaignScore, storyDifficulty);
				}

				FlxG.switchState(new StoryMenuState());

				/*
				// if ()
				StoryMenuState.weekUnlocked[Std.int(Math.min(storyWeek + 1, StoryMenuState.weekUnlocked.length - 1))] = true;

				if (SONG.validScore) {
					Highscore.saveWeekScore(storyWeek, campaignScore, storyDifficulty);
				}

				FlxG.save.data.weekUnlocked = StoryMenuState.weekUnlocked;
				FlxG.save.flush();
				*/
				
			}
			else {
				if (storyDifficulty == 0)
					dataFileDifficulty = '-easy';

				if (storyDifficulty == 2)
					dataFileDifficulty = '-hard';

				trace('LOADING NEXT SONG');
				trace(PlayState.storyPlaylist[0].toLowerCase() + dataFileDifficulty);

				if (SONG.song.toLowerCase() == 'eggnog') {
					var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
						-FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
					blackShit.scrollFactor.set();
					add(blackShit);
					camHUD.visible = false;

					FlxG.sound.play(Paths.sound('Lights_Shut_off'));
				}

				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;
				prevCamFollow = camFollow;

				if (!CoolUtil.isCustomWeek(storyWeek))
					PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + dataFileDifficulty, PlayState.storyPlaylist[0]);
				else
					PlayState.SONG = Song.PEloadFromJson(PlayState.storyPlaylist[0].toLowerCase() + dataFileDifficulty, PlayState.storyPlaylist[0].toLowerCase());
				FlxG.sound.music.stop();

				LoadingState.loadAndSwitchState(new PlayState());
			}
		}
		else {
			trace('WENT BACK TO FREEPLAY??');
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
			Conductor.changeBPM(102);
			FlxG.switchState(new FreeplayState());
		}
	}

	var endingSong:Bool = false;

	private function spawnSplashNote(whaNote:Note) {
		var splash = new Splash(whaNote);

		splash.scrollFactor.set();
		splash.cameras = [camHUD];

		splash.setGraphicSize(Std.int(splash.width * (Note.sizeShit + 0.3)));
		splash.updateHitbox();

		switch (SONG.whichK) {
			case 4:
				switch (whaNote.noteData) {
					case 0:
						splash.play(SplashColor.LEFT);
					case 1:
						splash.play(SplashColor.DOWN);
					case 2: 
						splash.play(SplashColor.UP);
					case 3:
						splash.play(SplashColor.RIGHT);
				}
			case 5:
				switch (whaNote.noteData) {
					case 0:
						splash.play(SplashColor.LEFT);
					case 1:
						splash.play(SplashColor.DOWN);
					case 2:
						splash.play(SplashColor.THING);
					case 3: 
						splash.play(SplashColor.UP);
					case 4:
						splash.play(SplashColor.RIGHT);
				}
			case 6:
				switch (whaNote.noteData) {
					case 0:
						splash.play(SplashColor.LEFT);
					case 1:
						splash.play(SplashColor.UP);
					case 2:
						splash.play(SplashColor.RIGHT);
					case 3:
						splash.play(SplashColor.LEFT);
					case 4:
						splash.play(SplashColor.DOWN);
					case 5:
						splash.play(SplashColor.RIGHT);
				}
			case 7:
				switch (whaNote.noteData) {
					case 0:
						splash.play(SplashColor.LEFT);
					case 1:
						splash.play(SplashColor.UP);
					case 2:
						splash.play(SplashColor.RIGHT);
					case 3:
						splash.play(SplashColor.THING);
					case 4:
						splash.play(SplashColor.LEFT);
					case 5:
						splash.play(SplashColor.DOWN);
					case 6:
						splash.play(SplashColor.RIGHT);
				}
			case 8:
				switch (whaNote.noteData) {
					case 0:
						splash.play(SplashColor.LEFT);
					case 1:
						splash.play(SplashColor.DOWN);
					case 2: 
						splash.play(SplashColor.UP);
					case 3:
						splash.play(SplashColor.RIGHT);
					case 4:
						splash.play(SplashColor.LEFT);
					case 5:
						splash.play(SplashColor.DOWN);
					case 6: 
						splash.play(SplashColor.UP);
					case 7:
						splash.play(SplashColor.RIGHT);
				}
			case 9:
				switch (whaNote.noteData) {
					case 0:
						splash.play(SplashColor.LEFT);
					case 1:
						splash.play(SplashColor.DOWN);
					case 2: 
						splash.play(SplashColor.UP);
					case 3:
						splash.play(SplashColor.RIGHT);
					case 4:
						splash.play(SplashColor.THING);
					case 5:
						splash.play(SplashColor.LEFT);
					case 6:
						splash.play(SplashColor.DOWN);
					case 7: 
						splash.play(SplashColor.UP);
					case 8:
						splash.play(SplashColor.RIGHT);
				}
		}

		switch (SONG.whichK) {
			case 4, 5:
				splash.offset.set(
					whaNote.width - (whaNote.width / 4), 
					whaNote.width
				);
			case 6, 7:
				splash.offset.set(
					whaNote.width + (whaNote.width / 6), 
					whaNote.width + (whaNote.width / (6 / (SONG.whichK == 6 ? 1.5 : 2.0)))
				);
			case 8, 9:
				splash.offset.set(
					whaNote.width + (whaNote.width * 1.4 / (SONG.whichK == 9 ? 2.0 : 3.0)), 
					whaNote.width + (whaNote.width * 1.4 / (SONG.whichK == 9 ? 1.5 : 2.0))
				);
		}

		splash.updatePos();

		add(splash);
	}

	private function popUpScore(daNote:Note):Void {
		if (daNote.isGoodNote) {
			var strumtime = daNote.strumTime;

			var noteDiff:Float = Math.abs(strumtime - Conductor.songPosition);
			// bf.playAnim('hey');
			vocals.volume = 1;
	
			var placement:String = Std.string(combo);
	
			var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
			coolText.screenCenter();
			coolText.x = FlxG.width * 0.55;
			//
	
			var rating:FlxSprite = new FlxSprite();
	
			// addSubtitle(noteDiff + " | " + Conductor.safeZoneOffset);
			
			var score:Int = 50;
			var daRating:String = "shit";

			if (SONG.song == "Stress") {
				peecoStressOnArrowShoot(daNote);
			}

			/*
			if (noteDiff > (curSpeed * 200)) {
				daRating = 'shit';
				score = 50;
			}
			*/
	
			if (noteDiff > Conductor.safeZoneOffset * 0.4) {
				daRating = 'shit';
				score = 50;
			}
			else if (noteDiff > Conductor.safeZoneOffset * 0.3) {
				daRating = 'bad';
				score = 100;
			}
			else if (noteDiff > Conductor.safeZoneOffset * 0.15) {
				daRating = 'good';
				score = 200;
			}
			else {
				daRating = 'sick';
				score = 350;
				spawnSplashNote(daNote);
			}
			switch (daRating) {
				case 'shit':
					//cry about it
					health -= 0.023;
				case 'bad':
					health += 0.003;
				case 'good', 'sick':
					health += 0.023;
			}
			//new Notification('${Conductor.safeZoneOffset} | $noteDiff', FlxColor.WHITE).show();

			accuracy.judge(daRating);
	
			/*
				if (noteDiff > Conductor.safeZoneOffset * 0.9) {
					daRating = 'shit';
					score = 50;
				}
				else if (noteDiff > Conductor.safeZoneOffset * 0.75) {
					daRating = 'bad';
					score = 100;
				}
				else if (noteDiff > Conductor.safeZoneOffset * 0.2) {
					daRating = 'good';
					score = 200;
				}
			 */
	
			songScore += score;
			sendMultiplayerMessage('SCO::$songScore');
	
			/* if (combo > 60)
					daRating = 'sick';
				else if (combo > 12)
					daRating = 'good'
				else if (combo > 4)
					daRating = 'bad';
			 */
	
			var pixelShitPart1:String = "";
			var pixelShitPart2:String = '';
	
			if (stage.name.startsWith('school')) {
				pixelShitPart1 = 'pixelUI/';
				pixelShitPart2 = '-pixel';
			}
	
			rating.loadGraphic(Paths.image(pixelShitPart1 + daRating + pixelShitPart2));
			rating.screenCenter();
			rating.x = coolText.x - 40;
			rating.y -= 60;
			rating.acceleration.y = 550;
			rating.velocity.y -= FlxG.random.int(140, 175);
			rating.velocity.x -= FlxG.random.int(0, 10);
	
			var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'combo' + pixelShitPart2));
			comboSpr.screenCenter();
			comboSpr.x = coolText.x;
			comboSpr.acceleration.y = 600;
			comboSpr.velocity.y -= 150;
	
			comboSpr.velocity.x += FlxG.random.int(1, 10);
			add(rating);
	
			if (!stage.name.startsWith('school')) {
				rating.setGraphicSize(Std.int(rating.width * 0.7));
				rating.antialiasing = true;
				comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
				comboSpr.antialiasing = true;
			}
			else {
				rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.7));
				comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * 0.7));
			}
	
			comboSpr.updateHitbox();
			rating.updateHitbox();
	
			var seperatedScore:Array<Int> = [];
	
			seperatedScore.push(Math.floor(combo / 100));
			seperatedScore.push(Math.floor((combo - (seperatedScore[0] * 100)) / 10));
			seperatedScore.push(combo % 10);
	
			var daLoop:Int = 0;
			for (i in seperatedScore) {
				var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'num' + Std.int(i) + pixelShitPart2));
				numScore.screenCenter();
				numScore.x = coolText.x + (43 * daLoop) - 90;
				numScore.y += 80;
	
				if (!stage.name.startsWith('school')) {
					numScore.antialiasing = true;
					numScore.setGraphicSize(Std.int(numScore.width * 0.5));
				}
				else {
					numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));
				}
				numScore.updateHitbox();
	
				numScore.acceleration.y = FlxG.random.int(200, 300);
				numScore.velocity.y -= FlxG.random.int(140, 160);
				numScore.velocity.x = FlxG.random.float(-5, 5);
	
				if (combo >= 10 || combo == 0)
					add(numScore);
	
				FlxTween.tween(numScore, {alpha: 0}, 0.2, {
					onComplete: function(tween:flixel.tweens.FlxTween) {
						numScore.destroy();
					},
					startDelay: Conductor.crochet * 0.002
				});
	
				daLoop++;
			}
			/* 
				trace(combo);
				trace(seperatedScore);
			 */
	
			coolText.text = Std.string(seperatedScore);
			// add(coolText);
	
			FlxTween.tween(rating, {alpha: 0}, 0.2, {
				startDelay: Conductor.crochet * 0.001
			});
	
			FlxTween.tween(comboSpr, {alpha: 0}, 0.2, {
				onComplete: function(tween:flixel.tweens.FlxTween) {
					coolText.destroy();
					comboSpr.destroy();
	
					rating.destroy();
				},
				startDelay: Conductor.crochet * 0.001
			});
	
			curSection += 1;
			combo += 1;
			if (combo % 50 == 0) {
				if (gf.curCharacter != "pico-speaker") {
					gf.playAnim('cheer', true);
				}
			}
		}
	}

	function isKeyPressedForNoteData(noteData:Int = 0, ?pressType:FlxInputState = PRESSED):Bool {
		switch (SONG.whichK) {
			case 4:
				switch noteData {
					case 0:
						return Controls.check(LEFT, pressType);
					case 1:
						return Controls.check(DOWN, pressType);
					case 2:
						return Controls.check(UP, pressType);
					case 3:
						return Controls.check(RIGHT, pressType);
				}
			case 5:
				switch noteData {
					case 0:
						return Controls.check(LEFT, pressType);
					case 1:
						return Controls.check(DOWN, pressType);
					case 2:
						switch (pressType) {
							case JUST_PRESSED:
								return FlxG.keys.justPressed.SPACE;
							case JUST_RELEASED:
								return FlxG.keys.justReleased.SPACE;
							default:
								return FlxG.keys.pressed.SPACE;
						}
					case 3:
						return Controls.check(UP, pressType);
					case 4:
						return Controls.check(RIGHT, pressType);
				}
			case 6:
				switch noteData {
					case 0:
						switch (pressType) {
							case JUST_PRESSED:
								return FlxG.keys.justPressed.S;
							case JUST_RELEASED:
								return FlxG.keys.justReleased.S;
							default:
								return FlxG.keys.pressed.S;
						}
					case 1:
						switch (pressType) {
							case JUST_PRESSED:
								return FlxG.keys.justPressed.D;
							case JUST_RELEASED:
								return FlxG.keys.justReleased.D;
							default:
								return FlxG.keys.pressed.D;
						}
					case 2:
						switch (pressType) {
							case JUST_PRESSED:
								return FlxG.keys.justPressed.F;
							case JUST_RELEASED:
								return FlxG.keys.justReleased.F;
							default:
								return FlxG.keys.pressed.F;
						}
					case 3:
						switch (pressType) {
							case JUST_PRESSED:
								return FlxG.keys.justPressed.J;
							case JUST_RELEASED:
								return FlxG.keys.justReleased.J;
							default:
								return FlxG.keys.pressed.J;
						}
					case 4:
						switch (pressType) {
							case JUST_PRESSED:
								return FlxG.keys.justPressed.K;
							case JUST_RELEASED:
								return FlxG.keys.justReleased.K;
							default:
								return FlxG.keys.pressed.K;
						}
					case 5:
						switch (pressType) {
							case JUST_PRESSED:
								return FlxG.keys.justPressed.L;
							case JUST_RELEASED:
								return FlxG.keys.justReleased.L;
							default:
								return FlxG.keys.pressed.L;
						}
				}
			case 7:
				switch noteData {
					case 0:
						switch (pressType) {
							case JUST_PRESSED:
								return FlxG.keys.justPressed.S;
							case JUST_RELEASED:
								return FlxG.keys.justReleased.S;
							default:
								return FlxG.keys.pressed.S;
						}
					case 1:
						switch (pressType) {
							case JUST_PRESSED:
								return FlxG.keys.justPressed.D;
							case JUST_RELEASED:
								return FlxG.keys.justReleased.D;
							default:
								return FlxG.keys.pressed.D;
						}
					case 2:
						switch (pressType) {
							case JUST_PRESSED:
								return FlxG.keys.justPressed.F;
							case JUST_RELEASED:
								return FlxG.keys.justReleased.F;
							default:
								return FlxG.keys.pressed.F;
						}
					case 3:
						switch (pressType) {
							case JUST_PRESSED:
								return FlxG.keys.justPressed.SPACE;
							case JUST_RELEASED:
								return FlxG.keys.justReleased.SPACE;
							default:
								return FlxG.keys.pressed.SPACE;
						}
					case 4:
						switch (pressType) {
							case JUST_PRESSED:
								return FlxG.keys.justPressed.J;
							case JUST_RELEASED:
								return FlxG.keys.justReleased.J;
							default:
								return FlxG.keys.pressed.J;
						}
					case 5:
						switch (pressType) {
							case JUST_PRESSED:
								return FlxG.keys.justPressed.K;
							case JUST_RELEASED:
								return FlxG.keys.justReleased.K;
							default:
								return FlxG.keys.pressed.K;
						}
					case 6:
						switch (pressType) {
							case JUST_PRESSED:
								return FlxG.keys.justPressed.L;
							case JUST_RELEASED:
								return FlxG.keys.justReleased.L;
							default:
								return FlxG.keys.pressed.L;
						}
				}
			case 8:
				switch noteData {
					case 0:
						switch (pressType) {
							case JUST_PRESSED:
								return FlxG.keys.justPressed.A;
							case JUST_RELEASED:
								return FlxG.keys.justReleased.A;
							default:
								return FlxG.keys.pressed.A;
						}
					case 1:
						switch (pressType) {
							case JUST_PRESSED:
								return FlxG.keys.justPressed.S;
							case JUST_RELEASED:
								return FlxG.keys.justReleased.S;
							default:
								return FlxG.keys.pressed.S;
						}
					case 2:
						switch (pressType) {
							case JUST_PRESSED:
								return FlxG.keys.justPressed.D;
							case JUST_RELEASED:
								return FlxG.keys.justReleased.D;
							default:
								return FlxG.keys.pressed.D;
						}
					case 3:
						switch (pressType) {
							case JUST_PRESSED:
								return FlxG.keys.justPressed.F;
							case JUST_RELEASED:
								return FlxG.keys.justReleased.F;
							default:
								return FlxG.keys.pressed.F;
						}
					case 4:
						switch (pressType) {
							case JUST_PRESSED:
								return FlxG.keys.justPressed.H;
							case JUST_RELEASED:
								return FlxG.keys.justReleased.H;
							default:
								return FlxG.keys.pressed.H;
						}
					case 5:
						switch (pressType) {
							case JUST_PRESSED:
								return FlxG.keys.justPressed.J;
							case JUST_RELEASED:
								return FlxG.keys.justReleased.J;
							default:
								return FlxG.keys.pressed.J;
						}
					case 6:
						switch (pressType) {
							case JUST_PRESSED:
								return FlxG.keys.justPressed.K;
							case JUST_RELEASED:
								return FlxG.keys.justReleased.K;
							default:
								return FlxG.keys.pressed.K;
						}
					case 7:
						switch (pressType) {
							case JUST_PRESSED:
								return FlxG.keys.justPressed.L;
							case JUST_RELEASED:
								return FlxG.keys.justReleased.L;
							default:
								return FlxG.keys.pressed.L;
						}
				}
			case 9:
				switch noteData {
					case 0:
						switch (pressType) {
							case JUST_PRESSED:
								return FlxG.keys.justPressed.A;
							case JUST_RELEASED:
								return FlxG.keys.justReleased.A;
							default:
								return FlxG.keys.pressed.A;
						}
					case 1:
						switch (pressType) {
							case JUST_PRESSED:
								return FlxG.keys.justPressed.S;
							case JUST_RELEASED:
								return FlxG.keys.justReleased.S;
							default:
								return FlxG.keys.pressed.S;
						}
					case 2:
						switch (pressType) {
							case JUST_PRESSED:
								return FlxG.keys.justPressed.D;
							case JUST_RELEASED:
								return FlxG.keys.justReleased.D;
							default:
								return FlxG.keys.pressed.D;
						}
					case 3:
						switch (pressType) {
							case JUST_PRESSED:
								return FlxG.keys.justPressed.F;
							case JUST_RELEASED:
								return FlxG.keys.justReleased.F;
							default:
								return FlxG.keys.pressed.F;
						}
					case 4:
						switch (pressType) {
							case JUST_PRESSED:
								return FlxG.keys.justPressed.SPACE;
							case JUST_RELEASED:
								return FlxG.keys.justReleased.SPACE;
							default:
								return FlxG.keys.pressed.SPACE;
						}
					case 5:
						switch (pressType) {
							case JUST_PRESSED:
								return FlxG.keys.justPressed.H;
							case JUST_RELEASED:
								return FlxG.keys.justReleased.H;
							default:
								return FlxG.keys.pressed.H;
						}
					case 6:
						switch (pressType) {
							case JUST_PRESSED:
								return FlxG.keys.justPressed.J;
							case JUST_RELEASED:
								return FlxG.keys.justReleased.J;
							default:
								return FlxG.keys.pressed.J;
						}
					case 7:
						switch (pressType) {
							case JUST_PRESSED:
								return FlxG.keys.justPressed.K;
							case JUST_RELEASED:
								return FlxG.keys.justReleased.K;
							default:
								return FlxG.keys.pressed.K;
						}
					case 8:
						switch (pressType) {
							case JUST_PRESSED:
								return FlxG.keys.justPressed.L;
							case JUST_RELEASED:
								return FlxG.keys.justReleased.L;
							default:
								return FlxG.keys.pressed.L;
						}
				}
		}
		return false;
	}

	function isAnyNoteKeyPressed(?pressType:FlxInputState = PRESSED) {
		var controlArray:Array<Bool> = [];
		for (index in 0...SONG.whichK) {
			controlArray.push(isKeyPressedForNoteData(index, pressType));
		}
		return controlArray.contains(true);
	}

	var noteHoldTime = new Map<Int, Float>();

	function isSpamming() {
		if (Options.disableSpamChecker) {
			return false;
		}
		if (blockSpamChecker)
			return false;
		var justPressedArr = [];
		for (index in 0...SONG.whichK) {
			justPressedArr.push(false);
			if (noteHoldTime.get(index) <= 0.4 && noteHoldTime.get(index) != 0)
				justPressedArr[index] = true;
		}
		return !justPressedArr.contains(false);
	}

	private function keyShit():Void {
		for (index in 0...SONG.whichK) {
			if (!isKeyPressedForNoteData(index, PRESSED))
				noteHoldTime.set(index, 0);
			else
				if (noteHoldTime != null) {
					noteHoldTime.set(index, noteHoldTime.get(index) + 1 * FlxG.elapsed);
				}
				else
					noteHoldTime.set(index, 1);
		}
		var charStunned = false;
		if (playAs == "bf") {
			charStunned = bf.stunned;
		} else {
			charStunned = dad.stunned;
		}
		if (isAnyNoteKeyPressed(JUST_PRESSED) && !charStunned && generatedMusic) {
			if (playAs == "bf") {
				bf.holdTimer = 0;
			} else {
				dad.holdTimer = 0;
			}

			var possibleNotes:Array<Note> = [];
			var possibleNoteDatas:Array<Bool> = [];

			for (index in 0...SONG.whichK) {
				possibleNoteDatas.push(false);
			}

			var ignoreList:Array<Int> = [];

			notes.forEachAlive(function(daNote:Note) {
				if (playAs == "bf") {
					if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit) {
						// the sorting probably doesn't need to be in here? who cares lol
						possibleNoteDatas[daNote.noteData] = true;
						possibleNotes.push(daNote);
						possibleNotes.sort((a, b) -> Std.int(a.strumTime - b.strumTime));
	
						ignoreList.push(daNote.noteData);
					}
				} else {
					if (daNote.canBeHit && !daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit) {
						// the sorting probably doesn't need to be in here? who cares lol
						possibleNoteDatas[daNote.noteData] = true;
						possibleNotes.push(daNote);
						possibleNotes.sort((a, b) -> Std.int(a.strumTime - b.strumTime));
	
						ignoreList.push(daNote.noteData);
					}
				}
			});

			var truePossibleNoteDatas:Array<Bool> = [];

			for (k in possibleNoteDatas)
				if (k == true)
					truePossibleNoteDatas.push(k);

			if (truePossibleNoteDatas.length == SONG.whichK) {
				blockSpamChecker = true;
				new FlxTimer().start(1, function(tmr:FlxTimer) {
					blockSpamChecker = false;
				});
			}

			if (!isSpamming()) {
				if (possibleNotes.length > 0) {
					var daNote = possibleNotes[0];
	
					/*
					if (perfectMode)
						noteCheck(true, daNote);
					*/
	
					// Jump notes
					if (possibleNotes.length >= 2) {
						if (possibleNotes[0].strumTime == possibleNotes[1].strumTime) {
							for (coolNote in possibleNotes) {
								if (isKeyPressedForNoteData(coolNote.noteData, JUST_PRESSED))
									goodNoteHit(coolNote, null, false);
								else {
									var inIgnoreList:Bool = false;
									for (shit in 0...ignoreList.length) {
										if (isKeyPressedForNoteData(ignoreList[shit]))
											inIgnoreList = true;
									}
									if (!inIgnoreList) {
										badNoteCheck();
									}
								}
							}
						}
						else if (possibleNotes[0].noteData == possibleNotes[1].noteData) {
							noteCheck(isKeyPressedForNoteData(daNote.noteData, JUST_PRESSED), daNote);
						}
						else {
							for (coolNote in possibleNotes) {
								noteCheck(isKeyPressedForNoteData(coolNote.noteData, JUST_PRESSED), coolNote);
							}
						}
					}
					else // regular notes?
					{
						noteCheck(isKeyPressedForNoteData(daNote.noteData, JUST_PRESSED), daNote);
					}
				}
				else {
					badNoteCheck();
				}
			}
			else if (isSpamming()) {
				if (possibleNotes.length != 0) {
					health -= 0.15;
				}
			}
		}

		if (isAnyNoteKeyPressed() && generatedMusic) {
			notes.forEachAlive(function(daNote:Note) {
				if (playAs == "bf") {
					if (daNote.canBeHit && daNote.mustPress && daNote.isSustainNote) {
						if (isKeyPressedForNoteData(daNote.noteData)) {
							goodNoteHit(daNote, null, false);
						}
					}
				} else {
					if (daNote.canBeHit && !daNote.mustPress && daNote.isSustainNote) {
						if (isKeyPressedForNoteData(daNote.noteData)) {
							goodNoteHit(daNote, null, false);
						}
					}
				}
				if (daNote.tooLate && !daNote.wasGoodHit) {
					if (isKeyPressedForNoteData(daNote.noteData, JUST_PRESSED)) {
						goodNoteHit(daNote, null, false);
					}
				}
			});
		}

		
		if (bf.holdTimer > Conductor.stepCrochet * 4 * 0.001 && !isAnyNoteKeyPressed()) {
			if (bf.animation.curAnim.name.startsWith('sing') && !bf.animation.curAnim.name.endsWith('miss')) {
				bf.playAnim('idle');
			}
		}
		if (playAs == "dad") {
			if (dad.holdTimer > Conductor.stepCrochet * 4 * 0.001 && !isAnyNoteKeyPressed()) {
				if (dad.animation.curAnim.name.startsWith('sing') && !dad.animation.curAnim.name.endsWith('miss')) {
					dad.playAnim('idle');
				}
			}
		}

		if (playAs == "bf") {
			bfStrumLineNotes.forEach(function(spr:FlxSprite) {
				if (isKeyPressedForNoteData(spr.ID, JUST_PRESSED) && spr.animation.curAnim.name != 'confirm') {
					strumPlayAnim(spr.ID, "bf", "pressed");
					sendMultiplayerMessage("SNP::" + spr.ID);
				}
				if (isKeyPressedForNoteData(spr.ID, JUST_RELEASED)) {
					strumPlayAnim(spr.ID, "bf", "static");
					sendMultiplayerMessage("SNR::" + spr.ID);
				}
			});
		} else {
			dadStrumLineNotes.forEach(function(spr:FlxSprite) {
				if (isKeyPressedForNoteData(spr.ID, JUST_PRESSED) && spr.animation.curAnim.name != 'confirm') {
					strumPlayAnim(spr.ID, "dad", "pressed");
					sendMultiplayerMessage("SNP::" + spr.ID);
				}
				if (isKeyPressedForNoteData(spr.ID, JUST_RELEASED)) {
					strumPlayAnim(spr.ID, "dad", "static");
					sendMultiplayerMessage("SNR::" + spr.ID);
				}
			});
		}
	}

	public function sendMultiplayerMessage(d:Dynamic) {
		if (isMultiplayer)
			if (!Lobby.isHost)
				Lobby.client.sendString(Std.string(d));
			else
				Lobby.server.sendStringToCurClient(Std.string(d));
	}

	function noteMiss(direction:Int = 1, tooLate:Bool = false, ?daNote:Note = null):Void {
		var charStunned = false;
		if (playAs == "bf") {
			charStunned = bf.stunned;
		} else {
			charStunned = dad.stunned;
		}

		var ignore = false;

		if (daNote == null) {
			ignore = false;
		}
		else if (daNote != null && daNote.canBeMissed) {
			ignore = true;
		}

		if (!ignore) {
			if (daNote != null) {
				if (!daNote.isSustainNote) {
					accuracy.judge("miss");
				} else {
					accuracy.judge("missSus");
				}
			}

			misses += 1;
			combo = 0;
			songScore -= 10;
	
			health -= 0.04;
			if (tooLate) health -= 0.025;
	
			if (!charStunned) {
				if (combo > 5 && gf.animOffsets.exists('sad')) {
					gf.playAnim('sad');
				}
	
				FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
				// FlxG.sound.play(Paths.sound('missnote1'), 1, false);
				// FlxG.log.add('played imss note');
				
				if (playAs == "bf") {
					bf.playAnim(getAnimName(direction, true), true);

					bf.stunned = true;

					// get stunned for 2 seconds
					new FlxTimer().start(2 / 60, function(tmr:FlxTimer) {
						bf.stunned = false;
					});
				}
				else {
					dad.playAnim(getAnimName(direction, true), true);

					dad.stunned = true;

					// get stunned for 2 seconds
					new FlxTimer().start(2 / 60, function(tmr:FlxTimer) {
						dad.stunned = false;
					});
				}
			}
		}
		sendMultiplayerMessage('MISN::${misses}');
	}

	function getAnimName(noteData:Int, ?miss:Bool = false, ?alt:Bool = false) {
		var suffix = "";
		if (miss) {
			suffix += "miss";
		}
		if (alt) {
			suffix += "-alt";
		}
		switch (SONG.whichK) {
			case 4:
				switch (noteData) {
					case 0:
						return 'singLEFT$suffix';
					case 1:
						return 'singDOWN$suffix';
					case 2:
						return 'singUP$suffix';
					case 3:
						return 'singRIGHT$suffix';
				}
			case 5:
				switch (noteData) {
					case 0:
						return 'singLEFT$suffix';
					case 1:
						return 'singDOWN$suffix';
					case 2:
						return 'singDOWN$suffix';
					case 3:
						return 'singUP$suffix';
					case 4:
						return 'singRIGHT$suffix';
				}
			case 6:
				switch (noteData) {
					case 0:
						return 'singLEFT$suffix';
					case 1:
						return 'singUP$suffix';
					case 2:
						return 'singRIGHT$suffix';
					case 3:
						return 'singLEFT$suffix';
					case 4:
						return 'singDOWN$suffix';
					case 5:
						return 'singRIGHT$suffix';
				}
			case 7:
				switch (noteData) {
					case 0:
						return 'singLEFT$suffix';
					case 1:
						return 'singUP$suffix';
					case 2:
						return 'singRIGHT$suffix';
					case 3:
						return 'singDOWN$suffix';
					case 4:
						return 'singLEFT$suffix';
					case 5:
						return 'singDOWN$suffix';
					case 6:
						return 'singRIGHT$suffix';
				}
			case 8:
				switch (noteData) {
					case 0:
						return 'singLEFT$suffix';
					case 1:
						return 'singDOWN$suffix';
					case 2:
						return 'singUP$suffix';
					case 3:
						return 'singRIGHT$suffix';
					case 4:
						return 'singLEFT$suffix';
					case 5:
						return 'singDOWN$suffix';
					case 6:
						return 'singUP$suffix';
					case 7:
						return 'singRIGHT$suffix';
				}
			case 9:
				switch (noteData) {
					case 0:
						return 'singLEFT$suffix';
					case 1:
						return 'singDOWN$suffix';
					case 2:
						return 'singUP$suffix';
					case 3:
						return 'singRIGHT$suffix';
					case 4:
						return 'singDOWN$suffix';
					case 5:
						return 'singLEFT$suffix';
					case 6:
						return 'singDOWN$suffix';
					case 7:
						return 'singUP$suffix';
					case 8:
						return 'singRIGHT$suffix';
				}
		}
		return null;
	}

	function badNoteCheck(?withNote:Bool = false) {
		// just double pasting this shit cuz fuk u
		// REDO THIS SYSTEM!

		//added withNote variable because it fucked up ghostTapping miss animations when the accuracy was worse than sick

		var whichAnimationToPlay = null;

		for (index in 0...SONG.whichK) {
			if (isKeyPressedForNoteData(index))
				if (!Options.ghostTapping)
					noteMiss(index);
				else if (!withNote)
					whichAnimationToPlay = getAnimName(index, true);
		}

		if (whichAnimationToPlay != null) {
			if (playAs == "bf") {
				bf.playAnim(whichAnimationToPlay, true);
			} else {
				dad.playAnim(whichAnimationToPlay, true);
			}
		}
	}

	function noteCheck(keyP:Bool, note:Note):Void {
		if (keyP)
			goodNoteHit(note, null, false);
		else {
			badNoteCheck(true);
		}
	}

	public function multiplayerNoteHit(noteDatas:Note, ?noteHitAsDad:Bool = null) {
		var note:Note = null;
		notes.forEachAlive(function(daNote:Note) {
			if (daNote.strumTime == noteDatas.strumTime && daNote.noteData == noteDatas.noteData && daNote.mustPress == !noteHitAsDad) {
				note = daNote;
			}
		});

		if (note != null) {
			if (noteHitAsDad) {
				dad.playAnim(getAnimName(note.noteData), true);
				
				strumPlayAnim(note.noteData, "dad", 'confirm');
			}
			else {
				bf.playAnim(getAnimName(note.noteData), true);
				
				strumPlayAnim(note.noteData, "bf", 'confirm');
			}

			note.wasGoodHit = true;
			vocals.volume = 1;

			removeNote(note);
		}
	}

	public function goodNoteHit(noteDatas:Note, ?noteHitAsDad:Bool = null, ?searchForNote:Bool = false):Void {
		var note:Note = null;
		if (searchForNote) {
			if (noteHitAsDad == null) {
				if (playAs == "dad") {
					noteHitAsDad = true;
				} else {
					noteHitAsDad = false;
				}
			}
			notes.forEachAlive(function(daNote:Note) {
				if (daNote.strumTime == noteDatas.strumTime && daNote.noteData == noteDatas.noteData && daNote.mustPress == !noteHitAsDad) {
					note = daNote;
				}
			});
		} else {
			note = noteDatas;
		}

		if (noteHitAsDad == null) {
			if (playAs == "bf") {
				noteHitAsDad = false;
			} else {
				noteHitAsDad = true;
			}
		}

		if (!note.wasGoodHit) {
			if (note.isSustainNote) {
				health += 0.0065;
			}
			if (noteHitAsDad) {
				dad.playAnim(getAnimName(note.noteData), true);
				
				strumPlayAnim(note.noteData, "dad", 'confirm');
			}
			else {
				bf.playAnim(getAnimName(note.noteData), true);
				
				strumPlayAnim(note.noteData, "bf", 'confirm');
			}

			note.wasGoodHit = true;
			vocals.volume = 1;

			if (!note.isSustainNote) {
				popUpScore(note);
				sendMultiplayerMessage("NP::" + note.strumTime + "::" + note.noteData);
				ActionNoteonPressed(note);

				removeNote(note);
			}

			luaCall("onNotePress", ["player1", note.toArray()]);
		}
	}

	function startDiscordRPCTimer() {
		new FlxTimer().start(5, function(timer:FlxTimer) {
			#if cpp
			if (health > 0 && !paused) {
				DiscordClient.changePresence(
					detailsText + " " + SONG.song + " (" + storyDifficultyText + ")", 

					"Score: " + songScore + " | Misses: " + misses,
					iconRPC, true,
					songLength - Conductor.songPosition);
			}
			#end
		}, 0);	
	}

	var fastCarCanDrive:Bool = true;

	function resetFastCar():Void {
		stage.fastCar.x = -12600;
		stage.fastCar.y = FlxG.random.int(140, 250);
		stage.fastCar.velocity.x = 0;
		fastCarCanDrive = true;
	}

	function fastCarDrive() {
		FlxG.sound.play(Paths.soundRandom('carPass', 0, 1), 0.7);

		stage.fastCar.velocity.x = (FlxG.random.int(170, 220) / FlxG.elapsed) * 3;
		fastCarCanDrive = false;
		new FlxTimer().start(2, function(tmr:FlxTimer) {
			resetFastCar();
		});
	}

	var trainMoving:Bool = false;
	var trainFrameTiming:Float = 0;

	var trainCars:Int = 8;
	var trainFinishing:Bool = false;
	var trainCooldown:Int = 0;

	function trainStart():Void {
		trainMoving = true;
		if (!stage.trainSound.playing)
			stage.trainSound.play(true);
	}

	var startedMoving:Bool = false;

	function updateTrainPos():Void {
		if (stage.trainSound.time >= 4700) {
			startedMoving = true;
			gf.playAnim('hairBlow');
		}

		if (startedMoving) {
			stage.phillyTrain.x -= 400;

			if (stage.phillyTrain.x < -2000 && !trainFinishing) {
				stage.phillyTrain.x = -1150;
				trainCars -= 1;

				if (trainCars <= 0)
					trainFinishing = true;
			}

			if (stage.phillyTrain.x < -4000 && trainFinishing)
				trainReset();
		}
	}

	function trainReset():Void {
		gf.playAnim('hairFall');
		stage.phillyTrain.x = FlxG.width + 200;
		trainMoving = false;
		// trainSound.stop();
		// trainSound.time = 0;
		trainCars = 8;
		trainFinishing = false;
		startedMoving = false;
	}

	function lightningStrikeShit():Void {
		FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
		stage.halloweenBG.animation.play('lightning');

		lightningStrikeBeat = curBeat;
		lightningOffset = FlxG.random.int(8, 24);

		bf.playAnim('scared', true);
		gf.playAnim('scared', true);
	}

	function peecoStressOnArrowShoot(note:Note) {
		if (gf.curCharacter == "pico-speaker")
			if (curBeat >= 0 && curBeat <= 31 ||
				curBeat >= 96 && curBeat <= 191 ||
				curBeat >= 288 && curBeat <= 316) {
				gf.playAnim("picoShoot" + (note.noteData + 1));
			}
	}

	override function stepHit() {
		luaCall("stepHit");

		super.stepHit();

		if (FlxG.sound.music.time > Conductor.songPosition + 20 || FlxG.sound.music.time < Conductor.songPosition - 20) {
			resyncVocals();
		}

		if (curSong == "Stress") {
			if (curStep == 736) {
				dad.playAnim("prettyGood");
			}
			if (curBeat >= 347) {
				switch (curStep) {
					//kinda need to make it faster
					case 1408: gf.playAnim("picoShoot2");
					case 1410: gf.playAnim("picoShoot3");
					case 1412: gf.playAnim("picoShoot1");
					case 1414: gf.playAnim("picoShoot1");
					case 1416: gf.playAnim("picoShoot3");
					case 1418: gf.playAnim("picoShoot4");
					case 1420: gf.playAnim("picoShoot2");
					case 1422: gf.playAnim("picoShoot1");
	
					case 1424: gf.playAnim("picoShoot1");
					case 1426: gf.playAnim("picoShoot4");
					case 1428: gf.playAnim("picoShoot3");
					case 1430: gf.playAnim("picoShoot4");
					case 1432: gf.playAnim("picoShoot2");
					case 1434: gf.playAnim("picoShoot4");
					case 1436: gf.playAnim("picoShoot1");
					case 1438: gf.playAnim("picoShoot4");
				}
			}
		}

		if (dad.curCharacter == 'spooky' && curStep % 4 == 2) {
			// dad.dance();
		}
	}

	override function beatHit() {
		super.beatHit();
		stage.onBeatHit();

		if (generatedMusic) {
			notes.sort(FlxSort.byY, FlxSort.DESCENDING);
		}
		
		if (stage.name == 'tank') {
			if ( new FlxRandom().int(0, 100) > 99) {
				spawnRollingTankmen();
			}
		}

		if (SONG.notes[Math.floor(curStep / 16)] != null) {
			if (SONG.notes[Math.floor(curStep / 16)].changeBPM) {
				Conductor.changeBPM(SONG.notes[Math.floor(curStep / 16)].bpm);
				FlxG.log.add('CHANGED BPM!');
			}
			// else
			// Conductor.changeBPM(SONG.bpm);

			// Dad doesnt interupt his own notes
			if (SONG.notes[Math.floor(curStep / 16)].mustHitSection)
				dad.dance();
		}
		// FlxG.log.add('change bpm' + SONG.notes[Std.int(curStep / 16)].changeBPM);
		wiggleShit.update(Conductor.crochet);

		// HARDCODING FOR MILF ZOOMS!
		if (camZooming && curBeat >= 168 && curBeat < 200 && curSong.toLowerCase() == 'milf') {
			FlxG.camera.zoom += 0.36;
			camHUD.zoom += 0.06;
		}

		if (camZooming && FlxG.camera.zoom < 1.35 && curBeat % 4 == 0) {
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;
		}

		iconP1.setGraphicSize(Std.int(iconP1.width + 30));
		iconP2.setGraphicSize(Std.int(iconP2.width + 30));

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		if (curBeat % gfSpeed == 0) {
			gf.dance();
		}

		if (!bf.animation.curAnim.name.startsWith("sing")) {
			bf.playAnim('idle');
		}

		if (playAs == "dad") {
			if (!dad.animation.curAnim.name.startsWith("sing")) {
				dad.playAnim('idle');
			}
		}

		if (curBeat % 8 == 7 && curSong == 'Bopeebo') {
			bf.playAnim('hey', true);
			gf.playAnim('cheer', true);
		}

		if (curBeat % 16 == 15 && SONG.song == 'Tutorial' && dad.curCharacter.startsWith('gf') && curBeat > 16 && curBeat < 48) {
			bf.playAnim('hey', true);
			dad.playAnim('cheer', true);
		}

		switch (stage.name) {
			case 'school':
				stage.bgGirls.dance();

			case 'limo':
				stage.grpLimoDancers.forEach(function(dancer:BackgroundDancer) {
					dancer.dance();
				});

				if (FlxG.random.bool(10) && fastCarCanDrive)
					fastCarDrive();
			case "philly":
				if (!trainMoving)
					trainCooldown += 1;

				if (curBeat % 4 == 0) {
					stage.phillyCityLights.forEach(function(light:FlxSprite) {
						light.visible = false;
					});

					curLight = FlxG.random.int(0, stage.phillyCityLights.length - 1);

					stage.phillyCityLights.members[curLight].visible = true;
					// phillyCityLights.members[curLight].alpha = 1;
				}

				if (curBeat % 8 == 4 && FlxG.random.bool(30) && !trainMoving && trainCooldown > 8) {
					trainCooldown = FlxG.random.int(-4, 0);
					trainStart();
				}
			case 'tank':
				stage.bgSkittles.animation.play('bop', true);
				stage.bgTank0.animation.play('bop', true);
				stage.bgTank1.animation.play('bop', true);
				stage.bgTank2.animation.play('bop', true);
				stage.bgTank3.animation.play('bop', true);
				stage.bgTank4.animation.play('bop', true);
				stage.bgTank5.animation.play('bop', true);
		}

		if (stage.name == "spooky" && FlxG.random.bool(10) && curBeat > lightningStrikeBeat + lightningOffset) {
			lightningStrikeShit();
		}

		luaCall("beatHit");
	}

	public function setPaused(b:Bool) {
		paused = b;
		FlxTween.globalManager.forEach(tween -> {
			tween.active = !paused;
		});
	}

	public function pauseGame(?skipTween:Bool = false) {
		persistentUpdate = false;
		persistentDraw = true;

		if (FlxG.random.bool(0.3)) {
			FlxG.switchState(new GitarooPause());
		}
		else {
			openSubState(new PauseSubState(bf.getScreenPosition().x, bf.getScreenPosition().y, skipTween));

			#if desktop
			DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconRPC);
			#end
	
			if (FlxG.sound.music != null) {
				FlxG.sound.music.pause();
				vocals.pause();
			}
	
			if (!startTimer.finished)
				startTimer.active = false;
		}
	}

	public function changeStage(name:String) {
		remove(stage);

		Paths.setCurrentStage(name);

		if (Cache.stages.exists(name)) {
			stage = Cache.stages.get(name);
		} else {
			stage = new Stage(name);
		}
		stage.applyStageShitToPlayState();
		updateCharPos("bf");
        updateCharPos("dad");
        updateCharPos("gf");
		add(stage);
	}

	public function changeCharacter(char:String, newChar:String) {
		var newNewChar:Character = null;
		var newBofrend:Boyfriend = null;

		if (char != "bf") {
			if (Cache.characters.exists(newChar)) {
				newNewChar = Cache.characters.get(newChar);
			} else {
				newNewChar = new Character(0, 0, newChar);
			}
		} else {
			if (Cache.bfs.exists(newChar)) {
				newBofrend = Cache.bfs.get(newChar);
			} else {
				newBofrend = new Boyfriend(0, 0, newChar);
			}
		}

		if (char == "dad") {
			dad = newNewChar;
		}
		else if (char == "bf") { 
			bf = newBofrend;
		}
		else if (char == "gf") {
			gf = newNewChar;
		}
		updateChar(char);
		updateCharPos(char);

		gf.scrollFactor.set(stage.gfScrollFactorX, stage.gfScrollFactorY);
		dad.scrollFactor.set(stage.dadScrollFactorX, stage.dadScrollFactorY);
		bf.scrollFactor.set(stage.bfScrollFactorX, stage.bfScrollFactorY);
	}

	function luaCall(func, ?args) {
		if (lua != null)
			lua.call(func, args);
	}

	function luaSetVariable(name:String, value:Dynamic) {
		if (lua != null)
			lua.setVariable(name, value);
	}

	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;

	/*
	
	l
	o
	n
	g

	s
	p
	a
	c
	e

	*/

    function ActionNoteonPressed(daNote:Note) {
		if (!daNote.blockActions) {
			switch (daNote.action.toLowerCase()) {
				case "ebola":
					new FlxTimer().start(0.01, function(timer:FlxTimer) {
						health -= 0.001;
					}, 0);	
				case "damage":
					if (daNote.actionValue != null)
						health -= Std.parseFloat(daNote.actionValue);
					else
						health -= 0.3;
			}
		}
		daNote.blockActions = true;
    }

    function ActionNoteOnGhostPressed(daNote:Note) {
		var actionValueFloat = Std.parseFloat(daNote.actionValue);
		if (!daNote.blockActions) {
			switch (daNote.action.toLowerCase()) {
				case "subtitle", "sub":
					addSubtitle(daNote.actionValue);
				case "p1 icon alpha":
					iconP1.alpha = actionValueFloat;
				case "p2 icon alpha":
					iconP2.alpha = actionValueFloat;
				case "picos":
					if (gf.curCharacter == "pico-speaker") {
						gf.playAnim("picoShoot" + daNote.actionValue);
					}
				case "change character":
					var splicedValue = daNote.actionValue.split(", ");
					changeCharacter(splicedValue[0], splicedValue[1]);
				case "change stage":
					changeStage(daNote.actionValue);
				case "change scroll speed":
					curSpeed = actionValueFloat;
				case "add camera zoom":
					addCameraZoom(actionValueFloat);
				case "hey":
					bf.playAnim('hey', true);
					gf.playAnim('cheer', true);
				case "play animation":
					var splicedValue = daNote.actionValue.split(", ");
					switch (splicedValue[0]) {
						case "bf":
							bf.playAnim(splicedValue[1], true);
						case "gf":
							gf.playAnim(splicedValue[1], true);
						case "dad":
							dad.playAnim(splicedValue[1], true);
					}
			}
		}
		daNote.blockActions = true;
    }

	var curLight:Int = 0;
	var misses:Int = 0;

	public static var openSettings:Bool = false;

	var debugStageAsset:FlxSprite;
	var debugStageAssetSize = 1.0;

	var video:MP4Handler;
	var isTankRolling:Bool;

	public static var gfVersion:String;

	var timeLeftText:FlxText;

	var lua:LuaShit;

	public static var week:Week;

	public function updateCharPos(arg0:String) {
		switch (arg0) {
			case "dad":
				dad.x = stage.dadX;
				dad.y = stage.dadY;
				if (dad.config != null) {
					if (Std.string(dad.config.get("X")) != "null") dad.x = stage.dadX + Std.parseFloat(Std.string(dad.config.get("X")));
					if (Std.string(dad.config.get("Y")) != "null") dad.y = stage.dadY + Std.parseFloat(Std.string(dad.config.get("Y")));
				}
			case "bf":
				bf.x = stage.bfX;
				bf.y = stage.bfY;
				if (bf.config != null) {
					if (Std.string(bf.config.get("X")) != "null") bf.x = stage.bfX + Std.parseFloat(Std.string(bf.config.get("X")));
					if (Std.string(bf.config.get("Y")) != "null") bf.y = stage.bfY + Std.parseFloat(Std.string(bf.config.get("Y")));
				}
			case "gf":
				gf.x = stage.gfX;
				gf.y = stage.gfY;
				if (gf.config != null) {
					if (Std.string(gf.config.get("X")) != "null") gf.x = stage.gfX + Std.parseFloat(Std.string(gf.config.get("X")));
					if (Std.string(gf.config.get("Y")) != "null") gf.y = stage.gfY + Std.parseFloat(Std.string(gf.config.get("Y")));
				}
		}

	}

	public function addCameraZoom(z0om:Float) {
		if (currentCameraTween != null) {
			currentCameraTween.cancel();
		}
		if (currentHUDCameraTween != null) {
			currentHUDCameraTween.cancel();
		}
		camZoom += z0om;
		camHUD.zoom += z0om / 4;
		currentCameraTween = FlxTween.num(camZoom, stage.camZoom, 0.8, null, f -> camZoom = f);
		currentHUDCameraTween = FlxTween.num(camHUD.zoom, 1, 0.8, null, f -> camHUD.zoom = f);
	}

	var iconCrown:FlxSprite;

	var db:DialogueBoxOg;

	var blockSpamChecker:Bool;

	public var forceDialogueBox:Bool;

	public static var openAchievements:Bool = false;
}

/*		⠀⠀⠀⡯⡯⡾⠝⠘⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢊⠘⡮⣣⠪⠢⡑⡌
	⠀⠀⠀⠟⠝⠈⠀⠀⠀⠡⠀⠠⢈⠠⢐⢠⢂⢔⣐⢄⡂⢔⠀⡁⢉⠸⢨⢑⠕⡌
	⠀⠀⡀⠁⠀⠀⠀⡀⢂⠡⠈⡔⣕⢮⣳⢯⣿⣻⣟⣯⣯⢷⣫⣆⡂⠀⠀⢐⠑⡌
	⢀⠠⠐⠈⠀⢀⢂⠢⡂⠕⡁⣝⢮⣳⢽⡽⣾⣻⣿⣯⡯⣟⣞⢾⢜⢆⠀⡀⠀⠪
	⣬⠂⠀⠀⢀⢂⢪⠨⢂⠥⣺⡪⣗⢗⣽⢽⡯⣿⣽⣷⢿⡽⡾⡽⣝⢎⠀⠀⠀⢡
	⣿⠀⠀⠀⢂⠢⢂⢥⢱⡹⣪⢞⡵⣻⡪⡯⡯⣟⡾⣿⣻⡽⣯⡻⣪⠧⠑⠀⠁⢐
	⣿⠀⠀⠀⠢⢑⠠⠑⠕⡝⡎⡗⡝⡎⣞⢽⡹⣕⢯⢻⠹⡹⢚⠝⡷⡽⡨⠀⠀⢔
	⣿⡯⠀⢈⠈⢄⠂⠂⠐⠀⠌⠠⢑⠱⡱⡱⡑⢔⠁⠀⡀⠐⠐⠐⡡⡹⣪⠀⠀⢘
	⣿⣽⠀⡀⡊⠀⠐⠨⠈⡁⠂⢈⠠⡱⡽⣷⡑⠁⠠⠑⠀⢉⢇⣤⢘⣪⢽⠀⢌⢎
	⣿⢾⠀⢌⠌⠀⡁⠢⠂⠐⡀⠀⢀⢳⢽⣽⡺⣨⢄⣑⢉⢃⢭⡲⣕⡭⣹⠠⢐⢗
	⣿⡗⠀⠢⠡⡱⡸⣔⢵⢱⢸⠈⠀⡪⣳⣳⢹⢜⡵⣱⢱⡱⣳⡹⣵⣻⢔⢅⢬⡷
	⣷⡇⡂⠡⡑⢕⢕⠕⡑⠡⢂⢊⢐⢕⡝⡮⡧⡳⣝⢴⡐⣁⠃⡫⡒⣕⢏⡮⣷⡟
	⣷⣻⣅⠑⢌⠢⠁⢐⠠⠑⡐⠐⠌⡪⠮⡫⠪⡪⡪⣺⢸⠰⠡⠠⠐⢱⠨⡪⡪⡰
	⣯⢷⣟⣇⡂⡂⡌⡀⠀⠁⡂⠅⠂⠀⡑⡄⢇⠇⢝⡨⡠⡁⢐⠠⢀⢪⡐⡜⡪⡊
	⣿⢽⡾⢹⡄⠕⡅⢇⠂⠑⣴⡬⣬⣬⣆⢮⣦⣷⣵⣷⡗⢃⢮⠱⡸⢰⢱⢸⢨⢌
	⣯⢯⣟⠸⣳⡅⠜⠔⡌⡐⠈⠻⠟⣿⢿⣿⣿⠿⡻⣃⠢⣱⡳⡱⡩⢢⠣⡃⠢⠁
	⡯⣟⣞⡇⡿⣽⡪⡘⡰⠨⢐⢀⠢⢢⢄⢤⣰⠼⡾⢕⢕⡵⣝⠎⢌⢪⠪⡘⡌⠀
	⡯⣳⠯⠚⢊⠡⡂⢂⠨⠊⠔⡑⠬⡸⣘⢬⢪⣪⡺⡼⣕⢯⢞⢕⢝⠎⢻⢼⣀⠀
	⠁⡂⠔⡁⡢⠣⢀⠢⠀⠅⠱⡐⡱⡘⡔⡕⡕⣲⡹⣎⡮⡏⡑⢜⢼⡱⢩⣗⣯⣟
	⢀⢂⢑⠀⡂⡃⠅⠊⢄⢑⠠⠑⢕⢕⢝⢮⢺⢕⢟⢮⢊⢢⢱⢄⠃⣇⣞⢞⣞⢾
	⢀⠢⡑⡀⢂⢊⠠⠁⡂⡐⠀⠅⡈⠪⠪⠪⠣⠫⠑⡁⢔⠕⣜⣜⢦⡰⡎⡯⡾⡽ */
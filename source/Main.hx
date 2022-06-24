package;

import flixel.tweens.misc.VarTween;
import flixel.system.FlxSound;
import flixel.math.FlxMath;
import openfl.system.System;
import Achievement.AchievementObject;
import openfl.display.Bitmap;
import openfl.display.Shape;
import lime.graphics.Image;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;
import openfl.text.Font;
import flixel.system.FlxAssets;
import flixel.tweens.misc.NumTween;
import openfl.events.TimerEvent;
import openfl.events.EventType;
import openfl.utils.Timer;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import openfl.text.TextFormat;
import openfl.text.TextField;
import haxe.DynamicAccess;
import haxe.Json;
import sys.Http;
import OptionsSubState.Background;
import clipboard.Clipboard;
import flixel.text.FlxText;
import haxe.Exception;
import flixel.util.FlxColor;
import openfl.display.StageDisplayState;
import openfl.display.StageQuality;
import openfl.filters.ShaderFilter;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import openfl.Assets;
import openfl.Lib;
import openfl.display.FPS;
import openfl.display.Sprite;
import openfl.events.Event;

class Main extends Sprite {
	public static inline var ENGINE_NAME:String = "PEngine"; //engine name in case i will change it lmao
	public static inline var ENGINE_VER = "v0.7";

	public static var gameWidth:Int = 1280; // Width of the game in pixels (might be less / more in actual pixels depending on your zoom).
	public static var gameHeight:Int = 720; // Height of the game in pixels (might be less / more in actual pixels depending on your zoom).
	public static var instance:Main;

	var initialState:Class<FlxState> = TitleState; // The FlxState the game starts with.
	var zoom:Float = -1; // If -1, zoom is automatically calculated to fit the window dimensions.

	//public static var framerate:Int = 69; // How many frames per second the game should run at. | use Options.framerate instead

	var skipSplash:Bool = true; // Whether to skip the flixel splash screen that appears in release mode.
	var startFullscreen:Bool = false; // Whether to start the game in fullscreen on desktop targets

	// You can pretty much ignore everything from here on - your code should go in your states.

	public static var notifTweenManager:NotificationTweenManager;

	public static function main():Void {
		Lib.current.addChild(new Main());
	}

	public function new() {
		super();
		instance = this;

		if (stage != null) {
			init();
		}
		else {
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
	}

	private function init(?E:Event):Void {
		if (hasEventListener(Event.ADDED_TO_STAGE)) {
			removeEventListener(Event.ADDED_TO_STAGE, init);
		}

		setupGame();
	}

	public function setupGame():Void {
		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		Options.startupSaveScript();
		Achievement.init();

		if (zoom == -1) {
			var ratioX:Float = stageWidth / gameWidth;
			var ratioY:Float = stageHeight / gameHeight;
			zoom = Math.min(ratioX, ratioY);
			gameWidth = Math.ceil(stageWidth / zoom);
			gameHeight = Math.ceil(stageHeight / zoom);
		}

		#if !debug
		initialState = TitleState;
		#end

		if (Options.updateChecker) {
			var request = new Http('https://api.github.com/repos/Paidyy/Funkin-PEngine/releases/latest');
			request.setHeader('User-Agent', 'haxe');
			request.setHeader("Accept", "application/vnd.github.v3+json");
			request.onData = data -> {
				try {
					gitJson = Json.parse(request.responseData);
					if (gitJson.tag_name != null)
						if (gitJson.tag_name != Main.ENGINE_VER)
							Main.outdatedVersion = true;
				}
				catch (exc) {
					trace("could not get github api json: " + exc.details());
				}
			};
			request.request();
		}

		if (Main.outdatedVersion)
			trace('Running Version: $ENGINE_VER while there\'s a newer Version: ${gitJson.tag_name}');

		addChild(new Game(gameWidth, gameHeight, initialState, zoom, Options.framerate, Options.framerate, skipSplash, startFullscreen));

		#if !mobile
		addChild(new EFPS());
		#end
		
		#if MUTE
		FlxG.sound.muted = true;
		#end

		FlxG.plugins.add(Main.notifTweenManager = new NotificationTweenManager());
	}

	public static var gitJson:Dynamic = null;

	public static var outdatedVersion:Bool = false;
}

class Game extends FlxGame {
	public static var pauseMusic:FlxSound;
	public static var pauseMusicTween:VarTween;

	override public function update() {
		if (pauseMusic != null) {
			if (pauseMusic.playing) {
				pauseMusicTween.active = true;
			}
		}
		
		if (Options.disableCrashHandler) {
			super.update();
		}
		else {
			try {
				super.update();
			}
			catch (exc) {
				trace("Caught an Exception! (aw hell nah)");
				trace(exc.details());
				FlxG.switchState(new CrashHandler(exc));
			}
		}
	}

	public static function playPauseMusic() {
		pauseMusic = new FlxSound().loadEmbedded(Paths.music('breakfast'), true, true);
		pauseMusic.volume = 0;
		pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));
		FlxG.sound.list.add(pauseMusic);

		pauseMusicTween = FlxTween.tween(pauseMusic, {volume: 0.9}, 15);
	}

	public static function stopPauseMusic() {
		if (pauseMusicTween != null) {
			pauseMusicTween.cancel();
		}
		if (pauseMusic != null) {
			pauseMusic.stop();
		}
	}
}

/**
 * made this class because FlxG.plugins.add() is fucked shit and can't accept plugins with the same class names
 */
class NotificationTweenManager extends FlxTweenManager { }

class CrashHandler extends FlxState {
	// inspired from ddlc mod and old minecraft crash handler
	// can someone explain to me why some people use external exes for crash handlers? it's fucking dumb
	var exception:Exception;
	var gf:Character;

	public function new(exc:Exception) {
		super();

		exception = exc;
	}

	override function create() {
		super.create();

		var bg = new Background(FlxColor.fromString("#696969"));
		bg.scrollFactor.set(0, 0);
		add(bg);

		var bottomText = new FlxText(0, 0, 0, "C to copy exception | ESC to send to menu");
		bottomText.scrollFactor.set(0, 0);
		bottomText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE);
		bottomText.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 1);
		bottomText.screenCenter(X);
		bottomText.y = FlxG.height - bottomText.height - 10;
		add(bottomText);

		var exceptionText = new FlxText();
		exceptionText.setFormat(Paths.font("vcr.ttf"), 42, FlxColor.WHITE);
		exceptionText.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 1);
		exceptionText.text = "Game has encountered a Exception!";
		exceptionText.color = FlxColor.RED;
		exceptionText.screenCenter(X);
		exceptionText.y += 20;
		add(exceptionText);

		var crashShit = new FlxText();
		crashShit.setFormat(Paths.font("vcr.ttf"), 15, FlxColor.WHITE);
		crashShit.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 1);
		crashShit.text = exception.details();
		crashShit.screenCenter(X);
		crashShit.y += exceptionText.y + exceptionText.height + 20;
		add(crashShit);

		gf = new Character(0, 0, "gf", false, true);
		gf.scrollFactor.set(0, 0);
		gf.animation.play("sad");
		add(gf);

		gf.setGraphicSize(Std.int(gf.frameWidth * 0.3));
		gf.updateHitbox();
		gf.x = FlxG.width - gf.width;
		gf.y = FlxG.height - gf.height;
	}

	override function update(elapsed) {
		if (FlxG.keys.justPressed.C) {
			Clipboard.set(exception.details());
		}

		if (FlxG.keys.justPressed.ESCAPE)
			FlxG.switchState(new MainMenuState());

		if (FlxG.mouse.wheel == -1) {
			if (FlxG.keys.pressed.CONTROL)
				FlxG.camera.zoom += 0.02;
			if (FlxG.keys.pressed.SHIFT)
				FlxG.camera.scroll.x += 20;
			if (!FlxG.keys.pressed.SHIFT && !FlxG.keys.pressed.CONTROL)
				FlxG.camera.scroll.y += 20;
		}
		if (FlxG.mouse.wheel == 1) {
			if (FlxG.keys.pressed.CONTROL)
				FlxG.camera.zoom -= 0.02;
			if (FlxG.keys.pressed.SHIFT) {
				if (FlxG.camera.scroll.x > 0)
					FlxG.camera.scroll.x -= 20;
			}
			if (!FlxG.keys.pressed.SHIFT && !FlxG.keys.pressed.CONTROL) {
				if (FlxG.camera.scroll.y > 0)
					FlxG.camera.scroll.y -= 20;
			}
		}
	}
}

class AchievementNotification {
	public var achieObject:AchievementObject;

	public function new(achieId:String) {
		achieObject = AchievementObject.fromID(achieId);

		var icon = new Bitmap(BitmapData.fromFile(achieObject.iconPath));
		icon.width = icon.width * 0.5;
		icon.height = icon.height * 0.5;
		icon.x = 40;
		icon.y = 40;

		var text = new TextField();
		text.selectable = false;
		text.defaultTextFormat = new TextFormat(Font.fromFile("assets/fonts/vcr.ttf").fontName, 20, FlxColor.WHITE);
		text.text = achieObject.displayName;
		text.width = text.textWidth;
		text.y = icon.y;
		text.x = icon.x + icon.width + 10;

		var textDesc = new TextField();
		textDesc.selectable = false;
		textDesc.defaultTextFormat = new TextFormat(Font.fromFile("assets/fonts/vcr.ttf").fontName, 16, FlxColor.WHITE);
		textDesc.text = achieObject.description;
		textDesc.width = textDesc.textWidth;
		textDesc.y = text.y + text.textHeight + 10;
		textDesc.x = text.x;

		var bgWidth:Float = textDesc.textWidth;
		if (text.textWidth > bgWidth) {
			bgWidth = text.textWidth;
		}
		bgWidth += icon.width + 10;
		bgWidth += 40;


		var bgHeight:Float = icon.height;
		if (text.textHeight > bgHeight) {
			bgHeight = text.textHeight;
		}
		if (textDesc.textHeight > bgHeight) {
			bgHeight = textDesc.textHeight;
		}

		bgHeight += 40;

		var bg = new Bitmap(new BitmapData(Std.int(bgWidth), Std.int(bgHeight), true, FlxColor.BLACK));
		bg.alpha = 0.6;
		bg.x = 20;
		bg.y = 20;

		Main.instance.addChild(bg);
		Main.instance.addChild(icon);
		Main.instance.addChild(text);
		Main.instance.addChild(textDesc);

		var timer = new Timer(1000 * 3, 1);
		timer.addEventListener(TimerEvent.TIMER_COMPLETE, l -> {
			Main.notifTweenManager.num(bg.alpha, 0.0, 1, {onComplete: f -> {
				Main.instance.removeChild(bg);
				Main.instance.removeChild(icon);
				Main.instance.removeChild(text);
				Main.instance.removeChild(textDesc);
			}},
			value -> {
				bg.alpha = value;
				icon.alpha = value;
				text.alpha = value;
				textDesc.alpha = value;
			}).start();
		});
		timer.start();
	}
}

class Notification extends TextField {
	public static var notifs:Array<Notification> = [];
	public static var curNotif:Notification;
	public var timer:Timer;
	public var tween:NumTween;

	public function new(text:String, ?color:Int = FlxColor.RED) {
		super();

		selectable = false;
		defaultTextFormat = new TextFormat(Font.fromFile("assets/fonts/vcr.ttf").fontName, 25, color);
		this.text = text;

		width = textWidth;

		x = (FlxG.width - width) / 2;
		y = FlxG.height - 200;
	}
	public function show() {
		if (!notifs.contains(this)) {
			notifs.push(this);
		}
		
		if (curNotif != null) {
			return;
		}
		var bg = new Bitmap(new BitmapData(Std.int(textWidth) + 20, Std.int(textHeight) + 20, true, FlxColor.BLACK));
		bg.alpha = 0.6;
		bg.x = x - 10;
		bg.y = y - 10;
		
		Main.instance.addChild(bg);
		Main.instance.addChild(this);
		curNotif = this;

		/*
		for (notif in notifs) {
			if (notif != this) {
				notifs.remove(notif);
				Main.instance.removeChild(notif);
			}
		}
		*/

		timer = new Timer(4000, 1);
		timer.addEventListener(TimerEvent.TIMER_COMPLETE, event -> {
			tween = Main.notifTweenManager.num(alpha, 0.0, 1, {onComplete: f -> {
				notifs.remove(this);
				Main.instance.removeChild(bg);
				Main.instance.removeChild(this);
				curNotif = null;
				if (notifs.length > 0) {
					notifs[notifs.length - 1].show();
				}
				}
			}, f -> {
				alpha = f;
				bg.alpha = f > 0.6 ? 0.6 : f;
			});
			tween.start();
		});
		timer.start();
	}
}

class EFPS extends FPS {
	override public function new() {
		super(10, 3, FlxColor.WHITE);
	}

	override public function __enterFrame(deltaTime) {
		super.__enterFrame(deltaTime);

		//only in debug because it's ugly
		#if debug
		if (!text.contains("RAM Used:")) {
			text += "\n(DEBUG) RAM Used: " + FlxMath.roundDecimal(System.totalMemory / 1000000, 1) + "MB";
			width = textWidth;
		}
		#end

		textColor = FlxColor.LIME;

		if (currentFPS <= Std.int(Options.framerate / 1.5)) {
			textColor = FlxColor.YELLOW;
		}
		if (currentFPS <= Std.int(Options.framerate / 3.5)) {
			textColor = FlxColor.RED;
		}
	}
}

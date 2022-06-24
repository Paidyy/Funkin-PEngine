package;

import haxe.Exception;
import Main.Notification;
import flixel.util.FlxTimer;
import flixel.math.FlxMath;
import haxe.io.Path;
import sys.FileSystem;
import yaml.util.ObjectMap.AnyObjectMap;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;

class Character extends AnimatedSprite {
	public var debugMode:Bool = false;

	public var isPlayer:Bool = false;
	public var curCharacter:String = 'bf';

	public var stunned:Bool = false;

	public var holdTimer:Float = 0;

	var animationsFromAlt:List<String>;

	public var config:AnyObjectMap = new AnyObjectMap();
	public var configPath:String = "";

	public var idleAnim:String = null;

	public var singDuration:Float = 0.4;

	public var singTimer:FlxTimer;

	public var isIdlePlaying(get, never):Bool;

	function get_isIdlePlaying():Bool {
		if (idleAnim == "danceRight" || idleAnim == "danceLeft") {
			return animation.name == "danceRight" || animation.name == "danceLeft";
		}
		return animation.name == idleAnim;
	}

	public function addPrefixAlternative(name, prefix, frames, looped) {
		animationsFromAlt.add(name);
		animation.addByPrefix(name, prefix, frames, looped);
	}

	public function startSingTimer() {
		if (singTimer != null) {
			singTimer.cancel();
			singTimer.destroy();
		}
		singTimer = new FlxTimer();
		singTimer.start(singDuration, (timer) -> {
			playIdle();
		});
	}

	public function new(x:Float, y:Float, ?character:String = "bf", ?isPlayer:Bool = false, isDebug = false, forceCache:Bool = false) {
		super(x, y);

		animationsFromAlt = new List<String>();
		animOffsets = new Map<String, Array<Dynamic>>();
		curCharacter = character;
		this.isPlayer = isPlayer;
		this.debugMode = isDebug;

		antialiasing = true;

		if (Paths.isCustomPath(Paths.getCharacterPath(curCharacter))) {
			trace("custom character: " + curCharacter);
			/*
			var path = Paths.getCharacterPath(curCharacter) + curCharacter;
			if (path.startsWith(${Paths.modsLoc} + "/skins/")) {
				var spltPath = path.split("/");
				spltPath[spltPath.length - 1] = spltPath[spltPath.length - 2];
				path = "";
				for (index in 0...spltPath.length) {
					path += spltPath[index] + "/";
				}
				path = path.substring(0, path.length - 1);
			}
			*/
			frames = Cache.cacheCharacterAssets(curCharacter, forceCache);
		}
		else {
			trace("openfl character: " + curCharacter);
			if (openfl.utils.Assets.exists(Paths.file('images/${"characters/" + curCharacter + "/" + curCharacter}.txt'))) {
				frames = Paths.getPackerAtlas('characters/' + curCharacter + '/' + curCharacter);
			}
			else {
				frames = Paths.getSparrowAtlas('characters/' + curCharacter + '/' + curCharacter);
			}
			Cache.cacheCharacterConfig(curCharacter, forceCache);
		}

		if (frames == null) {
			throw new Exception("frames is null");
		}
		
		setConfigPath(Paths.getCharacterPath(curCharacter) + 'config.yml');

		if (Cache.charactersConfigs.exists(curCharacter)) {
			config = Cache.charactersConfigs.get(curCharacter);
			if (config != null) {
				// take a shot everytime you see != null here
				var map:AnyObjectMap = config.get('animations');
				if (config.exists('animations')) {
					for (anim in map.keys()) {
						var values:AnyObjectMap = config.get('animations').get(anim);
						//trace(anim, values.get('x'), values.get('y'), values.get('frames'), values.get('looped'), values.get('name'), values.get('isIdle'));
						var _name = "";
						var _framerate = 24;
						var _looped = false;
						var _x = 0;
						var _y = 0;
						var _indices = null;
						if (values != null) {
							if (values.get('x') != null)
								_x = values.get('x');
							if (values.get('y') != null)
								_y = values.get('y');
							if (values.get('framerate') != null)
								_framerate = values.get('framerate');
							if (values.get('looped') != null)
								_looped = values.get('looped');
							if (values.get('name') != null)
								_name = values.get('name');
							if (values.get('isIdle') == true)
								idleAnim = anim;
							if (values.get('indices') != null)
								_indices = values.get('indices');
						}
						
						if (values.exists("indices")) {
							if (values.get('indices') != null) {
								animation.addByIndices(anim, _name, _indices, "", _framerate, _looped);
							}
						}
						else {
							animation.addByPrefix(anim, _name, _framerate, _looped);
						}
						setOffset(anim, _x, _y);
					}
				}
				if (idleAnim == null) {
					if (animation.exists('idle'))
						idleAnim = 'idle';
					else if (animation.exists('danceLeft'))
						idleAnim = 'danceLeft';
					else if (animation.exists('danceRight'))
						idleAnim = 'danceRight';
				}
				if (config.exists('singDuration')) {
					singDuration = config.get('singDuration');
				}
				if (Std.string(config.get('flipX')) == "true") {
					flipX = true;
				} else if (Std.string(config.get('flipX')) == "false") {
					flipX = false;
				}
			}
			else {
				new Notification("Character " + curCharacter + " doesnt have a config!").show();
				trace("character " + curCharacter + " doesnt have a config!");
				throw new Exception("no config");
			}
		}
		else {
			new Notification("Character " + curCharacter + " doesnt have a config!").show();
			trace("character " + curCharacter + " doesnt have a config!");
			throw new Exception("no config");
		}

		if (idleAnim == null) {
			trace("idle animation not found");
			throw new Exception("idle animation not found");
		}

		switch (curCharacter) {
			case 'gf-pixel':
				setGraphicSize(Std.int(width * PlayState.daPixelZoom));
				updateHitbox();
				antialiasing = false;
			case 'bf-pixel':
				setGraphicSize(Std.int(width * 6));
				updateHitbox();

				width -= 100;
				height -= 100;

				antialiasing = false;
			case 'bf-pixel-dead':
				playAnim('firstDeath');
				// pixel bullshit
				setGraphicSize(Std.int(width * 6));
				updateHitbox();
				antialiasing = false;
			case 'senpai':
				setGraphicSize(Std.int(width * 6));
				updateHitbox();

				antialiasing = false;
			case 'senpai-angry':
				setGraphicSize(Std.int(width * 6));
				updateHitbox();

				antialiasing = false;
			case 'spirit':
				setGraphicSize(Std.int(width * 6));
				updateHitbox();

				antialiasing = false;
		}

		playIdle();

		if (isPlayer) {
			flipX = !flipX;

			// Doesn't flip for BF, since his are already in the right place???
			if (!curCharacter.startsWith('bf')) {
				// var animArray
				var oldRight = animation.getByName('singRIGHT').frames;
				animation.getByName('singRIGHT').frames = animation.getByName('singLEFT').frames;
				animation.getByName('singLEFT').frames = oldRight;

				// IF THEY HAVE MISS ANIMATIONS??
				if (animation.getByName('singRIGHTmiss') != null) {
					var oldMiss = animation.getByName('singRIGHTmiss').frames;
					animation.getByName('singRIGHTmiss').frames = animation.getByName('singLEFTmiss').frames;
					animation.getByName('singLEFTmiss').frames = oldMiss;
				}
			}
		}
	}

	public function resetColorTransform() {
		missColorTransform = false;
		colorTransform.redOffset = 0;
		colorTransform.greenOffset = 0;
		colorTransform.blueOffset = 0;
	}

	public function playIdle() {
		//Sustain shit
		if (holdTimer > Conductor.stepCrochet * 4 * 0.001 && animation.curAnim.name.startsWith('sing') && !animation.curAnim.name.endsWith('miss')) {
			playAnim(idleAnim);
			return;
		}
		//Normal notes
		if (animation.finished || isIdlePlaying) {
			playAnim(idleAnim);
			return;
		}





		/*
		if (!animation.curAnim.name.startsWith("sing")) {
			playAnim(idleAnim);
			return;
		}
		if (animation.curAnim.name.endsWith('miss') && animation.curAnim.finished) {
			playAnim(idleAnim);
			return;
		}
		if (holdTimer > Conductor.stepCrochet * 4 * 0.001) {
			if (animation.curAnim.name.startsWith('sing') && !animation.curAnim.name.endsWith('miss')) {
				playAnim(idleAnim);
				return;
			}
		}
		*/
	}

	override function update(elapsed:Float) {
		if (!debugMode) {
			if (animation.curAnim.name.startsWith('sing')) {
				holdTimer += elapsed;
			}
			else
				holdTimer = FlxMath.lerp(holdTimer, 0, 2 * elapsed);

			if (animation.curAnim.name.endsWith('miss') && animation.curAnim.finished && !debugMode) {
				playAnim(idleAnim, true, false, 10);
			}
		}
		if (!animation.curAnim.name.startsWith("sing") && missColorTransform) {
			resetColorTransform();
		}
		if (animation.curAnim.name == 'firstDeath' && animation.curAnim.finished) {
			playAnim('deathLoop');
		}
		//null check for multiplayer
		if (PlayState.currentPlaystate != null) {
			if (PlayState.currentPlaystate.playAs == "bf") {
				if (!curCharacter.startsWith('bf')) {
					var dadVar:Float = 4;
					if (curCharacter == 'dad')
						dadVar = 6.1;

					if (holdTimer != 0 && holdTimer >= Conductor.stepCrochet * dadVar * 0.001) {
						playIdle();
						holdTimer = 0;
					}
				}
			}
		}

		switch (curCharacter) {
			case 'gf':
				if (animation.curAnim.name == 'hairFall' && animation.curAnim.finished)
					playIdle();
		}

		super.update(elapsed);
	}

	private var danced:Bool = false;

	/**
	 * FOR GF DANCING SHIT
	 */
	@:deprecated("use playIdle instead of dance dummy")
	public function dance() {
		var missAnim = false;
		if (animation.curAnim.name.endsWith('miss')) {
			if (animation.curAnim.finished) {
				missAnim = false;
			}
			else {
				missAnim = true;
			}
		}
		if (!debugMode && !stunned && !missAnim) {
			switch (curCharacter) {
				case 'gf':
					if (!animation.curAnim.name.startsWith('hair')) {
						danced = !danced;

						if (danced)
							playAnim('danceRight');
						else
							playAnim('danceLeft');
					}

				case 'gf-custom':
					if (!animation.curAnim.name.startsWith('hair')) {
						danced = !danced;

						if (danced)
							playAnim('danceRight');
						else
							playAnim('danceLeft');
					}

				case 'gf-christmas':
					if (!animation.curAnim.name.startsWith('hair')) {
						danced = !danced;

						if (danced)
							playAnim('danceRight');
						else
							playAnim('danceLeft');
					}

				case 'gf-car':
					if (!animation.curAnim.name.startsWith('hair')) {
						danced = !danced;

						if (danced)
							playAnim('danceRight');
						else
							playAnim('danceLeft');
					}
				case 'gf-pixel':
					if (!animation.curAnim.name.startsWith('hair')) {
						danced = !danced;

						if (danced)
							playAnim('danceRight');
						else
							playAnim('danceLeft');
					}

				case 'gf-tankmen':
					if (!animation.curAnim.name.startsWith('hair')) {
						danced = !danced;

						if (danced)
							playAnim('danceRight');
						else
							playAnim('danceLeft');
					}

				case 'spooky':
					danced = !danced;

					if (danced)
						playAnim('danceRight');
					else
						playAnim('danceLeft');
				default:
					playAnim(idleAnim);
			}
		}
	}

	override public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void {
		if (animation.exists(AnimName)) {
			resetColorTransform();

			if (AnimName.startsWith("sing") && !AnimName.endsWith("miss")) {
				startSingTimer();
			}

			if (AnimName == idleAnim) {
				if (singTimer != null && !singTimer.finished) {
					return;
				}

				if (idleAnim == "danceRight" || idleAnim == "danceLeft") {
					danced = !danced;

					if (danced)
						super.playAnim('danceRight', Force, Reversed, Frame);
					else
						super.playAnim('danceLeft', Force, Reversed, Frame);
					return;
				}
			}

			super.playAnim(AnimName, Force, Reversed, Frame);

			if (curCharacter == 'gf') {
				if (AnimName == 'singLEFT') {
					danced = true;
				}
				else if (AnimName == 'singRIGHT') {
					danced = false;
				}

				if (AnimName == 'singUP' || AnimName == 'singDOWN') {
					danced = !danced;
				}
			}
		} else {
			if (AnimName.endsWith("miss")) {
				super.playAnim(AnimName.substring(0, AnimName.length - 4), Force, Reversed, Frame);
				colorTransform.redOffset = -45;
				colorTransform.greenOffset = -80;
				colorTransform.blueOffset = -50;
				missColorTransform = true;
			}
		}
	}

	public function setConfigPath(path:String) {
		configPath = path;
	}

	var missColorTransform:Bool = false;
}

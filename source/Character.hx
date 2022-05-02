package;

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

	public function addPrefixAlternative(name, prefix, frames, looped) {
		animationsFromAlt.add(name);
		animation.addByPrefix(name, prefix, frames, looped);
	}

	public function new(x:Float, y:Float, ?character:String = "bf", ?isPlayer:Bool = false, isDebug = false) {
		super(x, y);

		animationsFromAlt = new List<String>();
		animOffsets = new Map<String, Array<Dynamic>>();
		curCharacter = character;
		this.isPlayer = isPlayer;
		this.debugMode = isDebug;

		antialiasing = true;

		if (Paths.isCustomPath(CoolUtil.getCharacterPath(curCharacter))) {
			var path = CoolUtil.getCharacterPath(curCharacter) + curCharacter;
			if (path.startsWith("mods/skins/")) {
				var spltPath = path.split("/");
				spltPath[spltPath.length - 1] = spltPath[spltPath.length - 2];
				path = "";
				for (index in 0...spltPath.length) {
					path += spltPath[index] + "/";
				}
				path = path.substring(0, path.length - 1);
			}
			if (FileSystem.exists(path + ".txt")) {
				frames = Paths.PEgetPackerAtlas(path);
			}
			else {
				frames = Paths.PEgetSparrowAtlas(path);
			}
		}
		else {
			if (FileSystem.exists(CoolUtil.getCharacterPath(curCharacter) + curCharacter + ".txt")) {
				frames = Paths.getPackerAtlas('characters/' + curCharacter + '/' + curCharacter);
			}
			else {
				frames = Paths.getSparrowAtlas('characters/' + curCharacter + '/' + curCharacter);
			}
		}

		var idleAnim = "idle";

		setConfig(CoolUtil.getCharacterPath(curCharacter) + 'config.yml');

		if (FileSystem.exists(configPath)) {
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
				if (idleAnim != null) {
					playAnim(idleAnim);
				}
				if (Std.string(config.get('flipX')) == "true") {
					flipX = true;
				} else if (Std.string(config.get('flipX')) == "false") {
					flipX = false;
				}
			}
		}

		switch (curCharacter) {
			case 'gf':
				playAnim('danceRight');
			case 'gf-christmas':
				playAnim('danceRight');
			case 'gf-car':
				playAnim('danceRight');
			case 'gf-pixel':
				playAnim('danceRight');

				setGraphicSize(Std.int(width * PlayState.daPixelZoom));
				updateHitbox();
				antialiasing = false;
			case 'dad':
				playAnim('idle');
			case 'spooky':
				playAnim('danceRight');
			case 'mom':
				playAnim('idle');
			case 'mom-car':
				playAnim('idle');
			case 'monster':
				playAnim('idle');
			case 'monster-christmas':
				playAnim('idle');
			case 'pico':
				playAnim('idle');
			case 'bf':
				playAnim('idle');
			case 'bf-christmas':
				playAnim('idle');
			case 'bf-car':
				playAnim('idle');
			case 'bf-pixel':
				setGraphicSize(Std.int(width * 6));
				updateHitbox();

				playAnim('idle');

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
				playAnim('idle');

				setGraphicSize(Std.int(width * 6));
				updateHitbox();

				antialiasing = false;
			case 'senpai-angry':
				playAnim('idle');

				setGraphicSize(Std.int(width * 6));
				updateHitbox();

				antialiasing = false;
			case 'spirit':
				setGraphicSize(Std.int(width * 6));
				updateHitbox();

				playAnim('idle');

				antialiasing = false;
			case 'parents-christmas':
				playAnim('idle');
			default:
				playAnim(idleAnim);
		}

		dance();

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

	override function update(elapsed:Float) {
		if (!animation.curAnim.name.startsWith("sing") && missColorTransform) {
			resetColorTransform();
		}
		if (animation.curAnim.name == 'firstDeath' && animation.curAnim.finished) {
			playAnim('deathLoop');
		}
		if (PlayState.playAs == "bf") {
			if (!curCharacter.startsWith('bf')) {
				if (animation.curAnim.name.startsWith('sing')) {
					holdTimer += elapsed;
				}

				var dadVar:Float = 4;
				if (curCharacter == 'dad')
					dadVar = 6.1;
				
				if (holdTimer >= Conductor.stepCrochet * dadVar * 0.001) {
					dance();
					holdTimer = 0;
				}
			}
		}

		switch (curCharacter) {
			case 'gf':
				if (animation.curAnim.name == 'hairFall' && animation.curAnim.finished)
					playAnim('danceRight');
		}

		super.update(elapsed);
	}

	private var danced:Bool = false;

	/**
	 * FOR GF DANCING SHIT
	 */
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
				case 'pico-speaker':
					playAnim("picoShoot1");
				default:
					playAnim('idle');
			}
		}
	}

	override public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void {
		if (animation.exists(AnimName)) {
			resetColorTransform();
			
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

	public function setConfig(path:String) {
		configPath = path;
		if (FileSystem.exists(configPath)) {
			config = CoolUtil.readYAML(configPath);
		}
	}

	var missColorTransform:Bool = false;
}

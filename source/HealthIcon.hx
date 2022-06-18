package;

import sys.io.File;
import sys.FileSystem;
import openfl.display.BitmapData;
import flixel.FlxSprite;

using StringTools;

class HealthIcon extends FlxSprite {
	/**
	 * Used for FreeplayState! If you use it elsewhere, prob gonna annoying
	 */
	public var sprTracker:FlxSprite;

	/**
	 * character name or the path if char is set by `setCharFromPath`
	 * if equals `face` then health icon was not found
	 */
	public var curChar:String;

	/**
	 * character name or the path if char is set by `setCharFromPath`
	 */
	public var actualChar:String;

	public var isPlayer:Bool = false;

	public function new(char:String = 'bf', isPlayer:Bool = false, skipSetChar:Bool = false) {
		super();
		this.isPlayer = isPlayer;
		if (!skipSetChar || char == null)
			setChar(char);
	}

	public function setCharFromPath(path:String) {
		actualChar = path;
		if (FileSystem.exists(path)) {
			loadGraphic(BitmapData.fromBytes(File.getBytes(path)), true, 150, 150);
			curChar = path;
		}
		else if (Paths.exists(path)) {
			loadGraphic(path, true, 150, 150);
			curChar = path;
		}
		else {
			loadGraphic(Paths.image('icons/icon-face'), true, 150, 150);
			curChar = "face";
		}
		antialiasing = true;
		setAnimationShit();
		scrollFactor.set();
	}

	public function setChar(char:String = 'bf', updateIsPlayer:Bool = null) {
		if (updateIsPlayer != null) {
			isPlayer = updateIsPlayer;
		}
		var type = "normal";

		actualChar = char;
		switch (char) {
			case 'bf-custom': 
				curChar = char;
				type = "skin";
			case 'gf-custom': 
				curChar = char;
				type = "skin";
			case 'dad-custom': 
				curChar = char;
				type = "skin";
			case 'gf-christmas': curChar = "gf";
			case 'gf-car': curChar = "gf";
			case 'gf-pixel': curChar = "gf";
			case 'gf-tankmen': curChar = "gf";
			case 'mom-car': curChar = "mom";
			case 'monster': curChar = char;
			case 'monster-christmas': curChar = "monster";
			case 'bf-christmas': curChar = "bf";
			case 'bf-car': curChar = "bf";
			case 'bf-holding-gf': curChar = "bf";
			case 'bf-pixel': curChar = "bf-pixel";
			case 'senpai-angry': curChar = "senpai";
			case 'parents-christmas': curChar = "parents";
			case "pico-speaker": curChar = "pico";
			default:
				curChar = char;
				if (FileSystem.exists(${Paths.modsLoc} + "/characters/" + curChar + "/icon.png")) {
					type = "mods";
				}
		}
		if (type == "skin") {
			if (isPlayer == false) {
				if (char.startsWith("gf")) {
					if (Options.customGf && FileSystem.exists(Paths.skinIcon("gf"))) {
						loadGraphic(BitmapData.fromBytes(File.getBytes(Paths.skinIcon("gf"))), true, 150, 150);
					} else {
						loadGraphic(Paths.image('icons/icon-gf'), true, 150, 150);
						curChar = "gf";
					}
				}
				else if (char.startsWith("dad")) {
					if (Options.customDad && FileSystem.exists(Paths.skinIcon("dad"))) {
						loadGraphic(BitmapData.fromBytes(File.getBytes(Paths.skinIcon("dad"))), true, 150, 150);
					} else {
						loadGraphic(Paths.image('icons/icon-dad'), true, 150, 150);
						curChar = "dad";
					}
				}
			}
			else if (isPlayer && Options.customBf && FileSystem.exists(Paths.skinIcon("bf"))) {
				loadGraphic(BitmapData.fromBytes(File.getBytes(Paths.skinIcon("bf"))), true, 150, 150);
			} else {
				loadGraphic(Paths.image('icons/icon-bf'), true, 150, 150);
				curChar = "bf";
			}
		}
		if (type == "mods") {
			if (FileSystem.exists(Paths.modsIcon(curChar))) {
				loadGraphic(BitmapData.fromBytes(File.getBytes(Paths.modsIcon(curChar))), true, 150, 150);
			} else {
				loadGraphic(Paths.image('icons/icon-face'), true, 150, 150);
				curChar = "face";
			}
		}
		if (type == "normal") {
			if (BitmapData.fromFile(Paths.image('icons/icon-$curChar')) != null) {
				loadGraphic(Paths.image('icons/icon-$curChar'), true, 150, 150);
			} else {
				loadGraphic(Paths.image('icons/icon-face'), true, 150, 150);
				curChar = "face";
			}
		}
		
		antialiasing = true;
		setAnimationShit();
		scrollFactor.set();
	}

	public function setAnimationShit() {
		animation.add(curChar, [0, 1], 0, false, isPlayer);
		animation.play(curChar);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 10, sprTracker.y - 30);
	}
}
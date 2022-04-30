package;

import openfl.display.StageQuality;
import sys.ssl.Key;
import flixel.input.keyboard.FlxKey;
import Controls.KeyBind;
import flixel.FlxG;
import flixel.math.FlxPoint;
import flixel.util.FlxSave;

class Options {
	// adding here a static variable without "_" at the beginning will make a new option

	// SKINS
	public static var customGf = false;
	public static var customGfPath = "";
	public static var customBf = false;
	public static var customBfPath = "";
	public static var customDad = false;
	public static var customDadPath = "";

	// MAIN
	public static var masterVolume:Float = 1;
	public static var ghostTapping = true;
	public static var bgDimness:Float = 0.0;
	public static var framerate:Int = 145;
	public static var discordRPC:Bool = true;
	public static var disableCrashHandler:Bool = false;
	public static var downscroll:Bool = false;
	public static var updateChecker:Bool = true;
	public static var disableSpamChecker:Bool = false;
	public static var freeplayListenVocals:Bool = false;
	
	private static var _optionsSave:FlxSave;
	private static var _controlsSave:FlxSave;

	public static function startupSaveScript() {
		_controlsSave = new FlxSave();
		_controlsSave.bind("controls");
		saveKeyBinds();

		_optionsSave = new FlxSave();
		_optionsSave.bind("options");
		saveAndLoadAll();
		#if debug
		trace("Options Data: " + _optionsSave.data);
		#end
	}

	public static function exists(variable):Dynamic {
		if (get(variable) != null) {
			return true;
		}
		return false;
	}

	public static function saveKeyBinds() {
		if (_controlsSave.data == "{ }" || _controlsSave.data == null) {
			KeyBind.setToDefault();
			for (keyType => keyArray in KeyBind.controlsMap) {
				Reflect.setField(_controlsSave.data, Std.string(keyType), keyArray);
			}
		}
		else {
			for (field in Reflect.fields(_controlsSave.data)) {
				var val = Reflect.field(_controlsSave.data, field);
				KeyBind.controlsMap.set(KeyBind.typeFromString(field), val);
			}
		}
	}

	public static function get(variable):Dynamic {
		return Reflect.field(_optionsSave.data, variable);
	}

	public static function set(variable, value) {
		Reflect.setField(_optionsSave.data, variable, value);
	}

	public static function setAndSave(variable, value) {
		Reflect.setField(_optionsSave.data, variable, value);
		saveFile();
	}

	/** Saves options and controls save file */
	public static function saveFile() {
		_optionsSave.flush();
		_controlsSave.flush();
	}

	public static function saveAndLoadAll() {
		for (i in getClassOptions()) {
			if (!exists(i)) {
				set(i, Reflect.field(Options, i));
			}
		}
		saveFile();
		loadAll();
	}

	/** Saves settings and saves them to the save file */
	public static function saveAll() {
		for (i in getClassOptions()) {
			set(i, Reflect.field(Options, i));
		}
		saveFile();
	}

	/** Loads settings from save file */
	public static function loadAll() {
		for (i in getClassOptions()) {
			Reflect.setField(Options, i, get(i));
		}
	}

	/** Applies shit from settings to the game like: controls, fps */
	public static function applyAll() {
		FlxG.updateFramerate = framerate;
		FlxG.drawFramerate = framerate;
		// PlayerSettings.player1.controls.bindFromSettings(true);
	}

	static function getClassOptions():Array<String> {
		var arr:Array<String> = [];
		for (i in Type.getClassFields(Options)) {
			if (Reflect.field(Options, i) != i) {
				if (!i.startsWith("_")) {
					arr.push(i);
				}
			}
		}
		return arr;
	}
}

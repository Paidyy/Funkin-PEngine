package;

import flixel.system.FlxSound;
import Song.SwagSong;
import sys.io.File;
import haxe.Exception;
import openfl.display.BitmapData;
import lime.ui.FileDialog;
import openfl.utils.ByteArray;
import openfl.display.PNGEncoderOptions;
import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import sys.FileSystem;
import multiplayer.Lobby;
import haxe.io.Path;
import lime.utils.Assets;
import yaml.Yaml;
import openfl.utils.Assets as OpenFlAssets;

class CoolUtil {
	public static var difficultyArray:Array<String> = ['EASY', "NORMAL", "HARD"];

	#if lime
	public static function setPitch(sound:FlxSound, pitch:Float = 1.0) {
		try {
			@:privateAccess
			lime.media.openal.AL.sourcef(sound._channel.__source.__backend.handle, lime.media.openal.AL.PITCH, pitch);
		}
		catch (exc) {}
	}

	public static function getPitch(sound:FlxSound) {
		try {
			@:privateAccess
			return lime.media.openal.AL.getSourcef(sound._channel.__source.__backend.handle, lime.media.openal.AL.PITCH);
		}
		catch (exc) { 
			return 1;
		}
	}
	#end

	public static function setDifficultyList(song:String):Array<String> {
		var DIFFS = [];
		for (file in FileSystem.readDirectory(Paths.getSongPath(song, true))) {
			if (file.startsWith(song.toLowerCase()) && file.endsWith(".json")) {
				var diff = file.substring(0, file.length - 5);
				diff = diff.split("-")[diff.split("-").length - 1];
				if (diff == song.toLowerCase() || diff == song.toLowerCase().split("-")[song.toLowerCase().split("-").length - 1])
					diff = "normal";
				DIFFS.push(diff.toUpperCase());
			}
		}
		var diffs = [];
		if (DIFFS.contains("EASY")) {
			diffs.push(DIFFS[DIFFS.indexOf("EASY")]);
			DIFFS.remove("EASY");
		}
		if (DIFFS.contains("NORMAL")) {
			diffs.push(DIFFS[DIFFS.indexOf("NORMAL")]);
			DIFFS.remove("NORMAL");
		}
		if (DIFFS.contains("HARD")) {
			diffs.push(DIFFS[DIFFS.indexOf("HARD")]);
			DIFFS.remove("HARD");
		}
		for (diff in DIFFS) {
			diffs.push(diff);
		}
		difficultyArray = diffs;
		return difficultyArray;
	}

	/**
	 * Writes to file, if the file doesnt exist it creates one
	 * @param path the path
	 * @param content the content, can be anything
	 * @param binary will it be saved to binary mode, false by default
	*/
	public static function writeToFile(path:String, content:Dynamic, ?binary:Bool = false):Void {
        if (!FileSystem.exists(path)) {
            File.write(path, binary);
        }
		if (binary)
			File.saveBytes(path, content);
		else
        	File.saveContent(path, content);
    }

	//taken from psych dont kill me
	public static function bound(value:Float, ?min:Float = 0, ?max:Float = 1):Float {
		return Math.max(min, Math.min(max, value));
	}

	/**
	 * :)
	 */
	public static function crash() {
		throw new Exception("no bitches error (690)");
	}

	public static function difficultyString():String {
		return difficultyArray[PlayState.storyDifficulty];
	}

	public static function isCustomWeek(week:String) {
		return !OpenFlAssets.hasLibrary(week);
	}

	public static function getLargestKeyInMap(map:Map<String, Float>):String {
		var largestKey:String = null;
		for (key in map.keys()) {
			if (largestKey == null || map.get(key) > map.get(largestKey)) {
				largestKey = key;
			}
		}
		return largestKey;
	}

	/**get dominant color so you dont have to set it manually*/
	public static function getDominantColor(sprite:FlxSprite):FlxColor {
		var colors = new Map<String, Float>();
		for (pixelWidth in 0...sprite.frameWidth) {
			for (pixelHeight in 0...sprite.frameHeight) {
				var pixel32 = sprite.pixels.getPixel32(pixelWidth, pixelHeight);
				var pixel = sprite.pixels.getPixel(pixelWidth, pixelHeight);
				var pixelHex = "#" + pixel.hex(6);

				if (pixel32 != 0) {
					if (colors.exists(pixelHex))
						colors.set(pixelHex, colors.get(pixelHex) + 1);
					else
						colors.set(pixelHex, 1);
				}
			}
		}

		//black has less score for not being used as a fill color
		if (colors.exists("#000000")) {
			colors.set("#000000", colors.get("#000000") / 4);
		}
		
		return FlxColor.fromString(getLargestKeyInMap(colors));
	}

	static inline var multiplier = 10000000;
	// The number of zeros in the following value
	// corresponds to the number of decimals rounding precision
	public static function roundFloat(value:Float):Float
		return Math.round(value * multiplier) / multiplier;

	public static function isStringInt(s:String) {
		var index = 0;
		if (s.startsWith("-")) {
			index = 1;
		}

		var splittedString = s.split("");
		switch (splittedString[index]) {
			case "1", "2", "3", "4", "5", "6", "7", "8", "9", "0":
				return true;
		}
		return false;
	}

	public static function stringToOgType(s:String):Dynamic {
		//if is integer or float
		if (isStringInt(s)) {
			if (s.contains(".")) {
				return Std.parseFloat(s);
			} else {
				return Std.parseInt(s);
			}
		}
		//if is a bool
		if (s == "true")
			return true;
		if (s == "false")
			return false;

		//if it is null
		if (s == "null")
			return null;

		//else return the original string
		return s;
	}

	public static function strToBool(s:String):Dynamic {
		switch (s.toLowerCase()) {
			case "true":
				return true;
			case "false":
				return false;
			default:
				return null;
		}
	}

	public static function toBool(d):Dynamic {
		var s = Std.string(d);
		switch (s.toLowerCase()) {
			case "true":
				return true;
			case "false":
				return false;
			default:
				return null;
		}
	}
	
	public static function clearMPlayers() {
		Lobby.player1.clear();
		Lobby.player2.clear();
	}

	public static function coolTextFile(path:String):Array<String> {
		var daList;
		if (Paths.isCustomPath(path)) {
			daList = File.getContent(path).trim().split('\n');
		}
		else {
			daList = Assets.getText(path).trim().split('\n');
		}

		for (i in 0...daList.length) {
			daList[i] = daList[i].trim();
			daList[i] = daList[i].replace('\\n', '\n');
		}

		return daList;
	}

	public static function readYAML(path:String):Dynamic {
		#if sys
		return Yaml.read(path);
		#else
		return null;
		#end
	}

	@:access(lime._internal.backend.native.NativeCFFI)
	public static function getAppData() {
		var path = "";
		#if hl
		path = @:privateAccess String.fromUTF8(lime._internal.backend.native.NativeCFFI.lime_system_get_directory(1, "", ""));
		#else
		path = lime._internal.backend.native.NativeCFFI.lime_system_get_directory(1, "", "");
		#end
		path = StringTools.replace(path, "//", "/");
		return path;
	}

	public static function getStages():Array<String> {
		var stages = Stage.stagesList;
		var mods_characters_path = '${Paths.modsLoc}/stages/';
		for (stage in FileSystem.readDirectory(mods_characters_path)) {
			var path = Path.join([mods_characters_path, stage]);
			if (FileSystem.isDirectory(path)) {
				stages.push(stage);
			}
		}
		return stages;
	}

	public static function getCharacters():Array<String> {
		var list = [];
		var assets_song_path = "assets/shared/images/characters/";
		for (file in FileSystem.readDirectory(assets_song_path)) {
			var path = haxe.io.Path.join([assets_song_path, file]);
			if (FileSystem.isDirectory(path)) {
				list.push(file);
			}
		}
		var mods_characters_path = '${Paths.modsLoc}/characters/';
		for (char in FileSystem.readDirectory(mods_characters_path)) {
			var path = Path.join([mods_characters_path, char]);
			if (FileSystem.isDirectory(path)) {
				list.push(char);
			}
		}
		return list;
	}

	public static function getSongs():Array<String> {
		var list = [];
		var assets_song_path = "assets/songs/";
		for (file in FileSystem.readDirectory(assets_song_path)) {
			var path = haxe.io.Path.join([assets_song_path, file]);
			if (FileSystem.isDirectory(path)) {
				list.push(file);
			}
		}
		var pengine_song_path = '${Paths.modsLoc}/songs/';
		for (file in FileSystem.readDirectory(pengine_song_path)) {
			var path = haxe.io.Path.join([pengine_song_path, file]);
			if (FileSystem.isDirectory(path)) {
				list.push(file);
			}
		}
		return list;
	}

	public static function numberArray(max:Int, ?min = 0):Array<Int> {
		var dumbArray:Array<Int> = [];
		for (i in min...max) {
			dumbArray.push(i);
		}
		return dumbArray;
	}

	public static function isEmpty(d:Dynamic):Bool {
		if (d == "" || d == 0 || d == null || d == "0" || d == "null" || d == "empty" || d == "none") {
			return true;
		}
		return false;
	}
}

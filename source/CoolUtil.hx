package;

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

	public static function getSongPath(songName:String, ?dataFolder = false) {
		if (FileSystem.exists("mods/songs/" + songName.toLowerCase() + "/")) {
			return "mods/songs/" + songName.toLowerCase() + "/";
		}
		else if (FileSystem.exists("assets/" + (dataFolder ? 'data' : 'songs') + "/" + songName.toLowerCase() + "/")) {
			return "assets/" + (dataFolder ? 'data' : 'songs') + "/" + songName.toLowerCase() + "/";
		}
		return null;
	}

	public static function getStagePath(stageName:String) {
		if (FileSystem.exists("mods/stages/" + stageName.toLowerCase() + "/")) {
			return "mods/stages/" + stageName.toLowerCase() + "/";
		} 
		else if (FileSystem.exists("assets/stages/" + stageName.toLowerCase() + "/")) {
			return "assets/stages/" + stageName.toLowerCase() + "/";
		}
		return null;
	}

	public static function getCharacterPath(characterName:String) {
		if (!characterName.endsWith("-custom")) {
			if (FileSystem.exists("mods/characters/" + characterName + "/")) {
				return "mods/characters/" + characterName + "/";
			}
			else if (FileSystem.exists("assets/shared/images/characters/" + characterName + "/")) {
				return "assets/shared/images/characters/" + characterName + "/";
			}
		}
		else {
			switch (characterName) {
				case 'bf-custom':
					return Options.customBfPath;
				case 'gf-custom':
					return Options.customGfPath;
				case 'dad-custom':
					return Options.customDadPath;
			}
		}
		return null;
	}

	public static function getSongJson(songName:String, ?difficulty:Int):SwagSong {
		var dataFileDifficulty:String = "";
		switch (difficulty) {
			case 0:
				dataFileDifficulty = '-easy';
			case 1:
				dataFileDifficulty = "";
			case 2:
				dataFileDifficulty = '-hard';
		}

		var json:SwagSong;
		if (FileSystem.exists(Paths.instNoLib(songName.toLowerCase()))) {
			json = Song.loadFromJson(songName.toLowerCase() + dataFileDifficulty, songName.toLowerCase());
		} else {
			json = Song.PEloadFromJson(songName.toLowerCase() + dataFileDifficulty, songName.toLowerCase());
		}
		return json;
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

	public static function splitDialogue(s:String) {
		var str = s.split('\n');

		for (i in 0...str.length) {
			str[i] = str[i].trim();
			str[i] = str[i].replace('\\n', '\n');
		}

		return str;
	}

	public static function readYAML(path:String) {
		#if sys
		return Yaml.read(path);
		#else
		return null;
		#end
	}

	public static function getStages():Array<String> {
		var stages = Stage.stagesList;
		var mods_characters_path = "mods/stages/";
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
		var mods_characters_path = "mods/characters/";
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
		var pengine_song_path = "mods/songs/";
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

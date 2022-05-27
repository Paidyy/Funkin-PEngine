package;

import Song.SwagSong;
import sys.io.File;
import sys.FileSystem;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.tile.FlxGraphicsShader;
import flixel.system.FlxAssets.FlxGraphicSource;
import flixel.util.FlxColor;
import haxe.io.Path;
import lime.utils.Assets;
import openfl.display.BitmapData;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;

using StringTools;

class Paths {

	// improve these because it's shit

	inline public static var FS = #if neko '/' #else '\\' #end;

	inline public static var SOUND_EXT = #if web 'mp3' #else 'ogg' #end;

	//for android support in future?
	public static var modsLoc:String = "mods";

	static var currentLevel:String = 'week0';

	static var currentStage:String = 'stage';

	static public function setCurrentLevel(name:String) {
		currentLevel = name.toLowerCase();
	}

	static public function setCurrentStage(stage:String) {
		currentStage = stage;
	}

	public static function slashPath(path:String) {
		path = path.replace("/", FS);
		path = path.replace("\\", FS);
		return path;
	} 

	public static function isCustomPath(arg0:String) {
		if (OpenFlAssets.exists(arg0)) {
			return false;
		}
		if (arg0.startsWith(Paths.modsLoc)) {
			return true;
		}
		else {
			return false;
		}
	}

	static function getPath(file:String, type:AssetType, library:Null<String>) {
		if (library != null)
			return getLibraryPath(file, library);
		
		if (currentLevel != null) {
			var levelPath = getLibraryPathForce(file, currentLevel);
			/*
			if (!(levelPath.contains('NOTE_assets') || levelPath.contains('alphabet'))) {
				trace(levelPath + ' | ' + OpenFlAssets.exists(levelPath, type));
			}
			*/
			if (OpenFlAssets.exists(levelPath, type))
				return levelPath;

			levelPath = getLibraryPathForce(file, 'shared');
			if (OpenFlAssets.exists(levelPath, type))
				return levelPath;
		}

		return getPreloadPath(file);
	}

	public static function getSongGlobalNotesPath(songName:String) {
		return getSongPath(songName, true) + 'global_notes.json';
	}

	public static function getSongPath(songName:String, ?dataFolder = false) {
		if (FileSystem.exists('${modsLoc}${FS}songs${FS}' + songName.toLowerCase() + '${FS}')) {
			return '${modsLoc}${FS}songs${FS}' + songName.toLowerCase() + ${FS};
		}
		else if (FileSystem.exists('assets${FS}' + (dataFolder ? 'data' : 'songs') + ${FS} + songName.toLowerCase() + ${FS})) {
			return 'assets${FS}' + (dataFolder ? 'data' : 'songs') + ${FS} + songName.toLowerCase() + ${FS};
		}
		return null;
	}

	public static function getStagePath(stageName:String) {
		if (FileSystem.exists('${modsLoc}/stages/' + stageName.toLowerCase() + '/')) {
			return '${modsLoc}/stages/' + stageName.toLowerCase() + '/';
		}
		else if (FileSystem.exists('assets/stages/' + stageName.toLowerCase() + '/')) {
			return 'assets/stages/' + stageName.toLowerCase() + '/';
		}
		return null;
	}

	/**
	 * WARNING: GETS THE SYS PATH, NOT OPENFL PATH
	 */
	public static function getCharacterPath(characterName:String) {
		if (!characterName.endsWith('-custom')) {
			if (FileSystem.exists('${modsLoc}/characters/' + characterName + '/')) {
				return '${modsLoc}/characters/' + characterName + '/';
			}
			else if (FileSystem.exists('assets/shared/images/characters/' + characterName + '/')) {
				return 'assets/shared/images/characters/' + characterName + '/';
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
		var dataFileDifficulty:String = '';
		switch (difficulty) {
			case 0:
				dataFileDifficulty = '-easy';
			case 1:
				dataFileDifficulty = '';
			case 2:
				dataFileDifficulty = '-hard';
		}

		var json:SwagSong;
		if (FileSystem.exists(Paths.instNoLib(songName.toLowerCase()))) {
			json = Song.loadFromJson(songName.toLowerCase() + dataFileDifficulty, songName.toLowerCase());
		}
		else {
			json = Song.PEloadFromJson(songName.toLowerCase() + dataFileDifficulty, songName.toLowerCase());
		}
		return json;
	}

	@:deprecated('use getSongPath()')
	public static function getSongFolder(songName:String):String {
		var song = songName.toLowerCase();

		for (file in FileSystem.readDirectory('${modsLoc}/songs/')) {
			var path = haxe.io.Path.join(['${modsLoc}/songs/', file]);
			if (FileSystem.isDirectory(path) && file == song) {
				return path + '/';
			}
		}
		for (file in FileSystem.readDirectory('assets/songs/')) {
			var path = haxe.io.Path.join(['assets/songs/', file]);
			if (FileSystem.isDirectory(path)) {
				if (FileSystem.isDirectory(path) && file == song) {
					return path + '/';
				}
			}
		}
		return null;
	}

	static public function getLibraryPath(file:String, library = 'preload') {
		return if (library == 'preload' || library == 'default') getPreloadPath(file); else getLibraryPathForce(file, library);
	}

	inline static function getLibraryPathForce(file:String, library:String) {
		return '$library:assets/$library/$file';
	}

	inline static function getPreloadPath(file:String) {
		return 'assets/$file';
	}

	inline static public function file(file:String, type:AssetType = TEXT, ?library:String) {
		return getPath(file, type, library);
	}

	inline static public function txt(key:String, ?library:String) {
		return getPath('data/$key.txt', TEXT, library);
	}

	inline static public function xml(key:String, ?library:String) {
		return getPath('data/$key.xml', TEXT, library);
	}

	inline static public function json(key:String, ?library:String) {
		return getPath('data/$key.json', TEXT, library);
	}

	static public function sound(key:String, ?library:String) {
		return getPath('sounds/$key.$SOUND_EXT', SOUND, library);
	}

	static public function stageMusic(key:String, ?stage:String) {
		if (stage == null) stage = currentStage;
		return getLibraryPathForce('$stage/music/$key.$SOUND_EXT', 'stages');
	}

	inline static public function stageImage(key:String, ?stage:String) {
		if (stage == null) stage = currentStage;
		return getLibraryPathForce('$stage/images/$key.png', 'stages');
	}

	inline static public function stageSparrow(key:String, ?stage:String) {
		if (stage == null) stage = currentStage;
		return FlxAtlasFrames.fromSparrow(stageImage(key, stage), getLibraryPathForce('$stage/images/$key.xml', 'stages'));
	}

	inline static public function stagePacker(key:String, ?stage:String) {
		if (stage == null) stage = currentStage;
		return FlxAtlasFrames.fromSpriteSheetPacker(stageImage(key, stage), getLibraryPathForce('$stage/images/$key.txt', 'stages'));
	}

	inline static public function soundRandom(key:String, min:Int, max:Int, ?library:String) {
		return sound(key + FlxG.random.int(min, max), library);
	}

	inline static public function music(key:String, ?library:String) {
		return getPath('music/$key.$SOUND_EXT', MUSIC, library);
	}

	inline static public function voices(song:String) {
		return 'songs:assets/songs/${song.toLowerCase()}/Voices.$SOUND_EXT';
	}

	inline static public function inst(song:String) {
		return 'songs:assets/songs/${song.toLowerCase()}/Inst.$SOUND_EXT';
	}

	inline static public function voicesNoLib(song:String) {
		return 'assets/songs/${song.toLowerCase()}/Voices.$SOUND_EXT';
	}

	inline static public function instNoLib(song:String) {
		return 'assets/songs/${song.toLowerCase()}/Inst.$SOUND_EXT';
	}

	inline static public function PEvoices(song:String) {
		return '${modsLoc}/songs/${song.toLowerCase()}/Voices.$SOUND_EXT';
	}

	inline static public function PEinst(song:String) {
		return '${modsLoc}/songs/${song.toLowerCase()}/Inst.$SOUND_EXT';
	}

	inline static public function getLuaPath(song:String) {
		return getSongPath(song.toLowerCase(), true) + 'script.lua';
	}

	static public function skinIcon(char:String):String {
		if (char == 'bf') {
			return Options.customBfPath + 'icon.png';
		}
		else if (char == 'dad') {
			return Options.customDadPath + 'icon.png';
		}
		else if (char == 'gf') {
			return Options.customGfPath + 'icon.png';
		}
		return null;
	}

	inline static public function modsIcon(char:String) {
		return getCharacterPath(char) + 'icon.png';
	}

	inline static public function PEgetSparrowAtlas(key:String, ?library:String) {
		#if sys
		return FlxAtlasFrames.fromSparrow(BitmapData.fromBytes(File.getBytes(key + '.png')), File.getContent(key + '.xml'));
		#else
		return Paths.getSparrowAtlas('DADDY_DEAREST');
		#end
	}

	inline static public function PEgetPackerAtlas(key:String) {
		return FlxAtlasFrames.fromSpriteSheetPacker(BitmapData.fromBytes(File.getBytes(key + '.png')), File.getContent(key + '.txt'));
	}

	/*
	public static function loadImage(path):Dynamic {
		if (OpenFlAssets.exists(image(path, null), IMAGE)) {
			return image(path, null);
		}
		else if (FileSystem.exists(path)) {
			return BitmapData.fromBytes(File.getBytes(path));
		}
		return null;
	}
	*/
	
	static public function isPathCustom(path:String) {
		return path.contains('${modsLoc}/');
	}

	static public function portrait(char:String) {
		if (OpenFlAssets.exists(image('portraits/${char}'), IMAGE)) {
			return image('portraits/${char}');
		}
		else if (FileSystem.exists('${modsLoc}/portraits/$char.png')) {
			return '${modsLoc}/portraits/$char.png';
		}
		return null;
	}

	inline static public function font(key:String) {
		return 'assets/fonts/$key';
	}

	inline static public function image(key:String, ?library:String) {
		return getPath('images/$key.png', IMAGE, library);
	}

	inline static public function video(key:String, ?library:String) {
		return getPath('cutscenes/$key.mp4', BINARY, library);
	}

	inline static public function getSparrowAtlas(key:String, ?library:String) {
		return FlxAtlasFrames.fromSparrow(image(key, library), file('images/$key.xml', library));
	}

	inline static public function weekimage(key:String, week:Int) {
		return getPath('images/$key.png', IMAGE, 'week$week');
	}

	inline static public function getWeekSparrowAtlas(key:String, week:Int) {
		return FlxAtlasFrames.fromSparrow(weekimage(key, week), file('images/$key.xml', 'week$week'));
	}

	inline static public function getPackerAtlas(key:String, ?library:String) {
		return FlxAtlasFrames.fromSpriteSheetPacker(image(key, library), file('images/$key.txt', library));
	}
}

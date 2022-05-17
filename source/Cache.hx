package;

import flixel.graphics.frames.FlxFramesCollection;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.FlxSprite;
import openfl.display.BitmapData;
import flixel.graphics.frames.FlxAtlasFrames;
import haxe.Resource;
import sys.io.File;
import sys.FileSystem;
import haxe.io.Bytes;
import openfl.media.Sound;

/**
 * Class that caches game assets
 */
class Cache {
    public static var characters:Map<String, Character> = new Map<String, Character>();
	public static var bfs:Map<String, Boyfriend> = new Map<String, Boyfriend>();
	public static var charactersAssets:Map<String, CharacterCache> = new Map<String, CharacterCache>();
	public static var charactersConfigs:Map<String, Dynamic> = new Map<String, Dynamic>();

	public static var menuCharacters:Map<String, MenuCharacter> = new Map<String, MenuCharacter>();

    public static var stages:Map<String, Stage> = new Map<String, Stage>();

    public static var sounds:Map<String, Sound> = new Map<String, Sound>();

    public static var bytes:Map<String, Bytes> = new Map<String, Bytes>();

	public static function cacheCharacter(char, daChar, ?forceCache:Bool = false):Dynamic {
		if (char == "bf") {
			if (!Cache.bfs.exists(daChar) || forceCache) {
				trace("caching character (boyfriend): " + daChar + "...");
				Cache.bfs.set(daChar, new Boyfriend(0, 0, daChar));
			}
			return Cache.bfs.get(daChar);
		}
		else {
			if (!Cache.characters.exists(daChar) || forceCache) {
				trace("caching character: " + daChar + "...");
				Cache.characters.set(daChar, new Character(0, 0, daChar));
			}
            return Cache.characters.get(daChar);
		}
	}

    public static function cacheCharacterConfig(daChar) {
		if (!Cache.charactersConfigs.exists(daChar)) {
            if (FileSystem.exists(Paths.getCharacterPath(daChar) + "config.yml")) {
                Cache.charactersConfigs.set(daChar, CoolUtil.readYAML(Paths.getCharacterPath(daChar) + "config.yml"));
            }
        }
    }

    public static function cacheCharacterAssets(daChar, ?forceCache:Bool = false) {
		var path = Paths.getCharacterPath(daChar);
		if (path.startsWith(${Paths.modsLoc} + "/skins/")) {
			var spltPath = path.split("/");
			path += spltPath[spltPath.length - 2];
		}
		else {
			path += daChar;
		}
		if (!Cache.charactersAssets.exists(daChar) || forceCache) {
            trace("caching character: " + path + "...");
            if (FileSystem.exists(path + ".txt")) {
				Cache.charactersAssets.set(daChar, new CharacterCache(File.getBytes(path + ".png"), File.getContent(path + ".txt")));
            }
            else {
				Cache.charactersAssets.set(daChar, new CharacterCache(File.getBytes(path + ".png"), File.getContent(path + ".xml")));
            }
        }
		cacheCharacterConfig(daChar);
		if (FileSystem.exists(path + ".txt")) {
			return FlxAtlasFrames.fromSpriteSheetPacker(BitmapData.fromBytes(Cache.charactersAssets.get(daChar).imageBytes),
				Cache.charactersAssets.get(daChar).xml);
        }
        else {
			return FlxAtlasFrames.fromSparrow(BitmapData.fromBytes(Cache.charactersAssets.get(daChar).imageBytes), 
                Cache.charactersAssets.get(daChar).xml);
        }
		
	}

    public static function cacheStage(name) {
		if (Cache.stages.get(name) == null) {
            Cache.stages.set(name, new Stage(name));
        }
		return Cache.stages.get(name);
    }

	public static function cacheSound(path:String) {
		if (Cache.sounds.get(path) == null) {
            Cache.sounds.set(path, Sound.fromFile(path));
        }
		return Cache.sounds.get(path);
    }

    public static function cacheBytes(path:String) {
		if (Cache.bytes.get(path) == null) {
            Cache.bytes.set(path, File.getBytes(path));
        }
		return Cache.bytes.get(path);
    }
}

//made this because haxeflixel asset handling is shit
class CharacterCache {
	public var imageBytes:Bytes;
	public var xml:String;

    public function new(imageBytes:Bytes, xml:String) {
        this.imageBytes = imageBytes;
        this.xml = xml;
    }
}
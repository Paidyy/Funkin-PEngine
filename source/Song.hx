package;

import sys.io.File;
import sys.FileSystem;
import Section.SwagSection;
import haxe.Json;
import haxe.format.JsonParser;
import lime.utils.Assets;

using StringTools;

typedef SwagSong = {
	var song:String;
	var bpm:Int;
	var needsVoices:Bool;
	var speed:Float;
	var player1:String;
	var player2:String;
	var validScore:Bool;
	var whichK:Int;
	var stage:String;
	var playAs:String;
	var swapBfGui:Bool;
	var notes:Array<SwagSection>;
}

typedef SwagGlobalNotes = {
	var notes:Array<SwagSection>;
}

class Song {
	public var song:String;
	public var bpm:Int;
	public var needsVoices:Bool = true;
	public var speed:Float = 1;
	public var player1:String = 'bf';
	public var player2:String = 'dad';
	public var whichK:Int = 4;
	public var stage:String;
	public var playAs:String = "bf";
	public var swapBfGui:Bool = false;
	public var notes:Array<SwagSection>;

	public var globalNotes:Array<SwagSection>;

	public function new(song, notes, bpm, stage, ?whichK, ?playAs, ?swapBfGui) {
		this.song = song;
		this.bpm = bpm;
		this.stage = stage;
		this.whichK = whichK;
		this.playAs = playAs;
		this.swapBfGui = swapBfGui;
		this.notes = notes;
	}

	public static function loadFromJson(jsonInput:String, ?folder:String):SwagSong {
		var rawJson = Assets.getText(Paths.json(folder.toLowerCase() + '/' + jsonInput.toLowerCase())).trim();
		// trace("Chart Path: " + Paths.json(folder.toLowerCase() + '/' + jsonInput.toLowerCase()));

		while (!rawJson.endsWith("}")) {
			rawJson = rawJson.substr(0, rawJson.length - 1);
			// LOL GOING THROUGH THE BULLSHIT TO CLEAN IDK WHATS STRANGE
		}

		// FIX THE CASTING ON WINDOWS/NATIVE
		// Windows???
		// trace(songData);

		// trace('LOADED FROM JSON: ' + songData.notes);
		/* 
			for (i in 0...songData.notes.length)
			{
				trace('LOADED FROM JSON: ' + songData.notes[i].sectionNotes);
				// songData.notes[i].sectionNotes = songData.notes[i].sectionNotes
			}

				daNotes = songData.notes;
				daSong = songData.song;
				daBpm = songData.bpm; */

		return parseJSONshit(rawJson);
	}

	public static function PEloadFromJson(songName:String, ?songNameNoDiff:String = null):SwagSong {
		songName = songName.toLowerCase();
		if (songNameNoDiff == null) {
			songNameNoDiff = songName;
		}
		else {
			songNameNoDiff = songNameNoDiff.toLowerCase();
		}
		// trace("Chart Path: " + 'mods/songs/' + songNameNoDiff + '/' + songName + ".json");
		var rawJson = "{}";
		try {
			if (FileSystem.exists(${Paths.modsLoc} + "/songs/" + songNameNoDiff + "/" + songName + ".json")) {
				#if desktop
				rawJson = sys.io.File.getContent(${Paths.modsLoc} + "/songs/" + songNameNoDiff + "/" + songName + ".json");
				#end
			}
			else {
				return null;
			}
		}
		catch (error) {
			trace(error);
		}

		while (!rawJson.endsWith("}")) {
			rawJson = rawJson.substr(0, rawJson.length - 1);
			// LOL GOING THROUGH THE BULLSHIT TO CLEAN IDK WHATS STRANGE
		}

		// FIX THE CASTING ON WINDOWS/NATIVE
		// Windows???
		// trace(songData);

		// trace('LOADED FROM JSON: ' + songData.notes);
		/* 
			for (i in 0...songData.notes.length)
			{
				trace('LOADED FROM JSON: ' + songData.notes[i].sectionNotes);
				// songData.notes[i].sectionNotes = songData.notes[i].sectionNotes
			}

				daNotes = songData.notes;
				daSong = songData.song;
				daBpm = songData.bpm; */

		return parseJSONshit(rawJson);
	}

	public static function parseJSONshit(rawJson:String):SwagSong {
		var swagShit:SwagSong = cast Json.parse(rawJson).song;
		swagShit.validScore = true;
		if (CoolUtil.isEmpty(swagShit.whichK)) {
			swagShit.whichK = 4;
		}
		return swagShit;
	}

	public static function parseGlobalNotesJSONshit(song:String):SwagGlobalNotes {
		var rawJson = null;
		if (Assets.exists(Paths.json(song.toLowerCase() + "/global_notes.json"))) {
			rawJson = Assets.getText(Paths.json(song.toLowerCase() + "/global_notes.json"));
		}
		else if (FileSystem.exists(Paths.getSongGlobalNotesPath(song.toLowerCase()))) {
			rawJson = File.getContent(Paths.getSongGlobalNotesPath(song.toLowerCase()));
		}
		if (rawJson == null)
			return null;
		
		var swagShit:SwagGlobalNotes = cast Json.parse(rawJson);
		return swagShit;
	}
}

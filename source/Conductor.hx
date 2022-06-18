package;

import flixel.FlxG;
import flixel.FlxBasic;
import Song.SwagSong;

/**
 * ...
 * @author
 */
typedef BPMChangeEvent = {
	var stepTime:Int;
	var songTime:Float;
	var bpm:Int;
}

class Conductor extends FlxBasic {
	public static var bpm:Int = 100;
	public static var crochet:Float = ((60 / bpm) * 1000); // beats in milliseconds
	public static var stepCrochet:Float = crochet / 4; // steps in milliseconds
	/**
	 * current Song Position in miliseconds
	 */
	public static var songPosition:Float;
	public static var lastSongPos:Float;
	public static var offset:Float = 0;
	public static var autoSongPosition = false;

	public static var safeFrames:Int = 10;

	// 2000 is 333ms
	/**
	 * zone that should make note be hittable
	 * setting safeZoneOffset to very high values will cause sarv engine
	 */
	public static var safeZoneOffset:Float = (safeFrames / 60) * 1000; // is calculated in create(), is safeFrames in milliseconds

	public static var bpmChangeMap:Array<BPMChangeEvent> = [];

	public static function mapBPMChanges(song:SwagSong) {
		bpmChangeMap = [];

		var curBPM:Int = song.bpm;
		var totalSteps:Int = 0;
		var totalPos:Float = 0;
		for (i in 0...song.notes.length) {
			if (song.notes[i].changeBPM && song.notes[i].bpm != curBPM) {
				curBPM = song.notes[i].bpm;
				var event:BPMChangeEvent = {
					stepTime: totalSteps,
					songTime: totalPos,
					bpm: curBPM
				};
				bpmChangeMap.push(event);
			}

			var deltaSteps:Int = song.notes[i].lengthInSteps;
			totalSteps += deltaSteps;
			totalPos += ((60 / curBPM) * 1000 / 4) * deltaSteps;
		}
		trace("new BPM map BUDDY " + bpmChangeMap);
	}

	public static function changeBPM(newBpm:Int) {
		bpm = newBpm;

		crochet = ((60 / bpm) * 1000);
		stepCrochet = crochet / 4;
	}

	override function update(elapsed:Float) {
		if (FlxG.sound.music != null && autoSongPosition) {
			songPosition = FlxG.sound.music.time;
		}
	}
}

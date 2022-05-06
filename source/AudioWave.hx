package;

import sys.FileSystem;
import openfl.media.Sound;
import flixel.FlxState;
import flixel.util.FlxColor;
import flixel.FlxG;
import openfl.geom.Rectangle;
import haxe.io.Bytes;
import lime.media.AudioBuffer;
import flixel.FlxSprite;

class AudioWave extends FlxSprite {

	// credit for most drawWaveform() code to Shadow Mario and gedehari

	public var audioBuffer:AudioBuffer;
	var isWaveRendered = false;

	public var waveHeight = 1;
	public var waveWidth = 1;
	public var startTime:Float = 0;
	/**
	 * for playstate: curSection lengthInSteps
	 */
	public var steps = 0;
	public var weirdZoom:Float = 1;

	public function new(x, y, song:String, width, height, ?startTime = 0) {
		super(x,y);

		this.startTime = startTime;
		this.waveWidth = width;
		this.waveHeight = height;

		makeGraphic(FlxG.width, height, 0x00FFFFFF);

		if (FileSystem.exists(Paths.instNoLib(song))) {
			audioBuffer = AudioBuffer.fromFile('assets/songs/${song.toLowerCase()}/Voices.' + Paths.SOUND_EXT);
		}
		else {
			audioBuffer = AudioBuffer.fromFile(Paths.modsLoc + '/songs/${song.toLowerCase()}/Voices.' + Paths.SOUND_EXT);
		}
	}

	public function drawWaveform() {
		#if desktop
		if (isWaveRendered) {
			makeGraphic(Std.int(waveWidth), Std.int(waveHeight), 0x00FFFFFF);
			pixels.fillRect(new Rectangle(0, 0, waveWidth, waveHeight), 0x00FFFFFF);
		}
		isWaveRendered = false;

		var sampleMult:Float = audioBuffer.sampleRate / 44100;
		var index:Int = Std.int(startTime * 44.0875 * sampleMult);
		var drawIndex:Int = 0;

		if (Math.isNaN(steps) || steps < 1)
			steps = 16;
		var samplesPerRow:Int = Std.int(((Conductor.stepCrochet * steps * 1.1 * sampleMult) / 16) / weirdZoom);
		if (samplesPerRow < 1)
			samplesPerRow = 1;
		var waveBytes:Bytes = audioBuffer.data.toBytes();

		var min:Float = 0;
		var max:Float = 0;
		while (index < (waveBytes.length - 1)) {
			var byte:Int = waveBytes.getUInt16(index * 4);

			if (byte > 65535 / 2)
				byte -= 65535;

			var sample:Float = (byte / 65535);

			if (sample > 0) {
				if (sample > max)
					max = sample;
			}
			else if (sample < 0) {
				if (sample < min)
					min = sample;
			}

			if ((index % samplesPerRow) == 0) {

				var pixelsMin:Float = Math.abs(min * waveWidth);
				var pixelsMax:Float = max * waveWidth;
				pixels.fillRect(new Rectangle(Std.int((waveWidth / 2) - pixelsMin), drawIndex, pixelsMin + pixelsMax, 1), FlxColor.BLUE);
				drawIndex++;

				min = 0;
				max = 0;

				if (drawIndex > waveHeight)
					break;
			}

			index++;
		}
		isWaveRendered = true;
		#end
	}
}

class AudioWaveState extends FlxState {
	var audioWave:AudioWave;
	override public function create() {
		super.create();
		
		audioWave = new AudioWave(0, 0, "bopeebo", 256, 1000, 0);
		audioWave.drawWaveform();
		add(audioWave);
	}

	override public function update(elapsed) {
		super.update(elapsed);

		/*
		if (FlxG.keys.justPressed.I) {
			audioWave.waveHeight += 1;
		}
		if (FlxG.keys.justPressed.K) {
			audioWave.waveHeight -= 1;
		}
		*/

		if (FlxG.keys.pressed.W) {
			audioWave.y++;
		}
		if (FlxG.keys.pressed.S) {
			audioWave.y--;
		}
		if (FlxG.keys.justPressed.Q) {
			camera.zoom -= 0.1;
		}
		if (FlxG.keys.justPressed.E) {
			camera.zoom += 0.1;
		}
	}
}
package;

import flixel.system.FlxSound;
import OptionsSubState.Background;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

using StringTools;

/**
 * Loosley based on FlxTypeText lolol
 */
class Alphabet extends FlxSpriteGroup {
	public var delay:Float = 0.05;
	public var paused:Bool = false;

	// for menu shit
	public var targetY:Float = 0;
	public var isMenuItem:Bool = false;

	var _finalText:String = "";
	var _curText:String = "";

	public var widthOfWords:Float = FlxG.width;

	var yMulti:Float = 1;

	// custom shit
	// amp, backslash, question mark, apostrophy, comma, angry faic, period
	var lastSprite:AlphaCharacter;
	var xPosResetted:Bool = false;
	var lastWasSpace:Bool = false;

	var splitWords:Array<String> = [];

	public var isBold:Bool = false;

	public var text(default, set):String = "";

	function set_text(value:String):String {
		//i should do this before, but i learnt about this today by accident lol 
		text = value.replace("\\n", "\n");
		if (generatedText) {
			for (alphab in this) {
				alphab.destroy();
			}
			clear();
			_finalText = text;

			lastSprite = null;
			lastWasSpace = false;

			addText();
		}

		return text;
	}

	public var size(default, set):Float = 1;

	function set_size(value:Float):Float {
		size = value;
		if (generatedText) {
			for (alphab in this) {
				alphab.destroy();
			}
			clear();

			lastSprite = null;
			lastWasSpace = false;

			addText();
		}

		return size;
	}

	var generatedText:Bool = false;

	public function new(x:Float, y:Float, text:String = "", ?bold:Bool = false, typed:Bool = false, ?size:Float = 1) {
		super(x, y);

		_finalText = text;
		this.text = text;
		isBold = bold;
		this.size = size;

		if (text != "") {
			if (typed) {
				addTypedText();
			}
			else {
				addText();
			}
		}

		width = 1;
		height = 1;
	}

	@:deprecated("use alphabet.text = 'value' instead")
	public function setText(s:String) {
		for (alphab in this) {
			alphab.destroy();
		}
		clear();
		_finalText = s;
		text = s;

		lastSprite = null;
		lastWasSpace = false;

		addText();
	}

	@:deprecated("use alphabet.text = 'text' instead")
	public function updateText(newText:String) {
		_finalText = newText;
		text = newText;
		doSplitWords();
	}

	public function remFromText() {
		text = text.substring(0, text.length - 1);
	}

	public function addText() {
		doSplitWords();
		
		yMulti = 0;

		var xPos:Float = 0;
		var curRow = 0;
		for (character in splitWords) {
			if (character == " ") {
				lastWasSpace = true;
			}

			if (isBold && character == "-") {
				lastWasSpace = true;
			}

			if (character == "\n") {
				yMulti++;
				curRow++;
				xPos = 0;
				xPosResetted = true;
			}
			
			#if (haxe >= "4.0.0")
			var isNumber:Bool = AlphaCharacter.numbers.contains(character);
			var isSymbol:Bool = AlphaCharacter.symbols.contains(character);
			#else
			var isNumber:Bool = AlphaCharacter.numbers.indexOf(character) != -1;
			var isSymbol:Bool = AlphaCharacter.symbols.indexOf(character) != -1;
			#end

			if (AlphaCharacter.alphabet.indexOf(character.toLowerCase()) != -1 || (!isBold && (isNumber || isSymbol))) {
				if (lastSprite != null && !xPosResetted) {
					xPos = lastSprite.x + lastSprite.width;
					xPos -= x;
				}
				else {
					xPosResetted = false;
				}

				if (lastWasSpace) {
					xPos += 40 * size;
					lastWasSpace = false;
				}

				// var letter:AlphaCharacter = new AlphaCharacter(30 * loopNum, 0);
				var letter:AlphaCharacter = new AlphaCharacter(xPos, 55 * yMulti, size);
				letter.row = curRow;
				letter.lastSprite = lastSprite;

				if (isBold)
					letter.createBold(character);
				else {
					if (isNumber) {
						letter.createNumber(character);
					}
					else if (isSymbol) {
						letter.createSymbol(character);
					}
					else {
						letter.createLetter(character);
					}
				}

				add(letter);

				lastSprite = letter;
			}
		}
		generatedText = true;
	}

	public function addTypedText():Void {
		if (dialogueSound == null) {
			dialogueSound = new FlxSound().loadEmbedded(Paths.sound("dialogueBop"));
		}

		doSplitWords();

		yMulti = 0;

		var xPos:Float = 0;
		var curRow = 0;

		var index = -1;
		typedTimer = new FlxTimer().start(0.05, function(tmr:FlxTimer) {
			index++;
			var character = splitWords[index];

			if (character == " ") {
				lastWasSpace = true;
			}

			if (isBold && character == "-") {
				lastWasSpace = true;
			}

			if (character == "\n") {
				yMulti++;
				curRow++;
				xPos = 0;
				xPosResetted = true;
			}

			#if (haxe >= "4.0.0")
			var isNumber:Bool = AlphaCharacter.numbers.contains(character);
			var isSymbol:Bool = AlphaCharacter.symbols.contains(character);
			#else
			var isNumber:Bool = AlphaCharacter.numbers.indexOf(character) != -1;
			var isSymbol:Bool = AlphaCharacter.symbols.indexOf(character) != -1;
			#end

			if (AlphaCharacter.alphabet.indexOf(character.toLowerCase()) != -1 || (!isBold && (isNumber || isSymbol))) {
				if (lastSprite != null && !xPosResetted) {
					xPos = lastSprite.x + lastSprite.width;
					xPos -= x;
				}
				else {
					xPosResetted = false;
				}

				if (lastWasSpace) {
					xPos += 40 * size;
					lastWasSpace = false;
				}

				// var letter:AlphaCharacter = new AlphaCharacter(30 * loopNum, 0);
				var letter:AlphaCharacter = new AlphaCharacter(xPos, 55 * yMulti, size);
				letter.row = curRow;
				letter.lastSprite = lastSprite;

				if (isBold)
					letter.createBold(character);
				else {
					if (isNumber) {
						letter.createNumber(character);
					}
					else if (isSymbol) {
						letter.createSymbol(character);
					}
					else {
						letter.createLetter(character);
					}
				}

				add(letter);

				lastSprite = letter;
			}
			dialogueSound.play(true);
			tmr.time = FlxG.random.float(0.04, 0.09);
		}, splitWords.length);
		generatedText = true;
	}
 
	function doSplitWords():Void {
		splitWords = _finalText.split("");
	}

	public var personTalking:String = 'gf';

	override function update(elapsed:Float) {
		if (isMenuItem) {
			var scaledY = FlxMath.remapToRange(targetY, 0, 1, 0, 1.3);

			y = FlxMath.lerp(y, (scaledY * 120) + (FlxG.height * 0.48), CoolUtil.bound(elapsed * 11));
			x = FlxMath.lerp(x, (targetY * 20) + 90, CoolUtil.bound(elapsed * 11));
		}

		super.update(elapsed);
	}

	public var dialogueSound:FlxSound;

	public var typedTimer:FlxTimer;
}

class AlphaCharacter extends FlxSprite {
	public static var alphabet:String = "abcdefghijklmnopqrstuvwxyz";

	public static var numbers:String = "1234567890";

	public static var symbols:String = "|~#$%()*+-:;<=>@[]^_.,'!?";

	public static var sparrow:FlxAtlasFrames = null;

	public var row:Int = 0;

	public var size:Float = 1;

	public function new(x:Float, y:Float, size:Float) {
		super(x, y);
		if (sparrow == null) {
			sparrow = Paths.getSparrowAtlas('alphabet');
		}
		frames = sparrow;

		setGraphicSize(Std.int(width * size));
		updateHitbox();
		this.size = size;

		antialiasing = true;
	}

	public function createBold(letter:String) {
		animation.addByPrefix(letter, letter.toUpperCase() + " bold", 24);
		animation.play(letter);
		updateHitbox();
	}

	public function createBlank(letter:String) {
		width = 0;
		height = 0;
		visible = false;

		y = 60 * size;

		// line break
		y += (row * 60) * size;
	}

	public function createLetter(letter:String):Void {
		var letterCase:String = "lowercase";
		if (letter.toLowerCase() != letter) {
			letterCase = 'capital';
		}

		animation.addByPrefix(letter, letter + " " + letterCase, 24);
		animation.play(letter);
		updateHitbox();

		y = (60 * size) - height;

		//line break
		y += (row * 60) * size;
	}

	public function createNumber(letter:String):Void {
		animation.addByPrefix(letter, letter, 24);
		animation.play(letter);
		updateHitbox();

		y = (60 * size) - height;

		// line break
		y += (row * 60) * size;
	}

	public function createSymbol(letter:String) {
		//pain begins
		switch (letter) {
			case '.':
				animation.addByPrefix(letter, 'period', 24);
			case "'":
				animation.addByPrefix(letter, 'apostraphie', 24);
			case "?":
				animation.addByPrefix(letter, 'question mark', 24);
			case "!":
				animation.addByPrefix(letter, 'exclamation point', 24);
			case ",":
				animation.addByPrefix(letter, 'comma', 24);
			case "#":
				animation.addByPrefix(letter, 'hashtag', 24);
			case "$":
				animation.addByPrefix(letter, 'dollarsign', 24);
			default:
				animation.addByPrefix(letter, letter, 24);
		}
		animation.play(letter);
		updateHitbox();

		y = (60 * size) - height;

		// line break
		y += (row * 60) * size;

		switch (letter) {
			case "|":
				y += 5 * size;
			case "~":
				y -= 35 * size;
			case "*":
				y -= 25 * size;
			case "+":
				y -= 10 * size;
			case "-":
				y -= 20 * size;
			case ":":
				y -= 5 * size;
			case "=":
				y -= 15 * size;
			case "^":
				y -= 30 * size;
			case ",":
				y += 10 * size;
			case "'":
				y -= 35 * size;
		}
	}

	public var lastSprite:AlphaCharacter;
}

class AlphabetState extends FlxState {
	var daAlphabet:Alphabet;
	override public function create() {
		super.create();

		var bg = new Background(FlxColor.WHITE);
		add(bg);

		daAlphabet = new Alphabet(0, 0, "abc123" + AlphaCharacter.symbols);
		daAlphabet.screenCenter(XY);
		add(daAlphabet);
	}

	override public function update(elapsed) {
		super.update(elapsed);

		if (FlxG.keys.justPressed.ENTER) {
			daAlphabet.size -= 0.1;
		}

		if (FlxG.keys.justPressed.N) {
			daAlphabet.text += "g";
		}
	}
}

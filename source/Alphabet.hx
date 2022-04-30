package;

import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
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

	public var text:String = "";

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

	var isBold:Bool = false;

	var size:Float = 1;

	public function new(x:Float, y:Float, text:String = "", ?bold:Bool = false, typed:Bool = false, ?size:Float = 1) {
		super(x, y);

		_finalText = text;
		this.text = text;
		isBold = bold;
		this.size = size;

		if (text != "") {
			if (typed) {
				startTypedText();
			}
			else {
				addText();
			}
		}

		width = 1;
		height = 1;
	}

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

	public function updateText(newText:String) {
		_finalText = newText;
		text = newText;
		doSplitWords();
	}

	public function remFromText() {
		if (lastSprite != null) {
			text = text.substring(0, text.length - 1);
			var lastLett = lastSprite.lastSprite;
			remove(lastSprite);
			lastSprite = lastLett;
			updateText(text);
		}
	}

	public var box:FlxSprite;

	public function addToText(character:String) {
		//it works?
		//when adding text use this instead of setText() to prevent lag drop

		updateText(text + character);

		if (lastSprite == null && box != null)
			lastSprite = new AlphaCharacter(box.x, 420, size);

		#if (haxe >= "4.0.0")
		var isNumber:Bool = AlphaCharacter.numbers.contains(character);
		var isSymbol:Bool = AlphaCharacter.symbols.contains(character);
		#else
		var isNumber:Bool = AlphaCharacter.numbers.indexOf(character) != -1;
		var isSymbol:Bool = AlphaCharacter.symbols.indexOf(character) != -1;
		#end

		var letter:AlphaCharacter = new AlphaCharacter((lastSprite.x + lastSprite.width) - x, 55 * yMulti, size);
		if (character == "\n") {
			letter.row = lastSprite.row + 1;
			letter.x = 0;
		} else {
			letter.row = lastSprite.row;
		}
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
			else if (character == " " || character == "\n") {
				letter.createBlank(character);
			}
			else {
				letter.createLetter(character);
			}
		}

		add(letter);

		lastSprite = letter;
	}

	public function addText() {
		doSplitWords();
		
		yMulti = 0;

		var xPos:Float = 0;
		var curRow = 0;
		for (character in splitWords) {
			if (character == " " || character == "-") {
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
	}

	function doSplitWords():Void {
		splitWords = _finalText.split("");
	}

	public var personTalking:String = 'gf';
	public function startTypedText():Void {
		_finalText = text;
		doSplitWords();

		// trace(arrayShit);

		var loopNum:Int = 0;

		var xPos:Float = 0;
		var curRow:Int = 0;

		new FlxTimer().start(0.05, function(tmr:FlxTimer) {
			// trace(_finalText.fastCodeAt(loopNum) + " " + _finalText.charAt(loopNum));
			if (_finalText.fastCodeAt(loopNum) == "\n".code) {
				yMulti += 1;
				xPosResetted = true;
				xPos = 0;
				curRow += 1;
			}

			if (splitWords[loopNum] == " ") {
				lastWasSpace = true;
			}

			#if (haxe >= "4.0.0")
			var isNumber:Bool = AlphaCharacter.numbers.contains(splitWords[loopNum]);
			var isSymbol:Bool = AlphaCharacter.symbols.contains(splitWords[loopNum]);
			#else
			var isNumber:Bool = AlphaCharacter.numbers.indexOf(splitWords[loopNum]) != -1;
			var isSymbol:Bool = AlphaCharacter.symbols.indexOf(splitWords[loopNum]) != -1;
			#end

			if (AlphaCharacter.alphabet.indexOf(splitWords[loopNum].toLowerCase()) != -1 || isNumber || isSymbol)
				// if (AlphaCharacter.alphabet.contains(splitWords[loopNum].toLowerCase()) || isNumber || isSymbol)

			{
				if (lastSprite != null && !xPosResetted) {
					lastSprite.updateHitbox();
					xPos += lastSprite.width + 3;
					// if (isBold)
					// xPos -= 80;
				}
				else {
					xPosResetted = false;
				}

				if (lastWasSpace) {
					xPos += 20;
					lastWasSpace = false;
				}
				// trace(_finalText.fastCodeAt(loopNum) + " " + _finalText.charAt(loopNum));

				// var letter:AlphaCharacter = new AlphaCharacter(30 * loopNum, 0);
				var letter:AlphaCharacter = new AlphaCharacter(xPos, 55 * yMulti, size);
				letter.row = curRow;
				if (isBold) {
					letter.createBold(splitWords[loopNum]);
				}
				else {
					if (isNumber) {
						letter.createNumber(splitWords[loopNum]);
					}
					else if (isSymbol) {
						letter.createSymbol(splitWords[loopNum]);
					}
					else {
						letter.createLetter(splitWords[loopNum]);
					}

					letter.x += 90 * size;
				}
				/*
				if (FlxG.random.bool(40)) {
					var daSound:String = "GF_";
					FlxG.sound.play(Paths.soundRandom(daSound, 1, 4));
				}
				*/
				FlxG.sound.play(Paths.sound("dialogueBop"));

				add(letter);

				lastSprite = letter;
			}

			loopNum += 1;

			tmr.time = FlxG.random.float(0.04, 0.09);
		}, splitWords.length);
	}

	override function update(elapsed:Float) {
		if (isMenuItem) {
			var scaledY = FlxMath.remapToRange(targetY, 0, 1, 0, 1.3);

			y = FlxMath.lerp(y, (scaledY * 120) + (FlxG.height * 0.48), CoolUtil.bound(elapsed * 11));
			x = FlxMath.lerp(x, (targetY * 20) + 90, CoolUtil.bound(elapsed * 11));
		}

		super.update(elapsed);
	}
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
		if (letter == " ") {
			width = 40 * size;
		}
		y += (row * 60) * size;
		visible = false;
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

		if (size == 0.7) {
			y += 100 * size;
		}
		else {
			y += 60 * size;
		}
	}

	public function createSymbol(letter:String) {
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
			default:
				animation.addByPrefix(letter, letter, 24);
		}
		animation.play(letter);
		updateHitbox();

		switch (letter) {
			case '.':
				// the text will go a bit off, needs to be rewritten
				y += Math.pow(100, size) / size / size;
			case "'":
				y += 20 * size;
			case "?":
				y += 30 * size;
			case "!":
				y += 20 * size;
			case ",":
				y += 70 * size;
			case ":":
				y += 70 * size;
			case "-":
				y += 20 * size;
				x -= 40 * size;
			case "(", ")":
				y += 60 * size;
			default:
				y += 20 * size;
		}
	}

	public var lastSprite:AlphaCharacter;
}

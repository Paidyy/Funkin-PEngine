package;

import sys.io.File;
import openfl.display.BitmapData;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.text.FlxTypeText;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxSpriteGroup;
import flixel.input.FlxKeyManager;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

using StringTools;

class DialogueBoxOg extends FlxSpriteGroup {
	public var box:FlxSprite;

	public var curCharacter:String = '';

	public var dialogue:Alphabet;
	var dialogueList:Array<String> = [];
	var dropText:FlxText;

	public var finishThing:Void->Void;

	public var talkingRight:Bool = false;

	public var portraitLeft:Portrait;
	public var portraitRight:Portrait;

	var handSelect:FlxSprite;
	var bgFade:FlxSprite;
	var hasDialog:Bool;

	public var style = "normal";

	public function new(?dialogueList:Array<String>, ?hasDialog = true) {
		super();

		this.hasDialog = hasDialog;

		box = new FlxSprite(0, 45);
		box.frames = Paths.getSparrowAtlas('dialogue/speech_bubble_talking');
		box.animation.addByPrefix('normalOpen', 'Speech Bubble Normal Open', 24, false);
		box.animation.addByIndices('normal', 'speech bubble normal', [0, 5, 10, 15], "", 6);

		box.animation.addByPrefix('loudOpen', 'speech bubble loud open', 24, false);
		box.animation.addByPrefix('loud', 'AHH speech bubble', 24);
		box.setGraphicSize(Std.int(box.width * 0.9));

		if (dialogueList != null) {
			if (!hasDialog)
				return;

			this.dialogueList = dialogueList;
	
			dialogue = new Alphabet(box.x + 40, box.y + 90, "", false, true, 0.7);
			// dialogue.x = 90;
			// add(dialogue);
	
			// set this state camera to camStatic
			cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
		}

		portraitLeft = new Portrait(box.x + 140, box.y + 40, 'none');
		add(portraitLeft);

		portraitRight = new Portrait(0, box.y + 40, 'none');
		portraitRight.flipX = true;
		add(portraitRight);

		box.animation.play('${style}Open');
		// box.setGraphicSize(Std.int(box.width * PlayState.daPixelZoom * 0.9));
		box.updateHitbox();
		box.y = FlxG.height - box.frameHeight;
		box.scrollFactor.set();
		add(box);

		box.screenCenter(X);
		box.x += 40;
		// portraitLeft.screenCenter(X);
	}

	var dialogueOpened:Bool = false;
	var dialogueStarted:Bool = false;

	var prevStyle = null;

	override function update(elapsed:Float) {
		if (style == null)
			style = "normal";
		if (prevStyle == null) {
			prevStyle = style;
		}

		if (!hasDialog) {
			dialogueOpened = false;
			dialogueStarted = false;
		}
		if (box.animation.curAnim != null) {
			if ((box.animation.curAnim.name.endsWith('Open') && box.animation.curAnim.finished) || prevStyle != style) {
				box.animation.play('${style}');
				dialogueOpened = true;
			}

			if (box.animation.curAnim.name.startsWith("loud")) {
				box.offset.set(98.608, 80.62);
			}
			else {
				box.offset.set(63.608, 16.62);
			}
		}
		else {
			box.offset.set(63.608, 16.62);
		}
		prevStyle = style;

		if (dialogueOpened && !dialogueStarted) {
			startDialogue();
			dialogueStarted = true;
		}

		if (FlxG.keys.justPressed.ANY && dialogueStarted) {
			remove(dialogue);

			FlxG.sound.play(Paths.sound('dialogueClose'), 0.8);

			if (dialogueList[1] == null && dialogueList[0] != null) {
				if (!isEnding) {
					isEnding = true;

					new FlxTimer().start(0.2, function(tmr:FlxTimer) {
						box.alpha -= 1 / 5;
						// bgFade.alpha -= 1 / 5 * 0.7;
						portraitLeft.alpha -= 1 / 5;
						portraitRight.alpha -= 1 / 5;
						theDialog.alpha -= 1 / 5;
					}, 5);

					new FlxTimer().start(1.2, function(tmr:FlxTimer) {
						finishThing();
						kill();
					});
				}
			}
			else {
				if (theDialog.typedTimer != null) {
					theDialog.typedTimer.cancel();
				}
				dialogueList.remove(dialogueList[0]);
				startDialogue();
			}
		}

		super.update(elapsed);
	}

	var isEnding:Bool = false;

	function startDialogue():Void {
		cleanDialog();

		if (theDialog != null)
			remove(theDialog);

		theDialog = new Alphabet(box.x + 40, box.y + 90, dialogueList[0], false, true, 0.7);
		add(theDialog);

		if (!talkingRight) {
			box.flipX = true;
		}
		else {
			box.flipX = false;
		}
		updatePortraits();
	}

	public function updatePortraits() {
		if (!talkingRight) {
			portraitLeft.visible = true;
			portraitLeft.setCharacter(curCharacter);
			portraitRight.visible = false;
		}
		else {
			portraitRight.visible = true;
			portraitRight.setCharacter(curCharacter);
			portraitRight.x = box.x + (box.width - portraitRight.width) - 100;
			portraitLeft.visible = false;
		}
	}

	function cleanDialog():Void {
		var splitName:Array<String> = dialogueList[0].split(":");
		var splitNameSplit:Array<String> = splitName[1].split(",");
		curCharacter = splitNameSplit[0];
		talkingRight = CoolUtil.strToBool(splitNameSplit[1]);
		dialogueList[0] = dialogueList[0].substr(splitName[1].length + 2).trim();
		if (splitNameSplit[2] != null)
			style = splitNameSplit[2];
		else
			style = "normal";
	}

	public var theDialog:Alphabet;
}

class Portrait extends FlxSprite {
	public var character:String = "none";

	public function new(X:Float, Y:Float, Character:String) {
		super(X, Y);
		setCharacter(Character);
	}

	public function setCharacter(char:String) {
		if (char != "none" || char != character) {
			if (Paths.isPathCustom(Paths.portrait(char))) {
				this.loadGraphic(BitmapData.fromFile(Paths.portrait(char)));
			}
			else if (openfl.utils.Assets.exists(Paths.portrait(char))) {
				this.loadGraphic(Paths.portrait(char));
			}
			else {
				this.makeGraphic(1,1);
			}
		}
		character = char;
	}
}

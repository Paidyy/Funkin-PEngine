package;

import flixel.util.FlxTimer;
import sys.FileSystem;
import flixel.FlxObject;
import flixel.math.FlxPoint;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.input.keyboard.FlxKey;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.FlxCamera;
import flixel.FlxGame;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;

using StringTools;

class OptionsSubState extends FlxSubState {

	var options = [
		'Gameplay',
		'Preferences'
	];
	var optionsItems = new FlxTypedGroup<Alphabet>();
	var curSelected:Int = 0;
	var inGame:Bool;

	public static var optionsCamera:FlxCamera;

	public function new(?inGame = false) {
		super();

		if (inGame)
			optionsCamera = PlayState.camOptions;
		else
			optionsCamera = FlxG.camera;

		this.inGame = inGame;

		optionsCamera.follow(null);

		optionsCamera.scroll.x = 0;
		optionsCamera.scroll.y = 0;

		//if (inGame)
			//optionsCamera.zoom = 0.7;

		var bg = new Background(FlxColor.ORANGE);
		add(bg);

		var curY = 0.0;
		var curIndex = -1;
		for (s in options) {
			curIndex++;
			var option = new Alphabet(0, 0, s, true);
			option.ID = curIndex;
			option.scrollFactor.set();
			option.screenCenter(XY);
			option.y += curY;
			curY += option.height;

			optionsItems.add(option);
		}
		for (item in optionsItems) {
			item.y -= curY / 2;
		}
		add(optionsItems);
		
		cameras = [optionsCamera];
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (Controls.check(UI_UP)) {
			FlxG.sound.play(Paths.sound('scrollMenu'));
			curSelected -= 1;
		}

		if (Controls.check(UI_DOWN)) {
			FlxG.sound.play(Paths.sound('scrollMenu'));
			curSelected += 1;
		}

		if (curSelected < 0)
			curSelected = optionsItems.length - 1;

		if (curSelected >= optionsItems.length)
			curSelected = 0;

		optionsItems.forEach(function(alphab:Alphabet) {
			alphab.alpha = 0.6;

			if (alphab.ID == curSelected) {
				alphab.alpha = 1;
			}
		});

		if (Controls.check(ACCEPT)) {
			FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
			switch (options[curSelected]) {
				case '${options[0]}', "Gameplay":
					closeSubState();
					FlxG.state.openSubState(new OptionsGameplaySubState(inGame));
				case '${options[1]}', "Preferences":
					closeSubState();
					FlxG.state.openSubState(new OptionsPrefencesSubState(inGame));
			}
		}

		if (Controls.check(BACK)) {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MainMenuState.selectedSomethin = false;
			PlayState.openSettings = false;
			PlayState.cancelGameResume = true;
			if (inGame) {
				close();
				PlayState.currentPlaystate.pauseGame(true, 2);
			}
			else 
				FlxG.switchState(new MainMenuState(true));
		}
	}
}

class OptionsPrefencesSubState extends OptionSubState {
	public function new(inGame) {
		var items = [
			new OptionItem('FPS Limit: ' + Options.framerate),
			new OptionItem('Background Dimness: ' + Options.bgDimness),
			new OptionItem('Background Blur: ' + Options.bgBlur + "XY"),
			new OptionItem('Discord Rich Presence', true, Options.discordRPC, value -> Options.discordRPC = value),
			new OptionItem('Disable Crash Handler', true, Options.disableCrashHandler, value -> Options.disableCrashHandler = value),
			new OptionItem('Update Checker', true, Options.updateChecker, value -> Options.updateChecker = value),
			new OptionItem('Freeplay Listen to Vocals', true, Options.freeplayListenVocals, value -> Options.freeplayListenVocals = value),
			new OptionItem('BF Skin'),
			new OptionItem('GF Skin'),
			new OptionItem('Dad Skin')
		];
		super(items, inGame);
	}
	
	override public function update(elapsed) {
		super.update(elapsed);

		if (Controls.check(UI_RIGHT) || Controls.check(UI_LEFT)) {
			if (Controls.check(UI_LEFT)) {
				if (itemList[curSelected].text.startsWith("FPS Limit")) {
					if (Options.framerate > 5)
						Options.framerate -= 5;
					setOptionText(curSelected, "FPS Limit: " + Options.framerate);
				}
				else if (itemList[curSelected].text.startsWith("Background Dimness")) {
					if (Options.bgDimness > 0.0)
						Options.bgDimness -= 0.05;
					Options.bgDimness = CoolUtil.roundFloat(Options.bgDimness);
					setOptionText(curSelected, "Background Dimness: " + Options.bgDimness);
				}
				else if (itemList[curSelected].text.startsWith("Background Blur")) {
					if (Options.bgBlur > 0)
						Options.bgBlur -= 1;
					Options.bgBlur = CoolUtil.roundFloat(Options.bgBlur);
					setOptionText(curSelected, "Background Blur: " + Options.bgBlur + "XY");
				}
			}
			if (Controls.check(UI_RIGHT)) {
				if (itemList[curSelected].text.startsWith("FPS Limit")) {
					if (Options.framerate < 240)
						Options.framerate += 5;
					setOptionText(curSelected, "FPS Limit: " + Options.framerate);
				}
				else if (itemList[curSelected].text.startsWith("Background Dimness")) {
					if (Options.bgDimness < 1.0) 
						Options.bgDimness += 0.05;
					Options.bgDimness = CoolUtil.roundFloat(Options.bgDimness);
					setOptionText(curSelected, "Background Dimness: " + Options.bgDimness);
				}
				else if (itemList[curSelected].text.startsWith("Background Blur")) {
					if (Options.bgBlur < 255)
						Options.bgBlur += 1;
					Options.bgBlur = CoolUtil.roundFloat(Options.bgBlur);
					setOptionText(curSelected, "Background Blur: " + Options.bgBlur + "XY");
				}
			}
		}

		if (Controls.check(ACCEPT)) {
			switch (itemList[curSelected].text) {
				case "BF Skin":
					closeSubState();
					FlxG.state.openSubState(new OptionsCharacterSubState("bf", inGame));
				case "GF Skin":
					closeSubState();
					FlxG.state.openSubState(new OptionsCharacterSubState("gf", inGame));
				case "Dad Skin":
					closeSubState();
					FlxG.state.openSubState(new OptionsCharacterSubState("dad", inGame));	
			}
		}
	}
}

class OptionsGameplaySubState extends OptionSubState {
	public function new(inGame) {
		var items = [
			new OptionItem("Controls"),
			// deleting ghost tapping for idk what time bcs it fucks up and no one fucking disables it
			//new OptionItem("Ghost Tapping", true, Options.ghostTapping, value -> Options.ghostTapping = value),
			new OptionItem("Downscroll", true, Options.downscroll, value -> Options.downscroll = value),
			new OptionItem("Disable Spam Checker (pussy mode)", true, Options.disableSpamChecker, value -> Options.disableSpamChecker = value),
			new OptionItem("Disable New Combo System", true, Options.disableNewComboSystem, value -> {
				Options.disableNewComboSystem = value;
				PlayState.currentPlaystate.combo.clearComboTimer = new FlxTimer();
				if (value) {
					PlayState.currentPlaystate.combo.clearComboTimer = null;
				}
				else {
					PlayState.currentPlaystate.combo.initTimer();
				}
			}),
			new OptionItem("Chill Mode", true, Options.chillMode, value -> Options.chillMode = value),
			new OptionItem("Hit Sounds", true, Options.hitSounds, value -> Options.hitSounds = value)
		];
		super(items, inGame);
	}
	
	override public function update(elapsed) {
		super.update(elapsed);

		if (Controls.check(ACCEPT)) {
			if (itemList[curSelected].text == "Controls") {
				closeSubState();
				FlxG.state.openSubState(new OptionsControlsSubstate(inGame));
			}
		}
	}
}





class OptionSubState extends FlxSubState {
	private var itemList:Array<OptionItem>;

	public var items = new FlxTypedGroup<OptionItem>();
	public var checkboxes = new FlxTypedGroup<Checkbox>();

	public var curSelected:Int = 0;
	var inGame:Bool;

	public function new(itemList, inGame) {
		super();
		
		this.inGame = inGame;
		this.itemList = itemList;

		var bg = new Background(FlxColor.MAGENTA);
		bg.setGraphicSize(Std.int(bg.width * (1 + (itemList.length * 0.01))), Std.int(bg.height * (1 + (itemList.length * 0.01))));
		bg.updateHitbox();
		add(bg);

		var curY = 0.0;
		var curIndex = -1;
		for (option in itemList) {
			curIndex++;
			option.ID = curIndex;
			option.y += curY + (curIndex * 15);
			curY += option.height + 25;
			option.scrollFactor.set(1, 1);
			items.add(option);

			if (option.hasCheckBox) {
				option.checkbox.x = option.x + option.width + 10;
				option.checkbox.y = option.y - 50;
				option.checkbox.ID = curIndex;
				option.checkbox.scrollFactor.set(option.scrollFactor.x, option.scrollFactor.y);
				checkboxes.add(option.checkbox);
			}
		}
		add(items);
		add(checkboxes);

		//if (inGame)
			//cameras = [PlayState.camStatic];

		cameras = [OptionsSubState.optionsCamera];

		camFollow = new FlxObject(FlxG.width / 2, 0, 0, 0);
		OptionsSubState.optionsCamera.follow(camFollow, LOCKON, 0.04);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (Controls.check(UI_UP)) {
			FlxG.sound.play(Paths.sound('scrollMenu'));
			curSelected -= 1;
		}

		if (Controls.check(UI_DOWN)) {
			FlxG.sound.play(Paths.sound('scrollMenu'));
			curSelected += 1;
		}

		if (curSelected < 0)
			curSelected = items.length - 1;

		if (curSelected >= items.length)
			curSelected = 0;

		items.forEach(function(alphab:Alphabet) {
			alphab.alpha = 0.6;

			if (alphab.ID == curSelected) {
				alphab.alpha = 1;
				camFollow.y = alphab.y + 100;
			}
		});

		if (Controls.check(ACCEPT)) {
			for (checkbox in checkboxes) {
				if (checkbox.ID == curSelected) {
					checkOption(curSelected);
					break;
				}
			}
		}

		if (Controls.check(BACK)) {
			Options.saveAll();
			Options.applyAll();
			closeSubState();
			FlxG.state.openSubState(new OptionsSubState(inGame));
		}
	}

	public function setOptionText(i:Int, s:String) {
		for (alphab in items) {
			if (alphab.ID == i) {
				alphab.text = s;
				alphab.screenCenter(X);
				break;
			}
		}
	}

	public function checkOption(i:Int) {
		for (checkbox in checkboxes) {
			if (checkbox.ID == i) {
				checkbox.triggerChecked();
				break;
			}
		}
	}

	public var camFollow:FlxObject;
}

class OptionItem extends Alphabet {
	public var checkbox:Checkbox;
	public var hasCheckBox:Bool;

	public function new(text, ?hasCheckBox = false, ?checkBoxValue = false, ?checkBoxCallback:(value:Bool) -> Void) {
		super(0, 0, text);

		this.hasCheckBox = hasCheckBox;
		scrollFactor.set();
		screenCenter(X);
		
		if (hasCheckBox) {
			checkbox = new Checkbox(x + width + 10, y, checkBoxValue);
			checkbox.hitCallback = checkBoxCallback;
			checkbox.scrollFactor.set();
		}
	}
}

class Checkbox extends AnimatedSprite {
	private var checked = false;

	public var hitCallback:(value:Bool) -> Void;

	public function new(X, Y, ?checked:Bool = false) {
		super(X, Y);

		this.checked = checked;

		frames = Paths.getSparrowAtlas('checkboxThingie');
		antialiasing = true;
		setGraphicSize(Std.int(frameWidth * 0.75));
        updateHitbox();

		animation.addByPrefix("unselected", "Check Box unselected", 24);
		animation.addByPrefix("selecting", "Check Box selecting animation", 24, false);
		animation.addByPrefix("selected", "Check Box Selected Static", 24);

		setOffset("unselected", 0, -25);
		setOffset("selecting", 19, 50);
		setOffset("selected", 10, 28);

		if (checked) playAnim("selected");
		else playAnim("unselected");

		animation.finishCallback = function(name:String) {
			if (name == "selecting")
				playAnim("selected");
		};
	}

	public function triggerChecked() {
		checked = !checked;
		trace("checking " + checked);
		hitCallback(checked);
		if (checked)
			playAnim("selecting");
		else
			playAnim("unselected");
	}
}

class Background extends FlxSprite {
	public function new(Color:FlxColor, ?onlyColor:Bool = false) {
		super(-80);

		loadGraphic(Paths.image('menuDesat'));
		if (onlyColor) {
			makeGraphic(frameWidth, frameHeight, Color);
		}
		scrollFactor.set(0, 0.15);
		setGraphicSize(Std.int(width * 1.1));
		updateHitbox();
		screenCenter();
		antialiasing = true;
		color = Color;
	}
}

class OptionsCharacterSubState extends FlxSubState {

    var character:String;
    var character_path:String;
    var character_list:Array<String>;

    var grpTexts:FlxTypedGroup<FlxText>;
    var inGame = false;
	
    override public function new(character, ?inGame) {
        super();

        this.inGame = inGame;
        this.character = character;
		character_path = ${Paths.modsLoc} + "/skins/" + character + "/";
        character_list = new Array<String>();

        character_list.push("Vanilla");
		for (file in FileSystem.readDirectory(character_path)) {
			var path = haxe.io.Path.join([character_path, file]);
            if (FileSystem.isDirectory(path)) {
                character_list.push(file);
            }
		}

		var bg = new Background(FlxColor.BLACK, true);
		bg.alpha = 0.7;
		add(bg);

        grpTexts = new FlxTypedGroup<FlxText>();

        add(bg);
		add(grpTexts);

        updateMenu();

		if (inGame)
			cameras = [PlayState.camStatic];
    }

    override function update(elapsed:Float) {
		super.update(elapsed);

		if (Controls.check(UI_UP)) {
			FlxG.sound.play(Paths.sound('scrollMenu'));
			curSelected -= 1;
		}

		if (Controls.check(UI_DOWN)) {
			FlxG.sound.play(Paths.sound('scrollMenu'));
			curSelected += 1;
		}

        if (Controls.check(BACK)) {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			closeSubState();
			FlxG.state.openSubState(new OptionsPrefencesSubState(inGame));
		}

        if (curSelected < 0)
			curSelected = character_list.length - 1;

		if (curSelected >= character_list.length)
			curSelected = 0;

		grpTexts.forEach(function(txt:FlxText) {
			if (txt.ID == curSelected)
				txt.color = FlxColor.YELLOW;
            else
                txt.color = FlxColor.WHITE;
		});

        if (Controls.check(ACCEPT)) {
			FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
            if (character_list[curSelected] == "Vanilla") {
                switch (character) {
                    case "bf":
                        Options.customBf = false;
                        if (inGame) PlayState.bf = new Boyfriend(PlayState.bf.x, PlayState.bf.y, PlayState.SONG.player1);
                    case "gf":
                        Options.customGf = false;
                        if (inGame) PlayState.gf = new Character(PlayState.gf.x, PlayState.gf.y, PlayState.gfVersion);
                    case "dad":
                        Options.customDad = false;
                        if (inGame) PlayState.dad = new Character(PlayState.dad.x, PlayState.dad.y, PlayState.SONG.player2);
                }
            } else {
                switch (character) {
                    case "bf":
                        Options.customBf = true;
                        Options.customBfPath = character_path + character_list[curSelected] + "/";
                        if (inGame) PlayState.bf = new Boyfriend(PlayState.bf.x, PlayState.bf.y, "bf-custom");
                    case "gf":
                        Options.customGf = true;
                        Options.customGfPath = character_path + character_list[curSelected] + "/";
                        if (inGame) PlayState.gf = new Character(PlayState.gf.x, PlayState.gf.y, "gf-custom");
                    case "dad":
                        Options.customDad = true;
                        Options.customDadPath = character_path + character_list[curSelected] + "/";
                        if (inGame) PlayState.dad = new Character(PlayState.dad.x, PlayState.dad.y, "dad-custom");
                }
            }
            Options.saveAll();
            if (inGame) {
                PlayState.currentPlaystate.updateChar(character);
            }
        }
    }

    function updateMenu() {
		grpTexts.clear();
        var i = 0;
		for (character in character_list) {
			var optionText:FlxText = new FlxText(20, 20 + (i * 50), 0, character, 32);
			optionText.scrollFactor.set();
			optionText.ID = i;
			optionText.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 2);
			grpTexts.add(optionText);
            i++;
		}
	}

	var curSelected:Int;
}

class ControlsItem extends FlxTypedSpriteGroup<Alphabet> {
	public var key:Alphabet;
	public var bind1:Alphabet;
	public var bind2:Alphabet;

	public function new(keyText:String, bind1Text:String, bind2Text:String) {
		super();

		key = new Alphabet(0, 0, keyText, true);
		key.scrollFactor.set();
		key.x += 150;

		bind1 = new Alphabet(key.x + 450, 0, bind1Text, false);
		bind1.scrollFactor.set();

		bind2 = new Alphabet(bind1.x + 300, 0, bind2Text, false);
		bind2.scrollFactor.set();

		add(key);
		add(bind1);
		add(bind2);
	}
}

class OptionsControlsSubstate extends FlxSubState {
	public var items = new FlxTypedGroup<ControlsItem>();

	public var curSelected:Int = 0;
	public var curTab:Int = 0;
	var inGame:Bool;

	var camFollow:FlxObject;
	var thisCamera:FlxCamera;

	var waiting:Bool;
	var inputText:FlxText;

	public function new(inGame) {
		super();
		
		this.inGame = inGame;

		var bg = new Background(FlxColor.MAGENTA);
		bg.scrollFactor.y = 0.1;
		bg.setGraphicSize(Std.int(bg.width * 1.2));
		bg.updateHitbox();
		bg.screenCenter();
		add(bg);

		var curY = 400.0;
		var curIndex = -1;
		for (keyType in Type.allEnums(KeyType)) {
			curIndex++;

			var name = keyType.getName();
			var bind1:String = KeyBind.fromType(keyType)[0];
			var bind2:String = KeyBind.fromType(keyType)[1];

			if (bind1 == null)
				bind1 = "---";
			if (bind2 == null)
				bind2 = "---";
			
			var shit = new ControlsItem(name, bind1, bind2);
			shit.ID = curIndex;
			shit.y += curY;
			curY += shit.key.height + 25;
			items.add(shit);
		}
		add(items);

		items.forEach(function(item:ControlsItem) {
			if (item.ID == 0) {
				var keyText = new Alphabet(item.key.x, item.bind1.y - item.bind1.height * 1.5, "Key", true);
				var bindsText = new Alphabet( item.bind1.x + ((item.bind2.x - item.bind1.x) / 2) , item.bind1.y - item.bind1.height * 1.5, "Binds", true);

				add(keyText);
				add(bindsText);
			}
		});

		inputText = new FlxText(0, 0, 0, "Waiting for input...");
		inputText.scrollFactor.set();
		inputText.setFormat("VCR OSD Mono", 24, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		inputText.screenCenter();
		inputText.visible = false;
		add(inputText);
		
		thisCamera = new FlxCamera();

		FlxG.cameras.add(thisCamera, false);

		camFollow = new FlxObject(FlxG.width / 2, 0, 0, 0);
		thisCamera.follow(camFollow, LOCKON, 0.04);

		cameras = [thisCamera];
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		inputText.visible = waiting;

		if (waiting) {
			waitForInput();
		} 
		else {
			if (Controls.check(UI_UP)) {
				FlxG.sound.play(Paths.sound('scrollMenu'));
				curSelected -= 1;
			}
	
			if (Controls.check(UI_DOWN)) {
				FlxG.sound.play(Paths.sound('scrollMenu'));
				curSelected += 1;
			}

			if (Controls.check(ACCEPT)) {
				waiting = true;
			}

			if (Controls.check(UI_RIGHT))
				curTab = 1;
	
			if (Controls.check(UI_LEFT))
				curTab = 0;

			if (Controls.check(BACK)) {
				Options.saveAll();
				Options.applyAll();
				closeSubState();
				FlxG.cameras.remove(thisCamera);
				FlxG.state.openSubState(new OptionsGameplaySubState(inGame));
			}
		}

		if (curSelected < 0)
			curSelected = items.length - 1;

		if (curSelected >= items.length)
			curSelected = 0;

		items.forEach(function(item:ControlsItem) {
			item.key.alpha = 0.5;
			item.bind1.alpha = 0.5;
			item.bind2.alpha = 0.5;

			if (item.ID == curSelected) {
				camFollow.y = item.y + 100;

				item.key.alpha = 1;

				if (curTab == 0)
					item.bind1.alpha = 1;
				else
					item.bind2.alpha = 1;
			}
		});
	}

	function waitForInput() {
		waiting = true;

		items.forEach(function(item:ControlsItem) {
			if (item.ID == curSelected) {
				if (curTab == 0)
					item.bind1.text = "...";
				else
					item.bind2.text = "...";

				if (FlxG.keys.anyJustPressed([ANY])) {
					waiting = false;
					var curKey = FlxG.keys.getIsDown()[0].ID;
					Controls.bind(KeyBind.typeFromString(item.key.text), curKey, curTab);
					if (curTab == 0)
						item.bind1.text = curKey.toString();
					else
						item.bind2.text = curKey.toString();
				}
			}
		});
	}
}
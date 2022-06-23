package;

import Main.Notification;
import Stage.StageAsset;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.util.FlxCollision;
import flixel.util.FlxColor;
import openfl.media.Sound;
import sys.FileSystem;
import sys.io.File;
import yaml.Yaml;
import yaml.util.ObjectMap.AnyObjectMap;
import yaml.util.ObjectMap;

class StageDebug extends MusicBeatState {

    var stageName = "";
    var stage:Stage;

    var dumbTexts:FlxTypedGroup<FlxText>;

    var imageList:Array<String> = [];

    var camFollow:FlxObject;

    var hudCamera:FlxCamera;

    var dumbTextsWidthWX:Float = 0.0;

    var draggedSprite:StageAsset;

	var currentSprite:Int = 0;

	var cum:FlxCamera;

	var midget:Character;

	var gf:Character;

	var dad:Character;

	var characters:FlxTypedGroup<Character>;

	var dumbTexts2:FlxTypedGroup<FlxText>;

    var textImg:FlxText;
    var textChar:FlxText;

    public function new(stageName:String = 'stage') {
		super();
		this.stageName = stageName;
	}

    function gendumbTexts(pushList:Bool = true):Void {
		var daLoop:Int = 0;

        for (penis in stage) {
            var text:FlxText = new FlxText(10, 42 + (23 * daLoop), 0, penis.name + " : " + "[ " + penis.x + ", " + penis.y + ", " + penis.sizeMultiplier + "]", 15);
            text.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 2);
            text.scrollFactor.set();
            text.color = FlxColor.GRAY;
            if (text.width + text.x > dumbTextsWidthWX) {
                dumbTextsWidthWX = text.width + text.x;
            }
            dumbTexts.add(text);

            if (pushList)
                imageList.push(penis.name);

            daLoop++;
        }

		for (penis in stage.frontLayer) {
			var text:FlxText = new FlxText(10, 42 + (23 * daLoop), 0,
				penis.name + " : " + "[ " + penis.x + ", " + penis.y + ", " + penis.sizeMultiplier + "]", 15);
			text.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 2);
			text.scrollFactor.set();
			text.color = FlxColor.GRAY;
			if (text.width + text.x > dumbTextsWidthWX) {
				dumbTextsWidthWX = text.width + text.x;
			}
			dumbTexts.add(text);

			if (pushList)
				imageList.push(penis.name);

			daLoop++;
        }
	}

    function gendumbTexts2(pushList:Bool = true):Void {
		var daLoop:Int = 0;

        for (char in characters) {
            var charName = null;
            if (char == midget)
				charName = "bf";
            if (char == gf)
				charName = "gf";
			if (char == dad)
				charName = "dad";
			textChar.x = dumbTextsWidthWX;
			var text:FlxText = new FlxText(dumbTextsWidthWX + 30, 42 + (23 * daLoop), 0, charName + " : " + "[ " + char.x + ", " + char.y + "]", 15);
            text.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 2);
            text.scrollFactor.set();
            text.color = FlxColor.GRAY;
            dumbTexts2.add(text);

            if (pushList)
				characterList.push(charName);

            daLoop++;
        }
	}

    function removeTexts():Void {
        dumbTexts.forEach(function(text:FlxText) {
            text.text = " ";
            text.kill();
            dumbTexts.remove(text, true);
        });
	}

    function removeTexts2():Void {
        dumbTexts2.forEach(function(text:FlxText) {
            text.text = " ";
            text.kill();
            dumbTexts2.remove(text, true);
        });
	}

    override function create() {
        hudCamera = new FlxCamera();
        hudCamera.bgColor.alpha = 0;

        FlxG.cameras.add(hudCamera, false);
        
        FlxG.sound.music.stop();
        if (Sound.fromFile(Paths.PEinst('test')) != null) {
            FlxG.sound.playMusic(Sound.fromFile(Paths.PEinst('test')));
            Conductor.changeBPM(150);
        }

        //collission stuff unused | FlxG.worldBounds.set(2147483647, 2147483647);

        stage = new Stage(stageName);
        if (!FileSystem.exists(stage.configPath)) {
            FlxG.switchState(PlayState.thisWithNotification(new Notification("Could not find stage config, create one before going here")));
        }
        FlxG.camera.zoom = stage.camZoom;
        add(stage);

        midget = new Boyfriend(stage.bfX, stage.bfY, "bf");
        gf = new Character(stage.gfX, stage.gfY, "gf");
        dad = new Character(stage.dadX, stage.dadY, "dad");

        characters = new FlxTypedGroup<Character>();

        characters.add(gf);
        characters.add(dad);
        characters.add(midget);

        add(characters);

		add(stage.frontLayer);
 
        textImg = new FlxText(15, 15, 0, "Images:", 20);
        textImg.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 2);
        textImg.scrollFactor.set();
        add(textImg);

        dumbTexts = new FlxTypedGroup<FlxText>();
		add(dumbTexts);
        gendumbTexts();

        var info:FlxText = new FlxText(0, 0, 0, "", 15);
		info.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 2);
		info.text =
        "CTRL + DRAG MOUSE CLICK - Move current Sprite\n" +
        "CTRL + DRAG MOUSE WHEEL - Change the size of current Sprite\n" +
        "WS - Change the Sprite\n" +
        "AD - Change the tab (Images / Characters)\n" +
		"IJKL - Move the camera (Shift to 2x faster)\n" +
        "CTRL + S - Save the Config\n" +
        "H - Change to current playstate assets\n" +
		"QE - Zoom Out/In\n"
		;
		info.scrollFactor.set();
		info.y = (FlxG.height - info.height) + (info.size * 2);
		info.x = 10;
		add(info);

        textChar = new FlxText(0, 15, 0, "Characters:", 20);
        textChar.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 2);
        textChar.scrollFactor.set();
        textChar.x = dumbTextsWidthWX + 20;
        add(textChar);

        dumbTexts2 = new FlxTypedGroup<FlxText>();
		add(dumbTexts2);
        gendumbTexts2();
        
        //copying from animation debug because yes
        camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);

        FlxG.camera.follow(camFollow);

        info.cameras = [hudCamera];
        dumbTexts.cameras = [hudCamera];
        textImg.cameras = [hudCamera];
        textChar.cameras = [hudCamera];
        dumbTexts2.cameras = [hudCamera];

        super.create();
    }

    override function update(elapsed) {
        Conductor.songPosition = FlxG.sound.music.time;
        FlxG.mouse.visible = true;

        if (FlxG.keys.justPressed.H) {
			midget.kill();
			dad.kill();
			gf.kill();
			characters.remove(midget);
			characters.remove(dad);
			characters.remove(gf);
			midget = new Boyfriend(midget.x, midget.y, PlayState.SONG.player1);
			dad = new Character(dad.x, dad.y, PlayState.SONG.player2);
			gf = new Character(gf.x, gf.y, PlayState.gfVersion);
			characters.add(gf);
			characters.add(dad);
			characters.add(midget);
			if (FileSystem.exists(Paths.instNoLib(PlayState.SONG.song))) {
				FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 1, false);
			}
			else {
				FlxG.sound.playMusic(Sound.fromFile(Paths.PEinst(PlayState.SONG.song)), 1, false);
			}
        }

        if (FlxG.keys.justPressed.Q) {
            camera.zoom -= 0.05;
        }

		if (FlxG.keys.justPressed.E) {
			camera.zoom += 0.05;
		}

        if (FlxG.keys.justPressed.A) {
            curTab = 0;
        }
        else if (FlxG.keys.justPressed.D) {
            curTab = 1;
        }

        if (curTab == 0) {
            textImg.color = FlxColor.YELLOW;
            textChar.color = FlxColor.WHITE;
            for (text in dumbTexts) {
                if (text.text.split(" ")[0] == imageList[currentSprite]) {
                    text.color = FlxColor.YELLOW;
                } else {
                    text.color = FlxColor.GRAY;
                }
            }
        }
        
        if (curTab == 1) {
            textImg.color = FlxColor.WHITE;
            textChar.color = FlxColor.YELLOW;
            for (text in dumbTexts2) {
                if (text.text.split(" ")[0] == characterList[currentCharacter]) {
                    text.color = FlxColor.YELLOW;
                } else {
                    text.color = FlxColor.GRAY;
                }
            }
        }

        if (FlxG.keys.justPressed.W)
            if (curTab == 0)
                currentSprite--;
            else if (curTab == 1)
                currentCharacter--;
        if (FlxG.keys.justPressed.S)
            if (curTab == 0)
                currentSprite++;
            else if (curTab == 1)
                currentCharacter++;

        if (currentSprite < 0)
            currentSprite = imageList.length - 1;

        if (currentSprite >= imageList.length)
            currentSprite = 0;

        if (currentCharacter < 0)
            currentCharacter = characterList.length - 1;

        if (currentCharacter >= characterList.length)
            currentCharacter = 0;

        if (FlxG.keys.pressed.I || FlxG.keys.pressed.J || FlxG.keys.pressed.K || FlxG.keys.pressed.L) {
            var multiplier = 1;
            if (FlxG.keys.pressed.SHIFT)
                multiplier = 2;

            if (FlxG.keys.pressed.I)
                camFollow.velocity.y = -90 * multiplier;
            else if (FlxG.keys.pressed.K)
                camFollow.velocity.y = 90 * multiplier;
            else
                camFollow.velocity.y = 0;
    
            if (FlxG.keys.pressed.J)
                camFollow.velocity.x = -90 * multiplier;
            else if (FlxG.keys.pressed.L)
                camFollow.velocity.x = 90 * multiplier;
            else
                camFollow.velocity.x = 0;
        }
        else {
            camFollow.velocity.set();
        }

        if ((FlxG.keys.pressed.CONTROL && FlxG.mouse.justPressed) || (FlxG.keys.justPressed.CONTROL && FlxG.mouse.pressed) || (FlxG.keys.justPressed.CONTROL && FlxG.mouse.justPressed)) {
            //on clicked sprite
        }

        if (FlxG.keys.pressed.CONTROL && FlxG.mouse.pressed) {
            if (FlxG.mouse.justMoved) {
                if (curTab == 0) {
					for (penis in stage) {
						if (penis.name == imageList[currentSprite]) {
							penis.x = penis.x + (FlxG.mouse.x - oldMousePos[0]);
							penis.y = penis.y + (FlxG.mouse.y - oldMousePos[1]);
						}
					}
					for (penis in stage.frontLayer) {
						if (penis.name == imageList[currentSprite]) {
							penis.x = penis.x + (FlxG.mouse.x - oldMousePos[0]);
							penis.y = penis.y + (FlxG.mouse.y - oldMousePos[1]);
						}
					}
                }
                if (curTab == 1)
                    for (char in characters) {
						if (char == getCurrentChar()) {
							char.x = char.x + (FlxG.mouse.x - oldMousePos[0]);
							char.y = char.y + (FlxG.mouse.y - oldMousePos[1]);
                        }
                    }
            }

            if (FlxG.mouse.wheel == 1) {
                if (curTab == 0) {
					for (penis in stage) {
						if (penis.name == imageList[currentSprite]) {
							penis.setAssetSize(penis.sizeMultiplier + 0.01);
						}
					}
					for (penis in stage.frontLayer) {
						if (penis.name == imageList[currentSprite]) {
							penis.setAssetSize(penis.sizeMultiplier + 0.01);
						}
					}
                }
            }
            if (FlxG.mouse.wheel == -1) {
                if (curTab == 0) {
					for (penis in stage) {
						if (penis.name == imageList[currentSprite]) {
							penis.setAssetSize(penis.sizeMultiplier - 0.01);
						}
					}
					for (penis in stage.frontLayer) {
						if (penis.name == imageList[currentSprite]) {
							penis.setAssetSize(penis.sizeMultiplier - 0.01);
						}
					}
                }
            }
        }
        if (FlxG.mouse.justReleased) {
            // do it 2 times to not glitch the text
            if (curTab == 0) {
                removeTexts();
                removeTexts();
                gendumbTexts(false);
            }
            if (curTab == 1) {
                removeTexts2();
                removeTexts2();
                gendumbTexts2(false);
            }
        }

        if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.S) {
			saveConfig();
		}
 
        if (FlxG.keys.justPressed.ESCAPE) {
			LoadingState.loadAndSwitchState(new PlayState());
		}

        super.update(elapsed);

        oldMousePos = [FlxG.mouse.x, FlxG.mouse.y];
    }

    override function beatHit() {
        stage.onBeatHit();
		midget.playIdle();
        gf.playIdle();
		dad.playIdle();
    }

    function getCurrentChar() {
		if (characterList[currentCharacter] == "bf") {
            return midget;
        }
		if (characterList[currentCharacter] == "dad") {
            return dad;
        }
		if (characterList[currentCharacter] == "gf") {
            return gf;
        }
        return null;
    }

    function charToCharName(char) {
		if (char == midget) {
			return "bf";
		}
		if (char == dad) {
			return "dad";
		}
		if (char == gf) {
			return "gf";
		}
		return null;
    }

    function saveConfig() {
		if (stage.config != null) {
			if (stage.config.get('images') == null) {
				stage.config.set('images', new AnyObjectMap());
			}
            stage.config.set('zoom', stage.camZoom);

            for (char in characters) {
				stage.config.set('${charToCharName(char)}X', char.x);
				stage.config.set('${charToCharName(char)}Y', char.y);
            }

            var images = stage.config.get('images');
            for (image in stage) {
                if (images.get(image.name) == null) {
                    images.set(image.name, new AnyObjectMap());
                }
                images.get(image.name).set('x', image.x);
				images.get(image.name).set('y', image.y);
                images.get(image.name).set('size', image.sizeMultiplier);
				images.get(image.name).set('layer', image.layer);
            }
			for (image in stage.frontLayer) {
				if (images.get(image.name) == null) {
					images.set(image.name, new AnyObjectMap());
				}
				images.get(image.name).set('x', image.x);
				images.get(image.name).set('y', image.y);
				images.get(image.name).set('size', image.sizeMultiplier);
				images.get(image.name).set('layer', image.layer);
			}
            stage.config.set('images', images);
			var renderedYaml = Yaml.render(stage.config);
            trace("saving config to: " + stage.configPath);
			CoolUtil.writeToFile(stage.configPath, renderedYaml);
		}
	}

	var curTab:Int = 0;

	var currentCharacter:Int = 0;

	var characterList:Array<String> = [];

	var oldMousePos:Array<Int>;
}
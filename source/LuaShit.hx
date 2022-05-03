package;

import Main.Notification;
import flixel.graphics.frames.FlxAtlasFrames;
import sys.io.File;
import sys.FileSystem;
import Stage.StageAsset;
import flixel.input.keyboard.FlxKey;
import openfl.media.Sound;
import flixel.system.FlxAssets.FlxSoundAsset;
import flixel.system.FlxSound;
import openfl.display.BitmapData;
import flixel.FlxG;
import flixel.tweens.FlxTween;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.util.FlxTimer;
import flixel.FlxCamera;
import llua.Convert;
import llua.Lua;
import llua.LuaL;
import llua.State;

class LuaShit {
    var lua:State;
    public function new(luaPath:String) {
        lua = LuaL.newstate();
        LuaL.openlibs(lua);
        #if debug
        trace("Lua version: " + Lua.version());
        trace("LuaJIT version: " + Lua.versionJIT());
        #end
        Lua.init_callbacks(lua);

        setVariable("swagSong", PlayState.SONG);
        setVariable("windowWidth", FlxG.width);
        setVariable("windowHeight", FlxG.height);

		Lua_helper.add_callback(lua, "getMousePosition", function() {
			return [FlxG.mouse.x, FlxG.mouse.y];
		});

		Lua_helper.add_callback(lua, "isMouseJustLeftPressed", function() {
			return FlxG.mouse.justPressed;
		});

		Lua_helper.add_callback(lua, "isMouseJustRightPressed", function() {
			return FlxG.mouse.justPressedRight;
		});

		Lua_helper.add_callback(lua, "isMouseJustMiddlePressed", function() {
			return FlxG.mouse.justPressedMiddle;
		});

		Lua_helper.add_callback(lua, "isMouseLeftPressed", function() {
			return FlxG.mouse.pressed;
		});

		Lua_helper.add_callback(lua, "isMouseRightPressed", function() {
			return FlxG.mouse.pressedRight;
		});

		Lua_helper.add_callback(lua, "isMouseMiddlePressed", function() {
			return FlxG.mouse.pressedMiddle;
		});

		Lua_helper.add_callback(lua, "isMouseLeftJustReleased", function() {
			return FlxG.mouse.justReleased;
		});

		Lua_helper.add_callback(lua, "isMouseRightJustReleased", function() {
			return FlxG.mouse.justPressedRight;
		});

		Lua_helper.add_callback(lua, "isMouseMiddleJustReleased", function() {
			return FlxG.mouse.justPressedMiddle;
		});

		Lua_helper.add_callback(lua, "saveSet", function(field:String, value:String) {
			Reflect.setField(FlxG.save.data, field, value);
			FlxG.save.flush();
		});

		Lua_helper.add_callback(lua, "saveGet", function(field:String) {
			return Reflect.field(FlxG.save.data, field);
		});

		Lua_helper.add_callback(lua, "close", function() {
			close();
		});

		Lua_helper.add_callback(lua, "unlockAchievement", function(id:String) {
			Achievement.unlock(id);
		});

		Lua_helper.add_callback(lua, "isAchievementUnlocked", function(id:String) {
			return Achievement.isUnlocked(id);
		});

		Lua_helper.add_callback(lua, "showNotification", function(str:String) {
			new Notification(str).show();
		});

        Lua_helper.add_callback(lua, "stageSpritePlay", function(sprite:String, animation:String, ?force:Bool = true) {
            for (sprite in PlayState.currentPlaystate.stage) {
                if (Std.isOfType(sprite, StageAsset)) {
                    var stageSprite:StageAsset = sprite;
                    if (stageSprite.name == sprite) {
                        stageSprite.animation.play(animation, force);
                    }
                }
            }
        });

        Lua_helper.add_callback(lua, "stageSpriteAnimationAddByPrefix", function(sprite:String, animationName:String, xmlAnimationName:String, framerate:Int = 24, ?looped:Bool = false) {
            for (sprite in PlayState.currentPlaystate.stage) {
                if (Std.isOfType(sprite, StageAsset)) {
                    var stageSprite:StageAsset = sprite;
                    if (stageSprite.name == sprite) {
                        stageSprite.animation.addByPrefix(animationName, xmlAnimationName, framerate, looped);
                    }
                }
            }
        });

        Lua_helper.add_callback(lua, "stageSpriteAnimationAddByIndices", function(sprite:String, animationName:String, xmlAnimationName:String, indices:Array<Int>, framerate:Int = 24, ?looped:Bool = false) {
            for (sprite in PlayState.currentPlaystate.stage) {
                if (Std.isOfType(sprite, StageAsset)) { 
                    var stageSprite:StageAsset = sprite;
                    if (stageSprite.name == sprite) {
                        stageSprite.animation.addByIndices(animationName, xmlAnimationName, indices, "", framerate, looped);
                    }
                }
            }
        });

        Lua_helper.add_callback(lua, "stageSpriteGetProperty", function(sprite:String, property:String) {
            for (sprite in PlayState.currentPlaystate.stage) {
                if (Std.isOfType(sprite, StageAsset)) {
                    var stageSprite:StageAsset = sprite;
                    if (stageSprite.name == sprite) {
                        return Reflect.getProperty(PlayState.currentPlaystate.stage, property);
                    }
                }
            }
            return null;
        });

        Lua_helper.add_callback(lua, "stageSpriteSetProperty", function(sprite:String, property:String, value:Dynamic) {
            for (sprite in PlayState.currentPlaystate.stage) {
                if (Std.isOfType(sprite, StageAsset)) {
                    var stageSprite:StageAsset = sprite;
                    if (stageSprite.name == sprite) {
                        Reflect.setProperty(PlayState.currentPlaystate.stage, property, value);
                    }
                }
            }
            return null;
        });

        Lua_helper.add_callback(lua, "tweenValue", function(originalValue:Float, value:Float, duration:Float = 1, tweenFunction:String = null) {
            FlxTween.num(originalValue, value, duration, null, f -> call(tweenFunction, [f]));
        });

        Lua_helper.add_callback(lua, "isKeyJustPressed", function(key:String) {
            return FlxG.keys.anyJustPressed([FlxKey.fromString(key)]);
        });

        Lua_helper.add_callback(lua, "isKeyPressed", function(key:String) {
            return FlxG.keys.anyPressed([FlxKey.fromString(key)]);
        });

        Lua_helper.add_callback(lua, "isKeyJustReleased", function(key:String) {
            return FlxG.keys.anyJustReleased([FlxKey.fromString(key)]);
        });

        Lua_helper.add_callback(lua, "isControlJustPressed", function(control:String) {
            return Controls.check(KeyBind.typeFromString(control), JUST_PRESSED);
        });

        Lua_helper.add_callback(lua, "isControlPressed", function(control:String) {
            return Controls.check(KeyBind.typeFromString(control), PRESSED);
        });

        Lua_helper.add_callback(lua, "isControlJustReleased", function(control:String) {
            return Controls.check(KeyBind.typeFromString(control), JUST_RELEASED);
        });

        Lua_helper.add_callback(lua, "cacheSound", function(path:String) {
            Cache.cacheSound("mods/" + path);
        });

        Lua_helper.add_callback(lua, "playSound", function(path:String) {
            if (Cache.sounds.exists("mods/" + path)) {
                FlxG.sound.play(Cache.sounds.get("mods/" + path));
            }
            else {
                FlxG.sound.play(Sound.fromFile("mods/" + path));
            }
        });

        Lua_helper.add_callback(lua, "addSprite", function(name:String, path:String, x:Float, y:Float) {
            var sprite:FlxSprite = new FlxSprite(x,y);
			var actualPath = "mods/" + path;
			if (FileSystem.exists(actualPath.substring(0, actualPath.length - 3) + "xml")) {
				sprite.frames = FlxAtlasFrames.fromSparrow(BitmapData.fromBytes(File.getBytes(actualPath)),
					File.getContent(actualPath.substring(0, actualPath.length - 3) + "xml"));
            }
            else {
				sprite.loadGraphic(BitmapData.fromFile(actualPath));
            }
            PlayState.currentPlaystate.addLuaSprite(name, sprite);
        });

        Lua_helper.add_callback(lua, "removeSprite", function(name:String) {
            PlayState.currentPlaystate.luaSprites.get(name).destroy();
            PlayState.currentPlaystate.luaSprites.remove(name);
        });

        Lua_helper.add_callback(lua, "spriteAnimationAddByPrefix", function(name:String, animationName:String, xmlAnimationName:String, ?framerate:Int = 24, ?looped:Bool = false) {
            PlayState.currentPlaystate.luaSprites.get(name).animation.addByPrefix(animationName, xmlAnimationName, framerate, looped);
        });

        Lua_helper.add_callback(lua, "spriteAnimationAddByIndices", function(name:String, animationName:String, xmlAnimationName:String, indices:Array<Int>, ?framerate:Int = 24, ?looped:Bool = false) {
            PlayState.currentPlaystate.luaSprites.get(name).animation.addByIndices(animationName, xmlAnimationName, indices, "", framerate, looped);
        });

        Lua_helper.add_callback(lua, "spritePlay", function(name:String, animation:String, ?force:Bool = true) {
            PlayState.currentPlaystate.luaSprites.get(name).animation.play(animation, force);
        });

		Lua_helper.add_callback(lua, "spriteSetSize", function(name:String, width:Int, height:Int) {
			PlayState.currentPlaystate.luaSprites.get(name).setGraphicSize(width, height);
		});

        Lua_helper.add_callback(lua, "tweenSpriteProperty", function(name:String, property:String, value:Float = 0, duration:Float = 1) {
            FlxTween.num(Reflect.getProperty(PlayState.currentPlaystate.luaSprites.get(name), property), value, duration, null, f -> Reflect.setProperty(PlayState.currentPlaystate.luaSprites.get(name), property, f));
        });

        Lua_helper.add_callback(lua, "setSpriteProperty", function(name:String, property:String, value:Dynamic) {
            Reflect.setProperty(PlayState.currentPlaystate.luaSprites.get(name), property, value);
        });

        Lua_helper.add_callback(lua, "getSpriteProperty", function(name:String, property:String) {
            return Reflect.getProperty(PlayState.currentPlaystate.luaSprites.get(name), property);
        });

        Lua_helper.add_callback(lua, "getProperty", function(field:String, property:String) {
            return Reflect.getProperty(getField(field), property);
        });

        Lua_helper.add_callback(lua, "setProperty", function (field:String, property:String, value:Dynamic) {
            Reflect.setProperty(getField(field), property, value);
        });

        Lua_helper.add_callback(lua, "tweenProperty", function(field:String, variable:String, value:Float = 0, duration:Float = 1, ?onComplete:String = null) {
            FlxTween.num(Reflect.getProperty(getField(field), variable), value, duration, {onComplete: (value) -> call(onComplete)}, f -> Reflect.setProperty(getField(field), variable, f));
        });

        // Gets the client setting
        Lua_helper.add_callback(lua, "getSetting", function(setting:String) {
            return Options.get(setting);
        });

        // Changes the stage of current playstate
        Lua_helper.add_callback(lua, "changeStage", function(stageName:String) {
            PlayState.currentPlaystate.changeStage(stageName);
        });

        // Caches stage
        Lua_helper.add_callback(lua, "cacheStage", function(name:String) {
            Cache.cacheStage(name);
        });

        // Add zoom to the camera
        Lua_helper.add_callback(lua, "addCameraZoom", function(value:Float) {
            PlayState.currentPlaystate.addCameraZoom(value);
        });

        // Sets the game camera default zoom
        Lua_helper.add_callback(lua, "setDownscroll", function(value:Bool) {
            PlayState.currentPlaystate.downscroll = value;
        });

        // Sets the game camera default zoom
        Lua_helper.add_callback(lua, "setDefaultCamZoom", function(zoom:Float) {
            PlayState.currentPlaystate.stage.camZoom = zoom;
        });

        // Caches character so it doesnt lag when changing the character
        Lua_helper.add_callback(lua, "cacheCharacter", function(char:String, daChar:String) {
			Cache.cacheCharacter(char, daChar, true);
        });

        // Changes character
        Lua_helper.add_callback(lua, "changeCharacter", function(char:String, newChar:String) {
            PlayState.currentPlaystate.changeCharacter(char, newChar);
		});

        // Sets the size of some sprite
        Lua_helper.add_callback(lua, "setGraphicSize", function (sprite:String, width:Int, height:Int) {
            var daSprite:FlxSprite = getField(sprite);
            daSprite.setGraphicSize(width, height);
        });

        // Returns the x position of some object
        Lua_helper.add_callback(lua, "getPositionX", function (object:String) {
            var daSprite:FlxObject = getField(object);
            return daSprite.x;
        });

        // Returns the y position of some object
        Lua_helper.add_callback(lua, "getPositionY", function (object:String) {
            var daSprite:FlxObject = getField(object);
            return daSprite.y;
        });

        // Sets the position of some object
        Lua_helper.add_callback(lua, "setPosition", function (object:String, x:Int, y:Int) {
            var daSprite:FlxObject = getField(object);
            daSprite.setPosition(x, y);
        });

        // Sets the position of specified strum note
        Lua_helper.add_callback(lua, "setStrumNotePos", function(char:String, note:Int, x:Float, y:Float) {
            if (char == "dad") {
                PlayState.currentPlaystate.dadStrumLineNotes.forEach(function(spr:FlxSprite) {
                    if (note == spr.ID) {
                        spr.setPosition(x, y);
                        return;
                    }
                });
            }
            else {
                PlayState.currentPlaystate.bfStrumLineNotes.forEach(function(spr:FlxSprite) {
                    if (note == spr.ID) {
                        spr.setPosition(x, y);
                        return;
                    }
                });
            }
        });

        // Returns position of specified strum note
        Lua_helper.add_callback(lua, "getStrumNotePos", function(char:String, note:Int) {
            var arr = new Null<Array<Float>>();
            if (char == "dad") {
                PlayState.currentPlaystate.dadStrumLineNotes.forEach(function(spr:FlxSprite) {
                    if (note == spr.ID) {
                        arr = [spr.x, spr.y];
                    }
                });
            } else {
                PlayState.currentPlaystate.bfStrumLineNotes.forEach(function(spr:FlxSprite) {
                    if (note == spr.ID) {
                        arr = [spr.x, spr.y];
                    }
                });
            }
            return arr;
        });

        // Sets some variable from playstate
        Lua_helper.add_callback(lua, "setVariable", function(object:String, value:Dynamic) {
            setField(object, value);
        });

        // Returns some variable from playstate
        Lua_helper.add_callback(lua, "getVariable", function(object:String) {
            return getField(object);
        });

        //alias for getVariable
		Lua_helper.add_callback(lua, "getField", function(object:String) {
			return getField(object);
		});

		// alias for setVariable
		Lua_helper.add_callback(lua, "setField", function(object:String, value:Dynamic) {
			setField(object, value);
		});

        // Sets the player's health
        Lua_helper.add_callback(lua, "setHealth", function(value:Float) {
            setField("health", value);
        });

        // Returns player's health
        Lua_helper.add_callback(lua, "getHealth", function() {
			return getField("health");
        });

        // Sets the camera position
        Lua_helper.add_callback(lua, "setCamPosition", function(cam:String, x:Float = 0, y:Float = 0) {
            if (cam == "hud") {
                PlayState.camHUD.setPosition(x, y);
            } else if (cam == "game") {
                PlayState.camFollow.setPosition(x, y);
            }
		});

        // Tweens the variable
        Lua_helper.add_callback(lua, "tweenVariable", function(object:String, value:Float = 0, duration:Float = 1) {
            FlxTween.num(getField(object), value, duration, null, f -> setField(object, f));
        });

        // Tweens the cam angle
        Lua_helper.add_callback(lua, "tweenCamAngle", function(cam:String, value:Float = 0, duration:Float = 1) {
            if (cam == "hud") {
                FlxTween.num(PlayState.camHUD.angle, value, duration, null, f -> PlayState.camHUD.angle = f);
            } else if (cam == "game") {
                FlxTween.num(PlayState.camGame.angle, value, duration, null, f -> PlayState.camGame.angle = f);
            }
        });

        // Tweens the cam zoom
        Lua_helper.add_callback(lua, "tweenCamZoom", function(cam:String, value:Float = 0, duration:Float = 1) {
            if (cam == "hud") {
                FlxTween.num(PlayState.camHUD.zoom, value, duration, null, f -> PlayState.camHUD.zoom = f);
            } else if (cam == "game") {
                FlxTween.num(PlayState.camZoom, value, duration, null, f -> PlayState.camZoom = f);
            }
        });

        // Sets the camera angle
        Lua_helper.add_callback(lua, "setCamAngle", function(cam:String, angle:Float = 0) {
            if (cam == "hud") {
                PlayState.camHUD.angle = angle;
            } else if (cam == "game") {
                PlayState.camGame.angle = angle;
            }
        });

        // Returns the camera angle
        Lua_helper.add_callback(lua, "getCamAngle", function(cam:String) {
            if (cam == "hud") {
                return PlayState.camHUD.angle;
            } else if (cam == "game") {
                return PlayState.camGame.angle;
            }
            return 0;
        });

        // Sets the camera zoom
        Lua_helper.add_callback(lua, "setCamZoom", function(cam:String, zoom:Float = 0) {
            if (cam == "hud") {
                PlayState.tweenCamZoom(zoom, "hud");
            } else if (cam == "game") {
                PlayState.tweenCamZoom(zoom);
            }
		});

        // Return the camera zoom
        Lua_helper.add_callback(lua, "getCamZoom", function(cam:String) {
            if (cam == "hud") {
                return PlayState.camHUD.zoom;
            } else if (cam == "game") {
                return PlayState.camZoom;
            }
            return 0;
        });

        // Makes camera do very epic effect (i killed 21 children in africa)
        Lua_helper.add_callback(lua, "shakeCamera", function(cam:String, intensity:Float = 0, duration:Float = 0) {
            if (cam == "hud") {
                PlayState.camHUD.shake(intensity, duration);
            } else if (cam == "game") {
                PlayState.camGame.shake(intensity, duration);
            }
		});

        LuaL.dofile(lua, luaPath);
    }

    public function setField(field:String, value:Dynamic) {
        if (getFieldType(field) == INSTANCE) {
            Reflect.setField(PlayState.currentPlaystate, field, value);
        }
        if (getFieldType(field) == STATIC) {
            Reflect.setField(PlayState, field, value);
        }
    }

    public function getField(field:String):Dynamic {
        if (getFieldType(field) == INSTANCE) {
            return Reflect.field(PlayState.currentPlaystate, field);
        }
        if (getFieldType(field) == STATIC) {
            return Reflect.field(PlayState, field);
        }
        return null;
    }

    public function getFieldType(field:String):FieldTypePlayState {
		if (Type.getInstanceFields(Type.getClass(PlayState.currentPlaystate)).contains(field)) {
            return INSTANCE;
        }
        if (Reflect.hasField(PlayState, field)) {
            return STATIC;
        }
        return NOTEXIST;
    }

    public function setVariable(name:String, value:Dynamic) {
		Convert.toLua(lua, value);
		Lua.setglobal(lua, name);
	}

    public function call(functionName:String, ?args:Array<Dynamic>) {
        if (functionName == null)
            return;

        Lua.getglobal(lua, functionName);

        if (args != null)
            for (s in args) {
                Convert.toLua(lua, s);
            }
        else
            args = [];
        
        Lua.pcall(lua, args.length, 1, 1);
    }

    public function close() {
        Lua.close(lua);
    }
}

enum FieldTypePlayState {
    NOTEXIST;
    STATIC;
    INSTANCE;
}

class Position {
    var x:Float;
    var y:Float;
}
package;

import flixel.FlxG;
import flixel.math.FlxMath;
import haxe.io.Input;
import haxe.zip.Reader;
import sys.FileSystem;
import haxe.Resource;
import lime.ui.FileDialog;
import lime.utils.Bytes;
import openfl.display.BitmapData;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.FlxSprite;
import flixel.text.FlxText;
import openfl.net.URLRequestMethod;
import openfl.net.URLLoader;
import openfl.net.URLRequest;
import openfl.events.ProgressEvent;
import openfl.events.Event;
import sys.io.FileInput;
import openfl.net.URLStream;
import sys.io.File;
import openfl.events.DataEvent;
import openfl.utils.ByteArray;
import openfl.events.EventDispatcher;
import flixel.FlxState;

class UpdateState extends FlxState {

    var URL = Main.gitJson.assets[0].browser_download_url;

    public var file = new ByteArray();
    var request:URLRequest;
    var stream:URLStream;

    var text:FlxText;

    override function create() {
        FlxG.sound.music.volume = 0.1;
        
        var verText = new FlxText();
        verText.text = Main.gitJson.name;
        verText.size = 28;
        verText.screenCenter(X);
        verText.y = 20;
        add(verText);

        var infoText = new FlxText();
		infoText.size = 14;
		infoText.textField.htmlText = Markdown.markdownToHtml(Main.gitJson.body);
        infoText.screenCenter(X);
        infoText.y = verText.y + verText.height + 20;
        add(infoText);

        text = new FlxText();
        text.text = "Preparing...";
        text.size = 18;
        text.screenCenter(X);
        text.y = (FlxG.height - text.height) - 20;
        add(text);

        if (!FileSystem.exists("funkin.updat")) {
            request = new URLRequest(URL);

            stream = new URLStream();
            stream.load(new URLRequest(URL));
            stream.addEventListener(ProgressEvent.PROGRESS, (event) -> onProgress(event));
            stream.addEventListener(Event.COMPLETE, (event) -> onComplete(event));
            stream.load(request);
        }
        else {
            onComplete(null, true);
        }

        super.create();
    }

	override public function onFocusLost():Void {
		super.onFocusLost();

		FlxG.autoPause = false;
	}

    function onProgress(event:ProgressEvent) {
        text.text = 'Downloading... ${FlxMath.roundDecimal(event.bytesLoaded / 1000000, 1)}MB of ${FlxMath.roundDecimal(event.bytesTotal / 1000000, 1)}MB';
        text.screenCenter(X);
    }
    function onComplete(?event:Event, ?fileExists = false) {
        text.text = 'Downloading Complete';
        text.screenCenter(X);
        
        #if linux
        var programPath = Sys.programPath().substring(0, Sys.programPath().length - 6);
        #else
        var programPath = Sys.programPath().substring(0, Sys.programPath().length - 10);
        #end

        if (!fileExists) {
            @:privateAccess
			file = stream.__data;
            CoolUtil.writeToFile(programPath + "funkin.updat", file, true);
        }

        #if cpp
        Sys.command('start "" "${programPath + "updateUnzipper.exe"}"');
        #elseif neko
        Sys.command("./updateUnzipper");
        #end
        Sys.exit(1);
    }
}

class OutdatedState extends FlxState {
    override function create() {
        super.create();

        var text = new FlxText();
        text.size = 24;
        text.text = 'You are on a older version!\nDo you want to update the game?\n\n${KeyBind.controlsMap.get(ACCEPT)[0].toString()} - Yes       |       ${KeyBind.controlsMap.get(BACK)[0].toString()} - No';
        text.screenCenter();
        add(text);
    }
    override function update(elapsed) {
        super.update(elapsed);

        if (Controls.check(ACCEPT)) {
            FlxG.switchState(new UpdateState());
        }
        if (Controls.check(BACK)) {
            FlxG.switchState(new MainMenuState());
        }
    }
}
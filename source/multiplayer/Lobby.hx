package multiplayer;

import sys.io.File;
import sys.FileSystem;
import Song.SwagSong;
import flixel.util.FlxTimer;
import sys.net.Host;
import sys.net.UdpSocket;
import flixel.math.FlxRandom;
import flixel.util.FlxColor;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.text.FlxTextField;
import flixel.text.FlxText;
import flixel.FlxG;
import flixel.ui.FlxButton;
import flixel.FlxState;

class Player1 {

	public static var nick = "(unknown)";
    public static var ready = false;

	/**
	* Sets every Player1 variable to their default value 
	*/
	public static function clear() {
		nick = "(unknown)";
        ready = false;
	}
}

class Player2 {

	public static var nick = "(unknown)";
    public static var ready = false;

	/**
	* Sets every Player2 variable to their default value 
	*/
	public static function clear() {
		nick = "(unknown)";
        ready = false;
	}
}

class Lobby extends MusicBeatState {

    public static var server:Server;
    public static var client:Client;
    public static var isHost:Bool;

    public static var player1:Character;
    public static var player2:Character;

    public static var player1DisplayName:FlxText;
	public static var player2DisplayName:FlxText;
    public static var player1DisplayReady:FlxText;
    public static var player2DisplayReady:FlxText;

    public static var ip:String;
    public static var port:Int;

    var starting:Bool = false;

    public function new(?host:String, ?port:Int, ?isHost:Bool, ?nick:String) {
        super();

        Player1.ready = false;
        Player2.ready = false;

        if (host != null) {
            CoolUtil.clearMPlayers();

            ip = host;
            Lobby.port = port;
            Lobby.isHost = isHost;
    
            if (isHost) {
                Player1.nick = nick;
                server = new Server(host, port);
            }
            else {
                Player2.nick = nick;
                client = new Client(host, port);
            }
        }
    }

    override function create() {
        super.create();

        FlxG.sound.playMusic(Paths.music("giveALilBitBack", "shared"));
        Conductor.changeBPM(126);

        var ipInfo = new FlxText(10, 10, 0, 'IP: $ip', 16);
        add(ipInfo);

        var portInfo = new FlxText(10, ipInfo.y + ipInfo.height, 0, 'Port: $port', 16);
        add(portInfo);

        var nickInfo = new FlxText(10, portInfo.y + portInfo.height, 0, '', 16);
        if (isHost)
            nickInfo.text = 'Nick: ' + Player1.nick;
        else
            nickInfo.text = 'Nick: ' + Player2.nick;
        add(nickInfo);

        if (isHost) {
            var hostMode = new FlxText(10, nickInfo.y + nickInfo.height + 5, 0, 'HOST MODE', 16);
            hostMode.color = FlxColor.YELLOW;
            add(hostMode);
        }

        var PLAYERSPACE = 300;

        Paths.setCurrentLevel("week-1");
        Paths.setCurrentStage("stage");

        player1 = new Character(0, 0, "bf");
        player1.flipX = !player1.flipX;
        player1.screenCenter(XY);
        player1.x += PLAYERSPACE;
        add(player1);

        player2 = new Character(0, 0, "bf");
        player2.screenCenter(XY);
        player2.x -= PLAYERSPACE;
        if (isHost && !server.hasClients())
            player2.alpha = 0.4;
        add(player2);

        player1DisplayName = new FlxText(0, player1.y - 40, 0, Player1.nick, 24);
        player1DisplayName.x = (player1.x + (player1.width / 2)) - (player1DisplayName.width / 2);
        add(player1DisplayName);

        player2DisplayName = new FlxText(0, player2.y - 40, 0, Player2.nick, 24);
        player2DisplayName.x = (player2.x + (player2.width / 2)) - (player2DisplayName.width / 2);
        add(player2DisplayName);

        player1DisplayReady = new FlxText(0, player1.y + player1.height + 40, 0, "READY", 24);
        player1DisplayReady.x = (player1.x + (player1.width / 2)) - (player1DisplayReady.width / 2);
        player1DisplayReady.color = FlxColor.YELLOW;
        player1DisplayReady.visible = false;
        add(player1DisplayReady);

        player2DisplayReady = new FlxText(0, player2.y + player2.height + 40, 0, "READY", 24);
        player2DisplayReady.x = (player2.x + (player2.width / 2)) - (player2DisplayReady.width / 2);
        player2DisplayReady.color = FlxColor.YELLOW;
        player2DisplayReady.visible = true;
        add(player2DisplayReady);
    }

    function goToSong(song:String, diff:Int) {
		if (SysFile.exists(Paths.instNoLib(song))) {
			PlayState.SONG = Song.loadFromJson(song, song);
		} else {
			PlayState.SONG = Song.PEloadFromJson(song, song);
		}

		PlayState.isStoryMode = false;
		PlayState.storyDifficulty = diff;
		switch (PlayState.storyDifficulty) {
			case 0:
				PlayState.dataFileDifficulty = '-easy';
			case 1:
				PlayState.dataFileDifficulty = "";
			case 2:
				PlayState.dataFileDifficulty = '-hard';
		}
		PlayState.storyWeek = -1;
		trace('CUR WEEK ' + PlayState.storyWeek);

		if (isHost) {
            FlxG.switchState(new PlayState("bf", true));
        } else {
            FlxG.switchState(new PlayState("dad", true));
        }
    }

    private function startCountDown() {
        var funnyNumbers = new FlxText(0, 0, 0, "3", 50);
        funnyNumbers.screenCenter(XY);
        add(funnyNumbers);

        new FlxTimer().start(1, function(swagTimer:FlxTimer) {
            funnyNumbers.text = "2";
            new FlxTimer().start(1, function(swagTimer:FlxTimer) {
                funnyNumbers.text = "1";
                new FlxTimer().start(1, function(swagTimer:FlxTimer) {
                    goToSong("fresh", 2);
                });
            });
        });
    }
 
    override function update(elapsed) {
        super.update(elapsed);

        if (Player1.ready && Player2.ready && !starting) {
            startCountDown();
        }

        if (Player1.ready && Player2.ready)
            starting = true;

        player1DisplayName.text = Player1.nick;
        player2DisplayName.text = Player2.nick;

        player1DisplayReady.visible = Player1.ready;
        player2DisplayReady.visible = Player2.ready;

        if (FlxG.keys.justPressed.ESCAPE) {
            if (isHost) {
                server.stop();
                CoolUtil.clearMPlayers();
                FlxG.switchState(new LobbySelectorState());
            }
            else {
                client.client.disconnect();
            }
        }

        if (FlxG.keys.justPressed.SPACE) {
            if (isHost) {
                Player1.ready = !Player1.ready;
                server.sendStringToCurClient('P1::ready::' + Player1.ready);
            }
            else {
                Player2.ready = !Player2.ready;
                client.sendString('P2::ready::' + Player2.ready);
            }
        }
        
        Conductor.songPosition = FlxG.sound.music.time;
    }

	override public function beatHit() {
		super.beatHit();

        player1.playAnim('idle', true);
        if (player2.alpha == 1) {
            player2.playAnim('idle', true);
        }
    }

    override public function onFocus() {
        super.onFocus();
        FlxG.sound.music.fadeIn(0.2, FlxG.sound.music.volume, 1);
    }

    override public function onFocusLost() {
        FlxG.autoPause = false;
        FlxG.sound.music.fadeOut(0.2, 0.1);
    }
}

class LobbySelectorState extends FlxState {
    public function new() {
        super();

        FlxG.mouse.visible = true;

        var BUTTONSPACE = 50;

        var clientIP = new FlxUIInputText(0, 0, 100, "127.0.0.1", 10);
        clientIP.screenCenter(XY);
        clientIP.y += 50;
        clientIP.x += 20;
        add(clientIP);

        var clientIPInfo = new FlxText(clientIP.x - 40, clientIP.y, 0, "IP:");
        add(clientIPInfo);


        var clientPort = new FlxUIInputText(0, 0, 100, "9000", 10);
        clientPort.screenCenter(XY);
        clientPort.y = clientIP.y + 20;
        clientPort.x = clientIP.x;
        add(clientPort);

        var clientPortInfo = new FlxText(clientPort.x - 40, clientPort.y, 0, "Port:");
        add(clientPortInfo);

        var nick = "";
        if (Options.get("nick") != null) {
            nick = Options.get("nick");
        } else {
            nick = "Player" + new FlxRandom().int(1, 99);
        }

        var clientNick = new FlxUIInputText(0, 0, 100, nick, 10);
        clientNick.screenCenter(XY);
        clientNick.y = clientPort.y + 20;
        clientNick.x = clientPort.x;
        add(clientNick);

        var clientNickInfo = new FlxText(clientNick.x - 40, clientNick.y, 0, "Nick:");
        add(clientNickInfo);

        
        var text = new FlxText(0, 0, 0, "Multiplayer", 48);
        text.screenCenter(XY);
        text.y -= 150;
        add(text);

        var clientButton = new FlxButton(0, 0, "Connect", function onConnectPressed() {
            Options.setAndSave("nick", clientNick.text);
            FlxG.switchState(new Lobby(clientIP.text, Std.parseInt(clientPort.text), false, clientNick.text));
        });
        clientButton.screenCenter(XY);
        clientButton.x -= BUTTONSPACE;
        add(clientButton);

        var serverButton = new FlxButton(0, 0, "Host", function onHostPressed() {
            Options.setAndSave("nick", clientNick.text);
            FlxG.switchState(new Lobby(clientIP.text, Std.parseInt(clientPort.text), true, clientNick.text));
        });
        serverButton.screenCenter(XY);
        serverButton.x += BUTTONSPACE;
        add(serverButton);
    }

    override function update(elapsed) {
        super.update(elapsed);

        if (FlxG.keys.justPressed.ESCAPE) {
            FlxG.switchState(new MainMenuState());
        }
    }
}
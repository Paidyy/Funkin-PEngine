package multiplayer;

import Modifier.Modifiers;
import udprotean.server.UDProteanClientBehavior;
import OptionsSubState.Background;
import Discord.DiscordClient;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUITabMenu;
import sys.io.File;
import sys.FileSystem;
import Song.SwagSong;
import flixel.util.FlxTimer;
import sys.net.Host;
import sys.net.UdpSocket;
import flixel.math.FlxRandom;
import flixel.util.FlxColor;
import flixel.addons.text.FlxTextField;
import flixel.text.FlxText;
import flixel.FlxG;
import flixel.ui.FlxButton;
import flixel.FlxState;

class MultiPlayer {

	public var nick:String;
    public var ready:Bool;

	public var peer:UDProteanClientBehavior;

    //CURRENTLY UNUSED
    public var score:Int;
    public var accuracy:Float;
    public var misses:Int;

    /** Sets every `this` variable to their default value */
	public function clear() {
		nick = "(unknown)";
        ready = false;

        score = 0;
        accuracy = 0.0;
        misses = 0;
	}

    public function new() {
        clear();
    }
}

class Lobby extends MusicBeatState {

    public static var server:Server;
    public static var client:Client;
    public static var isHost:Bool;

    public static var player1:MultiPlayer;
    public static var player2:MultiPlayer;


    public static var lobbyPlayer1:Character;
    public static var lobbyPlayer2:Character;

    public static var player1DisplayName:FlxText;
	public static var player2DisplayName:FlxText;
    public static var player1DisplayReady:FlxText;
    public static var player2DisplayReady:FlxText;

    public static var ip:String;
    public static var port:Int;

    var starting:Bool = false;
    public static var inGame:Bool = false;

    public static var curSong:String = "bopeebo";
    public static var curDifficulty:Int = 2;

    public static var songsDropDown:UIDropDownMenu;
	public static var difficultyDropDown:UIDropDownMenu;

    var uiBox:FlxUITabMenu;

    public function new(?host:String, ?port:Int, ?isHost:Bool, ?nick:String) {
        super();

        inGame = false;

        if (host != null) {
            //CoolUtil.clearMPlayers();

            player1 = new MultiPlayer();
            player2 = new MultiPlayer();

            ip = host;
            Lobby.port = port;
            Lobby.isHost = isHost;

            curSong = "bopeebo";
            curDifficulty = 2;
    
            if (isHost) {
                player1.nick = nick;
                server = new Server(host, port);
            }
            else {
                player2.nick = nick;
                client = new Client(host, port);
            }
        }

        player1.ready = false;
        player2.ready = false;
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
            nickInfo.text = 'Nick: ' + player1.nick;
        else
            nickInfo.text = 'Nick: ' + player2.nick;
        add(nickInfo);

        if (isHost) {
            var hostMode = new FlxText(10, nickInfo.y + nickInfo.height + 5, 0, 'HOST MODE', 16);
            hostMode.color = FlxColor.YELLOW;
            add(hostMode);
        }

        var PLAYERSPACE = 250;

        Paths.setCurrentLevel("week-1");
        Paths.setCurrentStage("stage");

        stage = new Stage("philly");
        add(stage);

        lobbyPlayer1 = new Character(0, 0, "bf");
        lobbyPlayer1.flipX = !lobbyPlayer1.flipX;
        lobbyPlayer1.screenCenter(XY);
        lobbyPlayer1.x += PLAYERSPACE;
        lobbyPlayer1.x -= 170;
        lobbyPlayer1.y += 250;
        add(lobbyPlayer1);

        lobbyPlayer2 = new Character(0, 0, "bf");
        lobbyPlayer2.screenCenter(XY);
        lobbyPlayer2.x -= PLAYERSPACE;
        lobbyPlayer2.x -= 170;
        if (isHost && !server.hasClients())
            lobbyPlayer2.alpha = 0.4;
        lobbyPlayer2.y += 250;
        add(lobbyPlayer2);

        FlxG.camera.scroll.y += 200;

        player1DisplayName = new FlxText(0, lobbyPlayer1.y - 40, 0, player1.nick, 24);
        player1DisplayName.x = (lobbyPlayer1.x + (lobbyPlayer1.width / 2)) - (player1DisplayName.width / 2);
        add(player1DisplayName);

        player2DisplayName = new FlxText(0, lobbyPlayer2.y - 40, 0, player2.nick, 24);
        player2DisplayName.x = (lobbyPlayer2.x + (lobbyPlayer2.width / 2)) - (player2DisplayName.width / 2);
        add(player2DisplayName);

        player1DisplayReady = new FlxText(0, lobbyPlayer1.y + lobbyPlayer1.height + 40, 0, "READY", 24);
        player1DisplayReady.x = (lobbyPlayer1.x + (lobbyPlayer1.width / 2)) - (player1DisplayReady.width / 2);
        player1DisplayReady.color = FlxColor.YELLOW;
        player1DisplayReady.visible = false;
        add(player1DisplayReady);

        player2DisplayReady = new FlxText(0, lobbyPlayer2.y + lobbyPlayer2.height + 40, 0, "READY", 24);
        player2DisplayReady.x = (lobbyPlayer2.x + (lobbyPlayer2.width / 2)) - (player2DisplayReady.width / 2);
        player2DisplayReady.color = FlxColor.YELLOW;
        player2DisplayReady.visible = true;
        add(player2DisplayReady);

        var tabs = [
			{name: "General", label: 'General'}
		];

		uiBox = new FlxUITabMenu(null, tabs, true);
        uiBox.scrollFactor.set(0, 0);
		uiBox.resize(300, 400);
		uiBox.x = FlxG.width - uiBox.width - 20;
		uiBox.y += 20;
		add(uiBox);

        addGeneralUI();
    }

    function addGeneralUI():Void {
		var tab_group_note = new FlxUI(null, uiBox);
		tab_group_note.name = 'General';

        songsDropDown = new UIDropDownMenu(10, 20, CoolUtil.getSongs(), function(song:String, i) {
            curSong = song;
            sendMessage('SONG::$curSong');
		});
		songsDropDown.selectLabel(curSong);
        if (!isHost)
            songsDropDown.lock = true;
		var songsText = new FlxText(songsDropDown.x - 5, songsDropDown.y - 15, 0, "Song:");

        var diffs:Array<String> = [
            "Easy",
            "Normal",
            "Hard"
        ];
        difficultyDropDown = new UIDropDownMenu(songsDropDown.x + songsDropDown.width + 10, songsDropDown.y, diffs, function(difficulty, index) {
            curDifficulty = CoolUtil.stringToOgType(difficulty);
            sendMessage('DIFF::$curDifficulty');
		}, 3);
        difficultyDropDown.selectLabel("Hard");
        if (!isHost)
            difficultyDropDown.lock = true;
		var difficultyText = new FlxText(difficultyDropDown.x - 5, difficultyDropDown.y - 15, 0, "Difficulty:");

        tab_group_note.add(songsText);
        tab_group_note.add(songsDropDown);

        tab_group_note.add(difficultyText);
        tab_group_note.add(difficultyDropDown);

		uiBox.addGroup(tab_group_note);
	}

    function goToSong(song:String, diff:Int) {
		Modifiers.activeModifiers = [];
        inGame = true;

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

        if (FileSystem.exists(Paths.instNoLib(song))) {
			PlayState.SONG = Song.loadFromJson(song + PlayState.dataFileDifficulty, song);
		}
        else if (FileSystem.exists(Paths.PEinst(song))) {
			PlayState.SONG = Song.PEloadFromJson(song + PlayState.dataFileDifficulty, song);
		}
		PlayState.SONGglobalNotes = Song.parseGlobalNotesJSONshit(song);

        PlayState.storyWeek = "week-1";
		trace('CUR WEEK ' + PlayState.storyWeek);

		if (isHost) {
			PlayState.currentPlaystate.playAs = "bf";
            FlxG.switchState(new PlayState(true));
        } else {
			PlayState.currentPlaystate.playAs = "dad";
            FlxG.switchState(new PlayState(true));
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
                    goToSong(curSong, curDifficulty);
                });
            });
        });
    }
 
    override function update(elapsed) {
        super.update(elapsed);

        var playerCount = 1;
        if (lobbyPlayer2.alpha == 1) {
            playerCount = 2;
        }

        DiscordClient.changePresence(
            "Multiplayer",
            'In Lobby ($playerCount/2)'
        );

        animationKeys();

        if (player1.ready && player2.ready && !starting) {
            startCountDown();
        }

        if (player1.ready && player2.ready)
            starting = true;

        player1DisplayName.text = player1.nick;
        player2DisplayName.text = player2.nick;

        player1DisplayReady.visible = player1.ready;
        player2DisplayReady.visible = player2.ready;

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
                player1.ready = !player1.ready;
                sendMessage('P1::ready::' + player1.ready);
            }
            else {
                player2.ready = !player2.ready;
                sendMessage('P2::ready::' + player2.ready);
            }
        }
        
        Conductor.songPosition = FlxG.sound.music.time;
    }

    public function sendMessage(s:String) {
        if (isHost)
            server.sendStringToCurClient(s);
        else
            client.sendString(s);
    }

	override public function beatHit() {
		super.beatHit();

        if (lobbyPlayer1.animation.curAnim.name == 'idle') {
            lobbyPlayer1.playAnim('idle', true);
        }
        if (lobbyPlayer2.animation.curAnim.name == 'idle') {
            if (lobbyPlayer2.alpha == 1) {
                lobbyPlayer2.playAnim('idle', true);
            }
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

    function animationKeys() {
        if (Controls.check(UP)) {
            if (isHost)
                lobbyPlayer1.playAnim("singUP");
            else
                lobbyPlayer2.playAnim("singUP");
            sendMessage("LKP::UP");
        }

        if (Controls.check(DOWN)) {
            if (isHost)
                lobbyPlayer1.playAnim("singDOWN");
            else
                lobbyPlayer2.playAnim("singDOWN");
            sendMessage("LKP::DOWN");
        }

        if (Controls.check(LEFT)) {
            if (isHost)
                lobbyPlayer1.playAnim("singLEFT");
            else
                lobbyPlayer2.playAnim("singLEFT");
            sendMessage("LKP::LEFT");
        }
        
        if (Controls.check(RIGHT)) {
            if (isHost)
                lobbyPlayer1.playAnim("singRIGHT");
            else
                lobbyPlayer2.playAnim("singRIGHT");
            sendMessage("LKP::RIGHT");
        }

        if (!Controls.check(UP) && !Controls.check(DOWN) && !Controls.check(LEFT) && !Controls.check(RIGHT)) {
            // player.animation.curAnim.name != "idle" so it doesnt spam
            if (isHost) {
                if (lobbyPlayer1.animation.curAnim.name != "idle")
                    sendMessage("LKR");
                lobbyPlayer1.playAnim("idle");
            }
            else {
                if (lobbyPlayer2.animation.curAnim.name != "idle")
                    sendMessage("LKR");
                lobbyPlayer2.playAnim("idle");
            }
        }
    }

	var stage:Stage;
}

class LobbySelectorState extends FlxState {
    public function new() {
        super();

        DiscordClient.changePresence(
            "Multiplayer",
            "In Connect Menu"
        );

        FlxG.mouse.visible = true;

        var BUTTONSPACE = 50;

        var bg = new Background(FlxColor.WHITE);
        bg.alpha = 0.4;
        add(bg);

        var clientIP = new UIInputText(0, 0, 100, "127.0.0.1", 10);
        clientIP.screenCenter(XY);
        clientIP.y += 50;
        clientIP.x += 20;
        add(clientIP);

        var clientIPInfo = new FlxText(clientIP.x - 40, clientIP.y, 0, "IP:");
        add(clientIPInfo);


        var clientPort = new UIInputText(0, 0, 100, "9000", 10);
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

        var clientNick = new UIInputText(0, 0, 100, nick, 10);
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
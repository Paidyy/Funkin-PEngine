package multiplayer;

import flixel.addons.ui.FlxUIDropDownMenu;
import multiplayer.Lobby;
import multiplayer.Lobby.LobbySelectorState;
import flixel.FlxG;
import haxe.io.Bytes;
import udprotean.client.UDProteanClient;

using StringTools;

class Client {
    
	public var client:ProteanClient;
    
    public function new(ip:String, port:Int) {
		client = new ProteanClient(ip, port);

		#if target.threaded
		sys.thread.Thread.create(() -> {
			client.connect();

			trace("Connected to a Server with IP: " + ip + " Port: " + port);

			sendString('P2::nick::' + Lobby.player2.nick);

			try {
				while (true) {
					client.update();
				}
	
				client.disconnect();
			} catch (exc) {
				trace("Exception // Disconnected from server");
				trace(exc.details());
				FlxG.switchState(new LobbySelectorState());
			}
		});
		#end
    }

	public function sendString(s:String) {
        client.send(Bytes.ofString(s));
    }
}

class ProteanClient extends UDProteanClient {
	// Called after the constructor.
	override function initialize() {

    }

	override function onMessage(msg:Bytes) {
		try {
			var strMsg = msg.toString();

			//trace("Client got a message: " + strMsg);
	
			if (strMsg.contains("::")) {
				var msgSplitted = strMsg.split("::");
	
				var splited1:Dynamic = CoolUtil.stringToOgType(msgSplitted[1]);
				var value = CoolUtil.stringToOgType(msgSplitted[2]);
				
				switch (msgSplitted[0]) {
					case "P1":
						Reflect.setField(Lobby.player1, msgSplitted[1], value);
					case "P2":
						Reflect.setField(Lobby.player2, msgSplitted[1], value);
					case "LKP":
						Lobby.lobbyPlayer1.playAnim('sing$splited1', true);
					case "LKR":
						Lobby.lobbyPlayer1.playAnim('idle', true);
					case "NP":
						PlayState.currentPlaystate.multiplayerNoteHit(new Note( splited1, CoolUtil.stringToOgType(msgSplitted[2]) ), false);
					case "SNP":
						PlayState.currentPlaystate.strumPlayAnim(splited1, "bf", "pressed");
					case "SNR":
						PlayState.currentPlaystate.strumPlayAnim(splited1, "bf", "static");
					case "SONG":
						Lobby.curSong = splited1;
						Lobby.difficultyDropDown.strList = CoolUtil.setDifficultyList(Lobby.curSong, true);
						Lobby.difficultyDropDown.scrollPosition = 0;
						Lobby.difficultyDropDown.showItems = Lobby.difficultyDropDown.strList.length;
						Lobby.difficultyDropDown.curList = [];
						Lobby.difficultyDropDown.setList();
						Lobby.difficultyDropDown.setData(FlxUIDropDownMenu.makeStrIdLabelArray(Lobby.difficultyDropDown.curList, true));
						Lobby.songsDropDown.selectLabel(Lobby.curSong);
					case "DIFF":
						Lobby.difficultyDropDown.selectLabel(splited1.toLowerCase());
						switch (splited1.toLowerCase()) {
							case "easy":
								Lobby.curDifficulty = 0;
							case "normal":
								Lobby.curDifficulty = 1;
							case "hard":
								Lobby.curDifficulty = 2;
							default:
								Lobby.curDifficulty = 1;
						}
					case "SCO":
						Lobby.player1.score = splited1;
					case "ACC":
						Lobby.player1.accuracy = splited1;
					case "MISN":
						Lobby.player1.misses = splited1;
				}
			}
		}
		catch (exc) {
			trace("Client caught an exception!");
			trace(exc.details());
		}
    }

	// Called after the connection handshake.
	override function onConnect() { }

	override function onDisconnect() {
        trace("disconnected from server");
		CoolUtil.clearMPlayers();
        FlxG.switchState(new LobbySelectorState());
    }
}

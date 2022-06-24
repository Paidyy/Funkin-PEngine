package multiplayer;

import udprotean.shared.Utils;
import multiplayer.Lobby;
import flixel.FlxG;
import haxe.io.Bytes;
import udprotean.server.UDProteanClientBehavior;
import udprotean.server.UDProteanServer;

using StringTools;

class Server extends UDProteanServer {

	public function new(host:String, port:Int) {
		super(host, port, ServerBehavior);

		#if target.threaded
		sys.thread.Thread.create(() -> {
			start();

			trace("Started Server with IP: " + host + " Port: " + port);

			@:privateAccess
			onClientConnected(client -> {
				if (peers.length > 1) {
					client.send(Bytes.ofString("EXC::Too many players!"));
					removePeer(Utils.addressToId(client.peerAddress));
				}
				trace("Some Client Connected");

				Lobby.player2.peer = client;
				Lobby.lobbyPlayer2.alpha = 1;
				sendStringToCurClient("P1::nick::" + Lobby.player1.nick);
				sendStringToCurClient("P1::ready::" + Lobby.player1.ready);
				sendStringToCurClient("SONG::" + Lobby.curSong);
				sendStringToCurClient('DIFF::${Lobby.difficultyDropDown.selectedLabel}');
			});
			onClientDisconnected(client -> {
				trace("Some Client Disconnected");

				Lobby.lobbyPlayer2.alpha = 0.4;
				Lobby.player2.clear();

				if (Lobby.inGame) {
					FlxG.switchState(new LobbySelectorState());
				}
			});

			try {
				while (true) {
					update();
				}
	
				stop();
			} catch (exc) {
				trace("Exception // Stopped the server");
				trace(exc.details());
				FlxG.switchState(new LobbySelectorState());
			}
		});
		#end
	}

	public function sendStringToCurClient(s:String) {
		for (client in peers) {
			client.send(Bytes.ofString(s));
		}
    }

	public function hasClients() {
		if (peers.length > 0)
			return true;
		return false;
    }
}

class ServerBehavior extends UDProteanClientBehavior {
	// Called after the constructor.
	override function initialize() { }

	override function onMessage(msg:Bytes) {
		try {
			var strMsg = msg.toString();
			//trace("Server got a message: " + strMsg);
	
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
						Lobby.lobbyPlayer2.playAnim('sing$splited1', true);
					case "LKR":
						Lobby.lobbyPlayer2.playAnim('idle', true);
					case "NP":
						PlayState.currentPlaystate.multiplayerNoteHit(new Note( splited1, CoolUtil.stringToOgType(msgSplitted[2]) ), true);
					case "SNP":
						PlayState.currentPlaystate.strumPlayAnim(splited1, "dad", "pressed");
					case "SNR":
						PlayState.currentPlaystate.strumPlayAnim(splited1, "dad", "static");
					case "SCO":
						Lobby.player2.score = splited1;
					case "ACC":
						Lobby.player2.accuracy = splited1;
					case "MISN":
						Lobby.player2.misses = splited1;

				}
			}
		}
		catch (exc) {
			trace("Server caught an exception!");
			trace(exc.details());
 		}
	}

	// Called after the connection handshake.
	override function onConnect() { }

	override function onDisconnect() { }
}


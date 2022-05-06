package;

import Sys.sleep;
#if windows
import discord_rpc.DiscordRpc;
#end

// discordrpc doesnt work on linux
using StringTools;

class DiscordClient {

	public static var isRunning = true;

	public function new() {
		if (Options.discordRPC == true) {
			#if windows
			trace("Discord Client starting...");
			DiscordRpc.start({
				clientID: "814588678700924999",
				onReady: onReady,
				onError: onError,
				onDisconnected: onDisconnected
			});
			isRunning = true;
			trace("Discord Client started.");
	
			while (true) {
				DiscordRpc.process();
				sleep(2);
				// trace("Discord Client Update");
			}
	
			shutdown();
			#end
		}
	}

	public static function shutdown() {
		//trace("Discord Client Shutted Down");
		isRunning = false;
		#if windows
		DiscordRpc.shutdown();
		#end
	}

	static function onReady() {
		#if windows
		DiscordRpc.presence({
			details: "In the Menus",
			state: null,
			largeImageKey: 'icon',
			largeImageText: "Friday Night Funkin'"
		});
		#end
	}

	static function onError(_code:Int, _message:String) {
		trace('Error! $_code : $_message');
	}

	static function onDisconnected(_code:Int, _message:String) {
		isRunning = false;
		trace('Disconnected! $_code : $_message');
	}

	public static function initialize() {
		#if windows
		var DiscordDaemon = sys.thread.Thread.create(() -> {
			new DiscordClient();
		});
		trace("Discord Client initialized");
		#end
	}

	public static function startPresence() {
		initialize();
	}

	public static function changePresence(details:String, state:Null<String>, ?smallImageKey:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float) {
		if (Options.discordRPC) {
			if (!isRunning) {
				startPresence();
			}
			#if windows
			var startTimestamp:Float = if (hasStartTimestamp) Date.now().getTime() else 0;

			if (endTimestamp > 0) {
				endTimestamp = startTimestamp + endTimestamp;
			}

			DiscordRpc.presence({
				details: details,
				state: state,
				largeImageKey: 'icon',
				largeImageText: "Friday Night Funkin'",
				smallImageKey: smallImageKey,
				// Obtained times are in milliseconds so they are divided so Discord can use it
				startTimestamp: Std.int(startTimestamp / 1000),
				endTimestamp: Std.int(endTimestamp / 1000)
			});

			// trace('Discord RPC Updated. Arguments: $details, $state, $smallImageKey, $hasStartTimestamp, $endTimestamp');
			#end
		} else {
			#if windows
			shutdown();
			#end
		}
	}
}

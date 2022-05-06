package;

import flixel.FlxG;
import flash.errors.Error;
import flash.net.SharedObject;
import flash.net.SharedObjectFlushStatus;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;

import openfl.net.SharedObjectFlushStatus;
import openfl.net.SharedObjectFlushStatus;
import openfl.net.NetConnection;
import openfl.net.ObjectEncoding;
#if !flash
import haxe.io.Bytes;
import haxe.io.Path;
import haxe.Serializer;
import haxe.Unserializer;
import openfl.errors.Error;
import openfl.events.EventDispatcher;
import openfl.utils.Object;
#if lime
import lime.app.Application;
import lime.system.System;
#end
#if (js && html5)
import js.Browser;
#end
#if sys
import sys.io.File;
import sys.FileSystem;
#end

/**
    Shared object that is outside "company" "name" folder
**/
#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class AltSharedObject extends EventDispatcher
{
	/**
		The default object encoding (AMF version) for all local shared objects created in
		the SWF file. When local shared objects are written to disk, the
		`AltSharedObject.defaultObjectEncoding` property indicates which Action Message
		Format version should be used: the ActionScript 3.0 format (AMF3) or the
		ActionScript 1.0 or 2.0 format (AMF0).

		For more information about object encoding, including the difference between
		encoding in local and remote shared objects, see the description of the
		`objectEncoding` property.

		The default value of `AltSharedObject.defaultObjectEncoding` is set to use the
		ActionScript 3.0 format, AMF3. If you need to write local shared objects that
		ActionScript 2.0 or 1.0 SWF files can read, set
		`AltSharedObject.defaultObjectEncoding` to use the ActionScript 1.0 or ActionScript
		2.0 format, `openfl.net.ObjectEncoding.AMF0`, at the beginning of your script,
		before you create any local shared objects. All local shared objects created
		thereafter will use AMF0 encoding and can interact with older content. You cannot
		change the `objectEncoding` value of existing local shared objects by setting
		`AltSharedObject.defaultObjectEncoding` after the local shared objects have been
		created.

		To set the object encoding on a per-object basis, rather than for all shared
		objects created by the SWF file, set the objectEncoding property of the local
		shared object instead.
	**/
	public static var defaultObjectEncoding:ObjectEncoding = ObjectEncoding.DEFAULT;

	// @:noCompletion @:dox(hide) @:require(flash11_7) public static var preventBackup:Bool;

	/**
		Indicates the object on which callback methods are invoked. The
		default object is `this`. You can set the client property to another
		object, and callback methods will be invoked on that other object.

		@throws TypeError The `client` property must be set to a non-null
						  object.
	**/
	public var client:Dynamic;

	/**
		The collection of attributes assigned to the `data` property of
		the object; these attributes can be shared and stored. Each attribute can
		be an object of any ActionScript or JavaScript type  -  Array, Number,
		Boolean, ByteArray, XML, and so on. For example, the following lines
		assign values to various aspects of a shared object:

		 For remote shared objects used with a server, all attributes of the
		`data` property are available to all clients connected to the
		shared object, and all attributes are saved if the object is persistent.
		If one client changes the value of an attribute, all clients now see the
		new value.
	**/
	public var data(default, null):Dynamic;

	/**
		Specifies the number of times per second that a client's changes to a
		shared object are sent to the server.
		Use this method when you want to control the amount of traffic between
		the client and the server. For example, if the connection between the
		client and server is relatively slow, you may want to set `fps` to a
		relatively low value. Conversely, if the client is connected to a
		multiuser application in which timing is important, you may want to
		set `fps` to a relatively high value.

		Setting `fps` will trigger a `sync` event and update all changes to
		the server. If you only want to update the server manually, set `fps`
		to 0.

		Changes are not sent to the server until the `sync` event has been
		dispatched. That is, if the response time from the server is slow,
		updates may be sent to the server less frequently than the value
		specified in this property.
	**/
	public var fps(null, default):Float;

	/**
		The object encoding (AMF version) for this shared object. When a local
		shared object is written to disk, the `objectEncoding` property
		indicates which Action Message Format version should be used: the
		ActionScript 3.0 format (AMF3) or the ActionScript 1.0 or 2.0 format
		(AMF0).
		Object encoding is handled differently depending if the shared object
		is local or remote.

		* **Local shared objects**. You can get or set the value of the
		`objectEncoding` property for local shared objects. The value of
		`objectEncoding` affects what formatting is used for _writing_ this
		local shared object. If this local shared object must be readable by
		ActionScript 2.0 or 1.0 SWF files, set `objectEncoding` to
		`ObjectEncoding.AMF0`. Even if object encoding is set to write AMF3,
		Flash Player can still read AMF0 local shared objects. That is, if you
		use the default value of this property, `ObjectEncoding.AMF3`, your
		SWF file can still read shared objects created by ActionScript 2.0 or
		1.0 SWF files.
		* **Remote shared objects**. When connected to the server, a remote
		shared object inherits its `objectEncoding` setting from the
		associated NetConnection instance (the instance used to connect to the
		remote shared object). When not connected to the server, a remote
		shared object inherits the `defaultObjectEncoding` setting from the
		associated NetConnection instance. Because the value of a remote
		shared object's `objectEncoding` property is determined by the
		NetConnection instance, this property is read-only for remote shared
		objects.

		@throws ReferenceError You attempted to set the value of the
							   `objectEncoding` property on a remote shared
							   object. This property is read-only for remote
							   shared objects because its value is determined
							   by the associated NetConnection instance.
	**/
	public var objectEncoding:ObjectEncoding;

	/**
		The current size of the shared object, in bytes.

		Flash calculates the size of a shared object by stepping through all of
		its data properties; the more data properties the object has, the longer
		it takes to estimate its size. Estimating object size can take significant
		processing time, so you may want to avoid using this method unless you
		have a specific need for it.
	**/
	public var size(get, never):Int;

	@:noCompletion private static var __sharedObjects:Map<String, AltSharedObject>;

	@:noCompletion private var __localPath:String;
	@:noCompletion private var __name:String;

	#if openfljs
	@:noCompletion private static function __init__()
	{
		untyped global.Object.defineProperty(AltSharedObject.prototype, "size", {
			get: untyped #if haxe4 js.Syntax.code #else __js__ #end ("function () { return this.get_size (); }")
		});
	}
	#end

	@:noCompletion private function new()
	{
		super();

		client = this;
		objectEncoding = defaultObjectEncoding;
	}

	/**
		For local shared objects, purges all of the data and deletes the shared
		object from the disk. The reference to the shared object is still active,
		but its data properties are deleted.

		 For remote shared objects used with Flash Media Server,
		`clear()` disconnects the object and purges all of the data. If
		the shared object is locally persistent, this method also deletes the
		shared object from the disk. The reference to the shared object is still
		active, but its data properties are deleted.

	**/
	public function clear():Void
	{
		data = {};

		try
		{
			#if (js && html5)
			var storage = Browser.getLocalStorage();

			if (storage != null)
			{
				storage.removeItem(__localPath + ":" + __name);
			}
			#else
			var path = __getPath(__localPath, __name);

			if (FileSystem.exists(path))
			{
				FileSystem.deleteFile(path);
			}
			#end
		}
		catch (e:Dynamic) {}
	}

	/**
		Closes the connection between a remote shared object and the server.
		If a remote shared object is locally persistent, the user can make
		changes to the local copy of the object after this method is called.
		Any changes made to the local object are sent to the server the next
		time the user connects to the remote shared object.

	**/
	public function close():Void {}

	#if !openfl_strict
	/**
		Connects to a remote shared object on a server through a specified
		NetConnection object. Use this method after calling `getRemote()`.
		When a connection is successful, the `sync` event is dispatched.
		Before attempting to work with a remote shared object, first check for
		any errors using a `try..catch..finally` statement. Then, listen for
		and handle the `sync` event before you make changes to the shared
		object. Any changes made locally — before the `sync` event is
		dispatched — might be lost.

		Call the `connect()` method to connect to a remote shared object, for
		example:

		```as3
		var myRemoteSO:AltSharedObject = AltSharedObject.getRemote("mo", myNC.uri, false);
		myRemoteSO.connect(myNC);
		```

		@param myConnection A NetConnection object that uses the Real-Time
							Messaging Protocol (RTMP), such as a NetConnection
							object used to communicate with Flash Media
							Server.
		@param params       A string defining a message to pass to the remote
							shared object on the server. Cannot be used with
							Flash Media Server.
		@throws Error Flash Player could not connect to the specified remote
					  shared object. Verify that the NetConnection instance is
					  valid and connected and that the remote shared object
					  was successfully created on the server.
	**/
	public function connect(myConnection:NetConnection, params:String = null):Void
	{
		openfl.utils._internal.Lib.notImplemented();
	}
	#end

	// @:noCompletion @:dox(hide) public static function deleteAll (url:String):Int;

	/**
		Immediately writes a locally persistent shared object to a local file. If
		you don't use this method, Flash Player writes the shared object to a file
		when the shared object session ends  -  that is, when the SWF file is
		closed, when the shared object is garbage-collected because it no longer
		has any references to it, or when you call
		`AltSharedObject.clear()` or `AltSharedObject.close()`.

		If this method returns `SharedObjectFlushStatus.PENDING`,
		Flash Player displays a dialog box asking the user to increase the amount
		of disk space available to objects from this domain. To allow space for
		the shared object to grow when it is saved in the future, which avoids
		return values of `PENDING`, pass a value for
		`minDiskSpace`. When Flash Player tries to write the file, it
		looks for the number of bytes passed to `minDiskSpace`, instead
		of looking for enough space to save the shared object at its current size.


		For example, if you expect a shared object to grow to a maximum size of
		500 bytes, even though it might start out much smaller, pass 500 for
		`minDiskSpace`. If Flash asks the user to allot disk space for
		the shared object, it asks for 500 bytes. After the user allots the
		requested amount of space, Flash won't have to ask for more space on
		future attempts to flush the object(as long as its size doesn't exceed
		500 bytes).

		After the user responds to the dialog box, this method is called again.
		A `netStatus` event is dispatched with a `code`
		property of `SharedObjectFlushStatus.Flush.Success` or
		`SharedObjectFlushStatus.Flush.Failed`.

		@param minDiskSpace The minimum disk space, in bytes, that must be
							allotted for this object.
		@return Either of the following values:

				 * `SharedObjectFlushStatus.PENDING`: The user has
				permitted local information storage for objects from this domain,
				but the amount of space allotted is not sufficient to store the
				object. Flash Player prompts the user to allow more space. To
				allow space for the shared object to grow when it is saved, thus
				avoiding a `SharedObjectFlushStatus.PENDING` return
				value, pass a value for `minDiskSpace`.
				 * `SharedObjectFlushStatus.FLUSHED`: The shared
				object has been successfully written to a file on the local
				disk.

		@throws Error Flash Player cannot write the shared object to disk. This
					  error might occur if the user has permanently disallowed
					  local information storage for objects from this domain.

					  **Note:** Local content can always write shared
					  objects from third-party domains(domains other than the
					  domain in the current browser address bar) to disk, even if
					  writing of third-party shared objects to disk is
					  disallowed.
	**/
	public function flush(minDiskSpace:Int = 0):SharedObjectFlushStatus
	{
		if (Reflect.fields(data).length == 0)
		{
			return SharedObjectFlushStatus.FLUSHED;
		}

		var encodedData = Serializer.run(data);

		try
		{
			#if (js && html5)
			var storage = Browser.getLocalStorage();

			if (storage != null)
			{
				storage.removeItem(__localPath + ":" + __name);
				storage.setItem(__localPath + ":" + __name, encodedData);
			}
			#else
			var path = __getPath(__localPath, __name);
			var directory = Path.directory(path);

			if (!FileSystem.exists(directory))
			{
				__mkdir(directory);
			}

			var output = File.write(path, false);
			output.writeString(encodedData);
			output.close();
			#end
		}
		catch (e:Dynamic)
		{
			return SharedObjectFlushStatus.PENDING;
		}

		return SharedObjectFlushStatus.FLUSHED;
	}

	// @:noCompletion @:dox(hide) public static function getDiskUsage (url:String):Int;

	/**
		Returns a reference to a locally persistent shared object that is only
		available to the current client. If the shared object does not already
		exist, this method creates one. If any values passed to
		`getLocal()` are invalid or if the call fails, Flash Player
		throws an exception.

		The following code shows how you assign the returned shared object
		reference to a variable:

		`var so:AltSharedObject =
		AltSharedObject.getLocal("savedData");`

		**Note:** If the user has chosen to never allow local storage for
		this domain, the object is not saved locally, even if a value for
		`localPath` is specified. The exception to this rule is local
		content. Local content can always write shared objects from third-party
		domains(domains other than the domain in the current browser address bar)
		to disk, even if writing of third-party shared objects to disk is
		disallowed.

		To avoid name conflicts, Flash looks at the location of the SWF file
		creating the shared object. For example, if a SWF file at
		www.myCompany.com/apps/stockwatcher.swf creates a shared object named
		`portfolio`, that shared object does not conflict with another
		object named `portfolio` that was created by a SWF file at
		www.yourCompany.com/photoshoot.swf because the SWF files originate from
		different directories.

		Although the `localPath` parameter is optional, you should
		give some thought to its use, especially if other SWF files need to access
		the shared object. If the data in the shared object is specific to one SWF
		file that will not be moved to another location, then use of the default
		value makes sense. If other SWF files need access to the shared object, or
		if the SWF file that creates the shared object will later be moved, then
		the value of this parameter affects how accessible the shared object will
		be. For example, if you create a shared object with `localPath`
		set to the default value of the full path to the SWF file, no other SWF
		file can access that shared object. If you later move the original SWF
		file to another location, not even that SWF file can access the data
		already stored in the shared object.

		To avoid inadvertently restricting access to a shared object, use the
		`localpath` parameter. The most permissive approach is to set
		`localPath` to `/`(slash), which makes the shared
		object available to all SWF files in the domain, but increases the
		likelihood of name conflicts with other shared objects in the domain. A
		more restrictive approach is to append `localPath` with folder
		names that are in the full path to the SWF file. For example, for a
		`portfolio` shared object created by the SWF file at
		www.myCompany.com/apps/stockwatcher.swf, you could set the
		`localPath` parameter to `/`, `/apps`, or
		`/apps/stockwatcher.swf`. You must determine which approach
		provides optimal flexibility for your application.

		When using this method, consider the following security model:

		* You cannot access shared objects across sandbox boundaries.
		* Users can restrict shared object access by using the Flash Player
		Settings dialog box or the Settings Manager. By default, an application
		can create shared objects of up 100 KB of data per domain. Administrators
		and users can also place restrictions on the ability to write to the file
		system.

		Suppose you publish SWF file content to be played back as local files
		(either locally installed SWF files or EXE files), and you need to access
		a specific shared object from more than one local SWF file. In this
		situation, be aware that for local files, two different locations might be
		used to store shared objects. The domain that is used depends on the
		security permissions granted to the local file that created the shared
		object. Local files can have three different levels of permissions:

		 1. Access to the local filesystem only.
		 2. Access to the network only.
		 3. Access to both the network and the local filesystem.

		Local files with access to the local filesystem(level 1 or 3) store
		their shared objects in one location. Local files without access to the
		local filesystem(level 2) store their shared objects in another
		location.

		You can prevent a SWF file from using this method by setting the
		`allowNetworking` parameter of the the `object` and
		`embed` tags in the HTML page that contains the SWF
		content.

		For more information, see the Flash Player Developer Center Topic:
		[Security](http://www.adobe.com/go/devnet_security_en).

		@param name      The name of the object. The name can include forward
						 slashes(`/`); for example,
						 `work/addresses` is a legal name. Spaces are
						 not allowed in a shared object name, nor are the
						 following characters: `~ % & \
						 ; : " ' , < > ? #`
		@param localPath The full or partial path to the SWF file that created the
						 shared object, and that determines where the shared
						 object will be stored locally. If you do not specify this
						 parameter, the full path is used.
		@param secure    Determines whether access to this shared object is
						 restricted to SWF files that are delivered over an HTTPS
						 connection. If your SWF file is delivered over HTTPS,
						 this parameter's value has the following effects:

						  * If this parameter is set to `true`,
						 Flash Player creates a new secure shared object or gets a
						 reference to an existing secure shared object. This
						 secure shared object can be read from or written to only
						 by SWF files delivered over HTTPS that call
						 `AltSharedObject.getLocal()` with the
						 `secure` parameter set to
						 `true`.
						  * If this parameter is set to `false`,
						 Flash Player creates a new shared object or gets a
						 reference to an existing shared object that can be read
						 from or written to by SWF files delivered over non-HTTPS
						 connections.


						 If your SWF file is delivered over a non-HTTPS
						 connection and you try to set this parameter to
						 `true`, the creation of a new shared object
						(or the access of a previously created secure shared
						 object) fails and `null` is returned.
						 Regardless of the value of this parameter, the created
						 shared objects count toward the total amount of disk
						 space allowed for a domain.

						 The following diagram shows the use of the
						 `secure` parameter:
		@return A reference to a shared object that is persistent locally and is
				available only to the current client. If Flash Player can't create
				or find the shared object(for example, if `localPath`
				was specified but no such directory exists), this method throws an
				exception.
		@throws Error Flash Player cannot create the shared object for whatever
					  reason. This error might occur is if persistent shared
					  object creation and storage by third-party Flash content is
					  prohibited(does not apply to local content). Users can
					  prohibit third-party persistent shared objects on the Global
					  Storage Settings panel of the Settings Manager, located at
					  [http://www.adobe.com/support/documentation/en/flashplayer/help/settings_manager03.html](http://www.adobe.com/support/documentation/en/flashplayer/help/settings_manager03.html).
	**/
	public static function getLocal(name:String, localPath:String = null, secure:Bool = false /* note: unsupported**/):AltSharedObject
	{
		var illegalValues = [" ", "~", "%", "&", "\\", ";", ":", "\"", "'", ",", "<", ">", "?", "#"];
		var allowed = true;

		if (name == null || name == "")
		{
			allowed = false;
		}
		else
		{
			for (value in illegalValues)
			{
				if (name.indexOf(value) > -1)
				{
					allowed = false;
					break;
				}
			}
		}

		if (!allowed)
		{
			throw new Error("Error #2134: Cannot create AltSharedObject.");
			return null;
		}

		if (__sharedObjects == null)
		{
			__sharedObjects = new Map();
			// Lib.application.onExit.add (application_onExit);
			#if lime
			if (Application.current != null)
			{
				Application.current.onExit.add(application_onExit);
			}
			#end
		}

		var id = localPath + "/" + name;

		if (!__sharedObjects.exists(id))
		{
			var encodedData = null;

			try
			{
				#if (js && html5)
				var storage = Browser.getLocalStorage();

				if (localPath == null)
				{
					// Check old default path, first
					if (storage != null)
					{
						encodedData = storage.getItem(Browser.window.location.href + ":" + name);
						storage.removeItem(Browser.window.location.href + ":" + name);
					}

					localPath = Browser.window.location.pathname;
				}

				if (storage != null && encodedData == null)
				{
					encodedData = storage.getItem(localPath + ":" + name);
				}
				#else
				if (localPath == null) localPath = "";

				var path = __getPath(localPath, name);

				if (FileSystem.exists(path))
				{
					encodedData = File.getContent(path);
				}
				#end
			}
			catch (e:Dynamic) {}

			var sharedObject = new AltSharedObject();
			sharedObject.data = {};
			sharedObject.__localPath = localPath;
			sharedObject.__name = name;

			if (encodedData != null && encodedData != "")
			{
				try
				{
					var unserializer = new Unserializer(encodedData);
					unserializer.setResolver(cast {resolveEnum: Type.resolveEnum, resolveClass: __resolveClass});
					sharedObject.data = unserializer.unserialize();
				}
				catch (e:Dynamic) {}
			}

			__sharedObjects.set(id, sharedObject);
		}

		return __sharedObjects.get(id);
	}

	#if !openfl_strict
	/**
		Returns a reference to a shared object on Flash Media Server that
		multiple clients can access. If the remote shared object does not
		already exist, this method creates one.
		To create a remote shared object, call `getRemote()` the call
		`connect()` to connect the remote shared object to the server, as in
		the following:

		```as3
		var nc:NetConnection = new NetConnection();
		nc.connect("rtmp://somedomain.com/applicationName");
		var myRemoteSO:AltSharedObject = AltSharedObject.getRemote("mo", nc.uri, false);
		myRemoteSO.connect(nc);
		```

		To confirm that the local and remote copies of the shared object are
		synchronized, listen for and handle the `sync` event. All clients that
		want to share this object must pass the same values for the `name` and
		`remotePath` parameters.

		To create a shared object that is available only to the current
		client, use `AltSharedObject.getLocal()`.

		@param name        The name of the remote shared object. The name can
						   include forward slashes (/); for example,
						   work/addresses is a legal name. Spaces are not
						   allowed in a shared object name, nor are the
						   following characters: `~ % & \ ; :  " ' , > ? ? #`
		@param remotePath  The URI of the server on which the shared object
						   will be stored. This URI must be identical to the
						   URI of the NetConnection object passed to the
						   `connect()` method.
		@param persistence Specifies whether the attributes of the shared
						   object's data property are persistent locally,
						   remotely, or both. This parameter can also specify
						   where the shared object will be stored locally.
						   Acceptable values are as follows:
						   * A value of `false` specifies that the shared
						   object is not persistent on the client or server.
						   * A value of `true` specifies that the shared
						   object is persistent only on the server.
						   * A full or partial local path to the shared object
						   indicates that the shared object is persistent on
						   the client and the server. On the client, it is
						   stored in the specified path; on the server, it is
						   stored in a subdirectory within the application
						   directory.

						   **Note:** If the user has chosen to never allow
						   local storage for this domain, the object will not
						   be saved locally, even if a local path is specified
						   for persistence. For more information, see the
						   class description.
		@param secure      Determines whether access to this shared object is
						   restricted to SWF files that are delivered over an
						   HTTPS connection. For more information, see the
						   description of the `secure` parameter in the
						   `getLocal` method entry.
		@return A reference to an object that can be shared across multiple
				clients.
		@throws Error Flash Player can't create or find the shared object.
					  This might occur if nonexistent paths were specified for
					  the `remotePath` and `persistence` parameters.
	**/
	public static function getRemote(name:String, remotePath:String = null, persistence:Dynamic = false, secure:Bool = false):AltSharedObject
	{
		openfl.utils._internal.Lib.notImplemented();

		return null;
	}
	#end

	#if !openfl_strict
	/**
		Broadcasts a message to all clients connected to a remote shared
		object, including the client that sent the message. To process and
		respond to the message, create a callback function attached to the
		shared object.

	**/
	public function send(args:Array<Dynamic>):Void
	{
		openfl.utils._internal.Lib.notImplemented();
	}
	#end

	/**
		Indicates to the server that the value of a property in the shared
		object has changed. This method marks properties as _dirty_, which
		means changed.
		Call the `AltSharedObject.setProperty()` to create properties for a
		shared object.

		The `AltSharedObject.setProperty()` method implements `setDirty()`. In
		most cases, such as when the value of a property is a primitive type
		like String or Number, you can call `setProperty()` instead of calling
		`setDirty()`. However, when the value of a property is an object that
		contains its own properties, call `setDirty()` to indicate when a
		value within the object has changed.

		@param propertyName The name of the property that has changed.
	**/
	public function setDirty(propertyName:String):Void {}

	/**
		Updates the value of a property in a shared object and indicates to
		the server that the value of the property has changed. The
		`setProperty()` method explicitly marks properties as changed, or
		dirty.
		For more information about remote shared objects see the <a
		href="http://www.adobe.com/go/learn_fms_docs_en"> Flash Media Server
		documentation</a>.

		**Note:** The `AltSharedObject.setProperty()` method implements the
		`setDirty()` method. In most cases, such as when the value of a
		property is a primitive type like String or Number, you would use
		`setProperty()` instead of `setDirty`. However, when the value of a
		property is an object that contains its own properties, use
		`setDirty()` to indicate when a value within the object has changed.
		In general, it is a good idea to call `setProperty()` rather than
		`setDirty()`, because `setProperty()` updates a property value only
		when that value has changed, whereas `setDirty()` forces
		synchronization on all subscribed clients.

		@param propertyName The name of the property in the shared object.
		@param value        The value of the property (an ActionScript
							object), or `null` to delete the property.
	**/
	public function setProperty(propertyName:String, value:Object = null):Void
	{
		if (data != null)
		{
			Reflect.setField(data, propertyName, value);
		}
	}

	@:noCompletion private static function __getPath(localPath:String, name:String):String {
		#if lime
		var path = CoolUtil.getAppData() + localPath + "/";

		name = StringTools.replace(name, "//", "/");
		name = StringTools.replace(name, "//", "/");

		if (StringTools.startsWith(name, "/")) {
			name = name.substr(1);
		}

		if (StringTools.endsWith(name, "/")) {
			name = name.substring(0, name.length - 1);
		}

		if (name.indexOf("/") > -1) {
			var split = name.split("/");
			name = "";

			for (i in 0...(split.length - 1)) {
				name += "#" + split[i] + "/";
			}

			name += split[split.length - 1];
		}

		return Path.normalize(path + name + ".sol");
		#else
		return Path.normalize(name + ".sol");
		#end
	}

	@:noCompletion private static function __mkdir(directory:String):Void
	{
		// TODO: Move this to Lime somewhere?

		#if sys
		directory = StringTools.replace(directory, "\\", "/");
		var total = "";

		if (directory.substr(0, 1) == "/")
		{
			total = "/";
		}

		var parts = directory.split("/");
		var oldPath = "";

		if (parts.length > 0 && parts[0].indexOf(":") > -1)
		{
			oldPath = Sys.getCwd();
			Sys.setCwd(parts[0] + "\\");
			parts.shift();
		}

		for (part in parts)
		{
			if (part != "." && part != "")
			{
				if (total != "" && total != "/")
				{
					total += "/";
				}

				total += part;

				if (!FileSystem.exists(total))
				{
					FileSystem.createDirectory(total);
				}
			}
		}

		if (oldPath != "")
		{
			Sys.setCwd(oldPath);
		}
		#end
	}

	@:noCompletion private static function __resolveClass(name:String):Class<Dynamic>
	{
		if (name != null)
		{
			if (StringTools.startsWith(name, "neash."))
			{
				name = StringTools.replace(name, "neash.", "openfl.");
			}

			if (StringTools.startsWith(name, "native."))
			{
				name = StringTools.replace(name, "native.", "openfl.");
			}

			if (StringTools.startsWith(name, "flash."))
			{
				name = StringTools.replace(name, "flash.", "openfl.");
			}

			if (StringTools.startsWith(name, "openfl._v2."))
			{
				name = StringTools.replace(name, "openfl._v2.", "openfl.");
			}

			if (StringTools.startsWith(name, "openfl._legacy."))
			{
				name = StringTools.replace(name, "openfl._legacy.", "openfl.");
			}

			return Type.resolveClass(name);
		}

		return null;
	}

	// Event Handlers
	@:noCompletion private static function application_onExit(_):Void
	{
		for (sharedObject in __sharedObjects)
		{
			sharedObject.flush();
		}
	}

	// Getters & Setters
	@:noCompletion private function get_size():Int
	{
		try
		{
			var d = Serializer.run(data);
			return Bytes.ofString(d).length;
		}
		catch (e:Dynamic)
		{
			return 0;
		}
	}
}
#else
typedef SharedObject = flash.net.SharedObject;
#end

/**
 * Save but it uses roaming location instead of company and game name
 */
class AltSave implements IFlxDestroyable
{
	/**
	 * Allows you to directly access the data container in the local shared object.
	 */
	public var data(default, null):Dynamic;

	/**
	 * The name of the local shared object.
	 */
	public var name(default, null):String;

	/**
	 * The path of the local shared object.
	 * @since 4.6.0
	 */
	public var path(default, null):String;

	/**
	 * The local shared object itself.
	 */
	var _sharedObject:AltSharedObject;

	/**
	 * Internal tracker for callback function in case save takes too long.
	 */
	var _onComplete:Bool->Void;

	/**
	 * Internal tracker for save object close request.
	 */
	var _closeRequested:Bool = false;

	public function new() {}

	/**
	 * Clean up memory.
	 */
	public function destroy():Void
	{
		_sharedObject = null;
		name = null;
		path = null;
		data = null;
		_onComplete = null;
		_closeRequested = false;
	}

	/**
	 * Automatically creates or reconnects to locally saved data.
	 *
	 * @param	Name	The name of the object (should be the same each time to access old data).
	 * 					May not contain spaces or any of the following characters: `~ % & \ ; : " ' , < > ? #`
	 * @param	Path	The full or partial path to the file that created the shared object,
	 * 					and that determines where the shared object will be stored locally.
	 * 					If you do not specify this parameter, the full path is used.
	 * @return	Whether or not you successfully connected to the save data.
	 */
	public function bind(Name:String, ?Path:String):Bool
	{
		destroy();
		name = Name;
		path = Path;
		try
		{
			_sharedObject = AltSharedObject.getLocal(name, path);
		}
		catch (e:Error)
		{
			FlxG.log.error("There was a problem binding to\nthe shared object data from FlxSave.");
			destroy();
			return false;
		}
		data = _sharedObject.data;
		return true;
	}

	/**
	 * A way to safely call flush() and destroy() on your save file.
	 * Will correctly handle storage size popups and all that good stuff.
	 * If you don't want to save your changes first, just call destroy() instead.
	 *
	 * @param	MinFileSize		If you need X amount of space for your save, specify it here.
	 * @param	OnComplete		This callback will be triggered when the data is written successfully.
	 * @return	The result of result of the flush() call (see below for more details).
	 */
	public function close(MinFileSize:Int = 0, ?OnComplete:Bool->Void):Bool
	{
		_closeRequested = true;
		return flush(MinFileSize, OnComplete);
	}

	/**
	 * Writes the local shared object to disk immediately. Leaves the object open in memory.
	 *
	 * @param	MinFileSize		If you need X amount of space for your save, specify it here.
	 * @param	OnComplete		This callback will be triggered when the data is written successfully.
	 * @return	Whether or not the data was written immediately. False could be an error OR a storage request popup.
	 */
	public function flush(MinFileSize:Int = 0, ?OnComplete:Bool->Void):Bool
	{
		if (!checkBinding())
		{
			return false;
		}
		_onComplete = OnComplete;
		var result = null;
		try
		{
			result = _sharedObject.flush();
		}
		catch (_:Error)
		{
			return onDone(ERROR);
		}

		return onDone(result == SharedObjectFlushStatus.FLUSHED ? SUCCESS : PENDING);
	}

	/**
	 * Erases everything stored in the local shared object.
	 * Data is immediately erased and the object is saved that way,
	 * so use with caution!
	 *
	 * @return	Returns false if the save object is not bound yet.
	 */
	public function erase():Bool
	{
		if (!checkBinding())
		{
			return false;
		}
		_sharedObject.clear();
		data = {};
		return true;
	}

	/**
	 * Event handler for special case storage requests.
	 * Handles logging of errors and calling of callback.
	 *
	 * @param	Result		One of the result codes (PENDING, ERROR, or SUCCESS).
	 * @return	Whether the operation was a success or not.
	 */
	function onDone(Result:FlxSaveStatus):Bool
	{
		switch (Result)
		{
			case FlxSaveStatus.PENDING:
				FlxG.log.warn("FlxSave is requesting extra storage space.");
			case FlxSaveStatus.ERROR:
				FlxG.log.error("There was a problem flushing\nthe shared object data from FlxSave.");
			default:
		}

		if (_onComplete != null)
			_onComplete(Result == SUCCESS);

		if (_closeRequested)
			destroy();

		return Result == SUCCESS;
	}

	/**
	 * Handy utility function for checking and warning if the shared object is bound yet or not.
	 *
	 * @return	Whether the shared object was bound yet.
	 */
	function checkBinding():Bool
	{
		if (_sharedObject == null)
		{
			FlxG.log.warn("You must call FlxSave.bind()\nbefore you can read or write data.");
			return false;
		}
		return true;
	}
}

enum FlxSaveStatus
{
	SUCCESS;
	PENDING;
	ERROR;
}
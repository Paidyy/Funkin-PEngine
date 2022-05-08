package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUIGroup;
import flixel.addons.ui.FlxUIText;
import flixel.addons.ui.interfaces.IEventGetter;
import flixel.addons.ui.interfaces.IFlxUIClickable;
import flixel.addons.ui.interfaces.IFlxUIWidget;
import flixel.addons.ui.interfaces.IResizable;
import flixel.input.mouse.FlxMouseEventManager;
import flixel.text.FlxText;
import openfl.geom.Rectangle;

/**
 * Works like windows in operating systems
 * Useful if you want to make toolbars etc.
 */
class UIWindow extends FlxUIGroup implements IResizable implements IFlxUIClickable implements IEventGetter {

	/**
	 * Gets currently focused window instance
	 */
	public static var focusedWindow:UIWindow;

	public var skipButtonUpdate(default, set):Bool;
	/**
	 * If `true` everything will be hidden except the up bar
	 */
	public var isMinimized(default, set):Bool = false;
	/**
	 * The sprites inside this window
	 */
	public var items:FlxUIGroup;
	/**
	 * The title of this window
	 * If you want to set this title `text` please use `setTitle()`
	 */
	public var title:FlxUIText;
	/**
	 * If `true` resizing the window with mouse will not be possible
	 */
	public var lockSize:Bool;

	private var _bg:FlxSprite;
	private var _bgUpBar:FlxSprite;
	private var _minimizeButton:FlxSprite;
	private var followMouse:Bool = false;
	private var oldMousePos:Array<Int> = [0, 0];
	private var currentMouseBorderPos:WindowBorderPositionType;

	/**
	 * @param x x position of window 
	 * @param y y position of window
	 * @param w width of window
	 * @param h height of window
	 * @param title the title of the window
	 */
	public function new(x:Float = 0, y:Float = 0, ?w:Float = 200, ?h:Float = 200, ?title:String = "") {
		super(x, y);

		items = new FlxUIGroup();
		currentMouseBorderPos = NONE;
		lockSize = false;

		_bg = new FlxUI9SliceSprite(0, 0, Paths.image("chrome_rect", "exclude"), new Rectangle(0, 0, w, h));
		_bgUpBar = new FlxUI9SliceSprite(0, 0, Paths.image("chrome_rect_darker", "exclude"), new Rectangle(0, 0, w, 20));
		_minimizeButton = new FlxSprite(0, 0, Paths.image("chrome_light_minimize", "exclude"));
		_minimizeButton.x = _bgUpBar.x + _bgUpBar.width - _minimizeButton.width;

		setTitle(title);

		addUIItem(_bg);
		addUIItem(items);
		addUIItem(_bgUpBar);
		addUIItem(this.title);
		addUIItem(_minimizeButton);

		FlxMouseEventManager.maxDoubleClickDelay = 200;
		FlxMouseEventManager.add(_bgUpBar);
		FlxMouseEventManager.setMouseDoubleClickCallback(_bgUpBar, sprite -> if (!FlxG.mouse.overlaps(_minimizeButton)) isMinimized = !isMinimized);
	}

	override public function update(elapsed) {
		super.update(elapsed);

		#if FLX_MOUSE
		if ((FlxG.mouse.justPressed || FlxG.mouse.justPressedRight || FlxG.mouse.justPressedMiddle) && FlxG.mouse.overlaps(_bg)) {
			focusedWindow = this;
		}

		if (isFocus()) {
			if (FlxG.mouse.justReleased) {
				followMouse = false;
				currentMouseBorderPos = NONE;
			}
			if (FlxG.mouse.justPressed) {
				if (FlxG.mouse.overlaps(_bg)) {
					focusedWindow = this;
				}
				if (FlxG.mouse.overlaps(_minimizeButton)) {
					isMinimized = !isMinimized;
				} else {
					if (FlxG.mouse.overlaps(_bgUpBar)) {
						followMouse = true;
					}
				}
			}
			if (FlxG.mouse.justPressedRight && FlxG.keys.pressed.ALT && FlxG.mouse.overlaps(_minimizeButton)) {
				resize(100, 50);
			}
			if (followMouse) {
				if (FlxG.mouse.justMoved) {
					x = x + (FlxG.mouse.x - oldMousePos[0]);
					y = y + (FlxG.mouse.y - oldMousePos[1]);
				}
			} 
			else if (FlxG.mouse.justPressed && !lockSize) {
				var offset = 2;

				var isRight = false;
				var isDown = false;
				
				if (!isMinimized) {
					if (FlxG.mouse.x >= (x + width) - (offset + 4)
						&& FlxG.mouse.x <= (x + width) + offset && FlxG.mouse.y >= _bgUpBar.y && FlxG.mouse.y <= y + height) {
						isRight = true;
					}
					if (FlxG.mouse.y >= (y + height) - (offset + 4)
						&& FlxG.mouse.y <= (y + height) + offset && FlxG.mouse.x >= x && FlxG.mouse.x <= x + width) {
						isDown = true;
					}

					if (isRight && isDown) {
						currentMouseBorderPos = MIDDLE;
					} else {
						if (isRight) {
							currentMouseBorderPos = RIGHT;
						} else if (isDown) {
							currentMouseBorderPos = DOWN;
						}
					}
					if (FlxG.mouse.overlaps(_minimizeButton)) {
						currentMouseBorderPos = NONE;
					}
				}
			}

			if (FlxG.mouse.justMoved && !lockSize) {
				switch (currentMouseBorderPos) {
					case RIGHT:
						resize(width + (FlxG.mouse.x - oldMousePos[0]), height);
					case DOWN:
						resize(width, height + (FlxG.mouse.y - oldMousePos[1]));
					case MIDDLE:
						resize(width + (FlxG.mouse.x - oldMousePos[0]), height + (FlxG.mouse.y - oldMousePos[1]));
					case NONE:
						// do nothing
				}
			}
		}

		oldMousePos = [FlxG.mouse.x, FlxG.mouse.y];
		#end
	}

	/**
	 * Sets the title of this window
	 * @param str new title name
	 */
	public function setTitle(?str:String = null) {
		if (title == null) {
			if (str == null) {
				str = "";
			}
			title = new FlxUIText(0, 0, width, str, 10);
			title.setFormat(title.font, title.size, title.color, FlxTextAlign.CENTER);
		}
		if (str != null && str != title.text) {
			title.text = str;
		}
	}

	/**
	 * Is this window focused
	 */
	public function isFocus() {
		if (focusedWindow == this) {
			return true;
		}
		return false;
	}

	/**
	 * Adds a sprite to `items`
	 * @param spr the sprite to add
	 */
	override public function add(spr:FlxSprite) {
		items.add(spr);
		spr.y += _bgUpBar.height;
		spr.visible = isInsideWindow(spr);
		spr.active = isInsideWindow(spr);
		return spr;
	}

	/**
	 * Resizes this window
	 * @param w new width
	 * @param h new height
	 */
	public function resize(w:Float, h:Float) {
		if (w < 50)
			w = width;
		if (h < _bgUpBar.height + 5)
			h = height;

		resizeThing(_bg, w, h);
		resizeThing(_bgUpBar, w, _bgUpBar.height);
		resizeThing(title, w, title.height);

		_minimizeButton.x = _bgUpBar.x + _bgUpBar.width - _minimizeButton.width;

		for (item in items) {
			item.visible = isInsideWindow(item);
			item.active = isInsideWindow(item);
		}
	}

	private function isInsideWindow(obj:FlxSprite):Bool {
		if (obj.x + obj.width < x + width && obj.y + obj.height < y + height) {
			return true;
		}
		return false;
	}

	private function addUIItem(spr:FlxSprite) {
		return super.add(spr);
	}

	private function resizeThing(thing:Dynamic, w:Float, h:Float) {
		var ir:IResizable;
		if ((thing is IResizable)) {
			ir = cast thing;
			ir.resize(w, h);
		}
	}

	public function getEvent(name:String, sender:IFlxUIWidget, data:Dynamic, ?params:Array<Dynamic>) {}

	public function getRequest(name:String, sender:IFlxUIWidget, data:Dynamic, ?params:Array<Dynamic>):Dynamic {
		return null;
	}

	override function get_width() {
		return _bg.width;
	}

	override function get_height() {
		return _bg.height;
	}

	public function set_skipButtonUpdate(value:Bool):Bool {
		skipButtonUpdate = value;
		for (sprite in this) {
			if ((sprite is IFlxUIClickable)) {
				var widget:IFlxUIClickable = cast sprite;
				widget.skipButtonUpdate = value;
			}
		}
		for (sprite in items) {
			if ((sprite is IFlxUIClickable)) {
				var widget:IFlxUIClickable = cast sprite;
				widget.skipButtonUpdate = value;
			}
		}
		return value;
	}

	function set_isMinimized(value:Bool):Bool {
		isMinimized = value;
		_bg.visible = !value;
		_bg.active = !value;
		for (spr in items) {
			spr.visible = value ? false : isInsideWindow(spr);
			spr.active = value ? false : isInsideWindow(spr);
		}

		return value;
	}

	/*
		public var isFullScreen(default, set):Bool = false;
		
		private var postFullScreenData:Array<Float> = [0, 0, 0, 0];

		function set_isFullScreen(value:Bool):Bool {
			isFullScreen = value;
			resize(width, height);
			if (value) {
				postFullScreenData = [x, y, width, height];
				x = FlxG.camera.x;
				y = FlxG.camera.y;
				resize(FlxG.width, FlxG.height);
				isMinimized = false;
			}
			else {
				x = postFullScreenData[0];
				y = postFullScreenData[1];
				resize(postFullScreenData[2], postFullScreenData[3]);
			}

			return value;
		}
	 */
}

private enum WindowBorderPositionType {
	RIGHT;
	DOWN;
	MIDDLE;
	NONE;
}
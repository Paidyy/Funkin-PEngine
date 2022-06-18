package;

import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUIButton;
import flixel.addons.ui.StrNameLabel;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.FlxG;
import flixel.addons.ui.FlxUIDropDownMenu;

class UIDropDownMenu extends FlxUIDropDownMenu {

	// why FlxUIDropDownMenu doesnt have scroll function
	// also this works better than psych one
	// use it whenever you want even outside fnf lol
    
    public static inline var CLICK_EVENT:String = "click_dropdown";

	public var scrollPosition:Int = 0;
	public var showItems:Int;
	public var lock:Bool = false;
    /*
        callback is ignored use fixedCallback instead
    */
	public var fixedCallback:(String, Int)->Void;
	public var strList:Array<String> = new Array<String>();
	public var curList:Array<String> = new Array<String>();

	public var selectedIndex:Int;

	override public function new(X:Float = 0, Y:Float = 0, strList:Array<String>, ?FixedCallback:(String, Int)->Void,
			?showItems:Int = 15, ?Header:FlxUIDropDownHeader, ?DropPanel:FlxUI9SliceSprite, ?ButtonList:Array<FlxUIButton>,
			?UIControlCallback:Bool->FlxUIDropDownMenu->Void) {
		super(X, Y, FlxUIDropDownMenu.makeStrIdLabelArray(strList, true));

		this.fixedCallback = FixedCallback;
		this.strList = strList;
		this.showItems = showItems;

		setList();
		setData(FlxUIDropDownMenu.makeStrIdLabelArray(curList, true));
	}

	public override function update(elapsed:Float):Void {
		super.update(elapsed);

		if (!lock) {
			if (visible && FlxG.mouse.overlaps(this)) {
				if (FlxG.mouse.wheel == 1 || FlxG.mouse.wheel == -1) {
					if (FlxG.mouse.wheel == 1) { // SCROLLING UP
						if ((scrollPosition) > 0) {
							scrollPosition -= 1;
						}
					}
					else if (FlxG.mouse.wheel == -1) { // SCROLLING DOWN
						if (scrollPosition < (strList.length - showItems)) {
							scrollPosition += 1;
						}
					}
					setList();
					setData(FlxUIDropDownMenu.makeStrIdLabelArray(curList, true));
				}
			}
		}
	}

	public function selectLabel(label:String) {
		if (label == "") {
			scrollPosition = 0;
			setList();
			setData(FlxUIDropDownMenu.makeStrIdLabelArray(curList, true));
			selectedLabel = label;
		}
		for (i in 0...strList.length) {
			if (!curList.contains(label)) {
				scrollPosition += 1;
				setList();
				setData(FlxUIDropDownMenu.makeStrIdLabelArray(curList, true));
				continue;
			} else {
				selectedLabel = label;
				return;
			}
		}
		//if not found the label
		
		scrollPosition = 0;
		setList();
		setData(FlxUIDropDownMenu.makeStrIdLabelArray(curList, true));
		selectedLabel = label;
	}


	

	override private function onClickItem(i:Int):Void {
		selectedIndex = i + scrollPosition;
		if (!lock) {
			var item:FlxUIButton = list[i];
			selectSomething(item.name, item.label.text);
			showList(false);
	
			if (fixedCallback != null) {
				fixedCallback(item.label.text, selectedIndex);
			}
	
			if (broadcastToFlxUI) {
				FlxUI.event(CLICK_EVENT, this, item.name, params);
			}
		}
	}

	public function setList() {
		for (i in 0...showItems) {
			curList[i] = strList[i + scrollPosition];
		}
	}

	override public function setData(DataList:Array<StrNameLabel>):Void {
		var i:Int = 0;

		if (DataList != null) {
			for (data in DataList) {
				var recycled:Bool = false;
				if (list != null) {
					if (i <= list.length - 1) { // If buttons exist, try to re-use them
						var btn:FlxUIButton = list[i];
						if (btn != null) {
							btn.label.text = data.label; // Set the label
							list[i].name = data.name; // Replace the name
							recycled = true; // we successfully recycled it
						}
					}
				}
				else {
					list = [];
				}
				if (!recycled) { // If we couldn't recycle a button, make a fresh one
					var t:FlxUIButton = makeListButton(i, data.label, data.name);
					list.push(t);
					add(t);
					t.visible = false;
				}
				i++;
			}

			// Remove excess buttons:
			if (list.length > DataList.length) { // we have more entries in the original set
				for (j in DataList.length...list.length) { // start counting from end of list
					var b:FlxUIButton = list.pop(); // remove last button on list
					b.visible = false;
					b.active = false;
					remove(b, true); // remove from widget
					b.destroy(); // destroy it
					b = null;
				}
			}

			// don't uncomment this | selectSomething(DataList[0].name, DataList[0].label);
		}

		dropPanel.resize(header.background.width, getPanelHeight());
		updateButtonPositions();
	}
}

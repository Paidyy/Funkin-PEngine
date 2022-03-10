package;

import flixel.input.actions.FlxActionInputAnalog.FlxActionInputAnalogMouseMotion;
import lime.media.AudioBuffer;
import haxe.io.Bytes;
import flixel.tweens.FlxTween;
import flixel.addons.effects.chainable.FlxOutlineEffect;
import flixel.addons.effects.chainable.IFlxEffect;
import flixel.addons.effects.chainable.FlxEffectSprite;
import openfl.desktop.ClipboardFormats;
import flixel.util.FlxSignal.FlxTypedSignal;
import openfl.desktop.Clipboard;
import Conductor.BPMChangeEvent;
import Section.SwagSection;
import Song.SwagSong;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUITooltip.FlxUITooltipStyle;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.ui.FlxSpriteButton;
import flixel.util.FlxColor;
import haxe.Json;
import lime.utils.Assets;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.media.Sound;
import openfl.net.FileReference;
import openfl.utils.ByteArray;

using StringTools;

//this file contains 31 sus words

class ChartingState extends MusicBeatState {
	public static var actionNoteList:Array<String> = [
		"",
        "Subtitle",
        "P1 Icon Alpha",
        "P2 Icon Alpha",
        "Ebola",
        "Damage",
        "Picos",
		"Change Character"
    ];

    public static var actionNoteDescriptionList:Array<String> = [
		"",

        "Creates a subtitle with <value> value\n
		to remove subtitle set value to blank\n
		[alias: sub]",

        "Changes the alpha (visibility) of player icon",

        "Changes the alpha (visibility) of opponent's icon",

        "Play /v/-tan mod for context",

        "Damages player with <value>\n
		Example value: 0.5",

        "Plays pico shoot animation for pico-speaker gf\n
		Value should be from 1 to 4",

		"Changes specific character to <value>\n
		It can cause a 1 second lag to load a character\n
		Using custom characters is recommended here\n
		Value Syntax: <gf, bf, dad>, <character>\n
		Example Value: dad, pico"
    ];

	var _file:FileReference;

	var bg:FlxSprite;

	var UI_box:FlxUITabMenu;

	/**
	 * Array of notes showing when each section STARTS in STEPS
	 * Usually rounded up??
	 */
	var curSection:Int = 0;

	public static var lastSection:Int = 0;

	var bpmTxt:FlxText;

	var strumLine:FlxSprite;
	var curSong:String = 'Dadbattle';
	var amountSteps:Int = 0;
	var bullshitUI:FlxGroup;

	var GRID_SIZE:Int = 40;

	var dummyArrow:FlxSprite;

	var curRenderedNotes:FlxTypedGroup<Note>;
	var curRenderedSustains:FlxTypedGroup<FlxSprite>;

	var gridBG:FlxSprite;

	public static var _song:SwagSong;

	var typingShit:FlxInputText;
	/*
	 * WILL BE THE CURRENT / LAST PLACED NOTE
	**/
	var curSelectedNote:Array<Dynamic>;
	var actionMenu:ScrollUIDropDownMenu;
	var actionValue:FlxUIInputText;

	var tempBpm:Int = 0;

	var vocals:FlxSound;

	private static var leftIcon:HealthIcon;
	private static var rightIcon:HealthIcon;
	//var audioWave:AudioWave;
	var gridBlackLine:FlxSprite;

	var gridBlackLine2:FlxSprite;

	var gridLayer:FlxTypedGroup<Dynamic>;

	var daSongName:String = null;

	override public function new(?song:SwagSong = null, ?daSongName = null) {
		super();

		if (song == null) {
			_song = PlayState.SONG;
		} else {
			_song = song;
			this.daSongName = daSongName;
		}
		
		if (_song == null) {
			_song = {
				song: 'Test',
				bpm: 150,
				speed: 1,
				whichK: 4,
				player1: 'bf',
				player2: 'dad',
				stage: "stage",
				needsVoices: true,
				validScore: false,
				notes: []
			};
			if (daSongName != null) {
				_song.song = daSongName;
			}
			Paths.setCurrentLevel("week-1");
			PlayState.stage = new Stage(_song.stage);
			PlayState.SONG = _song;
		}
	}

	override function create() {
		curSection = lastSection;

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = FlxColor.fromString("#AF66CE");
		bg.alpha = 0.3;
		bg.scrollFactor.set();
		add(bg);

		//audioWave = new AudioWave(0, 280, _song.song);
		//add(audioWave);
		// zzzzzzzzzzzzzz...

		gridLayer = new FlxTypedGroup<Dynamic>();

		leftIcon = new HealthIcon(_song.player1);
		rightIcon = new HealthIcon(_song.player2);

		setBGgrid();

		gridLayer.add(leftIcon);
		gridLayer.add(rightIcon);

		add(gridLayer);

		curRenderedNotes = new FlxTypedGroup<Note>();
		curRenderedSustains = new FlxTypedGroup<FlxSprite>();

		FlxG.mouse.visible = true;
		FlxG.save.bind('funkin', 'ninjamuffin99');

		tempBpm = _song.bpm;

		addSection();

		// sections = _song.notes;

		updateGrid();

		loadSong(_song.song);
		Conductor.changeBPM(_song.bpm);
		Conductor.mapBPMChanges(_song);

		bpmTxt = new FlxText(1000, 50, 0, "", 16);
		bpmTxt.scrollFactor.set();
		add(bpmTxt);

		// touching this variable fucks up grid placement
		strumLine = new FlxSprite(0, 50).makeGraphic(Std.int(FlxG.width / 2), 4);
		add(strumLine);

		dummyArrow = new FlxSprite().makeGraphic(GRID_SIZE, GRID_SIZE);
		add(dummyArrow);

		var tabs = [
			{name: "Song", label: 'Song'},
			{name: "Section", label: 'Section'},
			{name: "Note", label: 'Note'}
		];

		UI_box = new FlxUITabMenu(null, tabs, true);

		UI_box.resize(300, 400);
		UI_box.x = FlxG.width / 2;
		UI_box.y = 20;
		add(UI_box);

		addSongUI();
		addSectionUI();
		addNoteUI();

		add(curRenderedNotes);
		add(curRenderedSustains);

		super.create();
	}

	function setBGgrid() {
		if (gridLayer != null) {
			gridLayer.clear();
		}
		gridBG = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * (_song.whichK * 2) + GRID_SIZE, GRID_SIZE * 16);
		gridBG.x -= GRID_SIZE;
		if (_song.whichK > 4) {
			gridBG.x -= GRID_SIZE * (_song.whichK - 2);
		}
		updateHeads();
		gridBlackLine = new FlxSprite(gridBG.x + (gridBG.width / 2) + (GRID_SIZE / 2)).makeGraphic(2, Std.int(gridBG.height), FlxColor.BLACK);
		gridBlackLine2 = new FlxSprite(gridBG.x + GRID_SIZE).makeGraphic(2, Std.int(gridBG.height), FlxColor.BLACK);

		gridLayer.add(gridBG);
		gridLayer.add(gridBlackLine2);
		gridLayer.add(gridBlackLine);
	}

	function addSongUI():Void {
		var UI_songTitle = new FlxUIInputText(10, 10, 70, _song.song, 8);
		typingShit = UI_songTitle;

		var check_voices = new FlxUICheckBox(10, 25, null, null, "Has voice track", 100);
		check_voices.checked = _song.needsVoices;
		// _song.needsVoices = check_voices.checked;
		check_voices.callback = function() {
			_song.needsVoices = check_voices.checked;
			trace('CHECKED!');
		};

		var saveButton:FlxButton = new FlxButton(110, 8, "Save", function() {
			saveLevel();
		});

		var reloadSongJson:FlxButton = new FlxButton(saveButton.x + saveButton.width + 20, saveButton.y, "Reload JSON", function() {
			loadJson(_song.song.toLowerCase());
		});

		var reloadSong:FlxButton = new FlxButton(reloadSongJson.x, reloadSongJson.y + 30, "Reload Audio", function() {
			loadSong(_song.song);
		});

		var loadAutosaveBtn:FlxButton = new FlxButton(reloadSong.x, reloadSong.y + 30, 'Load Autosave', loadAutosave);

		var stepperBPM:FlxUINumericStepper = new FlxUINumericStepper(10, 65, 1, 1, 1, 339, 0);
		stepperBPM.value = Conductor.bpm;
		stepperBPM.name = 'song_bpm';

		var bpmText = new FlxText(5, stepperBPM.y - 15, 0, "BPM:");
		var speedText = new FlxText(bpmText.x, stepperBPM.y + 20, 0, "Speed:");
		
		var stepperSpeed:FlxUINumericStepper = new FlxUINumericStepper(stepperBPM.x, speedText.y + 15, 0.1, 1, 0.1, 10, 1);
		stepperSpeed.value = _song.speed;
		stepperSpeed.name = 'song_speed';

		var maniaList = ["4K", "6K"];
		var whichKMenu = new ScrollUIDropDownMenu(stepperSpeed.x, stepperSpeed.y + stepperSpeed.width + 17, maniaList, function onSelect(s, i) {
			_song.whichK = Std.parseInt(s);
			setBGgrid();
			updateGrid();
			updateHeads();
		}, 6);
		whichKMenu.selectLabel(_song.whichK + "K");
		var maniaText = new FlxText(whichKMenu.x - 5, whichKMenu.y - 15, 0, "Mania:");

		var stagesMenu = new ScrollUIDropDownMenu(whichKMenu.x + 130, whichKMenu.y, CoolUtil.getStages(), function onSelect(s, i) {
			_song.stage = s;
		}, 6);
		stagesMenu.selectLabel(_song.stage);
		var stageText = new FlxText(stagesMenu.x - 5, stagesMenu.y - 15, 0, "Stage:");

		var characters:Array<String> = CoolUtil.getCharacters();

		var player1DropDown = new ScrollUIDropDownMenu(10, whichKMenu.y + 50, characters, function(character:String, i) {
			_song.player1 = character;
			updateHeads();
		});
		player1DropDown.selectLabel(_song.player1);
		var boyfriendText = new FlxText(player1DropDown.x - 5, player1DropDown.y - 15, 0, "Boyfriend:");

		var player2DropDown = new ScrollUIDropDownMenu(player1DropDown.x + 130, player1DropDown.y, characters, function(character:String, i) {
			_song.player2 = character;
			updateHeads();
		});
		player2DropDown.selectLabel(_song.player2);

		var opponentText = new FlxText(player2DropDown.x - 5, player2DropDown.y - 15, 0, "Opponent:");

		var check_mute_inst = new FlxUICheckBox(player1DropDown.x, player1DropDown.y + 120, null, null, "Mute Instrumental (in editor)", 100);
		check_mute_inst.checked = false;
		check_mute_inst.callback = function() {
			var vol:Float = 1;

			if (check_mute_inst.checked)
				vol = 0;

			FlxG.sound.music.volume = vol;
		};

		var tab_group_song = new FlxUI(null, UI_box);
		tab_group_song.name = "Song";

		tab_group_song.add(bpmText);
		tab_group_song.add(speedText);
		tab_group_song.add(boyfriendText);
		tab_group_song.add(opponentText);
		tab_group_song.add(maniaText);
		tab_group_song.add(stageText);

		tab_group_song.add(UI_songTitle);
		tab_group_song.add(check_voices);
		tab_group_song.add(check_mute_inst);
		tab_group_song.add(saveButton);
		tab_group_song.add(reloadSong);
		tab_group_song.add(reloadSongJson);
		tab_group_song.add(loadAutosaveBtn);
		tab_group_song.add(stepperBPM);
		tab_group_song.add(stepperSpeed);
		tab_group_song.add(player1DropDown);
		tab_group_song.add(player2DropDown);
		tab_group_song.add(whichKMenu);
		tab_group_song.add(stagesMenu);

		UI_box.addGroup(tab_group_song);
		UI_box.scrollFactor.set();

		FlxG.camera.follow(strumLine);
	}

	var stepperLength:FlxUINumericStepper;
	var check_mustHitSection:FlxUICheckBox;
	var check_centerCamera:FlxUICheckBox;
	var check_changeBPM:FlxUICheckBox;
	var stepperSectionBPM:FlxUINumericStepper;
	var check_altAnim:FlxUICheckBox;

	function addSectionUI():Void {
		var tab_group_section = new FlxUI(null, UI_box);
		tab_group_section.name = 'Section';

		stepperSectionBPM = new FlxUINumericStepper(10, 80, 1, Conductor.bpm, 0, 999, 0);
		stepperSectionBPM.value = Conductor.bpm;
		stepperSectionBPM.name = 'section_bpm';

		stepperLength = new FlxUINumericStepper(10, 10, 4, 0, 0, 999, 0);
		stepperLength.value = _song.notes[curSection].lengthInSteps;
		stepperLength.name = "section_length";

		var stepperCopy:FlxUINumericStepper = new FlxUINumericStepper(90, 132, 1, 1, -999, 999, 0);

		var copyButton:FlxButton = new FlxButton(10, 130, "Copy last section", function() {
			copySection(Std.int(stepperCopy.value));
		});

		var clearSectionButton:FlxButton = new FlxButton(10, 150, "Clear", clearSection);

		var swapSection:FlxButton = new FlxButton(10, 170, "Swap section", function() {
			for (i in 0..._song.notes[curSection].sectionNotes.length) {
				var note = _song.notes[curSection].sectionNotes[i];
				note[1] = (note[1] + _song.whichK) % (_song.whichK * 2);
				_song.notes[curSection].sectionNotes[i] = note;
				updateGrid();
			}
		});

		check_mustHitSection = new FlxUICheckBox(10, 30, null, null, "Must hit section", 100);
		check_mustHitSection.name = 'check_mustHit';
		check_mustHitSection.checked = true;
		// _song.needsVoices = check_mustHit.checked;

		check_centerCamera = new FlxUICheckBox(check_mustHitSection.width + 10, 30, null, null, "Center the Camera", 100);
		check_centerCamera.name = 'check_centerCamera';
		check_centerCamera.checked = false;

		check_altAnim = new FlxUICheckBox(10, 400, null, null, "Alt Animation", 100);
		check_altAnim.name = 'check_altAnim';

		check_changeBPM = new FlxUICheckBox(10, 60, null, null, 'Change BPM', 100);
		check_changeBPM.name = 'check_changeBPM';

		tab_group_section.add(stepperLength);
		tab_group_section.add(stepperSectionBPM);
		tab_group_section.add(stepperCopy);
		tab_group_section.add(check_mustHitSection);
		tab_group_section.add(check_centerCamera);
		tab_group_section.add(check_altAnim);
		tab_group_section.add(check_changeBPM);
		tab_group_section.add(copyButton);
		tab_group_section.add(clearSectionButton);
		tab_group_section.add(swapSection);

		UI_box.addGroup(tab_group_section);
	}

	var stepperSusLength:FlxUINumericStepper;

	function addNoteUI():Void {
		var tab_group_note = new FlxUI(null, UI_box);
		tab_group_note.name = 'Note';

		stepperSusLength = new FlxUINumericStepper(10, 10, Conductor.stepCrochet / 2, 0, 0, Conductor.stepCrochet * 16);
		stepperSusLength.value = 0;
		stepperSusLength.name = 'note_susLength';

		var applyLength:FlxButton = new FlxButton(100, 10, 'Apply');

		actionValue = new FlxUIInputText(10, 90, 85 * 2, "", 8);
		actionValue.callback = function onType(s, enter) {
			if (curSelectedNote != null) {
				if (!CoolUtil.isEmpty(s) && curSelectedNote.length < 4) {
					curSelectedNote[3] = "";
					curSelectedNote[4] = s;
				} else {
					curSelectedNote[4] = s;
				}
			}
		}
		var text2 = new FlxText(actionValue.x, actionValue.y - 15, 0, "Value:");

		actionMenu = new ScrollUIDropDownMenu(10, 50, actionNoteList, function onSelect(s, i) {
			if (curSelectedNote != null) {
				if (!CoolUtil.isEmpty(s) && curSelectedNote.length < 4) {
					curSelectedNote[3] = s;
					curSelectedNote[4] = "";
				}
				else if (CoolUtil.isEmpty(s)) {
					curSelectedNote[3] = s;
				}
			} else {
				actionDescription.text = actionNoteDescriptionList[i];
			}
		}, 6);
		var text = new FlxText(actionMenu.x, actionMenu.y - 15, 0, "Action:");

		actionDescription = new FlxText(actionValue.x, actionValue.y + 40, 0, "");

		tab_group_note.add(text);
		tab_group_note.add(text2);
		tab_group_note.add(actionValue);
		tab_group_note.add(actionDescription);

		tab_group_note.add(actionMenu);
		tab_group_note.add(stepperSusLength);
		tab_group_note.add(applyLength);

		UI_box.addGroup(tab_group_note);
	}

	function loadSong(daSong:String):Void {
		if (FlxG.sound.music != null) {
			FlxG.sound.music.stop();
			// vocals.stop();
		}
		
		if (SysFile.exists(Paths.instNoLib(daSong))) {
			vocals = new FlxSound().loadEmbedded(Paths.voices(daSong));
			FlxG.sound.playMusic(Paths.inst(daSong), 0.6);
		} else {
			vocals = FlxG.sound.load(Sound.fromFile(Paths.PEvoices(daSong)));
			FlxG.sound.playMusic(Sound.fromFile(Paths.PEinst(daSong)), 0.6);
		}

		FlxG.sound.list.add(vocals);

		FlxG.sound.music.pause();
		vocals.pause();

		FlxG.sound.music.onComplete = function() {
			vocals.pause();
			vocals.time = 0;
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
			changeSection();
		};
	}

	function generateUI():Void {
		while (bullshitUI.members.length > 0) {
			bullshitUI.remove(bullshitUI.members[0], true);
		}

		// general shit
		var title:FlxText = new FlxText(UI_box.x + 20, UI_box.y + 20, 0);
		bullshitUI.add(title);
		/* 
			var loopCheck = new FlxUICheckBox(UI_box.x + 10, UI_box.y + 50, null, null, "Loops", 100, ['loop check']);
			loopCheck.checked = curNoteSelected.doesLoop;
			tooltips.add(loopCheck, {title: 'Section looping', body: "Whether or not it's a simon says style section", style: tooltipType});
			bullshitUI.add(loopCheck);

		 */
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>) {
		if (id == FlxUICheckBox.CLICK_EVENT) {
			var check:FlxUICheckBox = cast sender;
			var label = check.getLabel().text;
			switch (label) {
				case 'Must hit section':
					_song.notes[curSection].mustHitSection = check.checked;

					updateHeads();
				case 'Center the Camera':
					_song.notes[curSection].centerCamera = check.checked;
				case 'Change BPM':
					_song.notes[curSection].changeBPM = check.checked;
					FlxG.log.add('changed bpm shit');
				case "Alt Animation":
					_song.notes[curSection].altAnim = check.checked;
			}
		}
		else if (id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper)) {
			var nums:FlxUINumericStepper = cast sender;
			var wname = nums.name;
			FlxG.log.add(wname);
			if (wname == 'section_length') {
				_song.notes[curSection].lengthInSteps = Std.int(nums.value);
				updateGrid();
			}
			else if (wname == 'song_speed') {
				_song.speed = nums.value;
			}
			else if (wname == 'song_bpm') {
				tempBpm = Std.int(nums.value);
				Conductor.mapBPMChanges(_song);
				Conductor.changeBPM(Std.int(nums.value));
			}
			else if (wname == 'note_susLength') {
				curSelectedNote[2] = nums.value;
				updateGrid();
			}
			else if (wname == 'section_bpm') {
				_song.notes[curSection].bpm = Std.int(nums.value);
				updateGrid();
			}
		}

		// FlxG.log.add(id + " WEED " + sender + " WEED " + data + " WEED " + params);
	}

	var updatedSection:Bool = false;

	/* this function got owned LOL
		function lengthBpmBullshit():Float
		{
			if (_song.notes[curSection].changeBPM)
				return _song.notes[curSection].lengthInSteps * (_song.notes[curSection].bpm / _song.bpm);
			else
				return _song.notes[curSection].lengthInSteps;
	}*/
	function sectionStartTime():Float {
		var daBPM:Int = _song.bpm;
		var daPos:Float = 0;
		for (i in 0...curSection) {
			if (_song.notes[i].changeBPM) {
				daBPM = _song.notes[i].bpm;
			}
			daPos += 4 * (1000 * 60 / daBPM);
		}
		return daPos;
	}
	override function update(elapsed:Float) {
		curStep = recalculateSteps();

		Conductor.songPosition = FlxG.sound.music.time;
		_song.song = typingShit.text;

		strumLine.y = getYfromStrum((Conductor.songPosition - sectionStartTime()) % (Conductor.stepCrochet * _song.notes[curSection].lengthInSteps));

		if (curBeat % 4 == 0 && curStep >= 16 * (curSection + 1)) {
			trace(curStep);
			trace((_song.notes[curSection].lengthInSteps) * (curSection + 1));
			trace('DUMBSHIT');

			if (_song.notes[curSection + 1] == null) {
				addSection();
			}

			changeSection(curSection + 1, false);
		}

		FlxG.watch.addQuick('daBeat', curBeat);
		FlxG.watch.addQuick('daStep', curStep);

		if (curSelectedNote != null) {
			if (actionNoteList.indexOf(curSelectedNote[3]) != -1) {
				actionDescription.text = actionNoteDescriptionList[actionNoteList.indexOf(curSelectedNote[3])];
			} else {
				actionDescription.text = "";
			}
		}

		curRenderedNotes.forEach(function(note:Note) {
			if (note != fixedCurSelectedNote) {
				if (note.y <= strumLine.y) {
					note.alpha = 0.3;
				} else {
					note.alpha = 1.0;
				}
			}
		});

		if (FlxG.mouse.justPressed) {
			if (FlxG.mouse.overlaps(curRenderedNotes)) {
				curRenderedNotes.forEach(function(note:Note) {
					if (FlxG.mouse.overlaps(note)) {
						if (FlxG.keys.pressed.CONTROL) {
							selectNote(note);
						}
						else {
							trace('tryin to delete note...');
							deleteNote(note);
						}
					}
					// if (FlxG.mouse.overlaps(player1)) {

					// }
				});
			}
			else {
				if (FlxG.mouse.x > gridBG.x
					&& FlxG.mouse.x < gridBG.x + gridBG.width
					&& FlxG.mouse.y > gridBG.y
					&& FlxG.mouse.y < gridBG.y + (GRID_SIZE * _song.notes[curSection].lengthInSteps)) {
					FlxG.log.add('added note');
					addNote();
				}
			}
		}

		if (FlxG.mouse.x > gridBG.x
			&& FlxG.mouse.x < gridBG.x + gridBG.width
			&& FlxG.mouse.y > gridBG.y
			&& FlxG.mouse.y < gridBG.y + (GRID_SIZE * _song.notes[curSection].lengthInSteps)) {
			dummyArrow.x = Math.floor(FlxG.mouse.x / GRID_SIZE) * GRID_SIZE;
			if (FlxG.keys.pressed.SHIFT)
				dummyArrow.y = FlxG.mouse.y;
			else
				dummyArrow.y = Math.floor(FlxG.mouse.y / GRID_SIZE) * GRID_SIZE;
		}

		if (!FlxG.mouse.overlaps(UI_box)) {
			if (FlxG.keys.justPressed.F3) {
				if (debugText) {
					debugText = false;
				} else {
					debugText = true;
				}
			}
			if (FlxG.keys.justPressed.ENTER) {
				lastSection = curSection;

				PlayState.SONG = _song;
				FlxG.sound.music.stop();
				vocals.stop();
				FlxG.mouse.visible = false;
				FlxG.switchState(new PlayState());
			}

			if (FlxG.keys.justPressed.E) {
				changeNoteSustain(Conductor.stepCrochet);
			}
			if (FlxG.keys.justPressed.Q) {
				changeNoteSustain(-Conductor.stepCrochet);
			}

			if (!typingShit.hasFocus) {
				if (FlxG.keys.justPressed.SPACE) {
					if (FlxG.sound.music.playing) {
						FlxG.sound.music.pause();
						vocals.pause();
					}
					else {
						vocals.play();
						FlxG.sound.music.play();
					}
				}

				if (FlxG.keys.justPressed.R) {
					if (FlxG.keys.pressed.SHIFT)
						resetSection(true);
					else
						resetSection();
				}

				if (FlxG.mouse.wheel != 0) {
					FlxG.sound.music.pause();
					vocals.pause();

					FlxG.sound.music.time -= (FlxG.mouse.wheel * Conductor.stepCrochet * 0.4);
					vocals.time = FlxG.sound.music.time;
				}

				if (!FlxG.keys.pressed.SHIFT) {
					if (FlxG.keys.pressed.W || FlxG.keys.pressed.S) {
						FlxG.sound.music.pause();
						vocals.pause();

						var daTime:Float = 700 * FlxG.elapsed;

						if (FlxG.keys.pressed.W) {
							FlxG.sound.music.time -= daTime;
						}
						else
							FlxG.sound.music.time += daTime;

						vocals.time = FlxG.sound.music.time;
					}
				}
				else {
					if (FlxG.keys.pressed.W || FlxG.keys.pressed.S) {
						FlxG.sound.music.pause();
						vocals.pause();

						var daTime:Float = (700 * FlxG.elapsed) * 2;

						if (FlxG.keys.pressed.W) {
							FlxG.sound.music.time -= daTime;
						}
						else
							FlxG.sound.music.time += daTime;

						vocals.time = FlxG.sound.music.time;
					}
				}
			}
			var shiftThing:Int = 1;
			if (FlxG.keys.pressed.SHIFT)
				shiftThing = 4;
			if (FlxG.keys.justPressed.RIGHT || FlxG.keys.justPressed.D)
				changeSection(curSection + shiftThing);
			if (FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.A)
				changeSection(curSection - shiftThing);
		}

		if (FlxG.keys.justPressed.TAB) {
			if (FlxG.keys.pressed.SHIFT) {
				UI_box.selected_tab -= 1;
				if (UI_box.selected_tab < 0)
					UI_box.selected_tab = 2;
			}
			else {
				UI_box.selected_tab += 1;
				if (UI_box.selected_tab >= 3)
					UI_box.selected_tab = 0;
			}
		}

		_song.bpm = tempBpm;

		/* if (FlxG.keys.justPressed.UP)
				Conductor.changeBPM(Conductor.bpm + 1);
			if (FlxG.keys.justPressed.DOWN)
				Conductor.changeBPM(Conductor.bpm - 1); */

		bpmTxt.text = bpmTxt.text = 
			"Song Position: " + Std.string(FlxMath.roundDecimal(Conductor.songPosition / 1000, 2)) + " / " + Std.string(FlxMath.roundDecimal(FlxG.sound.music.length / 1000, 2)) + "\n" +
			"Section: " + curSection;
		if (debugText) {
			if (curSelectedNote != null) {
				bpmTxt.text += "\n\n" + 
				"Note[0]: " + curSelectedNote[0] + "\n" +
				"Note[1]: " + curSelectedNote[1] + "\n" +
				"Note[2]: " + curSelectedNote[2] + "\n" +
				"Note[3]: " + curSelectedNote[3] + "\n" +
				"Note[4]: " + curSelectedNote[4] + "\n";
			}
		}
		super.update(elapsed);
	}

	function changeNoteSustain(value:Float):Void {
		if (curSelectedNote != null) {
			if (curSelectedNote[2] != null) {
				curSelectedNote[2] += value;
				curSelectedNote[2] = Math.max(curSelectedNote[2], 0);
			}
		}

		updateNoteUI();
		updateGrid();
	}

	function recalculateSteps():Int {
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		for (i in 0...Conductor.bpmChangeMap.length) {
			if (FlxG.sound.music.time > Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		curStep = lastChange.stepTime + Math.floor((FlxG.sound.music.time - lastChange.songTime) / Conductor.stepCrochet);
		updateBeat();

		return curStep;
	}

	function resetSection(songBeginning:Bool = false):Void {
		updateGrid();

		FlxG.sound.music.pause();
		vocals.pause();

		// Basically old shit from changeSection???
		FlxG.sound.music.time = sectionStartTime();

		if (songBeginning) {
			FlxG.sound.music.time = 0;
			curSection = 0;
		}

		vocals.time = FlxG.sound.music.time;
		updateCurStep();

		updateGrid();
		updateSectionUI();
		updateHeads();
	}

	function changeSection(sec:Int = 0, ?updateMusic:Bool = true):Void {
		trace('changing section' + sec);

		if (_song.notes[sec] != null) {
			curSection = sec;

			updateGrid();

			if (updateMusic) {
				FlxG.sound.music.pause();
				vocals.pause();

				/*var daNum:Int = 0;
					var daLength:Float = 0;
					while (daNum <= sec)
					{
						daLength += lengthBpmBullshit();
						daNum++;
				}*/

				FlxG.sound.music.time = sectionStartTime();
				vocals.time = FlxG.sound.music.time;
				updateCurStep();
			}

			updateGrid();
			updateSectionUI();
			updateHeads();
		}
	}

	function copySection(?sectionNum:Int = 1) {
		var daSec = FlxMath.maxInt(curSection, sectionNum);

		for (note in _song.notes[daSec - sectionNum].sectionNotes) {
			var strum = note[0] + Conductor.stepCrochet * (_song.notes[daSec].lengthInSteps * sectionNum);

			var copiedNote:Array<Dynamic> = [strum, note[1], note[2], note[3], note[4]];
			_song.notes[daSec].sectionNotes.push(copiedNote);
		}

		updateGrid();
	}

	function updateSectionUI():Void {
		var sec = _song.notes[curSection];

		stepperLength.value = sec.lengthInSteps;
		check_mustHitSection.checked = sec.mustHitSection;
		check_centerCamera.checked = sec.centerCamera;
		check_altAnim.checked = sec.altAnim;
		check_changeBPM.checked = sec.changeBPM;
		stepperSectionBPM.value = sec.bpm;
	}

	function updateHeads():Void {
		if (_song.notes[curSection] != null) {
			if (_song.notes[curSection].mustHitSection) {
				leftIcon.setChar(_song.player1);
				rightIcon.setChar(_song.player2);
				bg.color = FlxColor.fromString("#31B0D1");
			}
			else {
				leftIcon.setChar(_song.player2);
				rightIcon.setChar(_song.player1);
				bg.color = FlxColor.fromString("#AF66CE");
			}
	
			leftIcon.scrollFactor.set(1, 1);
			rightIcon.scrollFactor.set(1, 1);
	
			leftIcon.setGraphicSize(0, 45);
			rightIcon.setGraphicSize(0, 45);
	
			leftIcon.setPosition(gridBG.x + GRID_SIZE, -100);
			rightIcon.setPosition((gridBG.width / 2) + gridBG.x + (GRID_SIZE / 2), -100);
		} else {
			leftIcon.visible = false;
			rightIcon.visible = false;
		}
	}

	function updateNoteUI():Void {
		if (curSelectedNote != null) {
			trace("cur note: " + curSelectedNote);
			stepperSusLength.value = curSelectedNote[2];
			actionMenu.selectedLabel = "";
			actionValue.text = "";
			actionMenu.selectedLabel = curSelectedNote[3];
			actionValue.text = curSelectedNote[4];
		}
	}

	function updateGrid():Void {
		while (curRenderedNotes.members.length > 0) {
			curRenderedNotes.remove(curRenderedNotes.members[0], true);
		}

		while (curRenderedSustains.members.length > 0) {
			curRenderedSustains.remove(curRenderedSustains.members[0], true);
		}

		var sectionInfo:Array<Dynamic> = _song.notes[curSection].sectionNotes;

		if (_song.notes[curSection].changeBPM && _song.notes[curSection].bpm > 0) {
			Conductor.changeBPM(_song.notes[curSection].bpm);
			FlxG.log.add('CHANGED BPM!');
		}
		else {
			// get last bpm
			var daBPM:Int = _song.bpm;
			for (i in 0...curSection)
				if (_song.notes[i].changeBPM)
					daBPM = _song.notes[i].bpm;
			Conductor.changeBPM(daBPM);
		}

		/* // PORT BULLSHIT, INCASE THERE'S NO SUSTAIN DATA FOR A NOTE
			for (sec in 0..._song.notes.length)
			{
				for (notesse in 0..._song.notes[sec].sectionNotes.length)
				{
					if (_song.notes[sec].sectionNotes[notesse][2] == null)
					{
						trace('SUS NULL');
						_song.notes[sec].sectionNotes[notesse][2] = 0;
					}
				}
			}
		 */

		for (i in sectionInfo) {
			var daNoteInfo = i[1];
			var daStrumTime = i[0];
			var daSus = i[2];
			var action2 = i[3];
			var actionValue2 = i[4];

			var note:Note = new Note(daStrumTime, daNoteInfo % _song.whichK);
			note.sustainLength = daSus;
			note.action = action2;
			note.actionValue = actionValue2;
			note.setGraphicSize(GRID_SIZE, GRID_SIZE);
			note.updateHitbox();
			if (_song.whichK == 4) {
				note.x = Math.floor((daNoteInfo) * GRID_SIZE);
			} else {
				note.x = Math.floor((daNoteInfo - _song.whichK + 2) * GRID_SIZE);
			}
			note.y = Math.floor(getYfromStrum((daStrumTime - sectionStartTime()) % (Conductor.stepCrochet * _song.notes[curSection].lengthInSteps)));

			curRenderedNotes.add(note);

			if (curSelectedNote != null) {
				if (curSelectedNote[0] == note.strumTime && curSelectedNote[1] % _song.whichK == note.noteData) {
					fixedCurSelectedNote = note;
					selectedNoteTween();
				}
			}

			if (daSus > 0) {
				var sustainVis:FlxSprite = new FlxSprite(note.x + (GRID_SIZE / 2),
					note.y + GRID_SIZE).makeGraphic(8, Math.floor(FlxMath.remapToRange(daSus, 0, Conductor.stepCrochet * 16, 0, gridBG.height)));
				curRenderedSustains.add(sustainVis);
			}
		}
	}

	function selectedNoteTween(?direction:Int = 0) {
		var minValue = 0.6;
		if (direction == 0) {
			FlxTween.num(fixedCurSelectedNote.alpha, minValue, 0.7, null, function(s) {
				fixedCurSelectedNote.alpha = s;
				if (fixedCurSelectedNote.alpha == minValue) {
					selectedNoteTween(1);
				}
			});
		} else if (direction == 1) {
			FlxTween.num(fixedCurSelectedNote.alpha, 1.0, 0.7, null, function(s) {
				fixedCurSelectedNote.alpha = s;
				if (fixedCurSelectedNote.alpha == 1.0) {
					selectedNoteTween(0);
				}
			});
		}
	}

	private function addSection(lengthInSteps:Int = 16):Void {
		var sec:SwagSection = {
			lengthInSteps: lengthInSteps,
			bpm: _song.bpm,
			changeBPM: false,
			mustHitSection: true,
			centerCamera: false,
			sectionNotes: [],
			typeOfSection: 0,
			altAnim: false
		};

		_song.notes.push(sec);
	}

	function selectNote(note:Note):Void {
		var swagNum:Int = 0;

		for (i in _song.notes[curSection].sectionNotes) {
			if (i[0] == note.strumTime && i[1] % _song.whichK == note.noteData) {
				curSelectedNote = _song.notes[curSection].sectionNotes[swagNum];
			}

			swagNum += 1;
		}

		updateGrid();
		updateNoteUI();
		//doesnt work for some reason | add(new FlxEffectSprite(fixedCurSelectedNote, [new FlxOutlineEffect(4, FlxColor.BLUE, 100)]));
	}

	function deleteNote(note:Note):Void {
		for (i in _song.notes[curSection].sectionNotes) {
			if (i[0] == note.strumTime && i[1] % _song.whichK == note.noteData) {
				FlxG.log.add('FOUND EVIL NUMBER');
				_song.notes[curSection].sectionNotes.remove(i);
			}
		}

		updateGrid();
	}

	function clearSection():Void {
		_song.notes[curSection].sectionNotes = [];

		updateGrid();
	}

	function clearSong():Void {
		for (daSection in 0..._song.notes.length) {
			_song.notes[daSection].sectionNotes = [];
		}

		updateGrid();
	}

	private function addNote():Void {
		var noteStrum = getStrumTime(dummyArrow.y) + sectionStartTime();
		var noteData = 0;
		if (_song.whichK == 4) {
			noteData = Math.floor(FlxG.mouse.x / GRID_SIZE);
		} else {
			noteData = Math.floor(FlxG.mouse.x / GRID_SIZE) + (_song.whichK - 2);
		}
		var noteSus = 0;

		if (FlxG.keys.pressed.ALT) {
			_song.notes[curSection].sectionNotes.push([noteStrum, -1, noteSus]);
		}
		else {
			_song.notes[curSection].sectionNotes.push([noteStrum, noteData, noteSus]);
		}

		curSelectedNote = _song.notes[curSection].sectionNotes[_song.notes[curSection].sectionNotes.length - 1];

		if (FlxG.keys.pressed.CONTROL) {
			_song.notes[curSection].sectionNotes.push([noteStrum, (noteData + _song.whichK) % (_song.whichK * 2), noteSus]);
		}

		trace("noteStrum: " + noteStrum);
		trace("curSection:" + curSection);
		trace("noteData: " + noteData);

		updateGrid();
		updateNoteUI();

		autosaveSong();
	}

	function getStrumTime(yPos:Float):Float {
		return FlxMath.remapToRange(yPos, gridBG.y, gridBG.y + gridBG.height, 0, 16 * Conductor.stepCrochet);
	}

	function getYfromStrum(strumTime:Float):Float {
		return FlxMath.remapToRange(strumTime, 0, 16 * Conductor.stepCrochet, gridBG.y, gridBG.y + gridBG.height);
	}

	/*
		function calculateSectionLengths(?sec:SwagSection):Int
		{
			var daLength:Int = 0;

			for (i in _song.notes)
			{
				var swagLength = i.lengthInSteps;

				if (i.typeOfSection == Section.COPYCAT)
					swagLength * 2;

				daLength += swagLength;

				if (sec != null && sec == i)
				{
					trace('swag loop??');
					break;
				}
			}

			return daLength;
	}*/
	private var daSpacing:Float = 0.3;

	function loadLevel():Void {
		trace(_song.notes);
	}

	function getNotes():Array<Dynamic> {
		var noteData:Array<Dynamic> = [];

		for (i in _song.notes) {
			noteData.push(i.sectionNotes);
		}

		return noteData;
	}

	function loadJson(song:String):Void {
		try {
			if (Song.loadFromJson(song.toLowerCase(), song.toLowerCase()) != null) {
				PlayState.SONG = Song.loadFromJson(song.toLowerCase() + PlayState.dataFileDifficulty, song.toLowerCase());
			}
		}
		catch (error) {
			PlayState.SONG = Song.PEloadFromJson(song.toLowerCase() + PlayState.dataFileDifficulty, song.toLowerCase());
		}
		FlxG.resetState();
	}

	function loadAutosave():Void {
		PlayState.SONG = Song.parseJSONshit(FlxG.save.data.autosave);
		FlxG.resetState();
	}

	function autosaveSong():Void {
		FlxG.save.data.autosave = Json.stringify({
			"song": _song
		});
		FlxG.save.flush();
	}

	private function saveLevel() {
		var json = {
			"song": _song
		};

		var data:String = Json.stringify(json);

		if ((data != null) && (data.length > 0)) {
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			if (PlayState.dataFileDifficulty == null) {
				_file.save(data.trim(), _song.song.toLowerCase() + "-DIFFICULTY_HERE" + ".json");
			} else {
				_file.save(data.trim(), _song.song.toLowerCase() + PlayState.dataFileDifficulty + ".json");
			}
		}
	}

	function onSaveComplete(_):Void {
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved LEVEL DATA.");
	}

	/**
	 * Called when the save file dialog is cancelled.
	 */
	function onSaveCancel(_):Void {
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
	 * Called if there is an error while saving the gameplay recording.
	 */
	function onSaveError(_):Void {
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving Level data");
	}

	var fixedCurSelectedNote:Note;

	var actionDescription:FlxText;

	var debugText:Bool;
}

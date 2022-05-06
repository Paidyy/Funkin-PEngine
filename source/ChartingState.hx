package;

import sys.io.File;
import haxe.io.Path;
import lime.ui.FileDialog;
import Song.SwagGlobalNotes;
import sys.FileSystem;
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
		"Change Character",
		"Change Stage",
		"Change Scroll Speed",
		"Add Camera Zoom",
		"Hey",
		"Play Animation"
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
		Value Syntax: <gf, bf, dad>, <character>\n
		Example Value: dad, pico",

		"Changes current stage to <value>",

		"Just like in the name",

		"Zooms the camera also cancels previous camera zooms",

		"Plays hey animation on gf and bf",

		"Play Animation plays animation on specific character\n
		Example value: bf, hey"
    ];

	var bg:FlxSprite;

	var UI_box:FlxUITabMenu;

	/**
	 * Array of notes showing when each section STARTS in STEPS
	 * Usually rounded up??
	 */
	var curSection:Int = 0;

	public static var lastSection:Int = 0;

	var bpmTxt:FlxText;

	var audioWave:AudioWave;

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
	var actionMenu:UIDropDownMenu;
	var actionValue:UIInputText;

	var tempBpm:Int = 0;

	var vocals:FlxSound;

	private static var leftIcon:HealthIcon;
	private static var rightIcon:HealthIcon;
	//var audioWave:AudioWave;
	var gridBlackLine:FlxSprite;

	var gridBlackLine2:FlxSprite;

	var gridLayer:FlxTypedGroup<Dynamic>;

	var daSongName:String = null;

	var _songGlobalNotes:SwagGlobalNotes;

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
				playAs: "bf",
				needsVoices: true,
				validScore: false,
				swapBfGui: false,
				notes: []
			};
			if (daSongName != null) {
				_song.song = daSongName;
			}
			Paths.setCurrentLevel("week-1");
			PlayState.SONG = _song;
			if (PlayState.currentPlaystate == null)
				PlayState.currentPlaystate = new PlayState();
			PlayState.currentPlaystate.stage = new Stage(_song.stage);
		}
		_songGlobalNotes = Song.parseGlobalNotesJSONshit(_song.song);
		if (_songGlobalNotes == null) {
			_songGlobalNotes = {
				notes: []
			}
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

		audioWave = new AudioWave(gridBG.x + GRID_SIZE, gridBG.y, _song.song, Std.int(GRID_SIZE * (_song.whichK * 2)), Std.int(gridBG.height));
		audioWave.alpha = 0.4;
		add(audioWave);

		curRenderedNotes = new FlxTypedGroup<Note>();
		curRenderedSustains = new FlxTypedGroup<FlxSprite>();

		FlxG.mouse.visible = true;
		FlxG.save.bind('funkin', 'ninjamuffin99');

		tempBpm = _song.bpm;

		if (_song.notes[curSection] == null) {
			addSection();
		}

		if (_songGlobalNotes.notes[curSection] == null) {
			addGlobalSection();
		}

		// sections = _song.notes;

		updateGrid();

		loadSong(_song.song);
		Conductor.changeBPM(_song.bpm);
		Conductor.mapBPMChanges(_song);

		// touching this variable fucks up grid placement
		strumLine = new FlxSprite(0, 50).makeGraphic(Std.int(FlxG.width / 2), 4);
		add(strumLine);

		dummyArrow = new FlxSprite().makeGraphic(GRID_SIZE, GRID_SIZE);
		add(dummyArrow);

		var tabs = [
			{name: "Song", label: 'Song'},
			{name: "Editor", label: 'Editor'},
			{name: "Section", label: 'Section'},
			{name: "Note", label: 'Note'}
		];

		UI_box = new FlxUITabMenu(null, tabs, true);

		UI_box.resize(300, 400);
		UI_box.x = FlxG.width / 2;
		UI_box.y = 20;
		UI_box.x += GRID_SIZE * 3;

		var info:FlxText = new FlxText(UI_box.x + 10, UI_box.y + UI_box.height + 10, 0, "", 15);
		info.setFormat(Paths.font("vcr.ttf"), info.size, FlxColor.WHITE, LEFT);
		info.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 2);
		info.text = 
		      "WS - Move song position (shift to faster)\n"
			+ "AD - Change Section (shift to multiply by 4)\n"
			+ "ENTER - Test the song\n"
			+ "CTRL + ENTER - Test the song in current position\n"
			+ "QE - Change Sustain Note length\n"
			+ "LEFT CLICK - Add a note\n"
			+ "CTRL + LEFT CLICK - Select a note\n"
			+ "ALT + LEFT CLICK - Add a Global Note\n";
		// flx text is bugged with \n
		info.scrollFactor.set();
		add(info);

		bpmTxt = new FlxText(UI_box.x + UI_box.width + 10, 50, 0, "", 12);
		bpmTxt.scrollFactor.set();
		add(bpmTxt);

		add(UI_box);

		addSongUI();
		addEditorUI();
		addSectionUI();
		addNoteUI();

		add(curRenderedNotes);
		add(curRenderedSustains);
		add(globalNoteMarks);

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
			if (_song.whichK == 5) {
				gridBG.x += GRID_SIZE;
			}
			if (_song.whichK > 5) {
				gridBG.x -= GRID_SIZE * (_song.whichK - 6);
			}
		}
		gridBG.x += GRID_SIZE * 3;
		updateHeads();
		gridBlackLine = new FlxSprite(gridBG.x + (gridBG.width / 2) + (GRID_SIZE / 2)).makeGraphic(2, Std.int(gridBG.height), FlxColor.BLACK);
		gridBlackLine2 = new FlxSprite(gridBG.x + GRID_SIZE).makeGraphic(2, Std.int(gridBG.height), FlxColor.BLACK);

		gridLayer.add(gridBG);
		gridLayer.add(gridBlackLine2);
		gridLayer.add(gridBlackLine);
	}

	function addSongUI():Void {
		var UI_songTitle = new UIInputText(10, 10, 70, _song.song, 8);
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

		var maniaList = ["4K", "5K", "6K", "7K", "8K", "9K"];
		var whichKMenu = new UIDropDownMenu(stepperSpeed.x, stepperSpeed.y + stepperSpeed.width + 17, maniaList, function onSelect(s, i) {
			_song.whichK = Std.parseInt(s);
			setBGgrid();
			updateGrid();
			updateHeads();
		}, 6);
		whichKMenu.selectLabel(_song.whichK + "K");
		var maniaText = new FlxText(whichKMenu.x - 5, whichKMenu.y - 15, 0, "Mania:");

		var stagesMenu = new UIDropDownMenu(whichKMenu.x + 130, whichKMenu.y, CoolUtil.getStages(), function onSelect(s, i) {
			_song.stage = s;
		}, 6);
		stagesMenu.selectLabel(_song.stage);
		var stageText = new FlxText(stagesMenu.x - 5, stagesMenu.y - 15, 0, "Stage:");

		var characters:Array<String> = CoolUtil.getCharacters();

		var player1DropDown = new UIDropDownMenu(10, whichKMenu.y + 50, characters, function(character:String, i) {
			_song.player1 = character;
			updateHeads();
		});
		player1DropDown.selectLabel(_song.player1);
		var boyfriendText = new FlxText(player1DropDown.x - 5, player1DropDown.y - 15, 0, "Boyfriend:");

		var player2DropDown = new UIDropDownMenu(player1DropDown.x + 130, player1DropDown.y, characters, function(character:String, i) {
			_song.player2 = character;
			updateHeads();
		});
		player2DropDown.selectLabel(_song.player2);

		var opponentText = new FlxText(player2DropDown.x - 5, player2DropDown.y - 15, 0, "Opponent:");

		var playAsDropDown = new UIDropDownMenu(player1DropDown.x + 130, player2DropDown.y + 50, ["bf", "dad"], function(character:String, i) {
			_song.playAs = character;
		}, 2);
		playAsDropDown.selectedLabel = _song.playAs;

		var playAsText = new FlxText(playAsDropDown.x - 5, playAsDropDown.y - 15, 0, "Play As:");

		var check_swapgui = new FlxUICheckBox(whichKMenu.x, playAsDropDown.y + playAsDropDown.height + 5, null, null, "Swap Bf Gui with Dad", 100);
		check_swapgui.checked = _song.swapBfGui;
		check_swapgui.callback = function() {
			_song.swapBfGui = check_swapgui.checked;
		};

		var tab_group_song = new FlxUI(null, UI_box);
		tab_group_song.name = "Song";

		tab_group_song.add(bpmText);
		tab_group_song.add(speedText);
		tab_group_song.add(boyfriendText);
		tab_group_song.add(opponentText);
		tab_group_song.add(maniaText);
		tab_group_song.add(stageText);
		tab_group_song.add(playAsText);

		tab_group_song.add(UI_songTitle);
		tab_group_song.add(check_voices);
		tab_group_song.add(saveButton);
		tab_group_song.add(reloadSong);
		tab_group_song.add(reloadSongJson);
		tab_group_song.add(loadAutosaveBtn);
		tab_group_song.add(stepperBPM);
		tab_group_song.add(stepperSpeed);
		tab_group_song.add(check_swapgui);

		tab_group_song.add(playAsDropDown);
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

		check_altAnim = new FlxUICheckBox(10, 300, null, null, "Alt Animation", 100);
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

		actionValue = new UIInputText(10, 90, 85 * 2, "", 8);
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

		actionMenu = new UIDropDownMenu(10, 50, actionNoteList, function onSelect(s, i) {
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

	var instVolume:FlxUINumericStepper;
	var voicesVolume:FlxUINumericStepper;
	var isMetronome = false;
	var isAudioWave = false;

	function addEditorUI() {
		var tab_group_editor = new FlxUI(null, UI_box);
		tab_group_editor.name = 'Editor';

		var metronome = new FlxUICheckBox(10, 10, null, null, "Metronome", 100);
		metronome.checked = false;
		metronome.callback = function() {
			isMetronome = metronome.checked;
		};

		var waveform = new FlxUICheckBox(metronome.x, metronome.y + metronome.height + 5, null, null, "Waveform", 100);
		waveform.checked = false;
		waveform.callback = function() {
			isAudioWave = waveform.checked;
			updateGrid();
		};

		instVolume = new FlxUINumericStepper(10, waveform.height + waveform.y + 20, 0.1, FlxG.sound.music.volume, 0, 1.0, 1);
		instVolume.value = FlxG.sound.music.volume;
		instVolume.name = 'inst_volume';
		var text1 = new FlxText(instVolume.x - 5, instVolume.y - 16, 0, "Instrumental Volume:");

		voicesVolume = new FlxUINumericStepper(instVolume.x + instVolume.width + 70, instVolume.y, 0.1, vocals.volume, 0, 1.0, 1);
		voicesVolume.value = vocals.volume;
		voicesVolume.name = 'voices_volume';
		var text2 = new FlxText(voicesVolume.x - 5, voicesVolume.y - 16, 0, "Voices Volume:");

		tab_group_editor.add(instVolume);
		tab_group_editor.add(voicesVolume);
		tab_group_editor.add(text1);
		tab_group_editor.add(text2);
		tab_group_editor.add(metronome);
		tab_group_editor.add(waveform);

		UI_box.addGroup(tab_group_editor);
	}

	function onNewStep() {
		if (isMetronome) {
			if (curStep % 16 == 0) {
				FlxG.sound.play(Paths.sound('Metronome1'));
			}
			else if (curStep % 4 == 0) {
				FlxG.sound.play(Paths.sound('Metronome2'));
			}
		}
	}

	function loadSong(daSong:String):Void {
		if (FlxG.sound.music != null) {
			FlxG.sound.music.stop();
			// vocals.stop();
		}
		
		if (FileSystem.exists(Paths.instNoLib(daSong))) {
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

		Conductor.songPosition = 0;
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
			switch(wname) {
				case 'section_length':
					_song.notes[curSection].lengthInSteps = Std.int(nums.value);
					updateGrid();
				case 'song_speed':
					_song.speed = nums.value;
				case 'song_bpm':
					tempBpm = Std.int(nums.value);
					Conductor.mapBPMChanges(_song);
					Conductor.changeBPM(Std.int(nums.value));
				case 'note_susLength':
					curSelectedNote[2] = nums.value;
					updateGrid();
				case 'section_bpm':
					_song.notes[curSection].bpm = Std.int(nums.value);
					updateGrid();
				case 'inst_volume':
					FlxG.sound.music.volume = instVolume.value;
				case 'voices_volume':
					vocals.volume = voicesVolume.value;
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
	function resyncVocals():Void {
		vocals.pause();

		FlxG.sound.music.play();
		Conductor.songPosition = FlxG.sound.music.time;
		vocals.time = Conductor.songPosition;
		vocals.play();
	}
	override function update(elapsed:Float) {
		if (FlxG.sound.music.playing) {
			if (FlxG.sound.music.time > Conductor.songPosition + 20 || FlxG.sound.music.time < Conductor.songPosition - 20) {
				resyncVocals();
			}
		}

		FlxG.mouse.visible = true;
		curStep = recalculateSteps();

		Conductor.songPosition = FlxG.sound.music.time;
		_song.song = typingShit.text;

		strumLine.y = getYfromStrum((Conductor.songPosition - sectionStartTime()) % (Conductor.stepCrochet * _song.notes[curSection].lengthInSteps));

		if (curBeat % 4 == 0 && curStep >= 16 * (curSection + 1)) {
			trace((_song.notes[curSection].lengthInSteps) * (curSection + 1));

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

		curRenderedNotes.forEachAlive(function(note:Note) {
			note.alpha = 1;
			if (note.strumTime <= Conductor.songPosition) {
				note.alpha = 0.3;
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
				if (FlxG.keys.pressed.CONTROL)
					FlxG.switchState(new PlayState(null, Conductor.songPosition));
				else
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
						updateGrid();
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

		if (curStep != lastChange.stepTime + Math.floor((FlxG.sound.music.time - lastChange.songTime) / Conductor.stepCrochet)) {
			curStep = lastChange.stepTime + Math.floor((FlxG.sound.music.time - lastChange.songTime) / Conductor.stepCrochet);
			onNewStep();
		}
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

		if (_song.notes[sec] == null) {
			addSection();
		}

		if (_songGlobalNotes.notes[sec] == null) {
			addGlobalSection();
		}

		if (_song.notes[sec] != null) {
			curSection = sec;

			updateGrid();

			if (updateMusic) {
				FlxG.sound.music.pause();
				vocals.pause();

				FlxG.sound.music.time = sectionStartTime();
				vocals.time = FlxG.sound.music.time;
				updateCurStep();
			}

			updateGrid();
			updateSectionUI();
			updateHeads();
			updateGrid();
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
			actionMenu.selectLabel("");
			actionValue.text = "";
			actionMenu.selectLabel(curSelectedNote[3]);
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

		while (globalNoteMarks.members.length > 0) {
			globalNoteMarks.remove(globalNoteMarks.members[0], true);
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

		audioWave.visible = isAudioWave;
		if (audioWave.audioBuffer != null && isAudioWave) {
			audioWave.x = gridBG.x + GRID_SIZE;
			audioWave.waveWidth = Std.int(GRID_SIZE * (_song.whichK * 2));
			audioWave.startTime = sectionStartTime();
			audioWave.steps = _song.notes[curSection].lengthInSteps;
			audioWave.drawWaveform();
		}

		for (i in sectionInfo) {
			var daNoteInfo = i[1];
			var daStrumTime = i[0];
			var daSus = i[2];
			var action2 = i[3];
			var actionValue2 = i[4];

			var note:Note = new Note(daStrumTime, daNoteInfo % _song.whichK);
			var gottaHitNote:Bool = (daNoteInfo >= _song.whichK) ? !_song.notes[curSection].mustHitSection : _song.notes[curSection].mustHitSection;
			note.mustPress = gottaHitNote;
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
			note.x += GRID_SIZE * (_song.whichK - 1);
			if (_song.whichK > 5) {
				note.x -= GRID_SIZE * ((_song.whichK - 5) * 2);
			}
			
			note.y = Math.floor(getYfromStrum((daStrumTime - sectionStartTime()) % (Conductor.stepCrochet * _song.notes[curSection].lengthInSteps)));

			curRenderedNotes.add(note);

			note.alpha = 1;

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


		if (_songGlobalNotes.notes[curSection] != null) {
			for (i in _songGlobalNotes.notes[curSection].sectionNotes) {
				var daNoteInfo = i[1];
				var daStrumTime = i[0];
				var daSus = i[2];
				var action2 = i[3];
				var actionValue2 = i[4];

				var note:Note = new Note(daStrumTime, daNoteInfo % _song.whichK);
				var gottaHitNote:Bool = (daNoteInfo >= _song.whichK) ? !_songGlobalNotes.notes[curSection].mustHitSection : _songGlobalNotes.notes[curSection].mustHitSection;
				note.mustPress = gottaHitNote;
				note.sustainLength = daSus;
				note.action = action2;
				note.actionValue = actionValue2;
				note.setGraphicSize(GRID_SIZE, GRID_SIZE);
				note.updateHitbox();
				if (_song.whichK == 4) {
					note.x = Math.floor((daNoteInfo) * GRID_SIZE);
				}
				else {
					note.x = Math.floor((daNoteInfo - _song.whichK + 2) * GRID_SIZE);
				}
				note.x += GRID_SIZE * (_song.whichK - 1);
				if (_song.whichK > 5) {
					note.x -= GRID_SIZE * ((_song.whichK - 5) * 2);
				}

				note.y = Math.floor(getYfromStrum((daStrumTime - sectionStartTime()) % (Conductor.stepCrochet * _songGlobalNotes.notes[curSection].lengthInSteps)));

				curRenderedNotes.add(note);

				note.alpha = 1;

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
				
				var mark = new FlxSprite(note.x, note.y).loadGraphic(Paths.image("globalNoteSticker"));
				mark.setGraphicSize(Std.int(mark.width * 0.1), Std.int(mark.height * 0.1));
				mark.updateHitbox();
				globalNoteMarks.add(mark);
			}
		}
	}

	var globalNoteMarks = new FlxTypedGroup<FlxSprite>();

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

	private function addGlobalSection(lengthInSteps:Int = 16):Void {
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

		_songGlobalNotes.notes.push(sec);
	}

	function selectNote(note:Note):Void {
		var swagNum:Int = 0;

		for (i in _song.notes[curSection].sectionNotes) {
			if (i[0] == note.strumTime && i[1] % _song.whichK == note.noteData) {
				curSelectedNote = _song.notes[curSection].sectionNotes[swagNum];
			}

			swagNum += 1;
		}

		var swagNumAlt:Int = 0;
		for (i in _songGlobalNotes.notes[curSection].sectionNotes) {
			if (i[0] == note.strumTime && i[1] % _song.whichK == note.noteData) {
				curSelectedNote = _songGlobalNotes.notes[curSection].sectionNotes[swagNumAlt];
			}

			swagNumAlt += 1;
		}

		updateGrid();
		updateNoteUI();
		//doesnt work for some reason | add(new FlxEffectSprite(fixedCurSelectedNote, [new FlxOutlineEffect(4, FlxColor.BLUE, 100)]));
	}

	function deleteNote(note:Note):Void {
		var noteData = (_song.notes[curSection].mustHitSection != note.mustPress) ? note.noteData + _song.whichK : note.noteData;

		for (i in _song.notes[curSection].sectionNotes) {
			if (i[0] == note.strumTime && i[1] == noteData) {
				_song.notes[curSection].sectionNotes.remove(i);
			}
		}

		var noteDataAlt = (_songGlobalNotes.notes[curSection].mustHitSection != note.mustPress) ? note.noteData + _song.whichK : note.noteData;

		for (i in _songGlobalNotes.notes[curSection].sectionNotes) {
			if (i[0] == note.strumTime && i[1] == noteDataAlt) {
				_songGlobalNotes.notes[curSection].sectionNotes.remove(i);
			}
		}

		updateGrid();
	}

	function clearSection():Void {
		_song.notes[curSection].sectionNotes = [];
		_songGlobalNotes.notes[curSection].sectionNotes = [];

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
		noteData -= 3;
		noteData += Math.floor(FlxG.mouse.x / GRID_SIZE);

		if (_song.whichK > 4) {
			noteData += (_song.whichK - 4) * 2;
		}

		var noteSus = 0;

		if (FlxG.keys.pressed.ALT) {
			_songGlobalNotes.notes[curSection].sectionNotes.push([noteStrum, noteData, noteSus]);
		}
		else {
			_song.notes[curSection].sectionNotes.push([noteStrum, noteData, noteSus]);
		}

		curSelectedNote = _song.notes[curSection].sectionNotes[_song.notes[curSection].sectionNotes.length - 1];

		if (FlxG.keys.pressed.CONTROL) {
			_song.notes[curSection].sectionNotes.push([noteStrum, (noteData + _song.whichK) % (_song.whichK * 2), noteSus]);
		}
		
		/*
		trace("noteStrum: " + noteStrum);
		trace("curSection:" + curSection);
		trace("noteData: " + noteData);
		*/

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
			//using FileDialog instead of FileReference because it gives more options, like custom path
			var file = new FileDialog();
			file.onSave.add(onSave);
			file.save(data.trim(), "json",
				Paths.slashPath(Sys.getCwd() + Paths.getSongPath(_song.song.toLowerCase(), true) + _song.song.toLowerCase() + PlayState.dataFileDifficulty + ".json")
			);
		}
	}

	function onSave(s:String) {
		var thePath = "";
		var arr = s.split(Paths.FS);
		arr[arr.length - 1] = "";
		for (thing in arr) {
			thePath += thing + Paths.FS;
		}
		thePath = thePath.substring(0, thePath.length - 1);
		File.saveContent(thePath + "global_notes.json", Json.stringify(_songGlobalNotes).trim());
	}

	var fixedCurSelectedNote:Note;

	var actionDescription:FlxText;

	var debugText:Bool;
}

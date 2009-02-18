// VideoWarp Player source code
// by Michael Rondinelli

import mx.formatters.DateFormatter;
import mx.events.MenuEvent;
import mx.events.VideoEvent;
import mx.events.SliderEvent;
import mx.containers.Box;
import mx.controls.Alert;
import mx.controls.VSlider;
import mx.controls.videoClasses.VideoPlayer;
import mx.managers.PopUpManager;
import com.eyesee360.LargeSliderThumb;
import com.eyesee360.InstructionsPanel;
import com.eyesee360.AboutVideoWarpPlayerPanel;

/**
*	Embedded images for dynamic replacement
**/

[Bindable]
public var volumeIcon:Class;
[Bindable]
public var volumeActiveIcon:Class;

[Embed("images/volume-mute.png")]
public var volumeMuteImg:Class;

[Embed("images/volume-mute-active.png")]
public var volumeMuteActiveImg:Class;

[Embed("images/volume-0.png")]
public var volume0Img:Class;

[Embed("images/volume-0-active.png")]
public var volume0ActiveImg:Class;

[Embed("images/volume-1.png")]
public var volume1Img:Class;

[Embed("images/volume-1-active.png")]
public var volume1ActiveImg:Class;

[Embed("images/volume-2.png")]
public var volume2Img:Class;

[Embed("images/volume-2-active.png")]
public var volume2ActiveImg:Class;

[Embed("images/volume-3.png")]
public var volume3Img:Class;

[Embed("images/volume-3-active.png")]
public var volume3ActiveImg:Class;


/* Instance variables */

private var start:Date;
private var timeDisplayFormatter:DateFormatter;
private var seekTo:Number;
private var duration:Number;

private var volumeBox:Box = null;
private var volumeSlider:VSlider = null;

[Bindable]
public var panoSalado : PanoSalado;
[Bindable]
private var videoFileTotalBytes:Number;

private function init():void
{
	start = new Date("1/1/2000");
	timeDisplayFormatter  = new DateFormatter();
	duration = 0;
	
	volumeIcon = volume3Img;
	volumeActiveIcon = volume3ActiveImg;
}

private function initPaperCanvas():void {
	// If we're loaded directly, instantiate PanoSalado ourselves.
	if (!ApplicationDomain.currentDomain.hasDefinition("ModuleLoader")) {
		this.paperCanvas.panoSalado = new PanoSalado();
	}
	
	this.paperCanvas.addEventListener(VideoEvent.READY, videoReady);
	this.paperCanvas.addEventListener(VideoEvent.PLAYHEAD_UPDATE, updateTimeDisplay);		
}

private function appComplete():void {
	Application.application.stage.addEventListener(FullScreenEvent.FULL_SCREEN, fullScreenHandler);
//		Application.application.stage.addEventListener(KeyboardEvent.KEY_DOWN, keyboardHandler);
	Application.application.stage.addEventListener(KeyboardEvent.KEY_UP, keyboardHandler);
}

private function playPause() : void {		
	if (paperCanvas.currentVideo.state == VideoPlayer.PLAYING) {
		paperCanvas.currentVideo.pause();
	} else { 
		paperCanvas.currentVideo.play();
	}
}

private function videoReady(event:VideoEvent):void
{
	this.paperCanvas.currentVideo.addEventListener(VideoEvent.STATE_CHANGE, updateState);
	this.paperCanvas.currentVideo.addEventListener(ProgressEvent.PROGRESS, updateProgress);
	this.paperCanvas.currentVideo.progressInterval = 0.5;
	this.videoFileTotalBytes = this.paperCanvas.currentVideo.bytesTotal;
	this.downloadProgress.setProgress(this.paperCanvas.currentVideo.bytesLoaded, this.videoFileTotalBytes);
	
	this.paperCanvas.currentVideo.addEventListener("totalTimeUpdated", updateDurationDisplay);
	this.paperCanvas.currentVideo.addEventListener("volumeChanged", updateVolume);

	this.updateVolume();
	this.updateDurationDisplay();
}

private function updateDurationDisplay(event:Event = null):void
{
	if (duration != this.paperCanvas.currentVideo.totalTime) {
		timeDisplayFormatter.formatString = "N:SS";
		duration = this.paperCanvas.currentVideo.totalTime;
		var totalTime:Date = new Date ( start.getTime() + (duration * 1000) );
		this.tf_durationDisplay.text = timeDisplayFormatter.format(totalTime);
	}
}

private function updateTimeDisplay(event:VideoEvent):void
{
	timeDisplayFormatter.formatString = "N:SS";	
	var currentTime:Date = new Date ( start.getTime() + (event.playheadTime * 1000) );
	this.tf_playtimeDisplay.text = timeDisplayFormatter.format(currentTime);
	updateDurationDisplay();
}

private function updateProgress(event:ProgressEvent):void
{
	this.downloadProgress.setProgress(event.bytesLoaded, event.bytesTotal); 
	this.videoFileTotalBytes = event.bytesTotal;
}

private function updateState(event:VideoEvent):void
{
	this.btn_playPause.styleName = 
		(this.paperCanvas.currentVideo.playing) ? 'pauseButton' : 'playButton';
}

private function updateVolume(event:Event = null):void
{
	if (paperCanvas && paperCanvas.currentVideo) {
		var volume:Number = paperCanvas.currentVideo.volume;
		volumeSlider.value = volume;
		if (volume == 0) {
			volumeIcon = volumeMuteImg;
			volumeActiveIcon = volumeMuteActiveImg;
		} else if (volume < 0.25) {
			volumeIcon = volume0Img;
			volumeActiveIcon = volume0ActiveImg;
		} else if (volume < 0.50) {
			volumeIcon = volume1Img;
			volumeActiveIcon = volume1ActiveImg;
		} else if (volume < 0.75) {
			volumeIcon = volume2Img;
			volumeActiveIcon = volume2ActiveImg;
		} else {
			volumeIcon = volume3Img;
			volumeActiveIcon = volume3ActiveImg;
		}
	}
}

private function initVolumePopUp():void
{
	var popUpVolume:PopUpButton = this.btn_volume;
	
	volumeBox = new Box();
	volumeBox.width = 32;
	volumeSlider = new VSlider();
	volumeSlider.height = 64;
	volumeSlider.styleName = "volumeSlider";
	volumeSlider.sliderThumbClass = LargeSliderThumb;
	volumeSlider.minimum = 0.0;
	volumeSlider.maximum = 1.0;
	volumeSlider.liveDragging = true;
	volumeSlider.addEventListener(SliderEvent.CHANGE, function (event:SliderEvent):void {
		paperCanvas.currentVideo.volume = event.value;
	});
	volumeBox.addChild(volumeSlider);
	popUpVolume.popUp = volumeBox;
	popUpVolume.openAlways = true;
}

private function initMenu():void {
	this.btn_menu.popUp.addEventListener(MenuEvent.ITEM_CLICK, menuHandler);
}

private function toggleFullScreen():void {
	var stage:Stage = Application.application.stage;
    try {
        switch (Application.application.stage.displayState) {
            case StageDisplayState.FULL_SCREEN:
                /* If already in full screen mode, switch to normal mode. */
                stage.displayState = StageDisplayState.NORMAL;
                break;
            default:
                /* If not in full screen mode, switch to full screen mode. */
				stage.fullScreenSourceRect = new Rectangle(
					0, 0, stage.width, stage.height);
                stage.displayState = StageDisplayState.FULL_SCREEN;
                break;
        }
    } catch (err:SecurityError) {
        // ignore
    }
}

private function fullScreenHandler(evt:FullScreenEvent):void {
    if (evt.fullScreen) {
        /* Do something specific here if we switched to full screen mode. */
		this.playbackControls.visible = false;
    } else {
        /* Do something specific here if we switched to normal mode. */
		this.playbackControls.visible = true;
    }
}

private function showAboutBox():void {
	paperCanvas.currentVideo.pause();
	var aboutBox:AboutVideoWarpPlayerPanel =
		AboutVideoWarpPlayerPanel(PopUpManager.createPopUp( 
			this, AboutVideoWarpPlayerPanel, true));
	PopUpManager.centerPopUp(aboutBox);
}

private function showInstructionBox():void {
	paperCanvas.currentVideo.pause();
	var instructionBox:InstructionsPanel =
		InstructionsPanel(PopUpManager.createPopUp( 
			this, InstructionsPanel, true));
	PopUpManager.centerPopUp(instructionBox);
}

private function menuHandler(event:MenuEvent):void  {
	if (event.item.@action == "fullscreen") {
		this.toggleFullScreen();
	} else if (event.item.@action == "about") {
		showAboutBox();
	} else if (event.item.@action == "instructions") {
		showInstructionBox();
	}
}

private function keyboardHandler(event:KeyboardEvent):void {
	if (event.type == KeyboardEvent.KEY_UP) {
		if (event.keyCode == 32) { // Space
			this.playPause();
		}
	}
}

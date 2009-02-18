package com.fxcomponents.controls
{
	import com.fxcomponents.controls.musicbutton.Bar;
	
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	import flash.net.URLRequest;
	
	import mx.core.UIComponent;
	
	[Style(name="fillColor", type="uint", format="Color")]
	
	public class MusicButton extends UIComponent
	{
		public function MusicButton()
		{
			super();
			
			sound = new Sound();
			trans = new SoundTransform();
			request = new URLRequest();
		}
		
		private var sound:Sound;
		private var soundChannel:SoundChannel;
		private var pausePosition:Number = 0;
		private var request:URLRequest;
		private var trans:SoundTransform;
		
		private var playing:Boolean = false;
		private var bars:Array = new Array();
		
		// display objects
		
		private var panel:Sprite;
		private var icon:UIComponent;
		
		private var _source:String;
		private var sourceChanged:Boolean = false;
		
		public function set source(value:String):void
		{
			_source = value;
			sourceChanged = true;
			
			invalidateProperties();
		}
		
		private var _autoplay:Boolean = true;
		
		public function set autoplay(value:Boolean):void
		{
			_autoplay = value;
			
			playing = value;
			
			invalidateProperties();
		}
		
		private var _loops:uint = 0;
		
		public function set loops(value:int):void
		{
			_loops = value;
			
			invalidateProperties();
		}
		
		private var _volume:Number = .8;
		private var volumeChanged:Boolean = false;
		
		public function set volume(value:Number):void
		{
			_volume = value;
			volumeChanged = true;
			
			invalidateProperties();
		}
		
		private var _animationSpeed:uint;
		private var animationSpeedChanged:Boolean = false;
		
		public function set animationSpeed(value:uint):void
		{
			_animationSpeed = value;
			animationSpeedChanged = true;
			
			invalidateProperties();
		}
		
		override protected function createChildren():void
		{
			super.createChildren();
			
			for(var i:uint; i<5; i++)
			{
				bars[i] = new Bar();
				addChild(bars[i]);
			}
			
			icon = new UIComponent();
			addChild(icon);
			
			panel = new Sprite();
			addChild(panel);
			
			panel.useHandCursor = true;
			panel.buttonMode = true;
			panel.addEventListener(MouseEvent.CLICK, onClick);
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			
			if(animationSpeedChanged)
			{
				for(var i:String in bars)
					bars[i].speed = _animationSpeed;
					
				animationSpeedChanged = false;
			}
			
			if(sourceChanged)
			{
				request.url = _source;
				
				sound.load(request);
				
				if(_autoplay)
					play();
					
				sourceChanged = false;
			}
			
			if(volumeChanged)
			{
				trans.volume = _volume;
				
				stop();
				play();
				
				volumeChanged = false;
			}
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			for(var i:String in bars)
			{
				bars[i].x = 10 + Number(i)*3;
				bars[i].color = getStyle("fillColor");
			}
			
			icon.graphics.clear();
			icon.graphics.beginFill(getStyle("fillColor"));
			icon.graphics.drawRect(0, 2, 2, 5);
			icon.graphics.drawRect(3, 2, 1, 5);
			icon.graphics.drawRect(4, 1, 1, 7);
			icon.graphics.drawRect(5, 0, 1, 9);
			
			panel.graphics.beginFill(0xff0000, 0);
			panel.graphics.drawRect(0, 0, unscaledWidth, unscaledHeight);
		}
		
		override protected function measure():void
		{
			super.measure();
			
			measuredMinWidth = measuredWidth = 24;
			measuredMinHeight = measuredHeight = 9;
		}
		
		private function onClick(e:MouseEvent):void
		{
			(playing) ? stop() : play()
		}
		
		private function play():void
		{
			for(var i:String in bars)
				bars[i].play();
			
			playing = true;
			
			soundChannel = sound.play(pausePosition, _loops, trans);
		}
		
		public function stop():void
		{
			pausePosition = soundChannel.position;
			
			for(var i:String in bars)
				bars[i].stop();
			
			playing = false;
			
			soundChannel.stop();
		}
	}
}
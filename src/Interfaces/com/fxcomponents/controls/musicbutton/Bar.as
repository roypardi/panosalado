package com.fxcomponents.controls.musicbutton
{
	import mx.core.UIComponent;
	import mx.effects.Move;
	import mx.effects.Resize;
	import mx.events.TweenEvent;

	public class Bar extends UIComponent
	{
		public function Bar()
		{
			super();
			
			resize = new Resize();
		}
		
		private var _color:uint;
		
		public function set color(value:uint):void
		{
			_color = value;
			
			invalidateProperties();
		}
		
		private var _speed:uint = 220;
		
		public function set speed(value:uint):void
		{
			_speed = value;
		}
		
		private var w:uint = 2;
		private var h:uint = 9;
		
		private var shape:BarShape;
		
		
		private var resize:Resize;
		private var move2:Move;
		
		override protected function createChildren():void
		{
			super.createChildren();
			
			shape = new BarShape();
			shape.setActualSize(w, h);
			addChild(shape);
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			
			shape.color = _color;
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			
		}
		
		private function onTweenEnd(e:TweenEvent):void
		{
			resize.target = shape;
			resize.heightTo = Math.random()*h;
			resize.duration = _speed;
			resize.play();
		}
		
		public function play():void
		{
			resize.stop();
			
			onTweenEnd(new TweenEvent(TweenEvent.TWEEN_END));
			
			resize.addEventListener(TweenEvent.TWEEN_END, onTweenEnd);
		}
		
		public function stop():void
		{
			resize.stop();
			resize.target = shape;
			resize.heightTo = w;
			resize.duration = _speed;
			resize.play();
			
			resize.removeEventListener(TweenEvent.TWEEN_END, onTweenEnd);
		}
	}
}
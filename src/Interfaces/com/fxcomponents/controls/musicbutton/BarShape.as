package com.fxcomponents.controls.musicbutton
{
	import mx.core.UIComponent;

	public class BarShape extends UIComponent
	{
		public function BarShape()
		{
			super();
		}
		
		private var _color:uint;
		
		public function set color(value:uint):void
		{
			_color = value;
			
			invalidateDisplayList();
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			graphics.clear();
			graphics.beginFill(_color);
			graphics.drawRect(0, -unscaledHeight + 9, unscaledWidth, unscaledHeight);
		}
	}
}
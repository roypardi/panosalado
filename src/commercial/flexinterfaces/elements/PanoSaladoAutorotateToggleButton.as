package commercial.flexinterfaces.elements
{
	import commercial.flexinterfaces.elements.PanoSaladoEnhancedButton;
	import flash.events.*;
	import zephyr.BroadcastEvent;
	
	public class PanoSaladoAutorotateToggleButton extends PanoSaladoEnhancedButton
	{
		
		public function PanoSaladoAutorotateToggleButton()
		{
			super();
			
			styleName="PanoSaladoAutorotateToggleButton";
			
			toggle=true;
			
			addEventListener(MouseEvent.MOUSE_DOWN, interactionHandler, false, 0, true);
		}
		
		override protected function stageReady(e:Event):void
		{
			super.stageReady(e);
			
			panoSaladoToolTip =  settings.PanoSaladoAutorotateToggleButton.@toolTip || "Toggle Auto Rotation";
			//label = settings.PanoSaladoTiltDownButton.@label || "Down";
			
			moduleLoader.addEventListener(BroadcastEvent.AUTOROTATION_ON, setSelected, false, 0, true);
			
			moduleLoader.addEventListener(BroadcastEvent.AUTOROTATION_OFF, clearSelected, false, 0, true);
		}
		
		protected function interactionHandler(e:MouseEvent):void
		{
			e.stopImmediatePropagation();
			
			panoSaladoExecute( "toggleAutorotator" );
		}
		
		protected function setSelected(e:Event):void
		{
			selected = false;
		}
		
		protected function clearSelected(e:Event):void
		{
			selected = true;
		}
	}
}

package commercial.flexinterfaces.elements
{
	import commercial.flexinterfaces.elements.PanoSaladoEnhancedButton;
	import flash.events.*;
	
	public class PanoSaladoPanRightButton extends PanoSaladoEnhancedButton
	{
		
		public function PanoSaladoPanRightButton()
		{
			super();
			
			styleName="PanoSaladoPanRightButton";

			addEventListener(MouseEvent.MOUSE_DOWN, interactionHandler, false, 0, true);
			addEventListener(MouseEvent.MOUSE_UP, interactionHandler, false, 0, true);
		}
		
		override protected function stageReady(e:Event):void
		{
			super.stageReady(e);
			
			panoSaladoToolTip =  settings.PanoSaladoPanRightButton.@toolTip || "Pan Right";
			//label = settings.panoSaladoPanRightButton.@label || "Right";
		}
		
		private function interactionHandler(e:MouseEvent):void
		{
			e.stopImmediatePropagation();
				
			if (e.type == MouseEvent.MOUSE_DOWN)
			{
				panoSaladoExecute( "keyDown:right" );
				addEventListener(MouseEvent.MOUSE_OUT, interactionHandler, false, 0, true);
			}
			else if (e.type == MouseEvent.MOUSE_UP)
			{
				panoSaladoExecute( "keyUp:right" );
				removeEventListener(MouseEvent.MOUSE_OUT, interactionHandler);
			}
			else if (e.type == MouseEvent.MOUSE_OUT)
			{
				panoSaladoExecute( "keyUp:right" );
				removeEventListener(MouseEvent.MOUSE_OUT, interactionHandler);
			}
		}
	}
}
package commercial.flexinterfaces.elements
{
	import commercial.flexinterfaces.elements.PanoSaladoEnhancedButton;
	import flash.events.*;
	
	public class PanoSaladoZoomInButton extends PanoSaladoEnhancedButton
	{
		
		public function PanoSaladoZoomInButton()
		{
			super();
			
			styleName="PanoSaladoZoomInButton";

			addEventListener(MouseEvent.MOUSE_DOWN, interactionHandler, false, 0, true);
			addEventListener(MouseEvent.MOUSE_UP, interactionHandler, false, 0, true);
		}
		
		override protected function stageReady(e:Event):void
		{
			super.stageReady(e);
			
			panoSaladoToolTip =  settings.PanoSaladoZoomInButton.@toolTip || "Zoom In";
			//label = settings.panoSaladoZoomInButton.@label || "In";
		}
		
		private function interactionHandler(e:MouseEvent):void
		{
			e.stopImmediatePropagation();
			
			if (e.type == MouseEvent.MOUSE_DOWN)
			{
				panoSaladoExecute( "keyDown:shift" );
				addEventListener(MouseEvent.MOUSE_OUT, interactionHandler, false, 0, true);
			}
			else if (e.type == MouseEvent.MOUSE_UP)
			{
				panoSaladoExecute( "keyUp:shift" );
				removeEventListener(MouseEvent.MOUSE_OUT, interactionHandler);
			}
			else if (e.type == MouseEvent.MOUSE_OUT)
			{
				panoSaladoExecute( "keyUp:shift" );
				removeEventListener(MouseEvent.MOUSE_OUT, interactionHandler);
			}
		}
	}
}
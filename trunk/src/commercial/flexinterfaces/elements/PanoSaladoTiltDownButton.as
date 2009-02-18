package commercial.flexinterfaces.elements
{
	import commercial.flexinterfaces.elements.PanoSaladoEnhancedButton;
	import flash.events.*;
	
	public class PanoSaladoTiltDownButton extends PanoSaladoEnhancedButton
	{
		
		public function PanoSaladoTiltDownButton()
		{
			super();
			
			styleName="PanoSaladoTiltDownButton";

			addEventListener(MouseEvent.MOUSE_DOWN, interactionHandler, false, 0, true);
			addEventListener(MouseEvent.MOUSE_UP, interactionHandler, false, 0, true);
		}
		
		override protected function stageReady(e:Event):void
		{
			super.stageReady(e);
			
			panoSaladoToolTip =  settings.PanoSaladoTiltDownButton.@toolTip || "Tilt Down";
			//label = settings.PanoSaladoTiltDownButton.@label || "Down";
		}
		
		private function interactionHandler(e:MouseEvent):void
		{
			e.stopImmediatePropagation();
			
			if (e.type == MouseEvent.MOUSE_DOWN)
			{
				panoSaladoExecute( "keyDown:down" );
				addEventListener(MouseEvent.MOUSE_OUT, interactionHandler, false, 0, true);
			}
			else if (e.type == MouseEvent.MOUSE_UP)
			{
				panoSaladoExecute( "keyUp:down" );
				removeEventListener(MouseEvent.MOUSE_OUT, interactionHandler);
			}
			else if (e.type == MouseEvent.MOUSE_OUT)
			{
				panoSaladoExecute( "keyUp:down" );
				removeEventListener(MouseEvent.MOUSE_OUT, interactionHandler);
			}
		}
	}
}
package commercial.flexinterfaces.elements
{
	import commercial.flexinterfaces.elements.PanoSaladoEnhancedButton;
	import flash.events.*;
	
	public class PanoSaladoNextButton extends PanoSaladoEnhancedButton
	{
		protected var spacesList:XMLList;
		
		protected var previewsList:XMLList;
		
		internal var __len:int;
		
		public function PanoSaladoNextButton()
		{
			super();
			
			styleName = 'PanoSaladoNextButton';
		}
		
		protected function psClickHandler(e:MouseEvent):void
		{
			var nextSpace:String = getNextSpace();
			
			if ( previewsList.(@id == nextSpace+'.preview') != undefined)
				nextSpace = nextSpace+'.preview'
			
			
			panoSaladoExecute('loadSpace:'+nextSpace);
		}
		
		private function getNextSpace():String
		{
			// code to go to previous space
			
			var currentSpace:String = panoSalado.currentSpace;
			
			var idxOfdotPreview:int = currentSpace.search(/\.preview$/);
			if ( idxOfdotPreview > -1)
				currentSpace = currentSpace.substring( 0,idxOfdotPreview );
			
			for (var i:int = 0; i < __len; i++)
			{
				if (currentSpace == spacesList.@id[i])
					break;
			}
			
			var indexOfPrevious:int = i+1;
			
			if ( indexOfPrevious >= __len )
				indexOfPrevious = 0;
			
			var previousSpace:String = spacesList.@id[indexOfPrevious];
			
			return previousSpace;
		}
		
		protected function psNextPrevOverHandler(e:MouseEvent):void
		{
			var nextSpaceLabel:String = getNextSpaceLabel();
					
			panoSaladoToolTip =  nextSpaceLabel || "Next";
		}
		override protected function stageReady(e:Event):void
		{
			super.stageReady(e);
			
			var foreignXML:XML = moduleLoader.xmlByName["PanoSalado"] as XML;
			
			spacesList = foreignXML.spaces.space.( @id.search(/\.preview$/) == -1 );
			
			previewsList = foreignXML.spaces.space.( @id.search(/\.preview$/) > -1 );
			
			__len = spacesList.length();
			
			if (__len > 1) {
				addEventListener(MouseEvent.CLICK, psClickHandler, false, 0, true);
				addEventListener(MouseEvent.MOUSE_OVER, psNextPrevOverHandler, false, 0, true);
			} else {
				enabled = false;
			}
			
			//toolTip =  settings.panoSaladoNextButton.@toolTip || "Next";
			//label = settings.PanoSaladoNextButton.@label || "Next";
		}
		
		private function getNextSpaceLabel():String
		{
			// code to go to previous space
			
			var currentSpace:String = panoSalado.currentSpace;
			
			var idxOfdotPreview:int = currentSpace.search(/\.preview$/);
			if ( idxOfdotPreview > -1)
				currentSpace = currentSpace.substring( 0,idxOfdotPreview );
			
			for (var i:int = 0; i < __len; i++)
			{ 
				if (currentSpace == spacesList.@id[i])
					break;
			}
			
			var indexOfNext:int = i+1;
			
			if ( indexOfNext >= __len )
				indexOfNext = 0;
			
			var nextSpaceLabel:String = spacesList.@label[indexOfNext];
			
			return nextSpaceLabel;
		}
	}
}
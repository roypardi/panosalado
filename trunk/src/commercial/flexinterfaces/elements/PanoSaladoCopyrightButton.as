package commercial.flexinterfaces.elements
{
	import flash.net.*;
	import flash.events.*;
	import flash.system.ApplicationDomain;
	import flash.utils.*;
	import mx.styles.StyleManager;
	import mx.controls.*;
	
	import zephyr.BroadcastEvent;
	import commercial.flexinterfaces.elements.PanoSaladoEnhancedButton;
	
	public class PanoSaladoCopyrightButton extends PanoSaladoEnhancedButton
	{
		protected var spacesList:XMLList;
		
		protected var previewsList:XMLList;
		
		protected var globalCopyright:String = "";
		
		protected var localCopyright:String = "";

		protected var globalCopyrightTooltip:String = "";
		protected var localCopyrightTooltip:String = "";

		protected var globalCopyrightURL:String = "";
		protected var localCopyrightURL:String = "";

		protected var theURLrequest:String = "";
		
		internal var __len:int;
		
		public function PanoSaladoCopyrightButton()
		{
			super();
			
			styleName = 'PanoSaladoCopyrightButton';
			
			addEventListener(Event.ADDED_TO_STAGE, stageReady, false, 0, true);
			addEventListener(MouseEvent.MOUSE_DOWN, interactionHandler, false, 0, true);
		}
		
		override protected function stageReady(e:Event):void
		{
			
			super.stageReady(e);
			
			init();
		}
		
		protected function init():void
		{ 
			var foreignXML:XML = moduleLoader.xmlByName["PanoSalado"] as XML;
			
			spacesList = foreignXML.spaces.space.( @id.search(/\.preview$/) == -1 );
			
			previewsList = foreignXML.spaces.space.( @id.search(/\.preview$/) > -1 );
			
			moduleLoader.addEventListener(BroadcastEvent.SPACE_LOADED, updateOnNewPano, false, 0, true);
			
			globalCopyright = (settings.Copyright.@copyright != undefined) ? settings.Copyright.@copyright : "";

			globalCopyrightTooltip = (settings.Copyright.@toolTip != undefined) ? settings.Copyright.@toolTip : "";

			globalCopyrightURL = (settings.Copyright.@siteURL != undefined) ? settings.Copyright.@siteURL : "";
			
			updateOnNewPano();
		}
		
		protected function updateOnNewPano(e:Event=null):void
		{ 
			var spaceLoaded:String = String(panoSalado.currentSpace);
			var theCopyrightLabel:String;
			var theCopyrightTooltip:String;
			var theCopyrightURL:String;
			
			if (spaceLoaded.search(/\.preview$/) > -1)
				spaceLoaded = spaceLoaded.substring( 0 , spaceLoaded.search(/\.preview$/) );
			
			localCopyright = spacesList.(hasOwnProperty("@id") && @id == spaceLoaded).Copyright.@copyright;

			localCopyrightTooltip = spacesList.(hasOwnProperty("@id") && @id == spaceLoaded).Copyright.@toolTip;

			localCopyrightURL = spacesList.(hasOwnProperty("@id") && @id == spaceLoaded).Copyright.@siteURL;
			
			theCopyrightLabel = (localCopyright != "" && localCopyright != null) ? localCopyright : globalCopyright;
			theCopyrightTooltip = (localCopyrightTooltip != "" && localCopyrightTooltip != null) ? localCopyrightTooltip : globalCopyrightTooltip;
			theCopyrightURL = (localCopyrightURL != "" && localCopyrightURL != null) ? localCopyrightURL : globalCopyrightURL;
			
			if (theCopyrightLabel != "") {
				label = "\u00A9 " + theCopyrightLabel;
				panoSaladoToolTip =  theCopyrightTooltip || "Go to "+theCopyrightURL;
			}
			if (theCopyrightURL != "") {
				theURLrequest = theCopyrightURL;
			}
		}

		private function interactionHandler(e:MouseEvent):void
		{
			e.stopImmediatePropagation();
			if (theURLrequest != "") {
				navigateToURL( new URLRequest(theURLrequest), "_blank" );
			}
			
		}
	}
}
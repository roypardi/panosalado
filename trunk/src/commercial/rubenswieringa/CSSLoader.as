package commercial.rubenswieringa {
	
	
	import commercial.rubenswieringa.CSSParser;
	
	import flash.text.StyleSheet;
	
	import mx.rpc.http.HTTPService;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.events.FaultEvent;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	
	// event declarations:
	/**
	 * Dispatched when CSSLoader starts loading a CSS file.
	 * 
	 * @eventType	CSSLoader.LOAD_INIT
	 */
	[Event(name="load init", type="mx.events.Event")]
	/**
	 * Dispatched when a CSS file is loaded succesfully.
	 * 
	 * @eventType	CSSLoader.RESULT
	 */
	[Event(name="loaded", type="mx.events.Event")]
	/**
	 * Dispatched when there was an error while trying to load a CSS file.
	 * 
	 * @eventType	CSSLoader.FAULT
	 */
	[Event(name="load fault", type="mx.events.Event")]
	/**
	 * Dispatched when a parsing error occurs within CSSParser.
	 * 
	 * @see	CSSParser
	 * 
	 * @eventType	CSSParser.ERROR
	 */
	[Event(name="parse error", type="mx.events.Event")]
	
	
	/**
	 * Enables runtime loading of css files in Actionscript 3.0
	 * 
	 * @author		Ruben Swieringa
	 * 				ruben.swieringa@gmail.com
	 * 				www.rubenswieringa.com
	 * @version		1.1.1
	 * @see			CSSParser
	 * 
	 * 
	 * @internal
	 * 	Before modifying and/or redistributing this class, please contact Ruben Swieringa (ruben.swieringa@gmail.com)
	 * 
	 * 
	 * View code documentation at:
	 *  http://www.rubenswieringa.com/code/as3/flex/CSSLoader/docs/
	 * 
	 */
	public class CSSLoader extends EventDispatcher {
		
		
		private var styleSheets:XML;
		private var httpServices:Object;
		private var _lastLoadedName:String;
		private var parser:CSSParser;
		private var applyTo:Object;
		
		public static const LOAD_INIT:String = "onCSSLoadInit";
		public static const RESULT:String = "onCSSLoaded";
		public static const FAULT:String = "onCSSFault";
		
		
		/**
		 * Constructor.
		 */
		public function CSSLoader ():void {
			
			this.styleSheets = <styleSheets></styleSheets>;
			this.httpServices = {};
			this.applyTo = {};
			
			this.parser = new CSSParser();
			this.parser.addEventListener(CSSParser.ERROR, onCSSParseError);
			
		}
		
		
		/**
		 * Loads a css file.
		 * 
		 * @param	url		path of the css file
		 * @param	name	name for the stylesheet within the class [optional]
		 * @param	...		DisplayObject(s) to apply the loaded stylesheet to, note that the stylesheet will also be applied to the DisplayObjects' their children (use the RESULT event and applyStyle method if this is not what you want)
		 * 
		 */
		public function load (url:String, name:String="", ...args):void {
			
			if (name == ""){
				name = url.split('.')[0].split('/').reverse()[0];
			}
			
			this.prepareLoad(name, url, args);
			
			if (this.httpServices[name] == null){
				this.httpServices[name] = this.getNewHTTPService();
			}
			this.httpServices[name].url = url;
			this.httpServices[name].send();
			
			this.dispatchEvent(new Event(CSSLoader.LOAD_INIT));
			
		}
		/**
		 * Similar to the load function, the difference being that loadString takes the String content, where load takes a String URL.
		 * 
		 * @param	raw		the plain text stylesheet from a css file
		 * @param	name	name for the stylesheet within the class [optional]
		 * @param	...		DisplayObject(s) to apply the loaded stylesheet to, note that the stylesheet will also be applied to the DisplayObjects' their children
		 * 
		 * @see		CSSLoader#load()
		 * 
		 */
		public function loadString (raw:String, name:String, ...args):void {
			
			var url:String = "LOADSTRING:" + name;
	 		this.prepareLoad(name, url, args);
	 		this.processResult(url, raw);
	 		
		}
		
		
		/**
		 * Event-handler for the HTTPService instance, stores the stylesheet and broadcasts an Event.
		 * 
		 * @see	CSSParser#parse()
		 * @see	CSSLoader#applyStyle()
		 * 
		 * @private
		 */
		protected function onCSSLoaded (event:ResultEvent):void {
			
			this.processResult(event.target.url, String(event.result));
			
			this.dispatchEvent(new Event(CSSLoader.RESULT));
			
		}
		/**
		 * Event-handler for the HTTPService instance, broadcasts an Event.
		 * @private
		 */
		protected function onCSSFault (event:FaultEvent):void {
			
			this.dispatchEvent(new Event(CSSLoader.FAULT));
			
		}
		/**
		 * Event-handler for the CSSParser instance, broadcasts an Event.
		 * @private
		 */
		protected function onCSSParseError (event:Event):void {
			
			this.dispatchEvent(new Event(CSSParser.ERROR));
			
		}
		
		
		/**
		 * Creates a new node in the styleSheets XML property if necessary and stores the Array of DisplayObjects to which to apply the style declarations to.
		 * 
		 * @param	name			Identifier for the to be created stylesheet
		 * @param	url				URL for the stylesheet
		 * @param	displayObjects	Array of DisplayObjects to which the stylesheet needs to be applied after loading has finished
		 * 
		 * @private
		 */
		protected function prepareLoad (name:String, url:String, displayObjects:Array):void {
			
			if (this.styleSheets.styleSheet.(@name==name).length() == 0){
				var styleSheet:XML = <styleSheet name={name} url={url} loaded="false"></styleSheet>;
				this.styleSheets.appendChild(styleSheet);
			}else{
				this.styleSheets.styleSheet.(@name==name)[0].@url = url;
			}
			
			for (var i:String in displayObjects){
				if (this.applyTo[name] == null){
					this.applyTo[name] = [];
				}
				this.applyTo[name].push(displayObjects[i]);
			}
			
		}
		/**
		 * Parses the plain text style declarations and stores the resulting XML in the styleSheets property, also aplpies the resulting styles.
		 * 
		 * @param	url	URL of the stylesheet to be processed
		 * @param	css	Plain text stylesheet to be processed
		 * 
		 * @private
		 */
		protected function processResult (url:String, css:String):void {
			
		 	var index:int =		this.styleSheets.styleSheet.(@url==url)[0].childIndex();
			var name:String =	this.styleSheets.styleSheet[index].@name;
			var url:String =	this.styleSheets.styleSheet[index].@url;
			
			var parsedCSS:XML = this.parser.parse(css);
			if (parsedCSS == null){
				trace("parsedCSS returned null");
				return;
			}
			
			this.styleSheets.replace(index, parsedCSS);
			
			this.styleSheets.styleSheet[index].@name =	name;
			this.styleSheets.styleSheet[index].@url =	url;
			
			this._lastLoadedName = name;
			
			for (var i:String in this.applyTo[name]){
				this.applyStyle(name, this.applyTo[name][i], true);
			}
			this.applyTo[name] = [];
			
		}
		
		
		/**
		 * Creates a new instance of the HTTPService class.
		 * 
		 * @see	CSSLoader#load()
		 * 
		 * @return	the created httpservice instance
		 * 
		 * @private
		 */
		protected function getNewHTTPService ():HTTPService {
			
			var httpService:HTTPService = new HTTPService();
			httpService.resultFormat = "text";
			httpService.useProxy = false;
			httpService.addEventListener(ResultEvent.RESULT, onCSSLoaded);
			httpService.addEventListener(FaultEvent.FAULT, onCSSFault);	
			
			return httpService;
			
		}
		
		
		/**
		 * Applies the specified stylesheet to the specified DisplayObject.
		 * 
		 * @param	css				the name of the stylesheet (must have finished loading!)
		 * @param	displayObj		the DisplayObject to which to apply the stylesheet
		 * @param	applyToChildren	whether or not to apply the stylesheet to the DisplayObject's children (if any) [optional]
		 * 
		 */
		public function applyStyle (css:String, displayObj:*, applyToChildren:Boolean=false):void { // leave displayObj untyped in order to prevent compiler-errors
			
			this.applyStyleToOne (css, displayObj);
			
			if (applyToChildren && displayObj.hasOwnProperty("getChildren") && displayObj.numChildren > 0){
				var children:Array = displayObj.getChildren();
				for (var i:int=0; i<children.length; i++){
					this.applyStyle(css, children[i], true);
				}
			}
			
		}
		/**
		 * Applies the last loaded stylesheet to the specified DisplayObject.
		 * 
		 * @see	CSSLoader#applyStyle()
		 * 
		 * @param	displayObj		the DisplayObject to which to apply the stylesheet
		 * @param	applyToChildren	whether or not to apply the stylesheet to the DisplayObject's children (if any) [optional]
		 * 
		 */
		public function applyLastLoadedStyle (displayObj:DisplayObject, applyToChildren:Boolean=false):void {
			
			this.applyStyle (_lastLoadedName, displayObj, applyToChildren);
			
		}
		/**
		 * Applies the specified stylesheet to the specified DisplayObject (typically called by either applyStyle or applyLastLoadedStyle).
		 * 
		 * @see	CSSLoader#applyStyle()
		 * 
		 * @param	css				the name of the stylesheet (must have finished loading!)
		 * @param	displayObj		the DisplayObject to which to apply the stylesheet
		 * 
		 * @private
		 */
		protected function applyStyleToOne (css:String, displayObj:*):void { // leave displayObj untyped for preventing compiler-errors
			
			var n:String = displayObj.className;
			var p:String = null;
			var i:String = displayObj.id;
			var c:String = displayObj.styleName;
			
			var style:XMLList;
			
			if (c==null) style = this.styleSheets.styleSheet.(@name==css).style.(selectors.selector.((@name=='' || @name==n) && (@id=='' || @id==i) &&  @_class=='').length() > 0);
			if (c!=null) style = this.styleSheets.styleSheet.(@name==css).style.(selectors.selector.((@name=='' || @name==n) && (@id=='' || @id==i) && (@_class=='' || @_class==c)).length() > 0);
			
			for each (var property:XML in style.properties.property) {
				
				var setToValue:*;
				if ( property.@value.indexOf(",")>-1 )
				{
					var arr:Array = property.@value.split(',') as Array;
					setToValue = new Array();
					for each (var str:String in arr)
					{
						if ( str.match(/[a-zA-Z]/) ) { setToValue.push(str); }
						else { setToValue.push( Number(str) ); }
					}
				}
				else
				{
					if ( property.@value.match(/[a-zA-Z]/) )
					{
						setToValue = property.@value.toString();
					}
					else
					{
						setToValue = Number(property.@value);
					}
				}
				//displayObj.setStyle(property.@name, (property.@value.indexOf(",")>-1) ? property.@value.split(',') : property.@value.toString());
				displayObj.setStyle(property.@name, setToValue );
			}
			
		}
		
		
		/**
		 * Removes the specified stylesheet (must have finished loading!).
		 * 
		 * @param	name	the name of the stylesheet to be removed
		 * 
		 * @return	whether or not the specified stylesheet was found
		 * 
		 */
		public function removeStyle (name:String):Boolean {
			
			if (this.styleSheets.styleSheet.(@name==name && @loaded=='true').length() == 0){
				return false; // no styleSheet with this name
			}
			
			delete this.styleSheets.styleSheet.(@name==name)[0];
			
			return true;
			
		}
		
		
		/**
		 * Enlists all stylesheets (both loaded and still loading).
		 * 
		 * @return		an Array with the names of all stylesheets
		 * 
		 */
		public function getAllStyleNames ():Array {
			
			var namesXML:XMLList = this.styleSheets.styleSheet.@name
			var namesArray:Array = [];
			
			for (var i:int=0; i<namesXML.length(); i++){
				namesArray.push(namesXML[i]);
			}
			
			return namesArray;
			
		}
		
		
		/**
		 * Returns a StyleSheet instance containing all the style declarations from the specified stylesheet.
		 * 
		 * @param	css	Name identifier of a loaded stylesheet
		 * 
		 * @return	StyleSheet
		 * 
		 */
		public function getHTMLStyleSheet (css:String):StyleSheet {
			
			var styleSheet:StyleSheet = new StyleSheet();
			var styles:XMLList = this.styleSheets.styleSheet.(@name==css).style;
			
			// loop through all the styles of the CSS file:
			for each (var style:XML in styles){
				var styleObj:Object = {};
				// and create Object with all properties:
				for each (var property:XML in style.properties.property){
					styleObj[property.@name] = (property.@name.toString() != "color") ? property.@value : "#" + property.@value.toString().slice(2);
				}
				// loop through all selectors and apply properties Object to them:
				for each (var selector:XML in style.selectors.selector){
					// if there already was a selector with that name in the StyleSheet, maintain the original properties as well:
					var originalStyleObj:Object = styleSheet.getStyle(this.createSelector(selector));
					for (var i:String in styleObj){
						originalStyleObj[i] = styleObj[i];
					}
					// apply the style Object:
					styleSheet.setStyle(this.createSelector(selector), originalStyleObj);
				}
			}
			
			return styleSheet;
		}
		/**
		 * Returns a string that can be used as a selector for a StyleSheet.
		 * 
		 * @private
		 */
		protected function createSelector (selector:XML):String {
			
			var str:String = selector.@name;
			
			if (selector.@id != "")		str += "#" + selector.@id;
			if (selector.@_class != "")	str += "." + selector.@_class;
			if (selector.@pseudo != "")	str += ":" + selector.@pseudo;
			
			return str;
		}
		
		
		/**
		 * The name of the last loaded stylesheet.
		 */
		public function get lastLoadedName ():String {
			return this._lastLoadedName;
		}
		
		
	}
	
	
}

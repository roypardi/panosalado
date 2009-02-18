package commercial.rubenswieringa {
	
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	
	// event declarations:
	/**
	 * Dispatched when a parsing error occurs.
	 * 
	 * @eventType	CSSParser.ERROR
	 */
	[Event(name="parse error", type="mx.events.Event")]
	
	
	/**
	 * Parses plain text stylesheets into XML.
	 * For notes on what css syntax is allowed, please look at the CSSLoader source at:
	 *  http://www.rubenswieringa.com/code/as3/flex/CSSLoader/source/
	 * 
	 * @author		Ruben Swieringa
	 * 				ruben.swieringa@gmail.com
	 * 				www.rubenswieringa.com
	 * @version		1.1.1
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
	public class CSSParser extends EventDispatcher {
		
		
		public static const ERROR:String = "onCSSParseError";
		
		protected static const COMMENTS:RegExp = /\/\*[a-z0-9\s\n\!@#$%^&*()-_=+\[\]\\|:;'",.<>\/\?]*\*\//ig;
		protected static const WHITESPACE:RegExp = /[\s\n]*/ig;
		
		protected static const PIXELVALUE_SEARCH:RegExp = /[0-9]*px/ig;
		protected static const PIXELVALUE_REPLACE:RegExp = /([0-9]*)px/ig;
		
		protected static const COLORVALUE:RegExp = /#{1}(([a-f0-9]){3}(([a-f0-9]){3})?)/i;
		protected static const COLORVALUE_SHORTHAND:RegExp = /0x([a-f0-9]{1})([a-f0-9]{1})([a-f0-9]{1})/i;
		protected static const COLORKEYS:Object = {	black: "0x000000",
													blue: "0x0000FF",
													green: "0x00FF00",
													red: "0xFF0000",
													fuchsia: "0xFF00FF",
													cyan: "0x00FFFF",
													yellow: "0xFFFF00",
													white: "0xFFFFFF" };
		
		protected static const EMBED_START:String =	"@Embed(";
		protected static const EMBED_END:String =	")";
		
		
		/**
		 * constructor
		 */
		public function CSSParser ():void {
			
			//
			
		}
		
		
		/**
		 * parses the plain text stylesheet from a css file
		 * 
		 * @param	raw		the plain text stylesheet from a css file
		 * 
		 * @return	the stylesheet in xml format
		 * 
		 */
		public function parse (raw:String):XML {
			
			// remove linebreaks, whitespaces, and comments from the css:
			raw = raw.replace(CSSParser.COMMENTS, "");
			raw = raw.replace(CSSParser.WHITESPACE, "");
			
			if (raw.indexOf('/*') > -1){
				this.dispatchEvent(new Event(CSSParser.ERROR));
				return null;
			}
			
			// parse clean css data:
			var styleSheet:XML =	<styleSheet name="" url="" loaded="true"></styleSheet>;
			var style:XML;
			var rawStyles:Array = raw.split('}');
			rawStyles.splice(rawStyles.length-1, 1);
			for (var i:int=0; i<rawStyles.length; i++){
				style =	<style>
							<selectors>
							</selectors>
							<properties>
							</properties>
						</style>;
				var stylePortions:Array = rawStyles[i].split('{');
				var selectors:Array = stylePortions[0].split(',');
				for (var s:String in selectors){
					style.selectors.appendChild(this.parseSelector(selectors[s]));
				}
				var properties:Array = stylePortions[1].split(';');
				properties.pop(); // remove empty line
				if (properties.length == 0){
					continue; // if there are no style-declarations in it, it's useless
				}
				for (var p:String in properties){
					style.properties.appendChild(this.parseProperty(properties[p]));
				}
				styleSheet.appendChild(style);
			}
			
			return styleSheet;
			
		}
		
		
		/**
		 * parses a plain text selector from a css file
		 * 
		 * @see	#parse()
		 * 
		 * @param	element		a plain text selector from a css file
		 * 
		 * @return	the selector in xml format
		 * 
		 * @private
		 */
		protected function parseSelector (element:String):XML {
			
			// example: Button.highlighted
			// example: Button#topBtn
			// example:	a:hover
			var n:String; // selector (ie 'Button' or 'a')
			var p:String; // pseudo-selector (ie 'hover')
			var i:String; // id (ie 'topBtn')
			var c:String; // class (ie 'highlighted')
			
			n = element.split('.')[0].split('#')[0];
			if (n.indexOf(':') > -1){
				p = n.split(':')[1];
				n = n.split(':')[0];
			}
			i = element.split('#')[1];
			c = element.split('.')[1];
			
			if (n == null) n = '';
			if (p == null) p = '';
			if (i == null) i = '';
			if (c == null) c = '';
			
			if (n == '*') n = '';
			
			var node:XML = <selector name={n} pseudo={p} id={i} _class={c} />;
			
			return node;
			
		}
		
		
		/**
		 * parses a plain text property/value pair from a css file
		 * 
		 * @see	#parse()
		 * @see	#parseValue()
		 * 
		 * @param	property	a plain text property/value pair from a css file
		 * 
		 * @return	the pair in xml format
		 * 
		 * @private
		 */
		protected function parseProperty (property:String):XML {
			
			var splitAt:int = property.indexOf(':');
			var pair:Array = [];
			pair.push(property.slice(0, splitAt));
			pair.push(property.slice(splitAt+1));
			
			if (pair[1].indexOf(',') > -1){
				pair[1] = pair[1].split(',');
				for (var i:String in pair[1]){
					pair[1][i] = this.parseValue(pair[1][i]);
				}
				pair[1] = pair[1].join(',');
			}else{
				pair[1] = this.parseValue(pair[1]);
			}
			
			var node:XML = <property name={pair[0]} value={pair[1]} />
			
			return node;
			
		}
		
		
		/**
		 * parses a value from a css file
		 * 
		 * @see	#parseProperty()
		 * 
		 * @param	value	a value from a css file
		 * 
		 * @return	the value in accepted format
		 * 
		 * @private
		 */
		protected function parseValue (value:String):String {
			
			// '33px' -> '33'
			if (value.search(CSSParser.PIXELVALUE_SEARCH) > -1){
				value = value.replace(CSSParser.PIXELVALUE_REPLACE, "$1");
				return value;
			}
			
			// '#ff0000' -> '0xff0000'
			// '#f00'	 -> '0xff0000'
			if (value.search(CSSParser.COLORVALUE) > -1){
				value = value.replace(CSSParser.COLORVALUE, "0x$1");
				if (value.length == 5){
					value = value.replace(CSSParser.COLORVALUE_SHORTHAND, "0x$1$1$2$2$3$3");
				}
				return value;
			}
			
			// 'red' -> '0xff0000'
			var keys:Object = CSSParser.COLORKEYS;
			for (var i:String in keys){
				if (i == value.toLowerCase()){
					return keys[i];
				}
			}
			
			// ''img.png'' -> 'img.png'
			// '"img.png"' -> 'img.png'
	 		if ((value.slice(0, 1) == "\"" && value.slice(-1) == "\"") || (value.slice(0, 1) == "'" && value.slice(-1) == "'")){
				return value.slice(1, value.length-1);
			}
			
			return value;
			
		}
		
		
	}
	
	
}
package com.panosalado.utils {
	
	import flash.utils.*;
	import flash.xml.XMLDocument;
	
	public class XMPFileBase {
		protected	var _valid:Boolean 	= false;
		protected	var _hasXmp:Boolean = false;
		protected	var _hasThumb:Boolean = false;
		protected	var _xmp:XMLDocument = null; //XMPMeta = null;
		internal	var _xmp_was_read:Boolean = false;
		
		internal	var thumbnails:Array	= [];
		
		protected	var _data:ByteArray;
		
		public function get xmp():XMLDocument	{ return _xmp; }
		public function get hasXmp():Boolean	{ return _hasXmp; }
		public function get hasThumb():Boolean	{ return thumbnails.length > 0; }
		public function get valid():Boolean		{ return _valid; }
		
		public function XMPFileBase(fileData:ByteArray) {
			_data	= fileData;
			_valid  = true;
		}
		
		public function readPacket():Boolean {
			return false;
		}
	}
}
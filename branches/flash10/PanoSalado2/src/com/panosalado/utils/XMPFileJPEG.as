package com.panosalado.utils {
	
	import flash.utils.*;
	import flash.xml.XMLDocument;
	
	public class XMPFileJPEG extends XMPFileBase
	{
		private var markers:Array = [];
//		private var exif:TIFFStructure;
		public var width:int = -1;
		public var height:int = -1;
			
		public function XMPFileJPEG(data:ByteArray)
		{			
			super(data);
			
			if (_valid) {
				readPacket();
			}
		}
		
		override public function readPacket():Boolean
		{
			if (_valid) {
				thumbnails = [];
				_hasXmp = false;
				
				if (_data.bytesAvailable > 0) {
					_data.endian = Endian.LITTLE_ENDIAN;
					
					var _binaryPacket:ByteArray;
					var thisMarker:JPEGMarker;
					
					markers = [];
					
					do {
						thisMarker = new JPEGMarker(_data);
						markers.push(thisMarker);
						
					} while (thisMarker && thisMarker.isMarker);
					
					var exif_bytes:ByteArray = new ByteArray();
					var extensions:Array = [];
					
					for each(thisMarker in markers) {
						if (thisMarker.name == "http://ns.adobe.com/xap/1.0/") {
							_binaryPacket = thisMarker.getPayload(_data);
							_xmp = new XMLDocument(_binaryPacket.toString());
							_hasXmp = true;
						}
						if (thisMarker.description.search("Start Of Frame markers") == 0) {
							_data.position = thisMarker.position_start + 5;
							height	= _data.readUnsignedShort();
							width	= _data.readUnsignedShort();
						}
						
						/*
						if (thisMarker.name == "http://ns.adobe.com/xmp/extension/") {
							extensions.push(thisMarker.getPayload(_data));
						}
						
						if (thisMarker.name == "Exif") {
							exif_bytes.writeBytes(thisMarker.getPayload(_data));
						}
						*/
					}
					
					/*
					if (exif_bytes.length > 0) {
						exif = new TIFFStructure(exif_bytes);
						var o:Object = exif.getThumbnail(exif_bytes);
						if (o) thumbnails.push(o);
					}
					*/
					
					/*
					if (extensions.length > 0) {
						var ns:Namespace = XMPConst.xmpNote;
						var needed_md5:String = _xmp.ns::HasExtendedXMP;
						
						if(needed_md5.length == 32) {
							var extension_md5:String = "";
							var extension_length:int = 0;
							var extension_offset:int = 0;
							
							var needed_extensions:Array = [];
							var ba:ByteArray;
									
							for each (ba in extensions) {
								extension_md5 		= ba.readUTFBytes(32);
								extension_length	= ba.readUnsignedInt();
								extension_offset	= ba.readUnsignedInt();
								
								if (extension_md5 == needed_md5) {
									needed_extensions.push({md5:extension_md5, length:extension_length, offset:extension_offset, bytes:ba});
								}
							}
							
							if (needed_extensions.length > 0) {
								needed_extensions = needed_extensions.sortOn("offset", Array.NUMERIC);
								
								var extension_ba:ByteArray = new ByteArray();
								
								for each (ba in extensions) {
									extension_ba.writeBytes(ba, 40);
								}
								
								var extension_xmp:XMPMeta = new XMPMeta(extension_ba);
			
								for each (var node:XMPNode in extension_xmp) {
									copyNode(_xmp, extension_xmp);
								}
							}
						}
					}
					*/
					
					return true;
				}
			}
			
			return false;
		}

		/*
		private function copyNode(dest:XMPMeta, source:XMPMeta, uri:String= ""):void{
			var ns:Namespace = uri != "" ? new Namespace(uri) : null;
			
			for each (var xmp_node:XMPNode in source){
				if(uri == "") 
					ns = new Namespace(xmp_node.qname.uri);
					
				if(xmp_node.qname.uri == uri || uri == "")
					dest.ns::[xmp_node.qname.localName] = xmp_node;
			}
		}
		*/
	}
}
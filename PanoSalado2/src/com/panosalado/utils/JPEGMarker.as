package com.panosalado.utils {
	import flash.utils.*;
	
	public class JPEGMarker {
		public var type_nr:uint		= 0;
		public var length:uint		= 0;
		public var nameLength:uint	= 0;
		public var isMarker:Boolean	= false;
		public var name:String		= "";
		
		public var position_start:uint 	= 0;
		public var position_next:uint 	= 0;
		
		public function get payloadPositionStart():uint {	return position_start + 2 + 2 + nameLength;	}
		public function get payloadLength():uint 		{	return (length > 2 + nameLength) ? length - 2 - nameLength : 0;	}
		
		public function JPEGMarker(fileStream:ByteArray = null) 
		{
			if(!fileStream) return ;
			
			position_start	= fileStream.position;
			fileStream.endian = Endian.BIG_ENDIAN;
			
			if (fileStream.readUnsignedByte() == 0xFF) { // Marker Found
				isMarker	= true;
				type_nr		= fileStream.readUnsignedByte();
				
				if(!isStandalone){
					length			= fileStream.readUnsignedShort();
					
					var char:String = "";
					
					do {
						char = fileStream.readUTFBytes(1);
						name += char;
						nameLength++;
					} while (char != "");
					if(name == "Exif") nameLength++;
					
					position_next 	= position_start + 2 + length;
				} else position_next = position_start + 2;
			}
			
			fileStream.position = position_next;
		}

		public function getMarkerPacket(fileStream:ByteArray):ByteArray {
			var ba:ByteArray = new ByteArray();
				
			var pos:uint = fileStream.position;
			fileStream.position = position_start;
			
			if(!isStandalone)	fileStream.readBytes(ba, 0, length + 2);
			else 				fileStream.readBytes(ba, 0, 2);
				
			fileStream.position = pos;
			
			return ba;
		}
		public function getMarkerPacketAsString(fileStream:ByteArray):String {
			var ret:String = "";
				
			var pos:uint = fileStream.position;
			fileStream.position = payloadPositionStart;
			
			if(!isStandalone)	ret = fileStream.readUTFBytes(payloadLength);
				
			fileStream.position = pos;
			
			return ret;
		}
		public function getPayload(fileStream:ByteArray):ByteArray {
			var ba:ByteArray = new ByteArray();
				
			if(!isStandalone){
				var pos:uint = fileStream.position;
				
				fileStream.position = payloadPositionStart;
				fileStream.readBytes(ba, 0, length - (2 + nameLength));
				
				fileStream.position = pos;
			}
			
			return ba;
		}
		
		public function get isStandalone():Boolean {
			return (type_nr >= 0xD0 && type_nr <= 0xD9) || type_nr == 0x01;
		}
		
		public function get id():String{
			return get_id(type_nr);
		}
		static public function get_id(type_nr:uint):String{
			switch (type_nr){
				case 0xC0 :	return "Sof_0";
				case 0xC1 :	return "Sof_1";
				case 0xC2 :	return "Sof_2";
				case 0xC3 :	return "Sof_3";
				case 0xC5 :	return "Sof_5";
				case 0xC6 :	return "Sof_6";
				case 0xC7 :	return "Sof_7";
				case 0xC8 :	return "JPG";
				case 0xC9 :	return "Sof_9";
				case 0xCA :	return "Sof_10";
				case 0xCB :	return "Sof_11";
				case 0xCD :	return "Sof_13";
				case 0xCE :	return "Sof_14";
				case 0xCF :	return "Sof_15";
				case 0xC4 :	return "DHT";
				case 0xCC :	return "DAC";
				case 0xD0 :	return "RST_0";
				case 0xD1 :	return "RST_1";
				case 0xD2 :	return "RST_2";
				case 0xD3 :	return "RST_3";
				case 0xD4 :	return "RST_4";
				case 0xD5 :	return "RST_5";
				case 0xD6 :	return "RST_6";
				case 0xD7 :	return "RST_7";
				case 0xD8 :	return "SOI";
				case 0xD9 :	return "EOI";
				case 0xDA :	return "SOS";
				case 0xDB :	return "DQT";
				case 0xDC :	return "DNL";
				case 0xDD :	return "DRI";
				case 0xDE :	return "DHP";
				case 0xDF :	return "EXP";
				case 0xE0 :	return "APP_0";
				case 0xE1 :	return "APP_1";
				case 0xE2 :	return "APP_2";
				case 0xE3 :	return "APP_3";
				case 0xE4 :	return "APP_4";
				case 0xE5 :	return "APP_5";
				case 0xE6 :	return "APP_6";
				case 0xE7 :	return "APP_7";
				case 0xE8 :	return "APP_8";
				case 0xE9 :	return "APP_9";
				case 0xEA :	return "APP_10";
				case 0xEB :	return "APP_11";
				case 0xEC :	return "APP_12";
				case 0xED :	return "APP_13";
				case 0xEE :	return "APP_14";
				case 0xEF :	return "APP_15";
				case 0xF0 :	return "JPG_0";
				case 0xF1 :	return "JPG_1";
				case 0xF2 :	return "JPG_2";
				case 0xF3 :	return "JPG_3";
				case 0xF4 :	return "JPG_4";
				case 0xF5 :	return "JPG_5";
				case 0xF6 :	return "JPG_6";
				case 0xF7 :	return "JPG_7";
				case 0xF8 :	return "JPG_8";
				case 0xF9 :	return "JPG_9";
				case 0xFA :	return "JPG_10";
				case 0xFB :	return "JPG_11";
				case 0xFC :	return "JPG_12";
				case 0xFD :	return "JPG_13";
				case 0xFE :	return "COM";
			}
			
			return "Unknown";
		}
		public function get description():String{
			return get_description(type_nr);
		}
		static public function get_description(type_nr:uint):String{
			switch (type_nr){
				case 0xC0 :	return "Start Of Frame markers, non-differential, Huffman coding - Baseline DCT";
				case 0xC1 :	return "Start Of Frame markers, non-differential, Huffman coding - Extended sequential DCT";
				case 0xC2 :	return "Start Of Frame markers, non-differential, Huffman coding - Progressive DCT";
				case 0xC3 :	return "Start Of Frame markers, non-differential, Huffman coding - Lossless (sequential)";
				case 0xC5 :	return "Start Of Frame markers, differential, Huffman coding Differential sequential DCT";
				case 0xC6 :	return "Start Of Frame markers, differential, Huffman coding Differential progressive DCT";
				case 0xC7 :	return "Start Of Frame markers, differential, Huffman coding Differential lossless (sequential)";
				case 0xC8 :	return "Start Of Frame markers, non-differential, arithmetic coding - Reserved for JPEG extensions";
				case 0xC9 :	return "Start Of Frame markers, non-differential, arithmetic coding - Extended sequential DCT";
				case 0xCA :	return "Start Of Frame markers, non-differential, arithmetic coding - Progressive DCT";
				case 0xCB :	return "Start Of Frame markers, non-differential, arithmetic coding - Lossless (sequential)";
				case 0xCD :	return "Start Of Frame markers, differential, arithmetic coding - Differential sequential DCT";
				case 0xCE :	return "Start Of Frame markers, differential, arithmetic coding - Differential progressive DCT";
				case 0xCF :	return "Start Of Frame markers, differential, arithmetic coding - Differential lossless (sequential)";
				case 0xC4 :	return "Huffman table specification - Define Huffman table(s)";
				case 0xCC :	return "Arithmetic coding conditioning specification - Define arithmetic coding conditioning(s)";
				case 0xD0 :	return "Restart interval termination - Restart with modulo 8 count 0";
				case 0xD1 :	return "Restart interval termination - Restart with modulo 8 count 1";
				case 0xD2 :	return "Restart interval termination - Restart with modulo 8 count 2";
				case 0xD3 :	return "Restart interval termination - Restart with modulo 8 count 3";
				case 0xD4 :	return "Restart interval termination - Restart with modulo 8 count 4";
				case 0xD5 :	return "Restart interval termination - Restart with modulo 8 count 5";
				case 0xD6 :	return "Restart interval termination - Restart with modulo 8 count 6";
				case 0xD7 :	return "Restart interval termination - Restart with modulo 8 count 7";
				case 0xD8 :	return "Start of image";
				case 0xD9 :	return "End of image";
				case 0xDA :	return "Start of scan";
				case 0xDB :	return "Define quantization table";
				case 0xDC :	return "Define number of lines";
				case 0xDD :	return "Define restart interval";
				case 0xDE :	return "Define hierarchical progression";
				case 0xDF :	return "Expand reference component";
				case 0xE0 :	return "Application segment 0";
				case 0xE1 :	return "Application segment 1";
				case 0xE2 :	return "Application segment 2";
				case 0xE3 :	return "Application segment 3";
				case 0xE4 :	return "Application segment 4";
				case 0xE5 :	return "Application segment 5";
				case 0xE6 :	return "Application segment 6";
				case 0xE7 :	return "Application segment 7";
				case 0xE8 :	return "Application segment 8";
				case 0xE9 :	return "Application segment 9";
				case 0xEA :	return "Application segment 10";
				case 0xEB :	return "Application segment 11";
				case 0xEC :	return "Application segment 12";
				case 0xED :	return "Application segment 13";
				case 0xEE :	return "Application segment 14";
				case 0xEF :	return "Application segment 15";
				case 0xF0 :	return "JPEG extensions segment 0";
				case 0xF1 :	return "JPEG extensions segment 1";
				case 0xF2 :	return "JPEG extensions segment 2";
				case 0xF3 :	return "JPEG extensions segment 3";
				case 0xF4 :	return "JPEG extensions segment 4";
				case 0xF5 :	return "JPEG extensions segment 5";
				case 0xF6 :	return "JPEG extensions segment 6";
				case 0xF7 :	return "JPEG extensions segment 7";
				case 0xF8 :	return "JPEG extensions segment 8";
				case 0xF9 :	return "JPEG extensions segment 9";
				case 0xFA :	return "JPEG extensions segment 10";
				case 0xFB :	return "JPEG extensions segment 11";
				case 0xFC :	return "JPEG extensions segment 12";
				case 0xFD :	return "JPEG extensions segment 13";
				case 0xFE :	return "Comment";
			}
			
			return "Unknown";
		} 

	}
}
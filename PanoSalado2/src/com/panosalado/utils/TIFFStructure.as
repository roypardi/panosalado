package com.panosalado.utils {
	import flash.utils.*;
	
	public class TIFFStructure 
	{
		internal var all_idfs:Array			= [];
		
		internal var sub_idfs:Array			= [];
		internal var sub_leaf_idfs:Array	= [];
		
		internal var idf0:IDF;
		
		internal var exif_idf:IDF;
		internal var gp_idf:IDF;
		internal var gps_idf:IDF;
		internal var interop_idf:IDF;
		
		internal var endian:String = Endian.BIG_ENDIAN;

		public function TIFFStructure(stream:ByteArray) {
			var read_str:String;
			var read_uint:uint;
			var read_int:int;
			
			var idf0_pos:uint;
		
			stream.position = 0;
			
			read_str = stream.readUTFBytes(2);	//	trace("Endian marker: " + read_str);
			if(read_str == "MM" || read_str == "II"){
				stream.endian = endian = (read_str == "II" ? Endian.LITTLE_ENDIAN : Endian.BIG_ENDIAN);
				
				read_uint = stream.readUnsignedShort();	//	trace("Endian check (42): " + read_uint);
				if(read_uint == 42){
					idf0_pos = stream.readUnsignedInt();	//	trace("IDF0 pos: " + idf0_pos);
					stream.position = idf0_pos;
					
					idf0 = readIDFs(this, null, stream, idf0_pos);
				}
			}
		}
		
		public function getThumbnail(stream:ByteArray):Object 
		{
			var JPEGInterchangeFormat:uint			= getProperyAsUInt(513);
			var JPEGInterchangeFormatLength:uint	= getProperyAsUInt(514);
			var Compression:uint					= getProperyAsUInt(259);
			
			try {
				if(JPEGInterchangeFormat != uint.MAX_VALUE && JPEGInterchangeFormatLength != uint.MAX_VALUE){
					var thumb_bytes:ByteArray = new ByteArray();
					
					stream.position = JPEGInterchangeFormat;
					stream.readBytes(thumb_bytes, 0, JPEGInterchangeFormatLength);
					thumb_bytes.position = 0;

					return {type:(Compression == 6 || Compression == 7 ? "Jpeg" : (Compression == 1 ? "Bitmap" : "Unknown")), width:0 , height:0, bytes:thumb_bytes};
				}
			} catch (e:Error){ }
			
			return null;
		}
		
		protected function readIDFs(tiff:TIFFStructure, parentIDF:IDF, stream:ByteArray, start_position:uint):IDF
		{
			function getIDFs(thisIdf:IDF, tag_nr:uint):void 
			{
				var entry:IDF_Entry = thisIdf.getEntry(tag_nr);
				
				if(entry){
					var newIdf:IDF;
					
					for each(var offset:uint in entry.values){
						newIdf = readIDFs(tiff, thisIdf, stream, offset);
						
						if(entry.tag_nr == 34665	&& !tiff.exif_idf)		tiff.exif_idf	= newIdf;
						if(entry.tag_nr == 400		&& !tiff.gp_idf	)		tiff.gp_idf		= newIdf;
						if(entry.tag_nr == 34853	&& !tiff.gps_idf)		tiff.gps_idf	= newIdf;
						if(entry.tag_nr == 40965	&& !tiff.interop_idf)	tiff.interop_idf= newIdf;
						
						if(entry.tag_nr == 330		)	thisIdf.sub_idfs.push(newIdf);
						if(entry.tag_nr == 34954	)	thisIdf.sub_leaf_idfs.push(newIdf);
					}
				}
			}
			
			var thisIDF:IDF;
			
			for each (var idf:IDF in tiff.all_idfs) {
				if(idf.position_start == start_position) {
					return idf;
				}
			}
			
			stream.position = start_position;
		
			thisIDF = new IDF();
			thisIDF.readIDF(tiff, stream, stream.position);
			
			if(thisIDF.next_idf_position) {
				readIDFs(this, thisIDF, stream, thisIDF.next_idf_position);
			}
			
			if(thisIDF.hasPropery(34665))	{ getIDFs(thisIDF, 34665); }	// EXIT IDF
			if(thisIDF.hasPropery(400))		{ getIDFs(thisIDF, 400); }	// GlobalParametersIFD
			if(thisIDF.hasPropery(34853))	{ getIDFs(thisIDF, 34853); }	// GPS IFD
			if(thisIDF.hasPropery(40965))	{ getIDFs(thisIDF, 40965); }	// Interoperability IFD
			
			if(thisIDF.hasPropery(330))		{ getIDFs(thisIDF, 330); }	// SUB IDFS
			if(thisIDF.hasPropery(34954))	{ getIDFs(thisIDF, 34954); }	// LeafSubIFD
	
			return thisIDF;
		}
		
		public function getIDFLength():uint 
		{
			var len:uint = 0;
			var idf:IDF
			
			for each(idf in all_idfs)
				len += idf.getIDFLength();
			
			return len;
		}
		
		public function getValueLength():uint 
		{
			var len:uint = 0;
			var idf:IDF;
			
			for each(idf in all_idfs)
				len += idf.getValueLength();
			
			return len;
		}
		
		public function hasPropery(tag_nr:uint):Boolean 
		{
			for each(var idf:IDF in all_idfs){
				for each(var entry:IDF_Entry in idf.entries)
					if(entry.tag_nr == tag_nr)
						return true;
			}
			
			return false;
		}
		
		public function getPropery(tag_nr:uint):IDF_Entry 
		{
			for each(var idf:IDF in all_idfs) {
				for each(var entry:IDF_Entry in idf.entries)
					if(entry.tag_nr == tag_nr)
						return entry;
			}
			
			return null;
		}
		
		public function getProperyAsInt(tag_nr:uint):int 
		{
			for each(var idf:IDF in all_idfs) {
				for each(var entry:IDF_Entry in idf.entries) {
					if(entry.tag_nr == tag_nr) {
						if(entry.values.length > 0 && entry.values[0] is int)
							return entry.values[0] as int;
					}
				}
			}
			
			return int.MAX_VALUE;
		}
		
		public function getProperyAsUInt(tag_nr:uint):uint {
			for each(var idf:IDF in all_idfs) {
				for each(var entry:IDF_Entry in idf.entries) {
					if(entry.tag_nr == tag_nr) {
						if(entry.values.length > 0 && entry.values[0] is uint)
							return entry.values[0] as uint;
					}
				}
			}
			
			return uint.MAX_VALUE;
		}
	}
}
package zephyr.utils
{
	public class StringTo
	{
		public static function bool(str:String):Boolean
		{
			var ret:Boolean;
			ret = (str == "true") ? true : false;
			return ret;
		}
	}
}
package com.panosalado.event
{
	import com.panosalado.model.INode;
	
	import flash.events.Event;

	public class PresentationEvent extends Event
	{
		public static const NODE_ENTER:String = "nodeEnter";
		public static const NODE_EXIT:String = "nodeExit";
		
		private var _node:INode;
		
		public function PresentationEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false, node:INode = null)
		{
			super(type, bubbles, cancelable);
			_node = node;
		}
		
		public function get node():INode
		{
			return _node;
		}
	}
}
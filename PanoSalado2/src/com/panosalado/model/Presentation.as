package com.panosalado.model
{
	import __AS3__.vec.Vector;
	
	import com.panosalado.event.PresentationEvent;
	
	import flash.events.EventDispatcher;
	
	public class Presentation extends EventDispatcher
	{
		private var _nodes:Vector.<INode>;
		private var _currentNode:INode;
		
		public function Presentation(nodes:Array = null)
		{
			_nodes = Vector.<INode>(nodes);
			if (_nodes.length > 0) {
				_currentNode = _nodes[0];
			}
		}
		
		public function get nodes():Vector.<INode>
		{
			return _nodes;
		}

		public function set nodes(nodes:Vector.<INode>):void
		{
			_nodes = nodes;
			// Send changed event
		}
		
		public function addNode(node:INode, makeCurrent:Boolean = false):void
		{
			_nodes.push(node);
			if (makeCurrent) {
				this.currentNode = node;
			}
		}
		
		public function set currentNode(node:INode):void
		{
			if (node in _nodes) {
				var exitEvent:PresentationEvent = 
					new PresentationEvent(PresentationEvent.NODE_EXIT, true, true, _currentNode);
				if (this.dispatchEvent(exitEvent)) {
					_currentNode = node;

					var enterEvent:PresentationEvent = 
						new PresentationEvent(PresentationEvent.NODE_ENTER, false, false, _currentNode);
					this.dispatchEvent(enterEvent);
				}
			}
		}
		
		public function get currentNode():INode
		{
			return _currentNode;
		}
	}
}
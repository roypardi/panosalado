package com.panosalado.model
{
	import __AS3__.vec.Vector;
	
	public class Presentation
	{
		private var _nodes:Vector.<Node>;
		private var _currentNode:Node;
		
		public function Presentation(nodes:Array = [])
		{
			_nodes = Vector.<Node>(nodes);
			if (nodes.length > 0) {
				_currentNode = _nodes[0];
			}
		}
		
		public function get nodes():Vector.<Node>
		{
			return _nodes;
		}

		public function set nodes(nodes:Vector.<Node>):void
		{
			_nodes = nodes;
			// Send changed event
		}
		
		public function addNode(node:Node, makeCurrent:Boolean = false):void
		{
			_nodes.push(node);
			if (makeCurrent) {
				this.currentNode = node;
			}
		}
		
		public function set currentNode(node:Node):void
		{
			if (node in _nodes) {
				_currentNode = nodes;
				// Send changed node event
			}
		}
	}
}
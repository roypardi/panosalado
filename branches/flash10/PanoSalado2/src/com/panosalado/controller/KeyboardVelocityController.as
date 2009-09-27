package com.panosalado.controller
{
	import com.panosalado.model.PanoramaNode;
	import com.panosalado.motion.GTweenVelocity;
	
	import flash.display.DisplayObject;
	import flash.events.KeyboardEvent;
	
	public class KeyboardVelocityController
	{
		private var _parentObject:DisplayObject;
		private var _node:PanoramaNode;
		private var _panTween:GTweenVelocity;
		private var _zoomTween:GTweenVelocity;
		public var panSpeed:Number;
		public var tiltSpeed:Number;
		public var zoomSpeed:Number;

		public function KeyboardVelocityController(parent:DisplayObject, node:PanoramaNode)
		{
			_parentObject = parent;
			_node = node;
			
			panSpeed = 80;
			tiltSpeed = zoomSpeed = 40;
			
			this.addHandlers();
			_panTween = new GTweenVelocity(_node.viewProjection, 99999999.0);
			_zoomTween = new GTweenVelocity(_node.viewProjection, 99999999.0);
		}
		
		private function addHandlers():void
		{
			_parentObject.stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDown);
			_parentObject.stage.addEventListener(KeyboardEvent.KEY_UP, keyUp);
		}
		
		private function keyDown(e:KeyboardEvent):void
		{
			var dpan:Number = 0;
			var dtilt:Number = 0;
			var dzoom:Number = 0;
			
			switch (e.keyCode) {
				case 37: // Left
					dpan = panSpeed;
					break;
				case 38: // Up
					dtilt = tiltSpeed;
					break;
				case 39: // Right
					dpan = -panSpeed;
					break;
				case 40: // Down
					dtilt = -tiltSpeed;
					break;
			}
			
			if (e.shiftKey) {
				dzoom = -zoomSpeed;
			} else if (e.ctrlKey) {
				dzoom = zoomSpeed;
			}
			
			if (dpan || dtilt) {
				_panTween.setProperties({pan: dpan, tilt: dtilt});
				_panTween.play();
			}
			if (dzoom) {
				_zoomTween.setProperties({verticalFOV: dzoom});
				_zoomTween.play();
			}
		}
		
		private function keyUp(e:KeyboardEvent):void
		{
			if (e.keyCode >= 37 && e.keyCode <= 40) {
				_panTween.pause();
			}
			if (!e.shiftKey && !e.ctrlKey) {
				_zoomTween.pause();
			}
		}
	}
}
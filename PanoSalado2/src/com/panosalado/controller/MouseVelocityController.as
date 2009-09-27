package com.panosalado.controller
{
	import com.panosalado.model.PanoramaNode;
	import com.panosalado.motion.GTweenVelocity;
	
	import flash.display.DisplayObject;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	public class MouseVelocityController
	{
		private var _parentObject:DisplayObject;
		private var _node:PanoramaNode;
		private var _downPoint:Point;
		private var _panScale:Point;
		private var _viewScale:Point;
		private var _dragTween:GTweenVelocity;
		
		public function MouseVelocityController(parent:DisplayObject, node:PanoramaNode)
		{
			_parentObject = parent;
			_node = node;
			_panScale = new Point(20.0, 20.0);
			_viewScale = new Point(1.0, 1.0);
			
			this.addHandlers();
			_dragTween = new GTweenVelocity(_node.viewProjection, 99999999.0);
		}
		
		private function addHandlers():void
		{
			_parentObject.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
			_parentObject.addEventListener(MouseEvent.MOUSE_UP, mouseUp);
			_parentObject.addEventListener(MouseEvent.MOUSE_WHEEL, mouseWheel);
		}
		
		private function mouseDown(e:MouseEvent):void
		{
			_downPoint = new Point(e.localX, e.localY);
			_parentObject.addEventListener(MouseEvent.MOUSE_MOVE, mouseDrag);
			_viewScale = new Point(_node.viewProjection.horizontalFOV/_parentObject.width, 
								   _node.viewProjection.verticalFOV/_parentObject.height);
			
			_dragTween.setProperties({ pan: 0.0, tilt: 0.0 });
			_dragTween.play();
		}
		
		private function mouseUp(e:MouseEvent):void
		{
			_parentObject.removeEventListener(MouseEvent.MOUSE_MOVE, mouseDrag);
			_downPoint = null;
			_dragTween.setProperties({ pan: 0.0, tilt: 0.0 });
			_dragTween.pause();
		}
		
		private function mouseDrag(e:MouseEvent):void
		{
			var currentPos:Point = new Point(e.localX, e.localY);
			var deltaPos:Point = _downPoint.subtract(currentPos);
			_dragTween.setProperties({ 
				pan: (deltaPos.x * _panScale.x * _viewScale.x), 
				tilt: (deltaPos.y * _panScale.y * _viewScale.y) 
			});
		}
		
		private function mouseWheel(e:MouseEvent):void
		{
			_node.viewProjection.verticalFOV += e.delta;
		}
	}
}
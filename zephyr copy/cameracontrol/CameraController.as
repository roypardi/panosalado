package zephyr.cameracontrol
{
	import flash.events.EventDispatcher;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.KeyboardEvent;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.ui.Keyboard;
	import org.papervision3d.view.layer.ViewportBaseLayer;

	
	import zephyr.cameracontrol.CameraControllerEvent;
	
	public class CameraController extends EventDispatcher 
	{
		private var startPoint:Point;
		
		private var deltaPan:Number = 0;
		private var deltaTilt:Number = 0;
		public var sensitivity:Number = 60;
		public var friction:Number = 0.3;
		public var threshold:Number = 0.0001;
		public var zoomIncrement:Number = 0.2;
		public var keyIncrement:Number = 75;
		
		private var autorotatorTimer:Timer;
		private var _autorotatorDelay:Number = 15000;
		private var _autorotatorOn:Boolean = true;
		
		private var mouseIsDown:Boolean = false;
		private var keyIsDown:Boolean = false;
		
		public var isAutorotating:Boolean = false;
		
		private var up:Boolean = false;
		private var down:Boolean = false;
		private var left:Boolean = false;
		private var right:Boolean = false;
		private var zoomin:Boolean = false;
		private var zoomout:Boolean = false;
		
		private var _parent:Object;
		
		//public function FreeCamera3DController( scene:Scene3D, camera:FreeCamera3D, viewport:Viewport3D, panoCubeTree:Array, materials:MaterialsList, renderer:BasicRenderEngine, autoRotation:Boolean = true )
		public function CameraController( _parent:Object, autorotator:Boolean = true, autorotatorDelay:Number = 15000 )
		{
			this._parent = _parent;
			this.autorotatorDelay = autorotatorDelay
			_parent.stage.addEventListener( MouseEvent.MOUSE_DOWN,mouseDownEvent, false, 100, true );
			_parent.stage.addEventListener( MouseEvent.MOUSE_UP,mouseUpEvent, false, 0, true );
			_parent.stage.addEventListener( Event.DEACTIVATE, mouseUpEvent, false, 0, true );
			_parent.stage.addEventListener( KeyboardEvent.KEY_DOWN, keyDownEvent, false, 100, true );
			_parent.stage.addEventListener( KeyboardEvent.KEY_UP, keyUpEvent, false, 0, true);
			
			// start the autorotator
			if (autorotator)
			{
				setUpAutorotator();
			}
		}
		
		protected function mouseDownEvent( event:MouseEvent ):void
		{
			if (event.target is ViewportBaseLayer)
			{
				mouseIsDown = true;
				
				startPoint = new Point( _parent.mouseX,_parent.mouseY );
				
				_parent.addEventListener( Event.ENTER_FRAME,enterFrameEvent, false, 0, true );
				
				dispatchEvent(new CameraControllerEvent(CameraControllerEvent.ACCELERATING) );
				
				stopAutorotatorNow();
			}
		}
		
		protected function keyDownEvent( event:KeyboardEvent ):void
		{ 
			switch( event.keyCode )
			{
			case Keyboard.UP:
				up = true; 
				startKeyMovement();
			break;
	
			case Keyboard.DOWN:
				down = true;
				startKeyMovement();
			break;
	
			case Keyboard.LEFT:
				left = true;
				startKeyMovement();
			break;
	
			case Keyboard.RIGHT:
				right = true;
				startKeyMovement();
			break;
			case Keyboard.SHIFT:
				zoomin = true;
				startKeyMovement();
			break;
			case Keyboard.CONTROL:
				zoomout = true;
				startKeyMovement();
			break;
			}
		}
		
		protected function startKeyMovement():void
		{
			stopAutorotatorNow();
			
			keyIsDown = true;
			
			_parent.addEventListener( Event.ENTER_FRAME,enterFrameEvent, false, 0, true );
			
			dispatchEvent( new CameraControllerEvent(CameraControllerEvent.ACCELERATING) );
		}
		
		
		protected function mouseUpEvent( event:Event ):void
		{
			mouseIsDown = false;
			
			dispatchEvent( new CameraControllerEvent(CameraControllerEvent.DECELERATING) );
			
		}
		
		protected function keyUpEvent(event:KeyboardEvent):void
		{
			switch( event.keyCode )
				{
				case Keyboard.UP:
					up = false;
				break;
	
				case Keyboard.DOWN:
					down = false;
				break;
	
				case Keyboard.LEFT:
					left = false;
				break;
	
				case Keyboard.RIGHT:
					right = false;
				break;
				case Keyboard.SHIFT:
					zoomin = false;
				break;
				case Keyboard.CONTROL:
					zoomout = false;
				break;
				}
			if ( !up && !down && !left && !right && !zoomin && !zoomout )
			{
				keyIsDown = false;
				
				dispatchEvent(new CameraControllerEvent(CameraControllerEvent.DECELERATING) );
			}
		}
		
		protected function enterFrameEvent( event:Event ):void
		{
			// while mouse is down we calculate new velocities, when it is up we just slow with friction
			if (mouseIsDown || keyIsDown)
			{
				if (keyIsDown)
				{
					if ( up ) { startPoint.x = _parent.stage.mouseX, startPoint.y = _parent.stage.mouseY + keyIncrement ; }
					if ( down ) { startPoint.x = _parent.stage.mouseX, startPoint.y = _parent.stage.mouseY - keyIncrement ; }
					if ( left) { startPoint.x = _parent.stage.mouseX + keyIncrement, startPoint.y = _parent.stage.mouseY ; }
					if ( right ) { startPoint.x = _parent.stage.mouseX - keyIncrement, startPoint.y = _parent.stage.mouseY ; }
					if ( zoomin ) 
					{ 
						dispatchEvent( new CameraControllerEvent(CameraControllerEvent.MOVING, 0, 0, zoomIncrement) );
					}
					if ( zoomout ) 
					{ 
						dispatchEvent( new CameraControllerEvent(CameraControllerEvent.MOVING, 0, 0, -zoomIncrement) );
					}
				}
				if (mouseIsDown || up || down || left || right)
				{
					// calculate new position changes
					deltaPan = (deltaPan - (((startPoint.x - _parent.stage.mouseX) * sensitivity) * 0.00006));
					deltaTilt = (deltaTilt + (((startPoint.y - _parent.stage.mouseY) * sensitivity) * 0.00006));
				}
			}
			// motion is still over the threshold, so apply friction
			if ( ( (deltaPan * deltaPan) + (deltaTilt * deltaTilt) ) > threshold ) {
				// always apply friction so that motion slows AFTER mouse is up
				deltaPan = (deltaPan * (1 - friction) );
				deltaTilt = (deltaTilt * (1 - friction) );
				
				dispatchEvent( new CameraControllerEvent(CameraControllerEvent.MOVING, deltaPan, deltaTilt, 0) );
			} 
			else 
			{ // motion is under threshold stop camera motion
				if ( !mouseIsDown && !keyIsDown )
				{	
					// motion is under threshold, stop and remove enter frame listener
					deltaPan = 0;
					deltaTilt = 0;
					
					_parent.removeEventListener( Event.ENTER_FRAME,enterFrameEvent );
					
					//dispatchEvent( new CameraControllerEvent(CameraControllerEvent.MOVING, deltaPan, deltaTilt, 0) );
					
					dispatchEvent( new CameraControllerEvent(CameraControllerEvent.STOPPED) );
					
					if (_autorotatorOn)
						restartAutorotatorTimer();
				
				}
			}	
		}
		
		public function set autorotatorDelay(autorotatorDelay:Number):void
		{
			if (autorotatorTimer != null)
			{
				autorotatorTimer.delay = autorotatorDelay;
			}
			this._autorotatorDelay = autorotatorDelay;
		}
		public function get autorotatorDelay():Number
		{
			return _autorotatorDelay;
		}
		
		private function setUpAutorotator():void
		{
			autorotatorTimer = new Timer(autorotatorDelay);
			autorotatorTimer.addEventListener("timer", startAutorotatorNow, false, 0, true);
			restartAutorotatorTimer();
		}
		
		public function restartAutorotatorTimer():void
		{
			if (_autorotatorOn)
			{
				stopAutorotatorNow();
				autorotatorTimer.start();
			}
		}
		
		public function startAutorotatorNow(e:TimerEvent=null):void
		{
			if (autorotatorTimer)
			{
				autorotatorTimer.stop();
				autorotatorTimer.reset();
			}
			
			_parent.addEventListener( Event.ENTER_FRAME,autorotatorEnterFrameEventHandler, false, 1, true );
			
			isAutorotating = true;
		}
		
		private function autorotatorEnterFrameEventHandler(e:Event):void
		{
			dispatchEvent( new CameraControllerEvent(CameraControllerEvent.AUTOROTATING, 0, 0, 0) );
		}
		
		public function stopAutorotatorNow():void
		{
			_parent.removeEventListener( Event.ENTER_FRAME,autorotatorEnterFrameEventHandler );
			if (autorotatorTimer)
			{
				autorotatorTimer.stop();
				autorotatorTimer.reset();
			}
			
			isAutorotating = false;
		}
		
		public function set autorotatorOn(value:Boolean):void
		{
			_autorotatorOn = value;
			if (value)
			{
				restartAutorotatorTimer();
			}
			else
			{
				stopAutorotatorNow();
			}
		}
		
		public function get autorotatorOn():Boolean
		{
			return _autorotatorOn;
		}
		
	}
}
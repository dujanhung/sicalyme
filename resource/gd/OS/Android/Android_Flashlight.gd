@tool

@abstract

##Android flashlight.
##[br]
##[br][b]note[/b] :
##[br] ➣ when using [CameraFeed], internal flashlight won't work. so, use external flashlight instead.
##[br]
##[br][color=ffffaa][b]warning[/b][/color] :
##[br] [color=ff5500]➣[/color] don't point the light beam at your eye.

class_name Android_Flashlight
extends RefCounted

##==========

static var _context:JavaClass:
 get():
  return JavaClassWrapper.wrap(
   "android.content.Context"
  )

static var _context_inst:JavaObject:
 get():
  return AndroidRuntime.getApplicationContext()

static var _camera_manager_inst:JavaObject:
 get():
  return _context_inst.getSystemService(
   _context.CAMERA_SERVICE
  )

##==========

##act.
static var act:bool:
 get():
  return act
 set(v):
  act=v
  _camera_manager_inst.setTorchMode(
   "0"
   ,v
  )

##==========

#EOF
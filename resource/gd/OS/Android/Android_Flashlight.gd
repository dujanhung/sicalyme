#𒐪𒐪

@tool

@abstract

#𒐪𒐪

##Android flashlight.
##[br]
##[br][b]note[/b] :
##[br] ➣ when using [CameraFeed], internal flashlight won't work. so, use external flashlight instead.
##[br]
##[br][color=ffffaa][b]warning[/b][/color] :
##[br] [color=ff5500]➣[/color] don't point the light beam at your eye.

#𒐪𒐪

class_name Android_Flashlight
extends RefCounted

#𒐪𒐪

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

#𒐪𒐪

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

#𒐪𒐪

#EOF
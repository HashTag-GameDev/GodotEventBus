extends Node

#region --- Setup ---
@export var start_debug_enabled: bool = true

var _debug_enabled: bool
var _listeners: Dictionary = {}
var _once_flags: Dictionary = {}

func _ready() -> void:
	_debug_enabled = start_debug_enabled
	if _debug_enabled:
		_print_banner()
#endregion

#region --- API Hooks ---
## [b]Description[/b][br]
## Subscribes a listener to an event so it will be notified every time that event is published.  
## Use this to connect systems to a named event without hard node references.[br]
##[br]
## [b]Parameters[/b][br]
## • [code]event[/code]: The event/channel name to listen to (e.g. [code]&"player_damaged"[/code]).[br]
## • [code]method[/code]: The [code]Callable[/code] to invoke when the event is published.[br]
##[br]
## [b]Notes[/b][br]
## • Multiple listeners can subscribe to the same event; all will be called when the event fires.[br]
## • Events will be sent to listeners in order of subscription.[br]
## • If `_debug_enabled` is true, a SUB line is printed identifying the event and listener.[br]
##[br]
## [b]Example[/b]
## [codeblock]
## EventBus.subscribe(&"player_damaged", "_on_player_damaged"))
## [/codeblock]
func subscribe(event: StringName, method: Callable) -> void:
	if not _listeners.has(event):
		_listeners[event] = []
	_listeners[event].append(method)
	if _debug_enabled:
		_debug_log("SUB", str(event), [_format_callable(method)])

## [b]Description[/b][br]
## Subscribes a listener to an event for a single notification, then automatically unsubscribes it.  
## Ideal for one-time actions like tutorial tips, quest triggers, or setup callbacks.[br]
##[br]
## [b]Parameters[/b][br]
## • [code]event[/code]: The event/channel name to listen to once.[br]
## • [code]method[/code]: The [code]Callable[/code] to invoke the next time the event is published.[br]
##[br]
## [b]Notes[/b][br]
## • The listener is removed immediately after it runs once.[br]
## • Multiple [code]sub_once[/code] calls with the same [code]Callable[/code] each trigger once.[br]
## • If `_debug_enabled` is true, a SUB_ONCE line is printed for clarity.[br]
##[br]
## [b]Example[/b]
## [codeblock]
## EventBus.sub_once(&"scene_loaded", "_on_scene_loaded_once")
## [/codeblock]
func sub_once(event: StringName, method: Callable) -> void:
	subscribe(event, method)
	if not _once_flags.has(event):
		_once_flags[event] = {}
	_once_flags[event][method] = true
	if _debug_enabled:
		_debug_log("SUB_ONCE", str(event), [": %s" % [method]])

## [b]Description[/b][br]
## Unsubscribes a previously registered listener from an event.  
## Safe to call even if the listener was never subscribed.[br]
##[br]
## [b]Parameters[/b][br]
## • [code]event[/code]: The event/channel name to unsubscribe from.[br]
## • [code]method[/code]: The same [code]Callable[/code] originally passed to [code]subscribe[/code] or [code]sub_once[/code].[br]
##[br]
## [b]Notes[/b][br]
## • Only removes listeners that exactly match the stored [code]Callable[/code] (object + method).[br]
## • Removes pending one-shot subscriptions if they haven’t fired yet.[br]
## • When the last listener is removed, the event key is discarded.[br]
## • If `_debug_enabled` is true, an OFF line is printed identifying the event and listener.[br]
##[br]
## [b]Example[/b]
## [codeblock]
## EventBus.subscribe(&"player_damaged", _on_player_damaged)
## # Later:
## EventBus.unsubscribe(&"player_damaged", _on_player_damaged)
## [/codeblock]
func unsubscribe(event: StringName, method: Callable) -> void:
	if not _listeners.has(event):
		return
	var arr: Array = _listeners[event]
	for i in range(arr.size() - 1, -1, -1):
		if method.get_method() == str(method):
			arr.remove_at(i)
			if _once_flags.has(event):
				_once_flags[event].erase(method)
	if arr.is_empty():
		_listeners.erase(event)
	if _debug_enabled:
		_debug_log("OFF", str(event), [": %s" % [method]])

## [b]Description[/b][br]
## Publishes (broadcasts) an event to all current listeners.  
## Call this at the source of truth (e.g. Player, SaveSystem, Spawner).[br]
##[br]
## [b]Parameters[/b][br]
## • [code]event[/code]: The event/channel name to publish (e.g. [code]&"player_damaged"[/code]).[br]
## • [code]args[/code]: Zero or more arguments to forward to listeners in order.[br]
##[br]
## [b]Notes[/b][br]
## • Listeners are called in the order they were subscribed.[br]
## • [code]sub_once[/code] listeners are automatically removed after invocation.[br]
## • Invalid [code]Callable[/code]s (freed objects) are skipped safely.[br]
## • If `_debug_enabled` is true, an EMIT line is printed listing listeners and arguments.[br]
##[br]
## [b]Example[/b]
## [codeblock]
## EventBus.publish(&"player_damaged", 15, 80) # amount=15, hp_left=80
## [/codeblock]
func publish(event: StringName, ...args) -> void:
	var arr: Array = []
	if _listeners.has(event):
		for cb in _listeners[event]:
			if cb.is_valid():
				arr.append(cb)

	if _debug_enabled:
		var names: Array = []
		for cb in arr:
			names.append(_format_callable(cb))
		_debug_log("EMIT", str(event), names, args)

	# Call listeners
	var to_remove: Array = []
	for cb in arr:
		cb.callv(args)
		# Handle one-shot removal
		if _once_flags.has(event) and _once_flags[event].has(cb):
			to_remove.append(cb)
	for cb in to_remove:
		_listeners[event].erase(cb)
		_once_flags[event].erase(cb)
	if _listeners.has(event) and _listeners[event].is_empty():
		_listeners.erase(event)
#endregion

#region ---- Debug ----
func toggle_debug() -> void:
	_debug_enabled = !_debug_enabled
	_print_banner()

func _format_callable(cb: Callable) -> String:
	var obj := cb.get_object()
	var obj_name: String = obj.name if obj == Node else str(obj)
	return "%s: %s" % [obj_name, cb.get_method()]

func _debug_log(kind: String, event: String, listeners: Array, args: Array = []) -> void:
	var time_str := Time.get_time_string_from_system(true)
	var who: String = _join(listeners, ", ")
	var arg_str := str(args)
	match kind:
		"EMIT":
			print_rich("[color=yellow][EventBus][/color] %s  EMIT  [b]%s[/b]  args = %s  -> listeners = %d: %s"
				% [time_str, event, arg_str, listeners.size(), who])
		"SUB":
			print_rich("[color=green][EventBus][/color] %s  SUB   [b]%s[/b]  + %s"
				% [time_str, event, who])
		"SUB_ONCE":
			print_rich("[color=green][EventBus][/color] %s  SUB1  [b]%s[/b]  + %s (once)"
				% [time_str, event, who])
		"OFF":
			print_rich("[color=orangered][EventBus][/color] %s  OFF   [b]%s[/b]  - %s"
				% [time_str, event, who])

func _print_banner() -> void:
	print_rich("[color=yellow][EventBus][/color] Debug: %s. EventBus.toggle_debug() to toggle this on and off."
		% [_debug_enabled])

func _join(arr: Array, sep: String) -> String:
	var out := ""
	for i in arr.size():
		out += str(arr[i])
		if i < arr.size() - 1:
			out += sep
	return out

#endregion

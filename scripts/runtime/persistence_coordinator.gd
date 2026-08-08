extends RefCounted

const SaveManager = preload("res://scripts/systems/save_manager.gd")

var dirty := false
var elapsed_since_attempt := 0.0
var failure_message := ""

func reset() -> void:
	dirty=false
	elapsed_since_attempt=0.0
	failure_message=""

func mark_dirty() -> void:
	dirty=true

func advance(delta:float) -> void:
	if dirty:elapsed_since_attempt+=delta

func should_flush(interval:float) -> bool:
	return dirty and elapsed_since_attempt>=interval

func save(slot:int,state:Dictionary) -> bool:
	dirty=true
	elapsed_since_attempt=0.0
	if SaveManager.save_state(slot,state):
		dirty=false
		failure_message=""
		return true
	failure_message="Your progress is still in memory, but it could not be written to disk. The game will retry automatically."
	return false

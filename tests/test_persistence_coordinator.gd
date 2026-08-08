extends RefCounted

const PersistenceCoordinator = preload("res://scripts/runtime/persistence_coordinator.gd")
const TestSupport = preload("res://tests/test_support.gd")

static func run() -> Array:
	var errors:=[]
	var coordinator:=PersistenceCoordinator.new()
	TestSupport.check(errors,not coordinator.dirty and not coordinator.should_flush(5.0),"Persistence should begin clean.")
	coordinator.mark_dirty();coordinator.advance(4.9)
	TestSupport.check(errors,coordinator.dirty and not coordinator.should_flush(5.0),"Dirty persistence should wait for its debounce interval.")
	coordinator.advance(.1)
	TestSupport.check(errors,coordinator.should_flush(5.0),"Dirty persistence should request a flush after the debounce interval.")
	coordinator.reset()
	TestSupport.check(errors,not coordinator.dirty and coordinator.failure_message=="","Reset should clear pending persistence state and warnings.")
	return errors

extends RefCounted

const ItemCardView = preload("res://scripts/ui/item_card_view.gd")
const ItemData = preload("res://scripts/data/item_data.gd")
const TestSupport = preload("res://tests/test_support.gd")

static func run()->Array:
	var errors:=[]
	var card:=ItemCardView.new()
	var item:=ItemData.create_instance("marchwarden_plate","layout_test_plate")
	card.configure(ItemData.item_card_data(item,[]),[{"id":"equip","label":"Equip"},{"id":"change_hero","label":"Change Hero"}])
	TestSupport.check(errors,card.custom_minimum_size==Vector2(460,620),"The shared Item Card should remain inside the 1280x720 viewport.")
	var tier_label:=card.find_child("ItemCardTier",true,false) as Label
	TestSupport.check(errors,tier_label!=null and tier_label.custom_minimum_size.x>=90 and tier_label.autowrap_mode==TextServer.AUTOWRAP_OFF,"The item tier should reserve a horizontal single-line label instead of collapsing vertically.")
	var actions:=card.find_child("ItemCardActions",true,false) as HBoxContainer
	TestSupport.check(errors,actions!=null and actions.get_child_count()==2 and actions.get_children().all(func(button):return button.custom_minimum_size.x>=170),"Item Card actions should remain touch-sized and horizontally readable.")
	var plate_data:=ItemData.item_card_data(item,[])
	var knives_data:=ItemData.item_card_data(ItemData.create_instance("test_ashfang_knives","layout_test_knives"),[])
	TestSupport.check(errors,plate_data.stats[0].text=="+18 Armor" and knives_data.stats[0].text=="+25 Power" and knives_data.stats[1].text=="+20% Critical Chance","Whole-number item stats should use their actual values without inflated percentages or trailing .0 decimals.")
	card.free()
	return errors

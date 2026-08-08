extends RefCounted

const BalanceLabScreen = preload("res://scripts/balance_lab/balance_lab_screen.gd")
const TestSupport = preload("res://tests/test_support.gd")

static func run(tree:SceneTree)->Array:
	var errors:=[]
	var lab:=BalanceLabScreen.new();tree.root.add_child(lab)
	await tree.process_frame
	TestSupport.check(errors,lab.find_child("SimulationControls",true,false)!=null and lab.find_child("BuildSelector",true,false)!=null and lab.find_child("ResultsTable",true,false)!=null,"The standalone Balance Lab should compose separate setup, build-selection, and result components.")
	TestSupport.check(errors,lab.find_child("BalanceRunButton",true,false)!=null and lab.find_child("BalanceResultsTree",true,false)!=null,"The Balance Lab should expose a clear Run action and results table.")
	var warning:Label=lab.find_child("BalancePrototypeWarning",true,false)
	TestSupport.check(errors,warning!=null and warning.custom_minimum_size.x>=300.0 and warning.autowrap_mode==TextServer.AUTOWRAP_OFF,"The prototype warning should remain horizontal instead of collapsing the Balance Lab layout.")
	var results_heading:Label=lab.find_child("BalanceResultsHeading",true,false)
	TestSupport.check(errors,results_heading!=null and results_heading.custom_minimum_size.x>=100.0 and results_heading.autowrap_mode==TextServer.AUTOWRAP_OFF,"The Results heading should remain horizontal at the 1280 by 720 target size.")
	lab.controls.iteration_option.select(0)
	lab.run_simulation()
	await tree.process_frame
	await tree.process_frame
	var result_tree:Tree=lab.find_child("BalanceResultsTree",true,false)
	TestSupport.check(errors,result_tree.get_root()!=null and result_tree.get_root().get_child_count()==20,"The default Balance Lab run should display all compatible prototype scenario comparisons, including Slayer.")
	tree.root.remove_child(lab)
	lab.free()
	await tree.process_frame
	return errors

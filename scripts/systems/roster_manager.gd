extends RefCounted

static func hero_matches(
		hero:Dictionary,
		classes:Dictionary,
		search:String,
		role_filter:String,
		class_filter:String,
		type_filter:String
	) -> bool:
	var role:String=classes[hero["class"]]["role"]
	var is_special:=bool(hero.get("is_special_hero",false))
	var type_matches:=type_filter=="All Heroes" \
		or type_filter=="Special Heroes" and is_special \
		or type_filter=="Standard Heroes" and not is_special
	return (search=="" or search.to_lower() in str(hero["name"]).to_lower()) \
		and (role_filter=="All roles" or role==role_filter) \
		and (class_filter=="All classes" or hero["class"]==class_filter) \
		and type_matches

static func sorted_indices(
		heroes:Array,
		classes:Dictionary,
		search:String,
		role_filter:String,
		class_filter:String,
		type_filter:String,
		sort_field:String,
		descending:bool
	) -> Array:
	var result:=[]
	for index in heroes.size():
		if hero_matches(heroes[index],classes,search,role_filter,class_filter,type_filter):
			result.append(index)
	result.sort_custom(func(a,b):
		var hero_a=heroes[a]
		var hero_b=heroes[b]
		var value_a=hero_a["name"] if sort_field=="Name" else classes[hero_a["class"]]["role"] if sort_field=="Role" else hero_a["class"] if sort_field=="Class" else hero_a["level"]
		var value_b=hero_b["name"] if sort_field=="Name" else classes[hero_b["class"]]["role"] if sort_field=="Role" else hero_b["class"] if sort_field=="Class" else hero_b["level"]
		return value_a>value_b if descending else value_a<value_b)
	return result

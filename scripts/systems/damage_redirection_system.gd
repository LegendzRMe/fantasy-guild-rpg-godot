extends RefCounted

static func health_ratio(unit:Dictionary)->float:return float(unit.get("hp",0.0))/maxf(1.0,float(unit.get("max_hp",1.0)))
static func protective_bond_plan(original:Dictionary,partner:Dictionary,raw_amount:float,eligible:bool=true,already_redirected:bool=false,snapshot:Dictionary={})->Dictionary:
	if not eligible or already_redirected or float(original.get("hp",0.0))<=0.0 or float(partner.get("hp",0.0))<=0.0:return {"redirected":false,"original_amount":raw_amount,"redirect_amount":0.0}
	var original_ratio:=float(snapshot.get(str(original.get("combat_id","")),health_ratio(original)));var partner_ratio:=float(snapshot.get(str(partner.get("combat_id","")),health_ratio(partner)))
	if is_equal_approx(original_ratio,partner_ratio) or original_ratio>=partner_ratio:return {"redirected":false,"original_amount":raw_amount,"redirect_amount":0.0}
	var redirected:=maxf(0.0,raw_amount)*0.5
	return {"redirected":true,"original_amount":maxf(0.0,raw_amount)-redirected,"redirect_amount":redirected,"original_target_id":str(original.get("combat_id","")),"redirect_target_id":str(partner.get("combat_id",""))}


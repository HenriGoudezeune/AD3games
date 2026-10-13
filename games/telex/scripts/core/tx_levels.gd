class_name TxLevels
## Leveldata (GDD §5) en de machinefabriek (GDD §8.8).


## Maakt de machine voor een stage-spec (GDD §8.5). live = {"B": int} voor LIVE-stages.
static func make_machine(stage: Dictionary, carry: Dictionary = {}, mode: int = TxCodes.Mode.CALM,
		live: Dictionary = {}) -> TxMachine:
	var mc: TxMachine
	match str(stage.get("machine", "")):
		"brute":
			mc = TxBrute.new()
		"kmp":
			mc = TxKmp.new()
		"kmp_table":
			mc = TxKmpTable.new()
		_:
			push_error("TxLevels.make_machine: onbekende machine %s" % str(stage.get("machine", "")))
			mc = TxBrute.new()
	var lv := live
	if mode == TxCodes.Mode.LIVE and lv.is_empty():
		lv = {"B": -1}
	mc.setup(stage, carry, lv if mode == TxCodes.Mode.LIVE else {})
	return mc

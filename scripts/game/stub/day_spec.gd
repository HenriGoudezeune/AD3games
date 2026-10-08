extends RefCounted
## STUB (tijdelijk) van core DaySpec (GDD §10.5). Geen class_name om botsing met de core te vermijden.

enum Mode { CALM, REALTIME }
enum BitHint { FULL, COLORS, NONE }

var id := ""
var title := ""
var intro := ""
var icon := ""
var n := 5
var g := 2
var a0 := 1
var start_layout: Array = []
var keys: Array = []
var generator: Dictionary = {}
var mode := 0
var bit_hint := 0
var loupe_allowed := false
var overflow_bin := false
var spawn_interval := 2.5
var belt_time := 14.0
var burst_time := 0.0
var customers: Array = []
var customer_gen: Dictionary = {}
var reputation := 5
var stars: Array = []
var hints: Array = []
var phases: Array = []
var expect_end: Dictionary = {}

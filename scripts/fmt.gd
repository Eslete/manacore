class_name Fmt
extends RefCounted

static func compact(n: float) -> String:
	var prefix := "-" if n < 0.0 else ""
	n = absf(n)
	if n < 1000.0:
		if n < 10.0:
			return "%s%.2f" % [prefix, n]
		return "%s%.1f" % [prefix, n]
	var units := ["K", "M", "B", "T"]
	var i := 0
	while n >= 1000.0 and i < units.size():
		n /= 1000.0
		i += 1
	if n < 10.0:
		return "%s%.2f%s" % [prefix, n, units[i - 1]]
	if n < 100.0:
		return "%s%.1f%s" % [prefix, n, units[i - 1]]
	return "%s%d%s" % [prefix, int(n), units[i - 1]]


static func rate(n: float) -> String:
	var s := "+" if n >= 0.0 else ""
	return "%s%s/s" % [s, compact(n)]

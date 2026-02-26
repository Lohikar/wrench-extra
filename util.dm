#define NONUNIT_CEILING(x, y) ( -round(-(x) / (y)) * (y) )

#define __WRENCH_INTERNAL_TICKBENCH_INTERLEAVE_DO_OP(COUNT, CODE) \
	sleep(1); \
	_count = 0; \
	_start = world.tick_usage; \
	while (world.tick_usage - _start < 100) { \
		_count += 1; \
		CODE; \
	} \
	COUNT = _count;

#define __WRENCH_INTERNAL_REPEAT_TEN(X) X; X; X; X; X; X; X; X; X; X;
#define __WRENCH_INTERNAL_REPEAT_HUNDRED(X) __WRENCH_INTERNAL_REPEAT_TEN(X); __WRENCH_INTERNAL_REPEAT_TEN(X); __WRENCH_INTERNAL_REPEAT_TEN(X); __WRENCH_INTERNAL_REPEAT_TEN(X); __WRENCH_INTERNAL_REPEAT_TEN(X); __WRENCH_INTERNAL_REPEAT_TEN(X); __WRENCH_INTERNAL_REPEAT_TEN(X); __WRENCH_INTERNAL_REPEAT_TEN(X); __WRENCH_INTERNAL_REPEAT_TEN(X); __WRENCH_INTERNAL_REPEAT_TEN(X);
#define __WRENCH_INTERNAL_REPEAT_THOUSAND(X) __WRENCH_INTERNAL_REPEAT_HUNDRED(X); __WRENCH_INTERNAL_REPEAT_HUNDRED(X); __WRENCH_INTERNAL_REPEAT_HUNDRED(X); __WRENCH_INTERNAL_REPEAT_HUNDRED(X); __WRENCH_INTERNAL_REPEAT_HUNDRED(X); __WRENCH_INTERNAL_REPEAT_HUNDRED(X); __WRENCH_INTERNAL_REPEAT_HUNDRED(X); __WRENCH_INTERNAL_REPEAT_HUNDRED(X); __WRENCH_INTERNAL_REPEAT_HUNDRED(X); __WRENCH_INTERNAL_REPEAT_HUNDRED(X);

#define __WRENCH_INTERNAL_TICKBENCH_INTERLEAVE_DO_OP_HUNDRED(COUNT, OVERRUN, CODE) \
	sleep(1); \
	_count = 0; \
	_start = world.tick_usage; \
	while (world.tick_usage - _start < 100) { \
		_count += 100; \
		__WRENCH_INTERNAL_REPEAT_HUNDRED(CODE); \
	} \
	if (world.tick_usage > 110) { OVERRUN += 1; }; \
	COUNT = _count;

	#define __WRENCH_INTERNAL_TICKBENCH_INTERLEAVE_DO_OP_THOUSAND(COUNT, OVERRUN, CODE) \
	sleep(1); \
	_count = 0; \
	_start = world.tick_usage; \
	while (world.tick_usage - _start < 100) { \
		_count += 1000; \
		__WRENCH_INTERNAL_REPEAT_THOUSAND(CODE); \
	} \
	if (world.tick_usage > 110) { OVERRUN += 1; }; \
	COUNT = _count;

#define __WRENCH_INTERNAL_TICKBENCH_INTERLEAVE_DO_OP_N(COUNT, OVERRUN, MULT, CODE) \
	sleep(1); \
	_count = 0; \
	_start = world.tick_usage; \
	while (world.tick_usage - _start < 100) { \
		for (var/_tid_step in 1 to MULT) { \
			CODE; \
		} \
		_count += MULT; \
	} \
	if (world.tick_usage > 110) { OVERRUN += 1; }; \
	COUNT = _count;

/proc/__wrench_tickbench_print_phases(list/phases, list/identifiers, list/overrun, more_math = FALSE)
	var/samp
	var/samp_are_same = TRUE
	for (var/list/item in phases)
		if (!samp) samp = item.len
		if (samp != item.len) samp_are_same = FALSE

	if (!samp_are_same)
		world.log << "<~>\ntick_lag = [world.tick_lag] (~[world.fps] Hz)\n"
	else
		world.log << "<~>\nn (samples) = [samp]\ntick_lag = [world.tick_lag] (~[world.fps] Hz)\n"
	for (var/i in 1 to phases.len)
		__wrench_tickbench_calc_stats(identifiers[i], phases[i], overrun[i], !samp_are_same, more_math = more_math)

	world.log << "<~>"

#define TICKBENCH_INTERLEAVE_DEFAULT_SAMPLES 5

// This is interleave that allows for arbitrary phase _count via macro magic.
#define BEGIN_BENCH_WITH_SAMPLES(PHASES, SAMP) \
	var/_count; \
	var/list/_phases = new /list(PHASES, SAMP); \
	var/list/_overruns = new /list(PHASES); \
	var/_identifiers[PHASES]; \
	var/_start; \
	var/_current_phase = 1; \
	var/_samples = SAMP; \
	for (var/_samp in 1 to _samples)

#define BEGIN_BENCH(PHASES) BEGIN_BENCH_WITH_SAMPLES(PHASES, TICKBENCH_INTERLEAVE_DEFAULT_SAMPLES)

#define BENCH_PHASE(NAME,CODE) \
	_identifiers[_current_phase] = NAME; \
	__WRENCH_INTERNAL_TICKBENCH_INTERLEAVE_DO_OP(_phases[_current_phase][_samp], CODE); \
	++_current_phase; \
	if (_current_phase > _phases.len) { _current_phase = 1 };

#define BENCH_PHASE_CHUNKED(NAME,CHUNK_SIZE,CODE) \
	_identifiers[_current_phase] = NAME; \
	__WRENCH_INTERNAL_TICKBENCH_INTERLEAVE_DO_OP_N(_phases[_current_phase][_samp], _overruns[_current_phase], CHUNK_SIZE, CODE); \
	++_current_phase; \
	if (_current_phase > _phases.len) { _current_phase = 1 };

#define BENCH_PHASE_HUNDRED(NAME,CODE) \
	_identifiers[_current_phase] = NAME; \
	__WRENCH_INTERNAL_TICKBENCH_INTERLEAVE_DO_OP_HUNDRED(_phases[_current_phase][_samp], _overruns[_current_phase], CODE); \
	++_current_phase; \
	if (_current_phase > _phases.len) { _current_phase = 1 };

#define BENCH_PHASE_THOUSAND(NAME,CODE) \
	_identifiers[_current_phase] = NAME; \
	__WRENCH_INTERNAL_TICKBENCH_INTERLEAVE_DO_OP_THOUSAND(_phases[_current_phase][_samp], _overruns[_current_phase], CODE); \
	++_current_phase; \
	if (_current_phase > _phases.len) { _current_phase = 1 };

#define BENCH_PHASE_CHNK(NAME,CHUNK_SIZE,CODE) BENCH_PHASE_CHUNKED(NAME,CHUNK_SIZE,CODE)

#define END_BENCH if (_current_phase != 1) { OUT << "Phase count mismatch. Ensure declared phase count matches count of BENCH_PHASE() calls. Corrupt output suppressed."; } else { __wrench_tickbench_print_phases(_phases, _identifiers, _overruns); }
#define END_BENCH_WITH_MATH if (_current_phase != 1) { OUT << "Phase count mismatch. Ensure declared phase count matches count of BENCH_PHASE() calls. Corrupt output suppressed."; } else { __wrench_tickbench_print_phases(_phases, _identifiers, _overruns, more_math = TRUE); }

// for familiarity -- does terrible hacks to print only a single phase

#define TICKBENCH(N,C) do { BEGIN_BENCH(1) { BENCH_PHASE(N,C); } global.__wrench_tickbench_calc_stats(_identifiers[1], _phases[1], _overruns[1], TRUE); } while (FALSE);

/proc/__wrench_tickbench_calc_stats(name, list/samples, overruns, print_sample_count = TRUE, more_math = FALSE)
#if DM_VERSION >= 515
	samples.RemoveAll(null)
#else
	samples -= new /list(samples.len)
#endif
	if (!samples.len || max(samples) == 0)
		world.log << "[name]: no data"
		return

	var/mean = 0
	var/stddev_sum = 0
	var/harm_mean = __wrench_harmonic_mean(samples)

	for (var/val in samples)
		mean += val

	mean /= samples.len

	for (var/val in samples)
		stddev_sum += (val - mean)**2
	stddev_sum /= samples.len
	stddev_sum = sqrt(stddev_sum)

	var/ci_value = 1.96 * (stddev_sum/sqrt(samples.len))

	var/list/out_lines = list(
		print_sample_count ? "[name] (n = [samples.len]): " : "[name]:"
		//"\t~[round(harm_mean)] (± [round(stddev_sum)]) run\s/tick (95% confidence: [round(harm_mean - ci_value)] .. [round(harm_mean + ci_value)])",
	)

	if (more_math)
		out_lines += "\tH(Xn) [num2text(harm_mean, 9)], σ [stddev_sum] ([round((stddev_sum / harm_mean) * 100, 0.01)]%)\n\t95%: [round(harm_mean - ci_value)] .. [round(harm_mean + ci_value)]"
	else
		out_lines += "\t~[round(harm_mean)] (± [round(stddev_sum)]) run\s/tick (95% confidence: [round(harm_mean - ci_value)] .. [round(harm_mean + ci_value)])"

	if (overruns > 0)
		out_lines += "\t[overruns]/[samples.len] samples invalid due to sampling overrun."

	world.log << out_lines.Join("\n")

/proc/__wrench_harmonic_mean(list/samples)
	var/denom = 0
	for (var/i in samples)
		if (i == 0)
			return "<cannot compute>"

		denom += 1/i

	return samples.len / denom

/proc/seq(lo, hi, st=1)
	if(isnull(hi))
		hi = lo
		lo = 1

	. = list()
	for(var/x in lo to hi step st)
		. += x

/proc/enc(data)
	. = json_encode(data)

/proc/dec(data)
	. = json_decode(data)

var/list/cardinal    = list(NORTH, SOUTH, EAST, WEST)
var/list/cornerdirs  = list(NORTHWEST, SOUTHEAST, NORTHEAST, SOUTHWEST)
var/list/alldirs     = list(NORTH, SOUTH, EAST, WEST, NORTHEAST, NORTHWEST, SOUTHEAST, SOUTHWEST)
var/list/reverse_dir = list( // reverse_dir[dir] = reverse of dir
	 2,  1,  3,  8, 10,  9, 11,  4,  6,  5,  7, 12, 14, 13, 15, 32, 34, 33, 35, 40, 42,
	41, 43, 36, 38, 37, 39, 44, 46, 45, 47, 16, 18, 17, 19, 24, 26, 25, 27, 20, 22, 21,
	23, 28, 30, 29, 31, 48, 50, 49, 51, 56, 58, 57, 59, 52, 54, 53, 55, 60, 62, 61, 63
)

/proc/dir2text(dir)
	//ASSERT(!((dir & (dir >> 1)) & (NORTH|EAST|UP)) && dir)
	if (((dir & (dir >> 1)) & (NORTH|EAST|UP))) // check for illegal adjacent bits -- NORTHSOUTH, EASTWEST, UPDOWN.
		CRASH("malformed dir - conflicting bits")

	if (!dir)
		return "CENTER"

	. = ""
	if (dir & NORTH)
		. += "NORTH"
	else if (dir & SOUTH)
		. += "SOUTH"
	if (dir & EAST)
		. += "EAST"
	else if (dir & WEST)
		. += "WEST"

	if (dir & UP)
		. += "-UP"
	else if (dir & DOWN)
		. += "-DOWN"

#define PROTOTYPE(A) (copytext("\ref[A]", 4, 6))
#define STDOUT world.log
#define LOG world.log
#define WLOG world.log
#define OUT world.log
#define MAIN /proc/main()
#define TAG_OUT(A,B) world.log << "[#A]: [B]"

#define DECODE_PROTOTYPE(X) global.wrench_decode_prototype(text2num(PROTOTYPE(X), 16))

#define ENC_OUT(X) global.__wrench_enc_out(#X, X)
/proc/__wrench_enc_out(origin, data)
	var/post
	var/data_s = "[data]" || "<empty_string>"

	if (isnull(data))
		post = "null"
	else if (isnum(data))
		post = "[data]"
#if DM_VERSION >= 516
	else if (istype(data, /alist))
		post = "alist (.len [length(data)]) | [__wrench_json_encode(data)]"
#endif
	else if (istext(data))
		post = __wrench_json_encode(data)
	else if (istype(data, /matrix))
		var/matrix/M = data
		post = "matrix | \[ \[ [M.a] [M.d] 0 \]; \[ [M.b] [M.e] 0 \]; \[ [M.c] [M.f] 1 \] \]"
	else if (istype(data, /datum))
		post = "[data:type] | [data_s]"
	else if (islist(data))
		post = "list (.len [length(data)]) | [__wrench_json_encode(data)]"
#if DM_VERSION >= 515
	else if (ispointer(data))
		post = "pointer | [data_s]"
#endif
#if DM_VERSION >= 516
	else if (istype(data, /vector))
		post = "vector | [data_s]"

	else if (istype(data, /pixloc))
		post = "pixloc | [data_s]"
#endif
	else if (istype(data, /client))	// how tho
		post = "client? | [data_s]"
	else if (ispath(data))
		post = "path/type | [data_s]"
	else if (PROTOTYPE(data) == "3a")
		post = "immutable appearance? | <opaque>"
	else
		post = "unknown (prototype [PROTOTYPE(data)] \[[DECODE_PROTOTYPE(data)]\]) | [data_s]"

	world.log << "[origin] => [post]"

/proc/__wrench_json_encode(data)
#if DM_VERSION >= 515
	var/flags = 0
	/*
		Do not prettyprint:
		- Non-lists
		- Lists that are just short numbers
		- Very long lists
	*/
	if (islist(data) && (length(data) in 1 to 10))
		if (!isnum(data[1]))// || (isnum(data[1]) && max(data) > 99999))
			flags = JSON_PRETTY_PRINT

	. = json_encode(data, flags)
#else
	. = json_encode(data)
#endif

#define VAR_OUT(A) ENC_OUT(A)
#if DM_VERSION >= 515
#define PARGS OUT << "[__PROC__]([enc(args)])"
#else
#define PARGS OUT << "[.....]([enc(args)])"
#endif

// Wrench has a monkeypatch that will force this into the global context even if placed in a proc.
#define WORLD(X,Y,Z) world{maxx=X;maxy=Y;maxz=Z};
#define BOOL(X) !!(X)

#define INSULATE(EXPR) do { try { EXPR; } catch (var/exception/E) { global.__wrench_rethrow_exception(E); }; } while (FALSE);
#define INSULATE_OUT(EXPR) do { try { ENC_OUT(EXPR); } catch (var/exception/E) { global.__wrench_rethrow_exception(E); }; } while (FALSE);
#define INS_OUT(X) INSULATE_OUT(X)

/proc/__wrench_rethrow_exception(exception/E)
	throw E

/proc/pass(...)

#define PASS(X...) if (0 == 1) pass(##X)

#define LAZYINITLIST(L) if (!L) L = list()
#define UNSETEMPTY(L) if (L && !L.len) L = null
#define LAZYREMOVE(L, I) if(L) { L -= I; if(!L.len) { L = null; } }
#define LAZYADD(L, I) if(!L) { L = list(); } L += I;
#define LAZYACCESS(L, I) (L ? (isnum(I) ? (I > 0 && I <= L.len ? L[I] : null) : L[I]) : null)
#define LAZYLEN(L) length(L)
#define LAZYCLEARLIST(L) if(L) L.Cut()
#define LAZYSET(L, K, V) if (!L) { L = list(); } L[K] = V;
#define LAZYPICK(L,DEFAULT) (LAZYLEN(L) ? pick(L) : DEFAULT)

/proc/__sleep(x)
	sleep(x)

#define __WRENCH_INTERNAL_BENCHLOOP(INCR) for (__sleep(1) || (_count = 0) || (_start = world.tick_usage); world.tick_usage - _start < 100; INCR)

#define BENCH_BLOCK(NAME) for (var/_active_phase = (_identifiers[_current_phase] = NAME) && _current_phase; _current_phase == _active_phase; (_current_phase = ++_current_phase > _phases.len ? 1 : _current_phase) && (_phases[_active_phase][_samp] = _count)) __WRENCH_INTERNAL_BENCHLOOP(++_count)

#define BENCH_BLOCK_CHUNKED(NAME, CHUNK_SIZE) for (var/_active_phase = (_identifiers[_current_phase] = NAME) && _current_phase; _current_phase == _active_phase; (_current_phase = ++_current_phase > _phases.len ? 1 : _current_phase) && (_phases[_active_phase][_samp] = _count)) __WRENCH_INTERNAL_BENCHLOOP(_count += CHUNK_SIZE) for (var/_ctr in 1 to CHUNK_SIZE)

#define BENCH_EXPR(NAME,CODE) BENCH_PHASE(NAME,CODE)

/proc/wrench_decode_prototype(typeid)
	#define ENTITY(IDENT,VALUE) if (VALUE) return #IDENT

	// This is derived from opendream's list.
	switch (typeid)
		ENTITY(NULL_D, 0x00)
		ENTITY(TURF, 0x01)
		ENTITY(OBJ, 0x02)
		ENTITY(MOB, 0x03)
		ENTITY(AREA, 0x04)
		ENTITY(CLIENT, 0x05)
		ENTITY(STRING, 0x06)
		ENTITY(MOB_TYPEPATH, 0x08)
		ENTITY(OBJ_TYPEPATH, 0x09)
		ENTITY(TURF_TYPEPATH, 0x0A)
		ENTITY(AREA_TYPEPATH, 0x0B)
		ENTITY(RESOURCE, 0x0C)
		ENTITY(IMAGE, 0x0D)
		ENTITY(WORLD_D, 0x0E)
		ENTITY(LIST, 0x0F)
		ENTITY(LIST_ARGS, 0x10)
		ENTITY(LIST_MOB_VERBS, 0x11)
		ENTITY(LIST_VERBS, 0x12)
		ENTITY(LIST_TURF_VERBS, 0x13)
		ENTITY(LIST_AREA_VERBS, 0x14)
		ENTITY(LIST_CLIENT_VERBS, 0x15)
		ENTITY(LIST_SAVEFILE_DIR, 0x16)
		ENTITY(LIST_MOB_CONTENTS, 0x17)
		ENTITY(LIST_TURF_CONTENTS, 0x18)
		ENTITY(LIST_AREA_CONTENTS, 0x19)
		ENTITY(LIST_WORLD_CONTENTS, 0x1A)
		ENTITY(LIST_GROUP, 0x1B)
		ENTITY(LIST_CONTENTS, 0x1C)
		ENTITY(DATUM_TYPEPATH, 0x20)
		ENTITY(DATUM, 0x21)
		ENTITY(SAVEFILE, 0x23)
		ENTITY(SAVEFILE_TYPEPATH, 0x24)
		ENTITY(PROCPATH, 0x26)
		ENTITY(FILE_, 0x27)
		ENTITY(LIST_TYPEPATH, 0x28)
		ENTITY(PREFAB, 0x29)
		ENTITY(NUMBER, 0x2A)
		ENTITY(LIST_MOB_VARS, 0x2C)
		ENTITY(LIST_OBJ_VARS, 0x2D)
		ENTITY(LIST_TURF_VARS, 0x2E)
		ENTITY(LIST_AREA_VARS, 0x2F)
		ENTITY(LIST_CLIENT_VARS, 0x30)
		ENTITY(LIST_VARS, 0x31) //maybe?
		ENTITY(LIST_MOB_OVERLAYS, 0x32)
		ENTITY(LIST_MOB_UNDERLAYS, 0x33)
		ENTITY(LIST_OVERLAYS, 0x34)
		ENTITY(LIST_UNDERLAYS, 0x35)
		ENTITY(LIST_TURF_OVERLAYS, 0x36)
		ENTITY(LIST_TURF_UNDERLAYS, 0x37)
		ENTITY(LIST_AREA_OVERLAYS, 0x38)
		ENTITY(LIST_AREA_UNDERLAYS, 0x39)
		ENTITY(APPEARANCE, 0x3A)
		ENTITY(CLIENT_TYPEPATH, 0x3B)
		ENTITY(IMAGE_TYPEPATH, 0x3F)
		ENTITY(LIST_IMAGE_OVERLAYS, 0x40)
		ENTITY(LIST_IMAGE_UNDERLAYS, 0x41)
		ENTITY(LIST_IMAGE_VARS, 0x42)
		ENTITY(LIST_IMAGE_VERBS, 0x43)
		ENTITY(LIST_IMAGE_CONTENTS, 0x44) // wait wtf
		ENTITY(LIST_CLIENT_IMAGES, 0x46)
		ENTITY(LIST_CLIENT_SCREEN, 0x47)
		ENTITY(LIST_TURF_VIS_CONTENTS, 0x4B)
		ENTITY(LIST_VIS_CONTENTS, 0x4C)
		ENTITY(LIST_MOB_VIS_CONTENTS, 0x4D)
		ENTITY(LIST_TURF_VIS_LOCS, 0x4E)
		ENTITY(LIST_VIS_LOCS, 0x4F)
		ENTITY(LIST_MOB_VIS_LOCS, 0x50)
		ENTITY(LIST_WORLD_VARS, 0x51)
		ENTITY(LIST_GLOBAL_VARS, 0x52)
		ENTITY(FILTERS, 0x53)
		ENTITY(LIST_IMAGE_VIS_CONTENTS, 0x54)

	return "<unknown>"

	#undef ENTITY

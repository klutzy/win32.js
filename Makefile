EMCC?=emcc
EMXX?=em++
COFFEE?=coffee

# you may have to add mingw path like this.
#INCS?=-I/path/to/mingw/include

DEFS=-D_X86_ -DWIN32 -DUNICODE -DWIN32_LEAN_AND_MEAN
OBJS=src/library_win32.js src/window.js
EXAMPLES=examples/hello.js

.PHONY: all
all: $(OBJS)

src/%.js: src/%.coffee
	$(COFFEE) --bare -c $<

.PHONY: examples
examples: $(EXAMPLES)
	$(MAKE) -C lib/fake-mswin assets OUTDIR=../../examples/lib

examples/%.js: examples/%.cpp all
	$(EMXX) -o $@ --js-library src/library_win32.js --pre-js src/window.js \
	$< $(INCS) $(DEFS)

.PHONY: clean
clean:
	rm -f $(OBJS) $(EXAMPLES)
	rm -rf examples/lib

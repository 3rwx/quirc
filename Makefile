# quirc -- QR-code recognition library
# Copyright (C) 2010-2012 Daniel Beer <dlbeer@gmail.com>
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
WASI_SDK_PATH ?= /opt/wasi-sdk

CC = $(WASI_SDK_PATH)/bin/clang
LD = $(WASI_SDK_PATH)/bin/wasm-ld

PREFIX ?= /usr/local

LIB_VERSION = 1.0

QUIRC_EXPORTS = \
	quirc_begin \
	quirc_count \
	quirc_destroy \
	quirc_new \
	quirc_resize \
	quirc_strerror \
	quirc_version \
	malloc \
	free

CFLAGS ?= -c -Os -Wall --target=wasm32 --sysroot=$(WASI_SDK_PATH)/share/wasi-sysroot
LDFLAGS ?= -m wasm32 -L$(WASI_SDK_PATH)/share/wasi-sysroot/lib/wasm32-wasi --no-entry $(addprefix --export=,$(QUIRC_EXPORTS)) -lm -lc
QUIRC_CFLAGS = -Ilib $(CFLAGS)
LIB_OBJ = \
    lib/decode.o \
    lib/identify.o \
    lib/quirc.o \
    lib/version_db.o

.PHONY: all clean

all: libquirc.wasm

libquirc.wasm: $(LIB_OBJ)
	rm -f $@
	$(LD) $(LDFLAGS) $(LIB_OBJ) -o $@

.c.o:
	$(CC) $(QUIRC_CFLAGS) -o $@ -c $<

.SUFFIXES: .cxx
.cxx.o:
	$(CXX) $(QUIRC_CXXFLAGS) -o $@ -c $<

clean:
	rm -f */*.o
	rm -f */*.lo
	rm -f libquirc.wasm

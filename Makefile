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
BINARYEN_PATH ?= /opt/binaryen

CC = $(WASI_SDK_PATH)/bin/clang
LD = $(WASI_SDK_PATH)/bin/wasm-ld

PREFIX ?= /usr/local

LIB_VERSION = 1.0

QUIRC_EXPORTS = \
	quirc_version \
	quirc_new \
	quirc_destroy \
	quirc_resize \
	quirc_begin \
	quirc_end \
	quirc_strerror \
	quirc_count \
	quirc_extract \
	quirc_decode \
	quirc_flip \
	quirc_code_size \
	quirc_data_size \
	quirc_data_get_version \
	quirc_data_get_ecc_level \
	quirc_data_get_mask \
	quirc_data_get_data_type \
	quirc_data_get_payload \
	quirc_data_get_payload_len \
	quirc_data_get_eci \
	malloc \
	free

CFLAGS ?= -x c -D__wasi_api_h -D__wasilibc_unmodified_upstream -flto -I$(WASI_SDK_PATH)/lib/clang/11.0.0/include -I$(WASI_SDK_PATH)/share/wasi-sysroot/include -c -Os -Wall --target=wasm32 -nostdlib -nostdinc
LDFLAGS ?= -O9 -m wasm32 -L$(WASI_SDK_PATH)/share/wasi-sysroot/lib/wasm32-wasi --strip-all --no-entry -lc -lm $(addprefix --export=,$(QUIRC_EXPORTS)) 
QUIRC_CFLAGS = -Ilib $(CFLAGS)
LIB_OBJ = \
    lib/decode.o \
    lib/identify.o \
    lib/quirc.o \
    lib/version_db.o \
	lib/helpers.o

.PHONY: all clean

all: libquirc.wasm

libquirc.wasm: $(LIB_OBJ)
	rm -f $@
	$(LD) -o $@ $(LDFLAGS) $(LIB_OBJ)
	$(BINARYEN_PATH)/bin/wasm-opt -o libquirc.min.wasm -Os libquirc.wasm
	mv libquirc.min.wasm libquirc.wasm

.c.o:
	$(CC) $(QUIRC_CFLAGS) -o $@ -c $<

.SUFFIXES: .cxx
.cxx.o:
	$(CXX) $(QUIRC_CXXFLAGS) -o $@ -c $<

clean:
	rm -f */*.o
	rm -f */*.lo
	rm -f libquirc.wasm
	rm -rf *.a *.o

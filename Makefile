# This is a -*- Makefile -*- 
# Warning: this file contains tabs which cannot be converted to spaces

#CONFIG=debug

CC	=	$(CROSS)gcc
#CXX	=	$(CROSS)g++
#CPP	=	$(CROSS)gcc -E
LD	=	$(CC)

# CFLAGS_OPT is normally in the config$(CONFIG).mk file,
# but here's a reasonable default value
# add -ftree-vectorizer-verbose=3 to get information about vectorized loops
#CFLAGS_OPT=-Wall -g -O2 -ftree-vectorize -msse3 -mssse3 -ffast-math
#CFLAGS_OPT=-Wall -O3 -DNDEBUG -march=core2 -ftree-vectorize -msse3 -mssse3 -ffast-math
#CFLAGS_OPT=-Wall -g -O2 -march=pentium4 -ftree-vectorize -msse3 -mssse3 -ffast-math -DDISPARITYTAGGER_DISABLE_TEXTURE_RECTANGLE -DDISPARITYTAGGER_DISABLE_PBO
#CFLAGS_OPT=-Wall -g -O2 -march=pentium4 -ftree-vectorize -msse3 -mssse3 -ffast-math -DVIDEOINPUT_WITHOUT_NVSDI
CFLAGS_OPT= -Wall  -Wmissing-declarations
#CFLAGS_OPT= -Wall -g -O2
CFLAGS_OPENMP = -fopenmp

# the flag for .cpp files
#CXXFLAGS = -std=c++11

FFMPEG_PKGS = libavformat libavcodec libavdevice libswscale libavfilter libswresample libavutil
FFMPEG_CPPFLAGS = $(shell pkg-config $(FFMPEG_PKGS) --cflags)
FFMPEG_LDFLAGS = $(shell pkg-config $(FFMPEG_PKGS) --libs-only-L)
FFMPEG_LIBS = $(shell pkg-config $(FFMPEG_PKGS) --libs-only-l)
SDL_CPPFLAGS = $(shell sdl2-config --cflags)
SDL_LDFLAGS =
SDL_LIBS = $(shell sdl2-config --libs)

-include config$(CONFIG).mk

CPPFLAGS= \
	$(FFMPEG_CPPFLAGS) \
	$(SDL_CPPFLAGS)

LIBS = \
	$(FFMPEG_LDFLAGS) $(FFMPEG_LIBS) \
	$(SDL_LDFLAGS) $(SDL_LIBS)

#CFLAGS_EXTRA=$(CFLAGS_OPENMP)
CXXFLAGS=$(CFLAGS_OPT) $(CFLAGS_EXTRA)
CFLAGS=$(CFLAGS_OPT) $(CFLAGS_EXTRA)
LDFLAGS=$(CFLAGS_OPT) $(CFLAGS_EXTRA) $(LDFLAGS_EXTRA) $(OPENCL_LDFLAGS)

# for gcov profiling add:
#-fprofile-arcs -ftest-coverage

COMPILE.c=$(CC) -c $(CFLAGS) $(CPPFLAGS)
COMPILE.cpp=$(CXX) -c $(CXXFLAGS) $(CPPFLAGS)

PROGRAMS = ffplay

.PHONY: all

all: $(PROGRAMS)

ffplay_SOURCES_C = \
	ffplay.c \
	cmdutils.c
ffplay_HEADERS = \
	cmdutils.h \
	cmdutils_common_opts.h \
	compat/va_copy.h \
	config.h \
	libavutil/libm.h
ffplay_OBJS = $(ffplay_SOURCES_C:.c=.o)
ffplay_LIBS = $(LIBS)


SRCS_C = \
	$(ffplay_SOURCES_C)

HEADERS = \
	$(ffplay_HEADERS)

ffplay: $(ffplay_OBJS)
	$(LD) -o $@ $^ $(LDFLAGS) $(ffplay_LIBS) $(LDADD)

.SUFFIXES: .c .o

## gcc-only version:
%.o : %.c
	$(COMPILE.c) -MD -o $@ $<
	@cp $*.d $*.P; \
	    sed -e 's/#.*//' -e 's/^[^:]*: *//' -e 's/ *\\$$//' \
	        -e '/^$$/ d' -e 's/$$/ :/' < $*.d >> $*.P; \
	    rm -f $*.d

## general version:
# %.o : %.c
# 	@$(MAKEDEPEND); \
# 	    cp $*.d $*.P; \
# 	    sed -e 's/#.*//' -e 's/^[^:]*: *//' -e 's/ *\\$$//' \
# 		-e '/^$$/ d' -e 's/$$/ :/' < $*.d >> $*.P; \
# 	    rm -f $*.d
# 	$(COMPILE.c) -o $@ $<

.PHONY: clean distclean
clean:
	-rm -f $(PROGRAMS) $(LIBRARY) *.o  *~
	-rm -rf *.dSYM

distclean: clean
	-rm -f $(SRCS_C:.c=.P)

count:
	 wc -l $(SRCS_C) $(HEADERS)

-include $(SRCS_C:.c=.P)

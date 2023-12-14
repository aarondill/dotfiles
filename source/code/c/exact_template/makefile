CC=gcc
IDIR=.
override CFLAGS+=-I$(IDIR) -Wall -lm
OBJ=$(patsubst %.c,%.o,$(wildcard *.c))
HEADERS=$(wildcard *.h)

TARGET={{ $ROOT }}
# Ensure TARGET is never empty
ifeq ($(strip $(TARGET)),)
	TARGET::=out
endif

# patsubst %,'%',$^ quotes file lists when passed to shell. Doesn't handle spaces, just variable expansion

all: $(TARGET)

%.o: %.c $(HEADERS)
	$(CC) -c -o $(patsubst %,'%',$@) $(patsubst %,'%',$<) $(CFLAGS)

$(TARGET): $(OBJ)
	$(CC) -o $(patsubst %,'%',$@) $(patsubst %,'%',$^) $(CFLAGS)

clean:
	$(RM) ./*~ $(patsubst %,'%',$(TARGET)) $(patsubst %,'%',$(OBJ))

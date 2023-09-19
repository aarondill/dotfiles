CC::=gcc
IDIR=.
CFLAGS::=-I$(IDIR) -Wall
OBJ::=$(patsubst %.c,%.o,$(wildcard *.c))
HEADERS::=$(wildcard *.h)

TARGET::=${ROOT}
ifeq ($(strip $(TARGET)),) # ensure TARGET is never empty
	TARGET::=out
endif

# note: $(patsubst %,'%',$^) quotes file lists when passed to shell. Doesn't handle spaces, just variable expansion

all: $(TARGET)

%.o: %.c $(HEADERS)
	$(CC) -c -o $(patsubst %,'%',$@) $(patsubst %,'%',$<) $(CFLAGS)

$(TARGET): $(OBJ)
	$(CC) -o $(patsubst %,'%',$@) $(patsubst %,'%',$^) $(CFLAGS)

clean:
	$(RM) ./*~ $(patsubst %,'%',$(TARGET)) $(patsubst %,'%',$(OBJ))

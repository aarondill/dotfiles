CC::=gcc
IDIR=.
CFLAGS::=-I$(IDIR) -Wall
OBJ::=$(patsubst %.c,%.o,$(wildcard *.c))
HEADERS::=$(wildcard *.h)

TARGET::=out

all: $(TARGET)

%.o: %.c $(HEADERS)
	$(CC) -c -o $@ $< $(CFLAGS)

$(TARGET): $(OBJ)
	$(CC) -o $@ $^ $(CFLAGS) 

clean:
	$(RM) *~ $(TARGET) $(OBJ)

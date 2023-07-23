LIBS =
CC = gcc
CFLAGS = -std=gnu99 -Wall
INCEKF = -I../TinyEKF/src

.PHONY: parabola default all clean

default: parabola

all: parabola

obj/tiny_ekf.o: ../TinyEKF/src/tiny_ekf.c
	${CC} ${CFLAGS} -o $@ -c $^ $(INCEKF)

parabola: parabola.c obj/tiny_ekf.o
	$(CC) $^ -o $@ $(CFLAGS) $(INCEKF) -lm

clean:
	rm -f obj/*
	rm -f parabola

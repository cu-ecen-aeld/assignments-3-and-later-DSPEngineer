CC=gcc
CFLAGS=-I.

default:
	$(CC) writer.c  -o writer.o

hellomake: hellomake.o hellofunc.o
	$(CC) -o hellomake hellomake.o hellofunc.o

clean:
	rm *.o

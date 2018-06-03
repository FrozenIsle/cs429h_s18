CFLAGS=-g -std=c99 -O0 -Werror -Wall

CFILES=$(sort $(wildcard *.c))
OFILES=$(subst .c,.o,$(CFILES))

p3 : $(OFILES) Makefile
	gcc $(CFLAGS) -o p3 $(OFILES)

$(OFILES) : %.o : %.c Makefile
	gcc $(CFLAGS) -MD -c $*.c

%.o : %.S Makefile
	gcc $(CFLAGS) -MD -c $*.S

TESTS=$(sort $(wildcard *.fun))
RUNS=$(patsubst %.fun,%.result,$(TESTS))

test : $(RUNS)

$(RUNS) : %.result : %.fun Makefile p3
	@echo -n "[$*] ... "
	@-timeout 5 ./p3 $*.fun > $*.out
	@((diff -b $*.out $*.ok > /dev/null) && echo "pass") || (echo "fail" ; echo "--- expected ---"; cat $*.ok; echo "--- found ---" ; cat $*.out)

clean :
	rm -f *.out
	rm -f *.d
	rm -f *.o
	rm -f p3

-include *.d

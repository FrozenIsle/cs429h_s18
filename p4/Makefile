CFLAGS=-g -std=c99 -O0 -Werror -Wall

CFILES=$(sort $(wildcard *.c))
OFILES=$(subst .c,.o,$(CFILES))

p4 : $(OFILES) Makefile
	gcc $(CFLAGS) -o p4 $(OFILES)

$(OFILES) : %.o : %.c Makefile
	gcc $(CFLAGS) -MD -c $*.c

TESTS=$(sort $(wildcard *.fun))
EXECS=$(subst .fun,,$(TESTS))
RUNS=$(patsubst %.fun,%.result,$(TESTS))

test : $(RUNS)

$(EXECS) : % : %.fun Makefile p4
	@echo compiling $*.fun
	@-timeout 5 ./p4 $*

$(RUNS) : %.result : % %.args
	@echo -n "$* ... "
	@-timeout 5 ./$* `head -n 1 $*.args` > $*.out
	@((diff -b $*.out $*.ok > /dev/null) && echo "pass") || (echo "fail" ; echo "--- expected ---"; cat $*.ok; echo "--- found ---" ; cat $*.out)

clean :
	rm -f *.out $(EXECS)
	rm -f *.d
	rm -f *.o
	rm -f *.s
	rm -f p4

-include *.d

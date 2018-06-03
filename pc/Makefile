RSFLAGS=-O

pc : main.rs Makefile
	rustc $(RSFLAGS) -o pc main.rs

TESTS=$(sort $(wildcard *.fun))
RUNS=$(patsubst %.fun,%.result,$(TESTS))

test : $(RUNS)

$(RUNS) : %.result : %.fun Makefile pc
	@echo -n "[$*] ... "
	@-timeout 5 ./pc $*.fun > $*.out
	@((diff -b $*.out $*.ok > /dev/null) && echo "pass") || (echo "fail" ; echo "--- expected ---"; cat $*.ok; echo "--- found ---" ; cat $*.out)

clean :
	rm -f *.out
	rm -f pc


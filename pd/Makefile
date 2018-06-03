
pd : p3.go Makefile
	go build -o pd p3.go

TESTS=$(sort $(wildcard *.fun))
RUNS=$(patsubst %.fun,%.result,$(TESTS))

test : $(RUNS)

$(RUNS) : %.result : %.fun Makefile pd
	@echo -n "[$*] ... "
	@-timeout 5 ./pd $*.fun > $*.out
	@((diff -b $*.out $*.ok > /dev/null) && echo "pass") || (echo "fail" ; echo "--- expected ---"; cat $*.ok; echo "--- found ---" ; cat $*.out)

clean :
	rm -f *.out
	rm -f pd


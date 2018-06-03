CCFLAGS=-g -std=c++14 -O3 -Werror -Wall

CCFILES=$(sort $(wildcard *.cc))
SFILES=$(sort $(wildcard *.s))
OCCFILES=$(subst .cc,.o,$(CCFILES))
OSFILES=$(subst .s,.o,$(SFILES))
OFILES=$(OCCFILES) $(OSFILES)
TESTS=$(sort $(wildcard *.test))
EXECS=$(subst .test,,$(TESTS))
OKFILES=$(subst .test,.ok,$(TESTS))
RUNS=$(patsubst %.test,%.result,$(TESTS))


all : $(EXECS)

$(OCCFILES) : %.o : %.cc Makefile
	g++ $(CCFLAGS) -MD -c $*.cc

$(OSFILES) : %.o : %.s Makefile
	gcc $(CFLAGS) -MD -c $*.s

test : $(RUNS)

$(EXECS) : % : %.test Makefile $(OFILES)
	g++ -x c++ $(CCFLAGS) -MD -c $*.test
	g++ -o $* $*.o $(OFILES)
	

$(OKFILES) : %.ok :
	touch $@

$(RUNS) : %.result : % %.ok
	@/bin/echo -n "$* ... "
	@-timeout 5 ./$* > $*.out
	@((diff -b $*.out $*.ok > /dev/null) && echo "pass") || (echo "fail" ; echo "--- expected ---"; cat $*.ok; echo "--- found ---" ; cat $*.out)

clean :
	rm -f *.out $(EXECS)
	rm -f *.d
	rm -f *.o

-include *.d

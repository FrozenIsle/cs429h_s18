#include "go.h"
#include <stdlib.h>
#include <stdio.h>
#include <setjmp.h>

/* Look at the magic function in magic.s and make sure you
   understand what it's doing. It will look strange at first.
*/

extern "C" void magic(Routine* future);



///////////////////////////////////////////////////

Routine *current_ = nullptr;
Routine *after_ = nullptr;
Queue<Routine> ready;
Queue<Routine> blocked;
Queue<Routine> zombies;
bool first = true;
void error();

void nextRoutine(){
	Routine* next_ = ready.getHead();
	if(next_ == nullptr){
//		printf("no more routines\n");
		exit(0);
	}
//	printf("going to next\n");
	magic(next_);
}

void run(){
	if(current_ == nullptr)
		error();
	if(current_->func == nullptr)
		error();
	current_->func();
}

void death(){
	ready.remove2(current_);
	zombies.add(current_);
	nextRoutine();
}

extern "C" uint64_t createStack(){
	uint64_t stackpointer = (uint64_t)malloc(sizeof(uint64_t)*STACK_ENTRIES);
//	Func dfunc = &death;
	stackpointer = stackpointer + (sizeof(uint64_t)*STACK_ENTRIES-1);
	while(stackpointer %16 != 8)
		stackpointer--;
	*((uint64_t*)stackpointer) = (uint64_t) &death;
	stackpointer -= sizeof(&death);
	*((uint64_t*)stackpointer) = (uint64_t) &run;
	stackpointer -= REG_SPACE;
	return stackpointer;
}

void go(std::function<void()> func) {
//	printf("start go\n");
//	check();
	current();
//	check();
	Routine *newRoutine = new Routine();
	newRoutine->saved_rsp = createStack();
	newRoutine->func = func;
	ready.add(newRoutine);
//	check();
	magic(newRoutine);
}

void check(){
	printf("%p\n", ready.getHead());
	printf("%p\n", ready.getTail());
	printf("\n");
}

void block(Routine* r){
//	printf("blocking\n");
//	printf("%p\n%p\n", ready.getHead(), ready.getTail());
	ready.remove2(r);
//	printf("blocked\n");
	if(ready.getHead() == nullptr)
//		printf("no more ready\n");
	blocked.add(r);
}

void add(Routine* r){
	blocked.remove2(r);
	ready.add(r);
}

extern "C" Routine** current() {
//	printf("start current\n");
//	printf("%p\n", &ready);
    if (current_ == nullptr) {
//		printf("is null\n");
        current_ = new Routine();
		ready.add(current_);
    }
//	check();
    return &current_;
}

/* OSX is stuck in the past and prepends _ in front of external symbols */
extern "C" Routine** _current() {
    return current();
}

void error(){
	printf("error\n");
	exit(0);
}


#include "go.h"
#include <stdlib.h>
#include <stdio.h>
#include <setjmp.h>

/* Look at the magic function in magic.s and make sure you
   understand what it's doing. It will look strange at first.
*/

//struct Routine;
//typedef struct Routine Routine;

typedef struct Routine Routine;

extern void magic(Routine* future);

typedef struct Queue {
    struct Routine* head;
    struct Routine* tail;
}Queue;

struct Routine {
    uint64_t saved_rsp;
    struct Routine *next;
	struct Channel *ch;
	struct Routine *prev;
	Value val;
	Func func;
};

Routine* makeRoutine();
void addQ(Queue* q, Routine* r);
Routine* removeQ(Queue* q);
Routine* removeQ2(Queue* q, Routine* r);
Channel* makeChannel();

#define MISSING() do { \
    printf("missing code at %s:%d\n",__FILE__,__LINE__); \
    exit(0); \
} while (0)

#define STACK_ENTRIES (4*(8192 / sizeof(uint64_t)))
#define REG_SPACE (8 * 6)

struct Channel {
    Value val;
	Routine* sender;
	Routine* receiver;
	int poison;
};

//////////////////////////////////////////////

void addQ(Queue* q, Routine* r) {
    r->next = 0;
    if (q->tail != 0) {
        q->tail->next = r;
		r->prev = q->tail;
    }
    q->tail = r;

    if (q->head == 0) {
        q->head = r;
    }
}

Routine* removeQ(Queue* q) {
    Routine* r = q->head;
    if (r != 0) {
        q->head = r->next;
		if(r->next != 0)
			r->next->prev = 0;
        if (q->tail == r) {
            q->tail = 0;
        }
    }
    return r;
}

Routine* removeQ2(Queue* q, Routine* r){
	if(r->prev == 0){
		if(r->next == 0){
			q->head = 0;
			q->tail = 0;
		}
		else{
			q->head = r->next;
			r->next->prev = 0;
			r->next = 0;
		}
	}
	else{
		if(r->next == 0){
			q->tail = r->prev;
			r->prev->next = 0;
			r->prev = 0;
		}
		else{
			r->prev->next = r->next;
			r->next->prev = r->prev;
			r->prev = 0;
			r->next = 0;
		}
	}
	return r;
}

///////////////////////////////////////////////////

Routine *current_ = 0;
Queue ready = { 0, 0};
Queue blocked = {0, 0};
Queue zombies = { 0, 0 };
int cleared = 0;

void nextRoutine(){
	Routine* next_ = current_->next;
	if(cleared){
		next_ = ready.head;
		cleared = 0;
	}

	if(next_ == 0)
		exit(0);
	magic(next_);
}

Routine** current() {
    if (current_ == 0) {
		current_ = makeRoutine();
    }
    return &current_;
}

Routine* makeRoutine(){
	Routine *newRoutine = (Routine*) calloc(sizeof(Routine),1);
	newRoutine->ch = makeChannel();
	return newRoutine;
}

Channel* makeChannel(){
	Channel *newChannel = (Channel*) calloc(sizeof(Channel),1);
	return newChannel;
}

/* OSX is stuck in the past and prepends _ in front of external symbols */
Routine** _current() {
    return current();
}

/////////////////////////////////////////////////////////////////////////////////

void death(){
	cleared = 1;
	removeQ2(&ready, current_);
	addQ(&zombies, current_);
	nextRoutine();
}

uint64_t createStack(Func func){
	uint64_t stackpointer = (uint64_t)malloc(STACK_ENTRIES);
	Func dfunc = &death;
	stackpointer = stackpointer + (STACK_ENTRIES-1);
	while(stackpointer %16 != 8)
		stackpointer--;
	*((Func*)stackpointer) = dfunc;
	stackpointer -= sizeof(dfunc);
	*((Func*)stackpointer) = func;
	stackpointer -= REG_SPACE;
	return stackpointer;
}

Channel* go(Func func) {
	cleared = 1;
    if(current_ == 0){
		current_ = makeRoutine();
		addQ(&ready, current_);	
	}
	Routine* newRoutine = makeRoutine();
	addQ(&ready, newRoutine);
	newRoutine->saved_rsp = createStack(func);
	newRoutine->func = func;
	magic(newRoutine);
	cleared = 1;
		
    return newRoutine->ch;
}

////////////////////////////////////////////////////////////////

Channel* me() {
	cleared = 1;
    if(current_ == 0){
		current_ = makeRoutine();
		addQ(&ready, current_);
	}
	return current_->ch;
}

void again() {
    cleared = 1;
    if(current_ == 0){
		printf("failed again\n");
		exit(0);
	}
	Routine* newRoutine = makeRoutine();
	addQ(&ready, newRoutine);
	newRoutine->saved_rsp = createStack(current_->func);
	newRoutine->func = current_->func;
	newRoutine->ch = current_->ch;
	removeQ2(&ready, current_);
	addQ(&zombies, current_);
	magic(newRoutine);
	cleared = 1;
	printf("failed again 2\n");
	exit(0);
}

Channel* channel() {
    Channel* newChannel = makeChannel();
	return newChannel;
}

bool isPoisoned(Channel* ch) {
    if(ch->poison)
		return true;
	return false;
}

void poison(Channel* ch) {
	cleared = 1;
    ch->poison = 1;
	if(ch->sender != 0){
		removeQ2(&blocked, ch->sender);
		addQ(&zombies, ch->sender);
	}
	if(ch->receiver != 0){
		removeQ2(&blocked, ch->receiver);
		addQ(&zombies, ch->receiver);
	}

}

void transact(Channel* ch){
	cleared = 1;
	ch->receiver->val = ch->val;
	ch->sender = 0;
	ch->receiver = 0;
}

Value receive(Channel* ch) {
	cleared = 1;
	if(ch->poison){
		death();
	}	
	if(current_ == 0){
		current_ = makeRoutine();
		addQ(&ready, current_);
	}
	while(ch->receiver != 0)
		nextRoutine();
	cleared = 1;
	ch->receiver = current_;
	if(ch->sender != 0){
		removeQ2(&blocked, ch->sender);
		addQ(&ready, ch->sender);
		transact(ch);
	}
	else{
		removeQ2(&ready, current_);
		addQ(&blocked, current_);
		nextRoutine();
	}
	cleared = 1;
	return current_->val;
}

void send(Channel* ch, Value v) {
	cleared = 1;
	if(ch->poison){
		death();
	}	
    if(current_ == 0){
		current_ = makeRoutine();
		addQ(&ready, current_);
	}
	while(ch->sender != 0)
		nextRoutine();
	cleared = 1;
	ch->sender = current_;
	ch->val = v;
	if(ch->receiver != 0){
		removeQ2(&blocked, ch->receiver);
		addQ(&ready, ch->receiver);
		transact(ch);
	}
	else{
		removeQ2(&ready, current_);
		addQ(&blocked, current_);
		nextRoutine();
	}
	cleared = 1;
	return;
}

////////////
// Stream //
////////////

struct Stream {
    Channel* ch;
};

static void streamLogic(void) {
    StreamFunc fs = (StreamFunc) receive(me()).asPointer;
    Value v = receive(me());
    fs(v);
    poison(me());
}

Stream* stream(StreamFunc func, Value v) {
    Channel* ch = go(streamLogic);
    send(ch,asPointer(func));
    send(ch,v);
    Stream* out = (Stream*) calloc(sizeof(Stream),1);
    out->ch = ch;
    return out;
}

Value next(Stream* s) {
    return receive(s->ch);
}

bool endOfStream(Stream* s) {
    return isPoisoned(s->ch);
}

void yield(Value v) {
    send(me(),v);
}

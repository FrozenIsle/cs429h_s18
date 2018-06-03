#ifndef _GO_H_
#define _GO_H_

#include <cstdio>
#include <stdint.h>
#include <setjmp.h>
#include <stdlib.h>
#include <functional>
#include <memory>

#define MISSING() do { \
    printf("missing code at %s:%d\n",__FILE__,__LINE__); \
    exit(1); \
} while (0)

using std::shared_ptr;

/////////////////////////////////////////////////////////////////////
template <typename T>
class Queue {
    T* head;
    T* tail;
public:
    Queue(){}
	T* getHead(){
		return head;
	}
	T* getTail(){
		return tail;
	}
    void add(T* r) {
        r->next = nullptr;
		r->prev = nullptr;
        if (tail != nullptr) {
            tail->next = r;
			r->prev = tail;
        }
        tail = r;

        if (head == nullptr) {
            head = r;
        }
    }

    T* remove() {
        T* r = head;
        if (r != nullptr) {
            head = r->next;
			r->next = nullptr;
			if(head != nullptr)
				head->prev = nullptr;
            if (tail == r) {
                tail = nullptr;
            }
        }
        return r;
    }
	T* remove2(T* r){
		if(r->prev == nullptr){
			if(r->next == nullptr){
				head = nullptr;
				tail = nullptr;
			}
			else{
				head = r->next;
				r->next->prev = nullptr;
				r->next = nullptr;
			}
		}
		else{
			if(r->next == nullptr){
				tail = r->prev;
				r->prev->next = nullptr;
				r->prev = nullptr;
			}
			else{
				r->prev->next = r->next;
				r->next->prev = r->prev;
				r->prev = nullptr;
				r->next = nullptr;
			}
		}
		return r;
	}
/////////////////////////
	void add(T* r, bool b) {
        r->cnext = nullptr;
		r->cprev = nullptr;
        if (tail != nullptr) {
            tail->cnext = r;
			r->cprev = tail;
        }
        tail = r;

        if (head == nullptr) {
            head = r;
        }
    }

    T* remove(bool b) {
        T* r = head;
        if (r != nullptr) {
            head = r->cnext;
			r->cnext = nullptr;
			if(head != nullptr)
				head->cprev = nullptr;
            if (tail == r) {
                tail = nullptr;
            }
        }
        return r;
    }
	T* remove2(T* r, bool b){
		if(r->cprev == nullptr){
			if(r->cnext == nullptr){
				head = nullptr;
				tail = nullptr;
			}
			else{
				head = r->cnext;
				r->cnext->cprev = nullptr;
				r->cnext = nullptr;
			}
		}
		else{
			if(r->cnext == nullptr){
				tail = r->cprev;
				r->cprev->cnext = nullptr;
				r->cprev = nullptr;
			}
			else{
				r->cprev->cnext = r->cnext;
				r->cnext->cprev = r->cprev;
				r->cprev = nullptr;
				r->cnext = nullptr;
			}
		}
		return r;
	}
};

///////////////////////////////////////////////////////////////////////////

#define STACK_ENTRIES ((8192 / sizeof(uint64_t)))
#define REG_SPACE (8 * 6)

class Routine;
template <typename T> class Channel;

class Routine {
public:
    uint64_t saved_rsp = 0;
	Routine *next = nullptr;
	Routine *prev = nullptr;
	Routine *cnext = nullptr;
	Routine *cprev = nullptr;
	std::function<void()> func = nullptr;
};

///////////////////////////////////////////////////////////////////////////
extern "C" Routine** current();
extern void nextRoutine();
extern void block(Routine* r);
extern void add(Routine* r);
extern void check();

template <typename T>
class Channel {
    Channel() {}
    T val;
	Queue<Routine> senders;
	Queue<Routine> receivers;
	bool senderHeadIn = false;
	bool receiverHeadIn = false;
	bool poisoned = false;
public:
    void poison() {
        poisoned = true;
//		printf("%d\n", senderHeadIn);
//		printf("%d\n", receiverHeadIn);
//		printf("%p\n", senders.getHead());
//		printf("%p\n", receivers.getHead());
		if(senderHeadIn){
			senders.remove(true);
			senderHeadIn = false;
		}
		while(senders.getHead()!=nullptr){
			add(senders.getHead());
			senders.remove(true);
		}

		if(receiverHeadIn){
			receivers.remove(true);
			receiverHeadIn = false;		
		}
		while(receivers.getHead()!=nullptr){
			add(receivers.getHead());
			receivers.remove(true);
		}
    }

    T receive(bool* flag) {
		*flag = false;
        if(poisoned){
			*flag = true;		
			return val;
		}
		Routine* receiver = *current();
		receivers.add(receiver, true);
        if(receivers.getHead()!=receiver){
			block(receiver);
			nextRoutine();
		}
		receiverHeadIn = true;
        if(poisoned){
			*flag = true;			
			return val;
		}
		if(senders.getHead() == nullptr){
			receiverHeadIn = false;
			block(receiver);
			nextRoutine();
		}
        if(poisoned){
			*flag = true;			
			return val;
		}
		add(senders.getHead());
		senderHeadIn = true;

		senders.remove(true);
		senderHeadIn = false;

		receivers.remove(true);
		receiverHeadIn = false;

		if(senders.getHead() != nullptr){
			add(senders.getHead());
			senderHeadIn = true;
		}
		if(receivers.getHead() != nullptr){
			receiverHeadIn = true;
			add(receivers.getHead());
		}
        return val;
    }

    T receive() {
//		printf("starting receive\n");
//		check();
        if(poisoned){	
			return val;
		}
		Routine* receiver = *current();
		receivers.add(receiver, true);
//		check();
        if(receivers.getHead()!=receiver){
			block(receiver);
			nextRoutine();
		}
//		printf("Routine Head!\n");
		receiverHeadIn = true;
        if(poisoned){		
			return val;
		}
		if(senders.getHead() == nullptr){
//			printf("no sender :(\n");
			receiverHeadIn = false;
			block(receiver);
			nextRoutine();
		}
        if(poisoned){			
			return val;
		}
		add(senders.getHead());
		senderHeadIn = true;

		senders.remove(true);
		senderHeadIn = false;

		receivers.remove(true);
		receiverHeadIn = false;

		if(senders.getHead() != nullptr){
			add(senders.getHead());
			senderHeadIn = true;
		}
		if(receivers.getHead() != nullptr){
			receiverHeadIn = true;
			add(receivers.getHead());
		}
        return val;
    }

    void send(T v, bool* flag) {
		*flag = false;
        if(poisoned){
			*flag = true;			
			return;
		}
		Routine* sender = *current();
		senders.add(sender, true);
		if(senders.getHead() != sender){
			block(sender);
			nextRoutine();
		}
		senderHeadIn = true;
        if(poisoned){
			*flag = true;			
			return;
		}
		val = v;
		if(receivers.getHead() == nullptr){
			block(sender);
			senderHeadIn = false;
			nextRoutine();
		}
		else{
			add(receivers.getHead());
			receiverHeadIn = true;
			senderHeadIn = false;
			block(sender);
			nextRoutine();
		}
        if(poisoned){
			*flag = true;			
			return;
		}
    }

    void send(T v) {
        if(poisoned){			
			return;
		}
		Routine* sender = *current();
		senders.add(sender, true);
		if(senders.getHead() != sender){
			block(sender);
			nextRoutine();
		}
		senderHeadIn = true;
        if(poisoned){		
			return;
		}
		val = v;
		if(receivers.getHead() == nullptr){
			block(sender);
			senderHeadIn = false;
			nextRoutine();
		}
		else{
			add(receivers.getHead());
			receiverHeadIn = true;
			senderHeadIn = false;
			block(sender);
			nextRoutine();
		}
        if(poisoned){		
			return;
		}
    }

    static shared_ptr<Channel<T>> make() {
//		printf("making\n");
		current();
//		check();
        return shared_ptr<Channel<T>>(new Channel<T>());
    }

};

/////////////////////////////////////////////////////////////////////

extern void go(std::function<void()> func);

#endif

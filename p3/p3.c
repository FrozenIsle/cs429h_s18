#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <setjmp.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/stat.h>
#include <inttypes.h>
#include <ctype.h>

#define MISSING() printf("missing %s:%d\n",__FILE__,__LINE__)
#define PRIME 999983
#define MAXCHAR 127

/* Kinds of tokens */
enum Kind {
    ELSE,    // else 0
    END,     // <end of string> 1
    EQ,      // = 2
    EQEQ,    // == 3
    ID,      // <identifier> 4
    IF,      // if 5
    INT,     // <integer value > 6
    LBRACE,  // { 7
    LEFT,    // ( 8
    MUL,     // * 9
    NONE,    // <no valid token> 10
    PLUS,    // + 11
    PRINT,   // print 12
    RBRACE,  // } 13
    RIGHT,   // ) 14 
    SEMI,    // ; 15
    WHILE,    // while 16
	FUN,
	RUN			
};

static int check2();

/* information about a token */
struct Token {
    enum Kind kind;
    uint64_t value;
    char *ptr;
    char *start;
    char *end;
};

/* the symbol table */

typedef struct Symbol {
    struct Symbol *next;
    char* id;
    uint64_t value;
	int isfun;
}Symbol;

/* The current token */
static struct Token current = { NONE, 0, NULL, NULL, NULL };
static char *pointer = NULL;
static Symbol table[PRIME] = {{NULL, NULL, 0}, {NULL, NULL, 1}};

static jmp_buf escape;

static char *remaining() {
    return pointer;
}

static void error() {
    printf("error at '%s'\n", remaining());
    longjmp(escape, 1);
}

int hasher (char* id){
    int val = 0;
    while((*id >= 'a' && *id <= 'z') || (*id >= '0' && *id <= '9')){
        val *= 10;
        val %= PRIME;
        val += *id;
        val %= PRIME;
        id++;
    }
    return val;
}

void sAdd (Symbol *symbol, char *id, uint64_t value, int isfun){
    if(symbol->id == NULL||check2(symbol->id, id)){
        symbol->id = id;
        symbol->value = value;
		symbol->isfun = isfun;
    }
    else{
        if(symbol->next == NULL){
            symbol->next = (Symbol*)malloc(sizeof(Symbol));
        }
        sAdd(symbol->next, id, value, isfun);
    }
}

void set(char *id, uint64_t value, int isfun) {
    int hash = hasher(id);
    sAdd(&table[hash], id, value, isfun);
}

uint64_t sGet(Symbol *symbol, char *id){
    if(symbol->id == NULL){
        set(id, 0, 0);
		return 0;
    }
    if(check2(id, symbol->id))
        return symbol->value;
    if(symbol->next == NULL){
        set(id, 0, 0);
		return 0;
	}
    return sGet(symbol->next, id);
}

uint64_t get(char *id) {
    int hash = hasher(id);
    return sGet(&table[hash], id);
}

enum Kind peek();

enum Kind peek() {
    return current.kind;
}

static int check(char* word){
//    printf("startcheck\n");
    char *checker = current.start;
    while(*word != 0){
//        printf("%c\n", *word);
        if(checker == current.end || *checker != *word)
            return 0;
        checker++;
        word++;
    }
    if(checker != current.end)
        return 0;
    return 1;
}

static int check2(char *word1, char *word2){
    while(isalnum(*word1)){
        if(*word1 != *word2)
            return 0;
        word1++;
        word2++;
    }
    if(isalnum(*word2))
        return 0;
    return 1;
}

static int notchar(char* pointer){
	return isalnum(*pointer) == 0 &&
        *pointer != '=' && *pointer != '(' && *pointer != ')' && *pointer != '{' && *pointer != '}' &&
        *pointer != '+' && *pointer != '*' && *pointer != ';';
}

static void create() {
//    printf("create\n");
    if(current.start == NULL)
        error();
    else if(current.kind == ID){
        if(check("print")){
//          printf("checked\n");
            current.kind = PRINT;
        }
        else if(check("if")){
			current.kind = IF;
        }
		else if(check("else"))
			current.kind = ELSE;
		else if(check("while"))
			current.kind = WHILE;
		else if(check("fun"))
			current.kind = FUN;
    }
    else if(current.kind == INT){
//        printf("start int\n");
        uint64_t val = 0;
//        printf("%ld\n", current.end - current.start);
        while(current.start != current.end){
            if(*current.start == '_'){
                current.start++;
                continue;
            }
            uint64_t nextVal = *current.start - '0';
            if(nextVal < 0 || nextVal > 9)
                error();
            val *= 10;
            val += nextVal;
            current.start++;
        }
        current.value = val;
    }
}

void consume() {
    current = (struct Token){ .kind = NONE, .value = 0, .ptr = NULL, .start = NULL, .end = NULL };
    if(pointer == NULL)
        error();
    while(notchar(pointer)){
        if(*pointer == '$'){
            current.kind = END;
            break;
        }
        pointer++;
    }
    if(isalpha(*pointer)){
        current.kind = ID;
        current.start = pointer;
        while(isalnum(*pointer)){
            pointer++;
		}
		char* spointer = pointer;
		int isrun = 1;
		while(notchar(spointer)){
        	if(*spointer == '$'){
				isrun = 0;
            	break;
       		}
        	spointer++;
   		}
		if(*spointer != '(')
			isrun = 0;
		spointer++;
		while(notchar(spointer)){
        	if(*spointer == '$'){
				isrun = 0;
            	break;
       		}
        	spointer++;
   		}
		if(*spointer != ')')
			isrun = 0;
		spointer++;
		if(isrun){
			current.kind = RUN;
			pointer = spointer;
		}
        current.end = pointer;
        create();
    }
    else if(isdigit(*pointer)){
//        printf("int pointer\n");
        current.kind = INT;
        current.start = pointer;
        while(isdigit(*pointer) || *pointer == '_')
            pointer++;
        current.end = pointer;
        create();
    }
    else if(*pointer == '='){
        if(*(pointer + 1) == '='){
            current.kind = EQEQ;
            pointer += 2;
        }
        else{
            current.kind = EQ;
            pointer++;
        }
    }
    else if(*pointer == '*'){
        current.kind = MUL;
        pointer++;
    }
    else if(*pointer == '+'){
        current.kind = PLUS;
        pointer++;
    }
    else if(*pointer == '('){
        current.kind = LEFT;
        pointer++;
    }
    else if(*pointer == ')'){
        current.kind = RIGHT;
        pointer++;
    }
	else if(*pointer == '{'){
		current.kind = LBRACE;
		pointer++;
	}
	else if(*pointer == '}'){
		current.kind = RBRACE;
		pointer++;
	}
	else if(*pointer == ';'){
		current.kind = SEMI;
		pointer++;
	}
}

char *getId(void) {
    return current.start;
}

uint64_t getInt(void) {
    return current.value;
}

uint64_t expression(int run);
uint64_t statement(int run);
void seq(int run);

/* handle id, literals, and (...) */
uint64_t e1(int run) {
    if (peek() == LEFT) {
        consume();
        uint64_t v = expression(run);
        if (peek() != RIGHT) {
            error();
        }
        consume();
        return v;
    } else if (peek() == INT) {
        uint64_t v = getInt();
        consume();
		if(run)
        	return v;
		else
			return 0;
    } else if (peek() == ID) {
        char *id = getId();
        consume();
		if(run)
        	return get(id);
		else
			return 0;
    } else if(peek() == FUN) {
		uint64_t v = (uint64_t) pointer;
		consume();
		statement(0);
		return v;
	} 
	else {
        error();
        return 0;
    }
}

/* handle '*' */
uint64_t e2(int run) {
    uint64_t value = e1(run);
    while (peek() == MUL) {
        consume();
		if(run)        
			value = value * e1(run);
		else
			e1(run);
    }
    return value;
}

/* handle '+' */
uint64_t e3(int run) {
    uint64_t value = e2(run);
    while (peek() == PLUS) {
        consume();
		if(run)
        	value = value + e2(run);
		else
			e2(run);
    }
    return value;
}

/* handle '==' */
uint64_t e4(int run) {
    uint64_t value = e3(run);
    while (peek() == EQEQ) {
        consume();
		if(run)
        	value = value == e3(run);
		else
			e3(run);
    }
    return value;
}

uint64_t expression(int run) {
    return e4(run);
}

uint64_t statement(int run) {
    switch(peek()) {
    case NONE: {
        consume();
        return 1;
    }
    case ID: {
        char *id = getId();
        consume();
        if(peek()!=EQ)
            error();
        consume();
        uint64_t v = expression(run);
//		printf("%s\n", current.start);
//		printf("%d\n", peek() == FUN);
		if(peek() == FUN){
			if(run)
				set(id, v, 1);
		}
        else{
			if(run)
	        	set(id, v, 0);
		}
        return 1;
    }
    case LBRACE:
        consume();
        seq(run);
        if (peek() != RBRACE)
            error();
        consume();
		if(peek() == SEMI)
			consume();
        return 1;
    case IF: {
        consume();
        uint64_t v = expression(run);
        if(v == 0){
            statement(0);
			if(peek() == ELSE){
				consume();
				statement(run);
			}
			else if(peek() == SEMI)
				consume();
		}
		else{
			statement(run);
			if(peek() == ELSE){
				consume();
				statement(0);
			}
			else if(peek() == SEMI){
				consume();
			}
		}
        return 1;
    }
    case WHILE: {
		char* loopstart = pointer;
        consume();
		uint64_t v = expression(run);
		while(v != 0 && run){
			statement(run);
			pointer = loopstart;
			consume();
			v = expression(run);
		}
		statement(0);
		if(peek() == SEMI)
			consume();
        return 1;
    }
    case PRINT:
        consume();
        uint64_t v = expression(run);
        if(run)
            printf("%"PRIu64"\n",v);
		if(peek() == SEMI)
			consume();
        return 1;
	case RUN:
//		printf("running\n");
		if(run){
			uint64_t currPointer = (uint64_t) pointer;
			pointer = (char*)get(getId());
			consume();
			statement(run);
			pointer = (char*)currPointer;
		}
		consume();
		return 1;
    default:
        return 0;
    }
}

void seq(int run) {
    while (statement(run)) ;
}

void program(void) {
    seq(1);
    if (peek() != END)
        error();
}

void interpret(char *prog) {
	current.kind = NONE;
	pointer = prog;
	int x = setjmp(escape);
	if (x == 0) {
		program();
	}
}

void printSymbol(Symbol *symbol){
    printf("%s ",symbol->id);
    printf("%"PRIu64"\n", symbol->value);
    printf("\n");
    return;
}

void initialize(){
    for(int x = 0;x<PRIME;x++){
        table[x] = (Symbol){NULL, NULL, 0};
    }
}

int main(int argc, char *argv[]) {
/*
    set("one", 1);
    set("two", 2);
    set("three", 3);
    printf("%"PRIu64"\n", get("one"));
    printf("%"PRIu64"\n", get("two"));
    printf("%"PRIu64"\n", get("three"));
    set("one", 11);
    printf("%"PRIu64"\n", get("one"));
    return 0;
*/
/*
    char* one = "11";
    char* two = "2";
    char* three = "112";
    char* four = "1";
    char* five = "11;";
    char* six = "11";
    char* seven = "11a";
    printf("%d\n", check2(one, two));
    printf("%d\n", check2(one, three));
    printf("%d\n", check2(one, four));
    printf("%d\n", check2(one, five));
    printf("%d\n", check2(one, six));
    printf("%d\n", check2(one, seven));
*/
/*
    initialize();
    sAdd(table, "zero", 0);
    sAdd(table, "one", 1);
    printf("%"PRIu64"\n",table[0].value);
    printf("%p\n", table[0].next);
    printf("%p\n", table[0].id);
    printf("%s\n", table[0].id);
    printf("%"PRIu64"\n",table[0].next->value);
    printf("%p\n", table[0].next->next);
    printf("%p\n", table[0].next->id);
    printf("%s\n", table[0].next->id);
*/
/*
    Symbol test = {NULL, "zero", 0};
    sAdd(&test, "one", 1);
    sAdd(&test, "two", 2);
    printSymbol(&test);
    printSymbol(test.next);
    printSymbol(test.next->next); 
*/
/*
    char* word1 = "6___9__999";
    pointer = word1;
    consume();
*/
/*
    current.kind = INT;
    current.start = word1;
    current.end = current.start + 3;
    create();
*/
/*
    printf("%d\n", current.kind);
    printf("%"PRIu64"\n", current.value);
*/
	char prog[1000000];
	FILE *f = fopen(argv[1], "r");
	char c;
	int count = 0;
	while(1){
		c = fgetc(f);
		if(c == EOF)
			break;
		prog[count] = c;
		count ++;
	}
    prog[count] = '$';
	initialize();
	interpret(prog);

    return 0;
    	
    return 0;


}

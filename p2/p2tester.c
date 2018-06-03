#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <setjmp.h>
#include <string.h>
#include <inttypes.h>

#define MISSING() printf("missing %s:%d\n",__FILE__,__LINE__)

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
    WHILE    // while 16
};

/* information about a token */
struct Token {
    enum Kind kind;
    uint64_t value;
    char *ptr;
    char *start;
    char *end;
};

/* The symbol table */

uint64_t get(char *id) {
    MISSING();
    return 0;
}

void set(char *id, uint64_t value) {
    MISSING();
}

/* The current token */
static struct Token current = { NONE, 0, NULL, NULL, NULL };
static char *pointer = NULL;

static jmp_buf escape;

enum Kind peek();

static char *remaining() {
    MISSING();
    return "xyz";
}

static void error() {
    printf("error at '%s'\n", remaining());
    longjmp(escape, 1);
}

enum Kind peek() {
    return current.kind;
}

static enum Kind create() {
    if(current.start == NULL)
        error();
    else if(strcmp(current.start, "print") == 0)
        current.kind = PRINT;
    else if(current.kind == INT){
        uint64_t val = 0;
        while(*current.start != 0){
            if(*current.start == '_')
                continue;
            uint64_t nextVal = *current.start - '0';
            if(nextVal < 0 | nextVal > 9)
                error();
            val *= 10;
            val += nextVal;
            current.start++;
        }
        current.value = val;
    }
}

sstatic int check(char* word){
    char *checker = current.start;
    while(*word != 0){
        if(checker == current.end || *checker != *word)
            return 0;
        checker++;
        word++;
    }
    if(checker != current.end){
        return 0;
    return 1;
}

void consume() {
    current = (struct Token){ .kind = NONE, .value = 0, .ptr = NULL, .start = NULL, .end = NULL };
    if(pointer == NULL)
        error();
    else if(*pointer == 0)
        current.kind = END;
    else if((*pointer >= 'a') && (*pointer <= 'z')){
        current.start = pointer;
        while(*pointer >= 'a' && *pointer <= 'z') || (*pointer >= '0' && *pointer <= '9'))
            pointer++;
        current.end = pointer;
        create();
    }
    else if((*pointer >= '0') && (*pointer <= '9')){
        current.kind = INT;
        current.start = pointer;
        while(*pointer >= 0 || *pointer <= 9)
            pointer++;
        current.end = pointer;
        create();
    }
    while(*pointer != 0){
}
}

char *getId(void) {
    MISSING();
    return "current id";
}

uint64_t getInt(void) {
    MISSING();
    return 0;
}

uint64_t expression(void);
void seq(int doit);

/* handle id, literals, and (...) */
uint64_t e1(void) {
    if (peek() == LEFT) {
        consume();
        uint64_t v = expression();
        if (peek() != RIGHT) {
            error();
        }
        consume();
        return v;
    } else if (peek() == INT) {
        uint64_t v = getInt();
        consume();
        return v;
    } else if (peek() == ID) {
        char *id = getId();
        consume();
        return get(id);
    } else {
        error();
        return 0;
    }
}

/* handle '*' */
uint64_t e2(void) {
    uint64_t value = e1();
    while (peek() == MUL) {
        consume();
        value = value * e1();
    }
    return value;
}

/* handle '+' */
uint64_t e3(void) {
    uint64_t value = e2();
    while (peek() == PLUS) {
        consume();
        value = value + e2();
    }
    return value;
}

/* handle '==' */
uint64_t e4(void) {
    uint64_t value = e3();
    while (peek() == EQEQ) {
        consume();
        value = value == e3();
    }
    return value;
}

uint64_t expression(void) {
    return e4();
}

uint64_t statement(int doit) {
    switch(peek()) {
    case NONE: {
        consume();
        return 1;
    }
    case ID: {
        char *id = getId();
        consume();
        if (peek() != EQ)
            error();
        consume();
        uint64_t v = expression();
        if (doit)
            set(id, v);

        if (peek() == SEMI) {
            consume();
        }

        return 1;
    }
    case LBRACE:
        consume();
        seq(doit);
        if (peek() != RBRACE)
            error();
        consume();
        return 1;
    case IF: {
        MISSING();
        return 1;
    }
    case WHILE: {
        MISSING();
        return 1;
    }
    case PRINT:
        consume();
        printf("%ld\n",expression());
        return 1;
    case SEMI:
        consume();
        return 1;
    default:
        return 0;
    }
}

void seq(int doit) {
    while (statement(doit)) ;
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

int main(int argc, char *argv[]) {
    char* word1 = "hello";
    current.start = word1;
    current.end = current.start + 5;
    printf("%d", check("hello")
/*
    interpret(argv[1]);
    return 0;
*/
}

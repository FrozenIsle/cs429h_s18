use std::char;
use std::env;

use std::io;
use std::fs::File;
use std::io::prelude::*;
use std::io::{BufRead, BufReader};

const PRIME: usize = 49999;
const MAXCHAR: u64 = 127;

#[derive(PartialEq, Debug)]
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
}
struct Token {
    KIND: Kind,
    value: u64,
    ptr: usize,
    start: usize,
    end: usize
}

struct Statics{
	current: Token,
	chars: [char;1000000],
	pointer: usize,
}

#[derive(Default)]
struct Symbol {
    next: Option<Box<Symbol>>,
    id: usize,
    value: u64,
	isfun: u64,
}

fn change(test: &mut Statics){
	test.pointer += 5;
}

fn hasher(statics: &mut Statics, mut id: usize) -> usize{
	let mut val = 0;
    while(statics.chars[id] >= 'a' && statics.chars[id] <= 'z') || (statics.chars[id] >= '0' && statics.chars[id] <= '9'){
        val *= 10;
        val %= PRIME;
        val += statics.chars[id] as usize;
        val %= PRIME;
        id = id + 1;
    }
    return val;
}

fn check2(statics: &mut Statics, mut word1: usize, mut word2: usize) -> bool{
	while statics.chars[word1].is_alphanumeric() {
		if(statics.chars[word2] != statics.chars[word1]){
			return false;
		}
		word1 += 1;
		word2 += 1;
	}
	if(statics.chars[word2].is_alphanumeric()){
		return false;
	}
	return true;
}

fn sAdd(statics: &mut Statics, symbol: &mut Symbol, id: usize, value: u64, isfun: u64){
	if(symbol.isfun == 69 || check2(statics, symbol.id, id)){
		symbol.id = id;
		symbol.value = value;
		symbol.isfun = isfun;
	}
	else{
		if(symbol.next.is_none()){
			let mut next = Symbol{ next: None, id: 0, value: 0, isfun: 69};
			sAdd(statics, &mut next, id, value, isfun);
			symbol.next = Some(Box::new(next));
		}	
	}
}

fn set(statics: &mut Statics, table: &mut [Symbol; PRIME], id: usize, value: u64, isfun: u64){
	let hash = hasher(statics, id);
	sAdd(statics, &mut table[hash], id, value, isfun);
}

fn sGet(statics: &mut Statics, symbol: &mut Symbol, id: usize) -> u64{
	if(symbol.isfun == 69){
		sAdd(statics, symbol, id, 0, 0);
		return 0;
	}
	if(check2(statics, id, symbol.id)){
		return symbol.value;
	}
	match symbol.next{
		None => {
			sAdd(statics, symbol, id, 0, 0,);
			return 0;
		}
		Some(ref mut next) => {
			return sGet(statics, next, id);
		}
	}
}

fn get(statics: &mut Statics, table: &mut [Symbol; PRIME], id: usize) -> u64{
	let hash: usize = hasher(statics, id);
	return sGet(statics, &mut table[hash], id);
}

fn check(statics: &mut Statics, word: &[char]) -> bool{
//    printf("startcheck\n");
	let mut checker: usize = statics.current.start;
	let mut wordi: usize = 0;
    while(wordi < word.len()){
//        printf("%c\n", *word);
        if(checker == statics.current.end || statics.chars[checker] != word[wordi]){
            return false;
		}
        checker += 1;
        wordi += 1;
    }
    if(checker != statics.current.end){
        return false;
	}
    return true;
}

fn notchar(statics: &mut Statics, pointer: usize) -> bool{
	return statics.chars[pointer].is_alphanumeric() == false &&
        statics.chars[pointer] != '=' && statics.chars[pointer] != '(' && statics.chars[pointer] != ')' && statics.chars[pointer] != '{' && statics.chars[pointer] != '}' &&
        statics.chars[pointer] != '+' && statics.chars[pointer] != '*' && statics.chars[pointer] != ';';
}

fn create(statics: &mut Statics) {
//    printf("create\n");
    if(statics.current.KIND == Kind::ID){
        if(check(statics, &['p','r','i','n','t'])){
//          printf("checked\n");
            statics.current.KIND = Kind::PRINT;
        }
        else if(check(statics, &['i','f'])){
			statics.current.KIND = Kind::IF;
        }
		else if(check(statics, &['e','l','s','e'])){
			statics.current.KIND = Kind::ELSE;
		}
		else if(check(statics, &['w','h','i','l','e'])){
			statics.current.KIND = Kind::WHILE;
		}
		else if(check(statics, &['f','u','n'])){
			statics.current.KIND = Kind::FUN;
		}
    }
    else if(statics.current.KIND == Kind::INT){
//        printf("start int\n");
        let mut val: u64 = 0;
//        printf("%ld\n", current.end - current.start);
        while(statics.current.start != statics.current.end){
            if(statics.chars[statics.current.start] == '_'){
                statics.current.start += 1;
                continue;
            }
			let tempVal = statics.chars[statics.current.start].to_digit(10);
			let mut nextVal: u64 = 0;
			match tempVal{
				None => {}
				Some(value) => { nextVal = value as u64}
			}
            if(nextVal < 0 || nextVal > 9){
                error("creat fuk");
			}
            val *= 10;
            val += nextVal;
            statics.current.start += 1;
        }
        statics.current.value = val;
    }
}

fn consume(statics: &mut Statics) {
    statics.current = Token{KIND: Kind::NONE, value: 0, ptr: 0, start:0, end: 0};
    //if(pointer == NULL){
        //error();
	//}
	let mut temp = statics.pointer;
    while(notchar(statics,temp)){
        if(statics.chars[statics.pointer] == '$'){
            statics.current.KIND = Kind::END;
            break;
        }
        statics.pointer += 1;
		temp = statics.pointer;
    }
    if(statics.chars[statics.pointer].is_alphabetic()){
        statics.current.KIND = Kind::ID;
        statics.current.start = statics.pointer;
        while(statics.chars[statics.pointer].is_alphanumeric()){
            statics.pointer += 1;
		}
		let mut spointer: usize = statics.pointer;
		let mut isrun = 1;
		while(notchar(statics, spointer)){
        	if(statics.chars[spointer] == '$'){
				isrun = 0;
            	break;
       		}
        	spointer += 1;
   		}
		if(statics.chars[spointer] != '('){
			isrun = 0;
		}
		spointer += 1;
		while(notchar(statics, spointer)){
        	if(statics.chars[spointer] == '$'){
				isrun = 0;
            	break;
       		}
        	spointer += 1;
   		}
		if(statics.chars[spointer] != ')'){
			isrun = 0;
		}
		spointer += 1;
		if(isrun == 1){
			statics.current.KIND = Kind::RUN;
			statics.pointer = spointer;
		}
        statics.current.end = statics.pointer;
        create(statics);
    }
    else if(statics.chars[statics.pointer].is_numeric()){
//        printf("int pointer\n");
        statics.current.KIND = Kind::INT;
        statics.current.start = statics.pointer;
        while(statics.chars[statics.pointer].is_numeric() || statics.chars[statics.pointer] == '_'){
            statics.pointer += 1;
		}
        statics.current.end = statics.pointer;
        create(statics);
    }
    else if(statics.chars[statics.pointer] == '='){
        if(statics.chars[statics.pointer + 1] == '='){
            statics.current.KIND = Kind::EQEQ;
            statics.pointer += 2;
        }
        else{
            statics.current.KIND = Kind::EQ;
            statics.pointer += 1;
        }
    }
    else if(statics.chars[statics.pointer] == '*'){
        statics.current.KIND = Kind::MUL;
        statics.pointer += 1;
    }
    else if(statics.chars[statics.pointer] == '+'){
        statics.current.KIND = Kind::PLUS;
        statics.pointer += 1;
    }
    else if(statics.chars[statics.pointer] == '('){
        statics.current.KIND = Kind::LEFT;
        statics.pointer += 1;
    }
    else if(statics.chars[statics.pointer] == ')'){
        statics.current.KIND = Kind::RIGHT;
        statics.pointer += 1;
    }
	else if(statics.chars[statics.pointer] == '{'){
		statics.current.KIND = Kind::LBRACE;
		statics.pointer += 1;
	}
	else if(statics.chars[statics.pointer] == '}'){
		statics.current.KIND = Kind::RBRACE;
		statics.pointer += 1;
	}
	else if(statics.chars[statics.pointer] == ';'){
		statics.current.KIND = Kind::SEMI;
		statics.pointer += 1;
	}
}


fn e1(statics: &mut Statics, table: &mut [Symbol; PRIME], run: u64) -> u64 {
    if (statics.current.KIND == Kind::LEFT) {
        consume(statics);
        let v: u64 = expression(statics, table, run);
        if (statics.current.KIND != Kind::RIGHT) {
            error("e1 fuk");
        }
        consume(statics);
        return v;
    } else if (statics.current.KIND == Kind::INT) {
        let v: u64 = statics.current.value;
        consume(statics);
		if(run == 1){
        	return v;
		}
		else{
			return 0;
		}
    } else if (statics.current.KIND == Kind::ID) {
        let id = statics.current.start;
        consume(statics);
		if(run == 1){
        	return get(statics, table, id);
		}
		else{
			return 0;
		}
    } else if(statics.current.KIND == Kind::FUN) {
		let v: u64 = statics.pointer as u64;
		consume(statics);
		statement(statics, table, 0);
		return v;
	} 
	else {
//		println!("{} {} {} {:?}",statics.pointer, statics.current.start, statics.current.end, statics.current.KIND);
        error("e1 2nd fuk");
        return 0;
    }
}


fn e2(statics: &mut Statics, table: &mut [Symbol; PRIME], run: u64) -> u64 {
    let mut value: u64 = e1(statics, table, run);
    while (statics.current.KIND == Kind::MUL) {
        consume(statics);
		if(run == 1){        
			value = value * e1(statics, table, run);
		}
		else{
			e1(statics, table, run);
		}    
	}
    return value;
}


fn e3(statics: &mut Statics, table: &mut [Symbol; PRIME], run: u64) -> u64 {
    let mut value: u64 = e2(statics, table, run);
    while (statics.current.KIND == Kind::PLUS) {
        consume(statics);
		if(run == 1){
        	value = value + e2(statics, table, run);
		}	
		else{
			e2(statics, table, run);
		}
    }
    return value;
}


fn e4(statics: &mut Statics, table: &mut [Symbol;PRIME], run: u64) -> u64 {
    let mut value: u64 = e3(statics, table, run);
    while (statics.current.KIND == Kind::EQEQ) {
        consume(statics);
		if(run == 1){
        	if(value == e3(statics, table, run)){
				value = 1;
			}
			else{
				value = 0;
			}
		}
		else{
			e3(statics, table, run);
		}
    }
    return value;
}

fn expression(statics: &mut Statics, table: &mut [Symbol; PRIME], run: u64) -> u64 {
    return e4(statics, table, run);
}

fn statement(statics: &mut Statics, table: &mut[Symbol; PRIME], run: u64) -> u64 {
//	println!("{:?}, {:?}, {:?}. {:?}", statics.pointer, statics.current.start, statics.current.KIND, run);
//	return 0;
    match(statics.current.KIND) {
    Kind::NONE => {
//		return 0;
        consume(statics);
        return 1;
    }
   Kind::ID => {
        let id: usize = statics.current.start;
        consume(statics);
        if(statics.current.KIND != Kind::EQ){
            error("ID Fuk");
		}
        consume(statics);
        let mut v: u64 = expression(statics, table, run);
//		printf("%s\n", current.start);
//		printf("%d\n", peek() == FUN);
		if(statics.current.KIND == Kind::FUN){
			if(run == 1){
				set(statics, table, id, v, 1);
			}
		}
        else{
			if(run == 1){
	        	set(statics, table, id, v, 0);
			}
		}
        return 1;
    }
    Kind::LBRACE => {
        consume(statics);
        seq(statics, table, run);
        if (statics.current.KIND != Kind::RBRACE){
            error("lb fuk");
		}
        consume(statics);
		if(statics.current.KIND == Kind::SEMI){
			consume(statics);
		}
        return 1;
	}
    Kind::IF => {
        consume(statics);
        let mut v = expression(statics, table, run);
        if(v == 0){
            statement(statics, table, 0);
			if(statics.current.KIND == Kind::ELSE){
				consume(statics);
				statement(statics, table, run);
			}
			else if(statics.current.KIND == Kind::SEMI){
				consume(statics);
			}
		}
		else{
			statement(statics, table, run);
			if(statics.current.KIND == Kind::ELSE){
				consume(statics);
				statement(statics, table, 0);
			}
			else if(statics.current.KIND == Kind::SEMI){
				consume(statics);
			}
		}
        return 1;
    }
    Kind::WHILE => {
		let loopstart: usize = statics.pointer;
        consume(statics);
		let mut v = expression(statics, table, run);
		while(v != 0 && run == 1){
			statement(statics, table, run);
			statics.pointer = loopstart;
			consume(statics);
			v = expression(statics, table, run);
		}
		statement(statics, table, 0);
		if(statics.current.KIND == Kind::SEMI){
			consume(statics);
		}
        return 1;
    }
    Kind::PRINT => {
        consume(statics);
        let v = expression(statics, table, run);
		if(run == 1){
        	println!("{}",v);
		}		
		if(statics.current.KIND == Kind::SEMI){
			consume(statics);
		}
        return 1;
	}
	Kind::RUN => {
//		printf("running\n");
		if(run == 1){
			let currPointer: usize = statics.pointer;
			let tempstart = statics.current.start;
			statics.pointer = get(statics, table, tempstart) as usize;
			consume(statics);
			statement(statics, table, run);
			statics.pointer = currPointer;
		}
		consume(statics);
		return 1;
	}
    _ => {
        return 0;
    }
	}

}

fn seq(statics: &mut Statics, table: &mut [Symbol;PRIME], run: u64) {
    while (statement(statics, table, run) == 1){}
}

fn program(statics: &mut Statics, table: &mut [Symbol;PRIME]) {
    seq(statics, table, 1);
    if (statics.current.KIND != Kind::END){
        error("end fuk");
	}
}

fn interpret(statics: &mut Statics, table: &mut [Symbol;PRIME], prog: usize) {
	statics.current.KIND = Kind::NONE;
	statics.pointer = prog;
	program(statics, table);
}

fn printSymbol(symbol: &Symbol){
    return;
}

fn main() {
	/*
	let mut current = Token{KIND: Kind::NONE, value: 0, ptr: 0, start:0, end: 0};
    let mut pointer: usize = 0;
	let mut table: [Symbol; PRIME] = unsafe { std::mem::uninitialized() };
	for i in table.iter_mut() {
    	let z = std::mem::replace(i, Symbol{next: None, id: 0, value: 0, isfun: 69});
    	unsafe { std::mem::forget(z)};
	}
	let chars: [char;6] = ['a','b','$','a','b', '$'];
	let print: [char;2] = ['a','b'];
	let mut test: u64 = 1;
	let chars2: [char;100000] = ['a';100000];
	let mut t = Statics{current: current, chars: chars2, pointer: pointer};
	change(&mut t);
	println!("{}",t.pointer);
//	println!("{}",check(&print, &chars, 0, 3));
	*/

	
	let mut statics = Statics{current: Token{KIND: Kind::NONE, value: 0, ptr: 0, start:0, end: 0}, pointer: 0, chars: ['$';1000000]};

	let mut table: [Symbol; PRIME] = unsafe { std::mem::uninitialized() };
	for i in table.iter_mut() {
    	let z = std::mem::replace(i, Symbol{next: None, id: 0, value: 0, isfun: 69});
    	unsafe { std::mem::forget(z)};
	}

	let filename = env::args().nth(1).expect("Missing argument");
//	println!("{:?}", filename);
	let mut f = BufReader::new(File::open(filename).expect("open failed"));
	let mut cindex: usize = 0;
    for line in f.lines() {
        for c in line.expect("lines failed").chars() {
            statics.chars[cindex] = c;
			cindex += 1;
//			print!("{}",c);
        }
		statics.chars[cindex] = '\n';
		cindex += 1;
//		println!();
    }
//	println!();
//	println!("{}",statics.pointer);
	interpret(&mut statics, &mut table, 0);
}

fn error(err: &str){
	println!("{}",err);
}

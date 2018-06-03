package main

import (
	//"bufio"
	"fmt"
	//"io"
	"io/ioutil"
	"os"
	"strings"
)

type Kind int

const (
	ELSE Kind = 0 + iota
	END
	EQ
	EQEQ
	ID
	IF
	INT
	LBRACE
	LEFT
	MUL
	NONE
	PLUS
	PRINT
	RBRACE
	RIGHT
	WHILE
	FUNC
)

var kinds = [...]string{
	"ELSE",
	"END",
	"EQ",
	"EQEQ",
	"ID",
	"IF",
	"INT",
	"LBRACE",
	"LEFT",
	"MUL",
	"NONE",
	"PLUS",
	"PRINT",
	"RBRACE",
	"RIGHT",
	"WHILE",
	"FUNC",
}

// Return string of the kind
func (k Kind) String() string { return kinds[k] }

type token struct {
	name string
	kind Kind
	//valString string
	//valFloat float
	valInt int
	//valChar string
}

func tokenize(data string) {

}

func check(e error) {
	if e != nil {
		panic(e)
	}
}

func main() {
	args := os.Args[1:]
	argsString := strings.Join(args, " ")
	dat, err := ioutil.ReadFile(argsString)
	check(err)
	fmt.Print(string(dat))
	tokenize(string(dat))
	//kind := Kind(3)
	//fmt.Println(kind)
	//fmt.Printf("Hello, world.\n")
}

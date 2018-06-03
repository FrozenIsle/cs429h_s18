package main

import (
        //"bufio"
        "fmt"
        //"io"
        "io/ioutil"
        "math"
        "os"
        "strconv"
        "strings"
        "unicode"
)

type Kind int

var current *token = nil
var head *token = nil

//each of these tables maps id to respective value
var intMap map[string]uint64
var floatMap map[string]float64
var charMap map[string]string
var stringMap map[string]string

//this table maps id to its type, so get method knows which hashmap to look
var typeMap map[string]string

var tokenPtrs [1000000]*token
var nextFunc int = 0

const (
        ELSE = iota
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
        //new types
        FLOAT
        STRING
        CHAR
        DIV
        FOR
        LESS
        MORE
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
        //new types
        "FLOAT",
        "STRING",
        "CHAR",
        "DIV",
        "FOR",
        "LESS",
        "MORE",
}

// Return string of the kind
//func (k Kind) String() string { return kinds[k] }

type twople struct {
        valString string
        valFloat  float64
        valInt    uint64
        valChar   string
        valType   string
}

type token struct {
        name string
        kind Kind

        /*valString string
        valFloat  float64
        valInt  int
        valChar string*/

        value twople

        next   *token
        length uint64
}

//helper methods to check if a string is alphanumeric
func isLetter(s string) bool {
        for _, r := range s {
                if !unicode.IsLetter(r) {
                        return false
                }
        }
        return true
}

func isDigit(s string) bool {
        for _, r := range s {
                if !unicode.IsDigit(r) {
                        return false
                }
        }
        return true
}

/*func isFloat(s string) bool {
        decimal := false
        for _, r := range s {
                if !unicode.IsDigit(r) {
                        if !decimal && r == '.' {
                                decimal = true
                        } else {
                                return false
                        }
                }
        }
        return true
}*/

//------GET METHODS-------
//no overloading in go, so individual methods for retrieving each type
func getChar(id string) string {
        return charMap[id]
}

func getString(id string) string {
        return stringMap[id]
}

func getFloat(id string) float64 {
        return floatMap[id]
}

func getInteger(id string) uint64 {
        var val = intMap[id]
        return val
}

//get type of this id, then can use to call right method
func getType(id string) string {
        return typeMap[id]
}

func get(id string) twople {
        varType := typeMap[id]
        if varType == "" {
                var temp twople
                temp.valType = "int"
                set(id, temp)
                varType = "int"
        }

        var returnString string = ""
        var returnChar string = ""
        var returnFloat float64 = 0
        var returnInt uint64 = 0
        var returnType string

        switch varType {
        case "String":
                returnString = getString(id)
                returnType = "String"
        case "char":
                returnChar = getChar(id)
                returnType = "char"
        case "float":
                returnFloat = getFloat(id)
                returnType = "float"
        case "int":
                returnInt = getInteger(id)
                returnType = "int"
        default:

        }
        var temp twople
        temp.valString = returnString
        temp.valFloat = returnFloat
        temp.valInt = returnInt
        temp.valChar = returnChar
        temp.valType = returnType
        return temp
}

//-----SET METHODS-------

func setInt(id string, val uint64) {
        intMap[id] = val
}

func setFloat(id string, val float64) {
        floatMap[id] = val
}

func setString(id string, val string) {
        stringMap[id] = val
}

func setChar(id string, val string) {
        charMap[id] = val
}

func set(id string, value twople) {
        typeMap[id] = value.valType
        switch value.valType {
        case "int":
                //this might be problematic
                //temp, _ := strconv.ParseUint(value, 10, 64)
                setInt(id, value.valInt)
        case "float":
                //temp, _ := strconv.ParseFloat(value, 64)
                setFloat(id, value.valFloat)
        case "char":
                setChar(id, value.valChar)
        case "String":
                setString(id, value.valString)
        default:
                fmt.Println("invalid type")
        }
}

func peek() Kind {
        return current.kind
}

func consume() {
        current = current.next
}

func getId() string {
        return current.name
}

func getInt() uint64 {
        return current.value.valInt
}

func getfloat() float64 {
        return current.value.valFloat
}

func getValue() twople {
        return current.value
}

func e1() twople {
        if peek() == LEFT {
                consume()
                var v twople = expression()
                if peek() != RIGHT {
                        fmt.Println("first error\n")
                        //call an error method
                        //error()
                }
                consume()
                return v
        }

        if peek() == INT || peek() == FLOAT || peek() == CHAR || peek() == STRING {
                //fmt.Println("I recognize it's an int")
                var v twople = getValue()
                consume()
                var temp twople
                temp.valInt = v.valInt
                temp.valString = v.valString
                temp.valFloat = v.valFloat
                temp.valChar = v.valChar
                temp.valType = v.valType
                return temp
        }

        /*if peek() == FLOAT {
                var v float64 = getfloat()
                consume()
                var temp twople
                temp.valInt = 0
                temp.valString = ""
                temp.valFloat = v
                temp.valChar = ""
                temp.valType = "float"
                return temp
        }*/

        if peek() == ID {
                var id string = getId()
                consume()
                return get(id)
        }

        if peek() == FUNC {
                consume()
                tokenPtrs[nextFunc] = current
                var temp1 uint64 = uint64(nextFunc)
                nextFunc++
                //var c uint64 = uint64(current)
                var temp twople
                temp.valInt = temp1
                temp.valString = ""
                temp.valFloat = 0
                temp.valChar = ""
                temp.valType = "int"
                statement(0)
                return temp
        }
        //fmt.Println(current.kind)
        fmt.Println("second error")
        //error();
        var temp twople
        return temp
}

func e2() twople {
        var value twople = e1()
        for peek() == MUL || peek() == DIV {
                if peek() == MUL {
                        consume()
                        temp := e1()
                        value.valFloat = value.valFloat * temp.valFloat
                        value.valInt = value.valInt * temp.valInt

                        if value.valType == "String" || value.valType == "char" || temp.valType == "String" || temp.valType == "char" {

                                stringBase := value.valString + value.valChar + temp.valString + temp.valChar
                                var stringMul float64 = float64(value.valInt) + value.valFloat + float64(temp.valInt) + temp.valFloat

                                stringHole := math.Floor(stringMul)
                                var stringAnswer string

                                for i := 0; i < int(stringHole); i++ {
                                        stringAnswer = stringAnswer + stringBase
                                }

                                stringFrac := uint64((stringMul - stringHole) * float64(len(stringBase)))

                                stringAnswer = stringAnswer + stringBase[0:stringFrac]

                                var valU twople
                                valU.valType = "String"
                                valU.valString = stringAnswer

                                value = valU
                        }

                        //do nothing for strings (as of right now)
                } else if peek() == DIV {
                        consume()
                        temp := e1()
                        //divide by 0 problem
                        //fmt.Println(temp.valType, temp.valInt, temp.valFloat)
                        if temp.valFloat == 0 && temp.valInt == 0 {
                                Error("divide by 0 error")
                        }
                        if value.valType == "float" {
                                if temp.valType == "float" {
                                        value.valFloat = value.valFloat / temp.valFloat
                                } else {
                                        value.valFloat = value.valFloat / float64(temp.valInt)
                                }
                        } else if value.valType == "int" {
                                if temp.valType == "float" {
                                        value.valType = "float"
                                        value.valFloat = float64(value.valInt) / temp.valFloat
                                        value.valInt = 0
                                } else {
                                        value.valInt = value.valInt / temp.valInt
                                }
                        } else if value.valType == "String" || value.valType == "char" {
                                stringBase := value.valString + value.valChar
                                var stringMul float64 = 1 / (float64(temp.valInt) + temp.valFloat)

                                stringHole := math.Floor(stringMul)
                                var stringAnswer string

                                for i := 0; i < int(stringHole); i++ {
                                        stringAnswer = stringAnswer + stringBase
                                }

                                stringFrac := uint64((stringMul - stringHole) * float64(len(stringBase)))

                                stringAnswer = stringAnswer + stringBase[0:stringFrac]

                                var valU twople
                                valU.valType = "String"
                                valU.valString = stringAnswer

                                value = valU
                        }
                }
        }
        return value
}

func e3() twople {
        var value twople = e2()
        for peek() == PLUS {
                consume()
                //value = value + e2()
                temp := e2()
                value.valFloat = value.valFloat + temp.valFloat
                value.valInt = value.valInt + temp.valInt
                if value.valType == "String" || value.valType == "char" || temp.valType == "String" || temp.valType == "char" {
                        value.valType = "String"
                }
                value.valString = value.valString + temp.valString + value.valChar + temp.valChar
                value.valChar = ""
                temp.valChar = ""
        }
        return value
}

func e4() twople {
        var value twople = e3()
        if peek() == EQEQ {
                //only 1 valid value per tuple, other number value is a 0.
                //consequently, comparisons compare float to float and
                //int to int. The type not being compared will be a 0, so
                //will always be equal, so it is ok to AND it with the actual
                //comparison.
                consume()
                //value = (value == e3())
                temp := e3()

                tempVal := temp.valFloat + float64(temp.valInt)
                valVal := value.valFloat + float64(value.valInt)
                if math.Abs(valVal-tempVal) < 0.000001 {
                        value.valInt = 1
                } else {
                        value.valInt = 0
                }

                value.valFloat = 0
                value.valString = ""
                value.valChar = ""
                value.valType = "int"

        } else if peek() == LESS {
                consume()
                //value = (value == e3())
                temp := e3()

                tempVal := temp.valFloat + float64(temp.valInt)
                valVal := value.valFloat + float64(value.valInt)
                if math.Abs(valVal-tempVal) < 0.000001 || valVal > tempVal {
                        value.valInt = 0
                } else {
                        value.valInt = 1
                }
                value.valFloat = 0
                value.valString = ""
                value.valChar = ""
                value.valType = "int"

        } else if peek() == MORE {
                consume()
                //value = (value == e3())
                temp := e3()
                tempVal := temp.valFloat + float64(temp.valInt)
                valVal := value.valFloat + float64(value.valInt)
                if math.Abs(valVal-tempVal) < 0.000001 || valVal < tempVal {
                        value.valInt = 0
                } else {
                        value.valInt = 1
                }

                value.valFloat = 0
                value.valString = ""
                value.valChar = ""
                value.valType = "int"

        }
        return value
}

func expression() twople {
        return e4()
}

func statement(doit int) uint64 {
        switch peek() {
        case ID:
                {
                        var id string = getId()
                        consume()
                        if peek() == LEFT {
                                consume()
                                if peek() == RIGHT {
                                        consume()
                                        if doit != 0 {
                                                //fmt.Println("i run a function")
                                                var recent *token = current
                                                current = tokenPtrs[get(id).valInt]
                                                //fmt.Println("i update current")
                                                statement(doit)
                                                //fmt.Println("i successfully run statement")
                                                current = recent
                                                //current = (token*) get(id)
                                        }
                                }
                        } else {
                                consume()
                                var v twople = expression()
                                if doit != 0 {
                                        set(id, v)
                                }
                                //    }
                                //}
                        }
                        return 1
                }
        case LBRACE:
                {
                        consume()
                        seq(doit)
                        if peek() != RBRACE {
                                fmt.Println("third error")
                                //error()
                        }
                        consume()
                        return 1
                }
        case IF:
                {
                        consume()
                        var v twople = expression()
                        if v.valInt != 0 {

                                statement(doit)
                                if peek() == ELSE {
                                        consume()
                                        statement(0)
                                }
                        } else {
                                statement(0)
                                if peek() == ELSE {
                                        consume()
                                        statement(doit)
                                }
                        }
                        return 1
                }
        case WHILE:
                {
                        for true {
                                var start *token = current
                                consume()
                                var v twople = expression()
                                var cont = 0
                                if v.valInt != 0 && doit != 0 {
                                        cont = 1
                                }
                                statement(cont)
                                if cont == 0 {
                                        return 1
                                }
                                current = start
                        }
                }

        case FOR:
                {
                        consume()
                        start := expression()
                        end := expression()

                        for i := start.valInt; i < end.valInt; i++ {
                                var start *token = current
                                statement(doit)
                                current = start
                        }
                }

        case PRINT:
                {
                        //fmt.Println("i get to print")
                        consume()
                        if doit != 0 {
                                var temp twople = expression()
                                //fmt.Println(temp.valType)
                                switch temp.valType {
                                case "String":
                                        fmt.Println(temp.valString)
                                case "char":
                                        fmt.Println(temp.valChar)
                                case "int":
                                        //fmt.Println("finding an int return")
                                        fmt.Println(temp.valInt)
                                case "float":
                                        fmt.Println(temp.valFloat)
                                }
                        } else {
                                expression()
                        }
                        return 1
                }

        default:
                {
                        return 0
                }
        }
        return 0
}

func seq(doit int) {
        for statement(doit) != 0 {
        }
}

func program() {
        seq(1)
        //if peek() != END {
        //              fmt.Println("")
        //      }
}

func makeToken(name string, kind Kind, value twople, length uint64) {
        var tt token
        var t *token = &tt
        t.name = name
        t.kind = kind
        t.value = value
        t.length = length
        if head == nil {
                current = t
                head = current
        } else {
                current.next = t
                current = current.next
        }

        //fmt.Println(kinds[t.kind], value.valFloat)

}
func newToken(s string) {
        var temp twople
        switch s {
        case "{":
                makeToken("", LBRACE, temp, 0)
        case "(":
                makeToken("", LEFT, temp, 0)
        case "*":
                makeToken("", MUL, temp, 0)
        case "/":
                makeToken("", DIV, temp, 0)
        case "+":
                makeToken("", PLUS, temp, 0)
        case "}":
                makeToken("", RBRACE, temp, 0)
        case ")":
                makeToken("", RIGHT, temp, 0)
        case "<":
                makeToken("", LESS, temp, 0)
        case ">":
                makeToken("", MORE, temp, 0)
        case ";":
                fmt.Println("Bruh, no semicolons")
        }
}

func idfinder(data string, i uint64) uint64 {
        //var length uint64 = 0
        var start uint64 = i
        end := i
        for end < uint64(len(data)) && (isDigit(data[end:end+1]) || isLetter(data[end:end+1])) {
                end++
        }
        /*for isDigit(data[i:i+1]) || isLetter(data[i:i+1]) {
                i++
                length++
        }

        var unknown string
        var place uint64 = 0
        var temp twople

        for start < i {
                if place == 0 {
                        unknown = data[start : start+1]
                } else {
                        unknown += data[start : start+1]
                        start++
                        place++
                }
        }*/

        var temp twople
        temp.valChar = ""
        temp.valString = ""
        temp.valInt = 0
        temp.valFloat = 0.0

        var word string = data[start:end]

        switch word {
        case "if":
                makeToken("", IF, temp, 0)
        case "fun":
                makeToken("", FUNC, temp, 0)
        case "else":
                makeToken("", ELSE, temp, 0)
        case "while":
                makeToken("", WHILE, temp, 0)
        case "for":
                makeToken("", FOR, temp, 0)
        case "print":
                makeToken("", PRINT, temp, 0)
        default:
                makeToken(word, ID, temp, 0)
        }

        /*if length == 2 {
                if unknown[0:1] == "i" && unknown[1:2] == "f" {
                        makeToken("", IF, temp, 0)
                } else {
                        makeToken(unknown, ID, temp, length)
                }
        } else {
                if length == 3 {
                        if unknown[0:2] == "fun" {
                                makeToken("", FUNC, temp, 0)
                        } else {
                                makeToken(unknown, ID, temp, length)
                        }
                } else {
                        if length == 4 {
                                if unknown[0:3] == "else" {
                                        makeToken("", ELSE, temp, 0)
                                } else {
                                        makeToken(unknown, ID, temp, length)
                                }
                        } else {
                                if length == 5 {
                                        if unknown[0:4] == "while" {
                                                makeToken("", WHILE, temp, 0)
                                        } else {
                                                if unknown[0:4] == "print" {
                                                        makeToken("", PRINT, temp, 0)
                                                } else {
                                                        makeToken(unknown, ID, temp, length)
                                                }
                                        }
                                } else {
                                        //length 6+
                                        makeToken(unknown, ID, temp, length)
                                }
                        }
                }
        }
        i--*/
        return end - 1
}

//method that converts a string into a uint64 OR a float, returns both
func valueFinder(data string, i uint64) uint64 {
        //fmt.Println("starting value finder")
        var value uint64 = 0
        var floatVal float64 = 0.0
        seenPoint := false
        var decimalCt uint64 = 0
        //var temp float64 = 0.0
        //valid for numbers, _'s (ignored), and a singal decimal point
        for isDigit(data[i:i+1]) || data[i:i+1] == "_" || (data[i:i+1] == "." && !seenPoint) {
                //fmt.Println(data[i : i+1])
                //encounter decimal point, switch modes
                if data[i:i+1] == "." {
                        seenPoint = true
                        i++
                        floatVal = float64(value)
                        continue
                }

                if !seenPoint {
                        if isDigit(data[i : i+1]) {
                                //var x uint64
                                //parse digit into uint64, store in x
                                x, _ := strconv.ParseUint(data[i:i+1], 10, 64)
                                value = value * 10
                                value += x
                        }
                } else {
                        //case where we deal with numbers after decimal point
                        if isDigit(data[i : i+1]) {
                                decimalCt++
                                ii := decimalCt
                                //parse into float, store in temp
                                temp, _ := strconv.ParseFloat(data[i:i+1], 64)

                                for ii > 0 {
                                        temp = temp / 10
                                        ii--
                                }

                                floatVal += temp
                        }
                }

                i++
        }

        var tempTwople twople
        tempTwople.valChar = ""
        tempTwople.valString = ""
        if !seenPoint {
                tempTwople.valInt = value
                tempTwople.valFloat = 0
                tempTwople.valType = "int"
                makeToken("", INT, tempTwople, 0)
        } else {
                tempTwople.valInt = 0
                tempTwople.valFloat = floatVal
                tempTwople.valType = "float"
                makeToken("", FLOAT, tempTwople, 0)
        }
        //fmt.Println(tempTwople.valType, tempTwople.valFloat)
        i--
        return i
}

func charFinder(data string, i uint64) uint64 {
        //var length uint64 = 0
        if i+2 >= uint64(len(data)) {
                Error("bad character")
        }

        var char string = data[i+1 : i+2]

        var temp twople
        temp.valChar = char
        temp.valString = ""
        temp.valInt = 0
        temp.valFloat = 0.0
        temp.valType = "char"

        if data[i+2:i+3] != "'" {
                Error("bad character 2")
        }
        makeToken("", CHAR, temp, 0)
        return i + 2
}

func stringFinder(data string, i uint64) uint64 {
        var start uint64 = i + 1
        end := start
        for end < uint64(len(data)) && data[end:end+1] != "\"" {
                end++
        }

        if data[end:end+1] != "\"" {
                Error("bad string")
        }

        var temp1 string = data[start:end]

        var temp twople
        temp.valChar = ""
        temp.valString = temp1
        temp.valInt = 0
        temp.valFloat = 0.0
        temp.valType = "String"

        makeToken("", STRING, temp, 0)

        return end
}

/*func floatFinder(data string, i uint64) float64 {
    var value float64
    for isDigit(data[i:i+1]) || data[i:i+1] == "_" || data[i:i+1] == "."{

    }
}*/

/*
NOTE, not sure if char comparison/string slicing is correct due to go's
weird as funk rune system. Also, not sure if I'm using enum correctly.
*/
func tokenize(data string) {

        var temp twople
        var ii uint64 = 0
        for i := ii; i < uint64(len(data)); i++ {
                //fmt.Println(i)
                newToken(data[i : i+1])
                // Looking for either = or ==
                if data[i:i+1] == "=" {
                        if i+1 < uint64(len(data)) && data[i+1:i+2] == "=" {
                                makeToken("", EQEQ, temp, 0)
                                i++
                                continue
                        } else {
                                makeToken("", EQ, temp, 0)
                                continue
                        }
                }

                if isLetter(data[i : i+1]) {
                        i = idfinder(data, i)
                        continue
                }

                /*if isFloat(data[i : i+1]) {
                        i = floatFinder(data, i)
                        continue
                }*/

                if isDigit(data[i : i+1]) {
                        i = valueFinder(data, i)
                        continue
                }

                if data[i:i+1] == "'" {
                        i = charFinder(data, i)
                        continue
                }

                if data[i:i+1] == "\"" {
                        i = stringFinder(data, i)
                }

        }
        makeToken("", END, temp, 0)
        current = head
}

func check(e error) {
        if e != nil {
                panic(e)
        }
}

func Error(input string) {
        fmt.Println(input)
        os.Exit(3)
}

func printTokens() {
        memes := head
        for memes != nil {
                fmt.Println(kinds[memes.kind], memes.value.valString, memes.value.valChar)
                memes = memes.next
        }
}

func main() {
        intMap = make(map[string]uint64)
        floatMap = make(map[string]float64)
        charMap = make(map[string]string)
        stringMap = make(map[string]string)
        typeMap = make(map[string]string)
        //fmt.Println(ELSE)
        //fmt.Println(IF)
        /*      var temp twople
                temp.valInt = 0
                temp.valFloat = 0
                temp.valString = ""
                temp.valChar = ""
                makeToken("", ID, temp, 0)*/
        args := os.Args[1:]
        argsString := strings.Join(args, " ")
        dat, err := ioutil.ReadFile(argsString)
        check(err)
        //fmt.Println(isLetter(string(dat)[0:1]))
        //fmt.Print(string(dat))
        tokenize(string(dat))
        //printTokens()
        //kind := Kind(3)
        //fmt.Println(kind)
        //fmt.Printf("Hello, world.\n")
        current = head
        program()
        //current = head
        /*for current != nil {
                fmt.Println(kinds[current.kind]+" "+current.name+" %d", current.value.valInt)
                current = current.next
        }*/
        //os.Exit(3)
}

package main

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:slice"
import "core:mem"
import "core:bytes"
import "core:math/big"
import "core:unicode/utf8"
import "core:math"

OPERATORS :: "*/+-"
ALPHABET :: "abcdefghijklmnopqrstuvwxyz"

Token :: struct {
    type : rune,
    value : [8]byte
}

main :: proc() {

    // when ODIN_DEBUG {
	// 	track: mem.Tracking_Allocator
	// 	mem.tracking_allocator_init(&track, context.allocator)
	// 	context.allocator = mem.tracking_allocator(&track)

	// 	defer {
	// 		if len(track.allocation_map) > 0 {
	// 			fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
	// 			for _, entry in track.allocation_map {
	// 				fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
	// 			}
	// 		}
	// 		mem.tracking_allocator_destroy(&track)
	// 	}
	// }

    buf : [8]byte
    expression : [dynamic]string
    exp_ptr := &expression
    str : string
    
    state := "INPUT"
    for state != "STOP" {
        switch state {
        case "INPUT" :
            state, str = input_state()
        case "PARSE" : 
            state, exp_ptr^ = parse_state(str)
        case "EVALUATE" : 
            state = evaluate_state(buf[:], exp_ptr)
        case "OUTPUT" :
            fmt.println(expression[0])
            state = "CLEAR"
        case "CLEAR" :
            clear(exp_ptr)
            state = "INPUT"
        }
    }
}

input_state :: proc() -> (string, string) {
    buf : [256]byte
    ok : bool

    fmt.println("Please enter a math expression.")
    num_byte, err := os.read(os.stdin, buf[:])
    str := string(buf[:])
    str = clean_string(str)
    str, ok = strings.remove_all(str, " ")

    if str == "STOP" || str == "stop" || str == "Stop" {
        return "STOP", ""
    } 
    else if len(str) < 3 || strings.contains_any(str, OPERATORS) == false || strings.contains_any(str, ALPHABET) == true  {
        fmt.println("Invalid Input. Try again.")
        return "CLEAR", ""
    } else {
        return "PARSE", str
    }
}

parse_state :: proc(str : string) -> (string, [dynamic]string) {
    temp : f64
    number : string; defer delete(number)
    ok : bool
    expression : [dynamic]string
    numarr : [dynamic]string; defer delete(numarr)

    for i := 0; i < len(str); i += 1 {
        temp, ok = strconv.parse_f64(strings.cut(str, i, 1))
        if ok == true {
            append(&numarr, strings.cut(str, i, 1))
        } 
        else if ok == false && strings.cut(str, i, 1) == "." {
            append(&numarr, strings.cut(str, i, 1))
        } 
        else {
            number = strings.join(numarr[:], "")
            clear(&numarr)
            append(&expression, number)
            append(&expression, strings.cut(str, i, 1))
        }
    }
    append(&expression, strings.cut(str, len(str)-1, 1))
    return "EVALUATE", expression
}

evaluate_state :: proc(buf : []byte, darray : ^[dynamic]string) -> (string) {
    operators := OPERATORS; defer delete(operators)
    operand1, operand2, result : f64
    ok : bool

    for i := 0; i < len(OPERATORS); i += 1 {
        for j := 0; j < len(darray); j += 1 {
            if darray[j] == strings.cut(operators, i, 1) {
                operand1, ok = strconv.parse_f64(darray[j-1])
                operand2, ok = strconv.parse_f64(darray[j+1])
                if strings.cut(operators, i, 1) == "*" {
                    result = operand1 * operand2
                }
                else if strings.cut(operators, i, 1) == "/" {
                    result = operand1 / operand2
                }
                else if strings.cut(operators, i, 1) == "+" {
                    result = operand1 + operand2
                }
                else if strings.cut(operators, i, 1) == "-" {
                    result = operand1 - operand2
                }
                darray[j-1] = string(strconv.generic_ftoa(buf[:], result, 'f', 2, 64))
                j -= 1
                ordered_remove(darray, j+2)
                ordered_remove(darray, j+1)
            }
        }
    }
    return "OUTPUT"
}

/*
Removes "\r\n" strings and null runes.
*/
clean_string :: proc(s : string) -> (res: string) {
    str, ok := strings.remove_all(s, "\r\n")
    str = strings.trim_null(str)
    return str
}
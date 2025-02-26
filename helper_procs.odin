package main

//Imports
import "core:strings"
import "core:strconv"
import "core:os"


parse_f64_from_input :: proc (buf : []byte) -> (res : f64, ok : bool) {
    str := string(buf[:])
    str = clean_string(str)
    return strconv.parse_f64(str)
}

parse_int_from_input :: proc (buf : []byte) -> (res : int, ok : bool) {
    str := string(buf[:])
    str = clean_string(str)
    return strconv.parse_int(str)
}
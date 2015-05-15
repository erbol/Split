//: Playground - noun: a place where people can play

import Cocoa

let numberOfPlaces = 2.0
let multiplier = pow(10.0, numberOfPlaces)
let num = 10.12345

// Отбрасываем дробную часть числа с помощью функции round
let rounded = round(10.12345 * multiplier) / multiplier
println(rounded)



var isObjectInside = false
let serverPoint = CGPointMake(78,157)
let frame = CGRectMake(31, 207, 98, 28)
if(CGRectContainsPoint(frame, serverPoint))
{
    isObjectInside = true
}
else
{
    isObjectInside = false
    
}


var square = 9.4
// floor - округление
var floored = floor(square)
var root = sqrt(floored)

println("Starting with \(square), we rounded down to \(floored), then took the square root to end up with \(root)")


var f: CGFloat = 4.01
var roundedF = CGFloat(ceil(Double(f)))
// функция ceil округляет к целому числу, в сторону большего целого значения
func ceil(f: CFloat) -> CFloat {
    return ceilf(f)
}

var roundedF1: CGFloat = ceil(f)

// Аргументом функции log10 должен быть тип Double
let o = log10(822.0)


func test(p1: Int?) {
    if let val = p1 {
        print(p1!)
    } else {
        print(p1)
    }
}

test(2)

func test1(p1: Int?) {
    if p1 > 0 {
        print(p1!)
    } else {
        print(p1)
    }
}

test1(-2)

func test2(p1: Int?) {
    if (p1 != nil) {
        print(p1!)
    } else {
        print(p1)
    }
}
test2(-2)
var origin:Int? = nil
var graphCenter = 7
origin =  origin ?? graphCenter

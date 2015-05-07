//
//  CalculatorGraphic.swift
//  GraficCosinus
//
//  Created by erbol on 15.04.15.
//  Copyright (c) 2015 erbol. All rights reserved.
//

import Foundation
// Чтобы работать с CG (Core graphic) нужно импортировать UIKit
import UIKit

extension String {
    func toDouble() -> Double? {
        // numberFromString это метод класса NSNumberFormatter, он извлекает из строки число
        // возвращает либо число либо nil
        // Этот метод имеет свойство doubleValue
        return NSNumberFormatter().numberFromString(self)?.doubleValue
    }
}

class CalculatorGraphic{
    // Абстрактный  объект для хранения символов операций и значений их приоритетов
    enum Oper:Printable {
        case Value(String,Int)
 
        var description:String{
            get{
                switch self{
                case .Value(let symbol,_):
                    return symbol
                }
            }
        }
        
        var precedence:Int{
            get{
                switch self{
                case .Value(_,let number):
                    return number
                }
            }
        }
    }
    
    private enum Op : Printable{
        case Operand(Double)
        // Для BinaryOperation
        // Первый аргумент - символ операции
        // второй аргумент(целого типа) приоритет(precedence) операции
        // третий аргумент - операция математическая
        // последний аргумент замыкание обрабатывающее ошибки и возвращающее сообщения об ошибке
        case UnaryOperation(String,Double->Double,(Double->String?)?)
        case BinaryOperation(String, UInt8, (Double,Double)->Double,(Double->String?)?)
        case Variable(String)
        case Constant(String, ()->Double)
        
        var precedence:UInt8{
            get{
                switch self{
                case .BinaryOperation(_,let precedence, _,_):
                    return precedence
                default:
                    return UInt8.max
                }
            }
        }
        
        var description:String{
            get{
                switch self{
                case .Operand(let operand):
                    return "\(operand)"
                case .Variable(let symbol):
                    return symbol
                case .UnaryOperation(let symbol, _, _):
                    return symbol
                case .BinaryOperation(let symbol, _, _,_):
                    return symbol
                case .Constant(let symbol, _):
                    return symbol
                }
            }
        }
    }
    
    // Выходной массив
    // Массив для хранения операндов, функций и переменных
    private var opStack = [Op]()
    // Массив для хранения символов операций и значений их приоритетов
    private var stack = [Oper]()
    
    //Словарь для хранения символов функций и функционала - операнды плюс оператор соответсвующий функции
    private var knownOps = [String:Op]()
    // Словарь для ханения значений величин
    var variableValues = [String:Double]()
    
    // Массив куда помещается входная строка input
    var parse = [Character]()
    // Массив для хранения данных для построения кривой
    var data = [CGPoint]()

    

    
    
    
    
    
    // Заполняем словарь knownOps[String:Op]
    // Ключ - символ операции, значение - величина типа Op
    init() {
        func learnOp(op:Op){
            knownOps[op.description] = op
        }
        learnOp(Op.BinaryOperation("×", 10, *,nil))
        learnOp(Op.BinaryOperation("+", 1, +,nil))
        learnOp(Op.BinaryOperation("÷",10,{$1/$0}) {$0 == 0.0 ? "Деление на нуль" : nil})
        learnOp(Op.BinaryOperation("−", 4,{$1-$0},nil))
        learnOp(Op.UnaryOperation("√",sqrt) {$0<0 ? "√ отриц. числа" : nil})
        learnOp(Op.UnaryOperation("sin",sin, nil))
        learnOp(Op.UnaryOperation("cos",cos, nil))
        learnOp(Op.UnaryOperation("±", { -$0 }, nil))
        learnOp(Op.Constant("π",{M_PI}))
        learnOp(Op.Constant("e",{M_E}))
        
        learnOp(Op.Variable("M"))
    }

    
    func  graphData(left:Int,right:Int, scale:CGFloat)->[CGPoint]{
        

        // Если стек с выражением пустой то возвращаем пустой массив с данными
        if opStack.isEmpty {return []}
        // Очищаем массив
        data = []
        for var i = left; i < right; i += 1 {
            // Подставляем значение для переменной М и вызываем функцию evaluate 
            // для получения значения функции
            // Полученные значения помещаем в массив Data
            
            // Задаем значение переменной от левой к правой границе интервала
            let varX = Double(CGFloat(i)/scale)
            variableValues["M"] = varX
            // Вычисляем выражение если его поместили в стек
            // Если стек выражения пустой то выходим
            var point = CGPoint.zeroPoint
            if !opStack.isEmpty{
                
                let varY = evaluate(opStack)
                if varY.result!.isNaN {
                    point = CGPoint(x: varX, y: 0)
                }else{
                    point = CGPoint(x: varX, y: varY.result!)
                }
                // Задаем значение для CG точки
                
            
                data.append(point)
            } else{
                println("opStack is empty")
                break
            }
            
        }
        //println(data)
        //println(data.count)

        return data
    }
    
    private func variableToEvaluate(symbolVariable:String)->Double?{
        if let variableValue = variableValues[symbolVariable] {
            return variableValue
        } else {
            return nil
        }
    }
    
    private func copyArrayAndTakeTopStack(ops:[Op])->([Op],Op){
        // Менять массив ops внутри функции нельзя, так как он передан по значению
        // Создаем новый массив remainStack, его можно менять, то есть выполнять removeLast() над ним
        var remainStack = ops
        let topStack = remainStack.removeLast()
        return (remainStack,topStack)
    }
    
    private func unaryOperationToEvaluate(ops:[Op],operation:Double->Double)->(Double?,[Op]){
        
        let (operand, remainingOps) = evaluate(ops)
        if let operand1 = operand{
            return (operation(operand1),remainingOps)
        }else{
            return (nil,remainingOps)
        }
    }
    
    private func binaryOperationToEvaluate(ops:[Op],operation:(Double,Double)->Double)->(Double?,[Op]){
        
        let (operand1, remainingOps1) = evaluate(ops)
        if let operandFirst = operand1{
            let (operand2, remainingOps2) = evaluate(remainingOps1)
            if let operandSecond = operand2{
                return (operation(operandFirst,operandSecond),remainingOps2)
            }else{
                return (nil,remainingOps2)
            }
        }else{
            return (nil,remainingOps1)
        }
    }
    
    private func evaluate(ops: [Op])  -> (result: Double?, remainingOps: [Op]){
        if !ops.isEmpty {
            let (remainingOps,op) = copyArrayAndTakeTopStack(ops)
            switch op{
            case .Operand(let operand): return(operand,remainingOps)
            case .Constant(_, let operation): return (operation(),remainingOps)
            case .Variable(let symbol): let variableValue = variableToEvaluate(symbol)
            return (variableValue, remainingOps)
            case .UnaryOperation(_,let operation, _): let (operand, remainingOps) = unaryOperationToEvaluate(remainingOps,operation: operation)
            return (operand, remainingOps)
            case .BinaryOperation(_, _, let operation,_): let (operand, remainingOps) = binaryOperationToEvaluate(remainingOps,operation: operation)
            return (operand, remainingOps)
            }
        }
        return (nil,ops)
    }

    private func clearArray(){
        println("Неопознан символ операции или константы")
        stack = []
        opStack = []
        parse = []
    }
    
    func parseString(input:String){
        
        // Очищаем стек
        opStack = []
        // Массив куда помещается входная строка input
        // Получаем массив Character
        parse = Array(input)
        //println(parse)
        // Строка куда помещаем очередной символ из массива parseArray для его анализа
        var buffer = ""
        // Читаем посимвольно массив parse и классифицируем его содержимое, слева-напрвво, до конца
        while !parse.isEmpty {
            // Помещаем очередной элемент массива в буфер
            var symbol = parse.removeAtIndex(0)
            //println(symbol)
            buffer = ""
            buffer.append(symbol)
            // Проверка символа - не число ли ?
            if let number = buffer.toDouble(){
                // Если число то :
                if parse.isEmpty{
                    // Если входной массив пустой, то вставляем число в выходной массив и заканчиваем парсинг
                    opStack += [Op.Operand(buffer.toDouble()!)]
                    break
                }else{
                    // Достаем число типа Double из входного массива и отправляем в выходной
                    numberIs(buffer)
                    // Берем очередной символ из входного массива
                    continue
                }
            }
            
            // Проверка символа - какая операция, константа или переменная
            
            switch symbol{
                // Константы и переменные
            case "π":
                if let operation = knownOps["π"]{
                    opStack += [operation]
                }
            case "e":
                if let operation = knownOps["e"]{
                    opStack += [operation]
                }
                
            case "M": opStack += [Op.Variable("M")]
                // Операции
            case "s":
                
                if parse.count >= 2 {
                    let first = parse.removeAtIndex(0)
                    let second = parse.removeAtIndex(0)
                    
                    if first == "i" && second == "n"{
                        pushStack(4)
                        stack += [.Value("sin",4)]
                    }else{
                        clearArray()
                        break
                    }
                }else{
                    clearArray()
                    break
                }

                

            case "c":
                if parse.count >= 2 {
                    let first = parse.removeAtIndex(0)
                    let second = parse.removeAtIndex(0)
                    
                    if first == "o" && second == "s"{
                        pushStack(4)
                        stack += [.Value("cos",4)]
                    }else{
                        clearArray()
                        break
                    }
                }else{
                    clearArray()
                    break
                }
                
            case "√":
                pushStack(4)
                stack += [.Value("√",4)]
            case "±":
                pushStack(4)
                stack += [.Value("±",4)]
            case "-":
                pushStack(2)
                stack += [.Value("−",2)]
            case "/":
                pushStack(3)
                stack += [.Value("÷",3)]
            case "+":
                pushStack(2)
                stack += [.Value("+",2)]
            case "×":
                pushStack(3)
                stack += [.Value("×",3)]
                // Скобки
            case "(": stack += [.Value("(",0)]
            case ")":
                var flag = true
                while flag && !stack.isEmpty{
                    let temp = stack.removeLast()
                    temp.description
                    if temp.description == "("{
                        flag = false
                    }else{
                        if let operation = knownOps[temp.description]{
                            opStack += [operation]
                        }
                    }
                }
            case " ": break
            default:
                
                
                clearArray()
                break // Если знак операции не известен удаляем данные из всех массивов где содержатся данные о строке с выражением
            }
            
        }
        // Если стек операций не пустой то переносим все операции в выходной стек
        while !stack.isEmpty{
            let temp = stack.removeLast()
            if let operation = knownOps[temp.description]{
                opStack += [operation]
            }
        }
        //println(opStack)
    }

    
    func parseString1(input:String){
        // Очищаем стек
        opStack = []
        // Массив куда помещается входная строка input
        // Получаем массив Character
        parse = Array(input)
        // Строка куда помещаем очередной символ из массива parseArray для его анализа
        var buffer = ""
        // Читаем посимвольно массив parse и классифицируем его содержимое, слева-напрвво, до конца
        while !parse.isEmpty {
            // Помещаем очередной элемент массива в буфер
            var symbol = parse.removeAtIndex(0)
            buffer = ""
            buffer.append(symbol)
            // Проверка символа - не число ли ?
            if let number = buffer.toDouble(){
                // Если число то :
                if parse.isEmpty{
                // Если входной массив пустой, то вставляем число в выходной массив и заканчиваем парсинг
                    opStack += [Op.Operand(buffer.toDouble()!)]
                    break
                }else{
                    // Достаем число типа Double из входного массива и отправляем в выходной
                    numberIs(buffer)
                    // Берем очередной символ из входного массива
                    continue
                }
            }

            // Проверка символа - какая операция, константа или переменная
            
            switch symbol{
                // Константы и переменные
            case "π":
                    if let operation = knownOps["π"]{
                        opStack += [operation]
                    }
            case "e":
                    if let operation = knownOps["e"]{
                        opStack += [operation]
                    }

            case "M": opStack += [Op.Variable("M")]
                // Операции
            case "s":
                let o = parse.removeAtIndex(0)
                if  o == "i"{
                    if parse.removeAtIndex(0) == "n"{
                        pushStack(4)
                        stack += [.Value("sin",4)]
                    }else{
                        clearArray()
                        break
                    }

                    
                }else{
                    if o == "q"{
                        if parse.removeAtIndex(0) == "r"{
                            if parse.removeAtIndex(0) == "t"{
                                pushStack(4)
                                stack += [.Value("√",4)]
                            }else{
                                clearArray()
                                break
                            }
                        }else{
                            clearArray()
                            break
                        }
                    }else{
                        clearArray()
                        break
                    }
                }
                
            case "c":
                    if parse.removeAtIndex(0) == "o"{
                        if parse.removeAtIndex(0) == "s"{
                            pushStack(4)
                            stack += [.Value("cos",4)]
                        }else{
                            clearArray()
                            break
                        }
                    }else{
                        clearArray()
                        break
                    }
                
                
            case "±":
                pushStack(4)
                stack += [.Value("±",4)]
            case "-":
                pushStack(2)
                stack += [.Value("−",2)]
            case "/":
                pushStack(3)
                stack += [.Value("÷",3)]
            case "+":
                pushStack(2)
                stack += [.Value("+",2)]
            case "×":
                pushStack(3)
                stack += [.Value("×",3)]
                // Скобки
            case "(": stack += [.Value("(",0)]
            case ")":
                    var flag = true
                    while flag && !stack.isEmpty{
                        let temp = stack.removeLast()
                        temp.description
                        if temp.description == "("{
                            flag = false
                        }else{
                            if let operation = knownOps[temp.description]{
                                opStack += [operation]
                            }
                        }
                    }
            default:
                // Если знак операции не известен удаляем данные из всех массивов где содержатся данные о строке с выражением
                clearArray()
                break
            }
                
        }
        // Если стек операций не пустой то переносим все операции в выходной стек
        while !stack.isEmpty{
            let temp = stack.removeLast()
            if let operation = knownOps[temp.description]{
                opStack += [operation]
            }
        }
        println(opStack)
    }
    
    /*
    private func pushStack1(s:Int){
        while !stack.isEmpty{
            // Достаем элемент из стека операций
            let temp = stack.removeLast()
            // Если дошли до открывающей скобки, то помещаем ее обратно в стек stack 
            // и выходим из цикла
            if temp.description == "("{
                stack += [.Value(temp.description,temp.precedence)]
                break
            }
            // Если приоритет temp больше или равен приоритету s (той операции которую нужно поместить в стек)
            // перемещаем операцию temp в выходной стек
            if temp.precedence>=s{
                if let operation = knownOps[temp.description]{
                    opStack += [operation]
                }
            // Если меньше , то помещаем операцию обратно в стек и выходим из цикла
            } else{
                stack += [.Value(temp.description,temp.precedence)]
                break
            }
        }
    }
    */
    
    // Если токен является оператором *, /, + или -, поместить его в opstack. Однако, перед этим вытолкнуть любой из операторов, уже находящихся в opstack, если он имеет больший или равный приоритет, и добавить его в результирующий список.
    
    // Если получаем со входа знак соответствующий оператору
    // надо выбрать из стека операций все операции приоритет которых
    // больше или равен приоритета  s (приоритет операции которую нужно вставить в стек операций)
    
    private func pushStack(s:Int){
        // Если стек пустой возврщаемся обратно
        if stack.isEmpty {return}
        // Создаем отображение массива stack
        var ref = stack.map{$0.precedence}
        //Удаляем все элементы которые больше s справо-налево, до тех пор пока s <= ref.first
        while !ref.isEmpty {
            if s <= ref.last {
                ref.removeLast()
            }else{
                break
            }
        }

        // Считаем разницу между длинами массивов
        let n = stack.count - ref.count
        // Удаляем из stack количество элементов n
        // и вставляем их в opStack
        for var i=0;i<n;++i{
            let oo = stack.removeLast()
            if let operation = knownOps[oo.description]{
                opStack += [operation]
            }else{}
        }
    }
    
    
    // Первый вариант функции
    private func numberIs(symbol:String){
        // Делаем отображение входного массива
        var ref = parse.map{String($0)}
        // Добавляем к нему слева анализируемый символ
        ref.insert(symbol,atIndex: 0)
        // Удаляем все элементы из массива которые не образуют число, удаляем справа-налево
        while true {
            // Создаем total строку из остатка массива
            let total = ref.reduce("",combine:+)//{$0 + $1}
            
            if let oo = total.toDouble(){
                // Если строка является числом, то выходим из цикла
                break
            }else{
                // Если полученная строка не является числом, то удаляем
                // правый крайний элемент массива
                ref.removeLast()
            }
        }
        
        // Вычисляем число как строку
        let number = ref.reduce("",combine:+)//{$0 + $1}
        // Помещаем его в выходной стек как число
        opStack += [Op.Operand(number.toDouble()!)]


        // Удаляем из входного массива все элементы числа  переданного в выходной массив
        let count = ref.count - 1
        for var i=0; i < count; ++i {
            parse.removeAtIndex(0)
        }
    }
    
}

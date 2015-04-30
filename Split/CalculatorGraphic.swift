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
    var origin = CGPoint(x: 200, y: 300)
    
    
    
    
    
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
        learnOp(Op.Constant("π",{M_PI}))
        learnOp(Op.Constant("e",{M_E}))
        learnOp(Op.Variable("M"))
    }

    
    func  graphData(left:Int,right:Int, scale:CGFloat)->[CGPoint]{
        

        data = []
        for var i = left; i < right; i += 1 {
            // Подставляем значение для переменной М и вызываем функцию evaluate 
            // для получения значения функции
            // Полученные значения помещаем в массив Data
            variableValues["M"] = Double(CGFloat(i)/scale)
            let oo = evaluate(opStack)
            var o = CGPoint(x: Double(CGFloat(i)/scale), y: oo.result!)
            
            data.append(o)
            
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

    
    
    func parseString(input:String){
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
            case "q":
                // корень квадратный
                
                pushStack(4)
                stack += [.Value("sqrt",4)]
                    
            case "s":
                    parse.removeAtIndex(0)
                    parse.removeAtIndex(0)
                    pushStack(4)
                    stack += [.Value("sin",4)]
            case "c":
                    parse.removeAtIndex(0)
                    parse.removeAtIndex(0)
                    pushStack(4)
                    stack += [.Value("cos",4)]
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
            default: break
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

import Foundation

class enumStack  {
    enum Op : Printable{
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
    var opStack = [Op]()
    
    //Словарь для хранения символов функций и функционала - операнды плюс оператор соответсвующий функции
    var knownOps = [String:Op]()
    // Словарь для ханения значений величин
    var variableValues = [String:Double]()

    // Заполняем словарь knownOps[String:Op]
    // Ключ - символ операции, значение - величина типа Op
    init() {
        func learnOp(op:Op){
            knownOps[op.description] = op
        }
        learnOp(.BinaryOperation("×", 10, *, nil))
        learnOp(.BinaryOperation("+", 1, +, nil))
        learnOp(.BinaryOperation("÷", 10, {$1/$0}, {$0 == 0.0 ? "Деление на нуль" : nil}))
        learnOp(.BinaryOperation("−", 4, {$1-$0}, nil))
        learnOp(.BinaryOperation("^", 15, {pow($1, $0)}, nil))
        learnOp(.UnaryOperation("√",sqrt, {$0<0 ? "√ отриц. числа" : nil}))
        learnOp(.UnaryOperation("sin",sin, nil))
        learnOp(.UnaryOperation("cos",cos, nil))
        learnOp(.UnaryOperation("tan",tan, nil))
        learnOp(.UnaryOperation("asin",asin, nil))
        learnOp(.UnaryOperation("acos",acos, nil))
        learnOp(.UnaryOperation("atan",atan, nil))
        learnOp(.UnaryOperation("exp",exp, nil))
        learnOp(.UnaryOperation("ln",log, nil))
        learnOp(.UnaryOperation("2log",log2, nil))
        
        learnOp(.UnaryOperation("±", { -$0 }, nil))
        learnOp(.Constant("π",{M_PI}))
        learnOp(.Constant("e",{M_E}))
        
        learnOp(.Variable("M"))
    }
    
    func variableToEvaluate(symbolVariable:String)->Double?{
        if let variableValue = variableValues[symbolVariable] {
            return variableValue
        } else {
            return nil
        }
    }
    
    func copyArrayAndTakeTopStack(ops:[Op])->([Op],Op){
        // Менять массив ops внутри функции нельзя, так как он передан по значению
        // Создаем новый массив remainStack, его можно менять, то есть выполнять removeLast() над ним
        var remainStack = ops
        let topStack = remainStack.removeLast()
        return (remainStack,topStack)
    }
    
    func unaryOperationToEvaluate(ops:[Op],operation:Double->Double)->(Double?,[Op]){
        
        let (operand, remainingOps) = evaluate(ops)
        if let o = operand{
            return (operation(operand!),remainingOps)
        }else{
            return (nil,remainingOps)
        }
    }
    
    func binaryOperationToEvaluate(ops:[Op],operation:(Double,Double)->Double)->(Double?,[Op]){
        
        let (operand1, remainingOps1) = evaluate(ops)
        if let o = operand1{
            let (operand2, remainingOps2) = evaluate(remainingOps1)
            if let o = operand2{
                return (operation(operand1!,operand2!),remainingOps2)
            }else{
                return (nil,remainingOps2)
            }
        }else{
            return (nil,remainingOps1)
        }
    }
    
    func evaluate(ops: [Op])  -> (result: Double?, remainingOps: [Op]){
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
    
    func evaluate()->Double?{
        let(result,remainder) = evaluate(opStack)
        
        // Чтобы при печати результата не было слова Optional
        /*
        if result != nil {
        println("\(opStack) = \(result!) with \(remainder) left over")
        }else{
        println("\(opStack) = nil with \(remainder) left over")
        }
        */
        return result
    }

}


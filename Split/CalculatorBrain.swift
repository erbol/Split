import Foundation


class CalculatorBrain {
    
    // enum Result - либо для значения стэка, либо для сообщения об ошибке
    // public, так как используется ViewController для получения оценки стэка
    enum Result:Printable {
        case Value(Double)
        case Error(String)
        
        var description:String{
            switch self{
            case .Value(let value):
                return CalculatorFormatter.sharedInstance.stringFromNumber(value)!
            case .Error(let errorMessage):
                return errorMessage
            }
        }
    }
    
    // Создаем тип данных Op, который представлен альтернативным списком именованных наборов величин
    // Например экземпляр типа с именем UnaryOperation состоит из трех величин - типа String, функции типа Double->Double
    // и функции типа (Double->String?)?
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
    

    // Массив для хранения операндов, функций и переменных
    private var opStack = [Op]()
    //Словарь для хранения символов функций и функционала - операнды плюс оператор соответсвующий функции
    private var knownOps = [String:Op]()
    // Словарь для ханения значений величин
    var variableValues = [String:Double]()
    
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
        learnOp(Op.UnaryOperation("±", { -$0 }, nil))
        learnOp(Op.Variable("M"))
    }
    
    func nonPrivateAPI(name:String,operand:Double=0.0,symbol:String=""){
        switch name{
        case "pushOperand" :
            // Вводим число в стек
            opStack.append(Op.Operand(operand))
        case "pushVariable" :
            // Вводим переменную в стек
            opStack.append(Op.Variable(symbol))
        case "performOperation" :
            // Выполняем операцию
            if let operation = knownOps[symbol]{
                opStack.append(operation)
            }
        case "clearArray" :
            // Очищаем стек
            opStack = []
        case "undo" :
            // Удаляем элемент с вершины стека
            if !opStack.isEmpty{
                opStack.removeLast()
            }
        case "enterVariable" :
            // Определяем значение для переменной М
            variableValues["M"] = operand
        default: break
        }
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
    
    func evaluate()->Double?{
        let(result,remainder) = evaluate(opStack)

        // Чтобы при печати результата не было слова Optional
        if let resultPrint = result {
            println("\(opStack) = \(resultPrint) with \(remainder) left over")
        }else{
            println("\(opStack) = nil with \(remainder) left over")
        }

        return result
    }
  
    private func binaryOperationToDescription(ops:[Op], symbolOperation:String, opUpper:Op)->(String,[Op],UInt8){
        var (operand1, remainingOps1, precedenceOperand1) = description(ops)
        // Метод odd() определяет четное ли число
        // Например для операции вычитания используется приоритет равный четырем
        // Это позволяет правильно выставить скобки для такого выражения записанного в стек
        // "3,5,-,7,8,-,-" - получается "3 - 5 - (7 - 8)"
        // т.е. в данном случае учитывается некоммутативность операции вычитания
        // Приоритет вычитания равен четырем
        // Приоритет сложения равен единице
        // Для выражения "3,4,5,+,-" - получаем "3 - (4 + 5)"
        if opUpper.precedence > precedenceOperand1
            || (opUpper.precedence == precedenceOperand1 && !precedenceOperand1.odd() )
        {
            operand1 = "(\(operand1))"
        }
        var (operand2, remainingOpsOperand2, precedenceOperand2) = description(remainingOps1)
        if opUpper.precedence > precedenceOperand2
            //         || (op.precedence == precedenceOperand2 && !op.commutative )
        {
            operand2 = "(\(operand2))"
        }
        return ("\(operand2) \(symbolOperation) \(operand1)", remainingOpsOperand2, opUpper.precedence)
    }
    
    
    private func description(ops: [Op])  -> (result: String, remainingOps: [Op], precedence:UInt8){
        if !ops.isEmpty {
            let (remainingOps,op) = copyArrayAndTakeTopStack(ops)
            switch op{
            case .Operand(let operand):
                return(CalculatorFormatter.sharedInstance.stringFromNumber(operand)!, remainingOps, UInt8.max)
            case .Constant(let symbol, _):
                return (symbol, remainingOps, UInt8.max)
            case .Variable(let symbol):
                return(symbol, remainingOps, UInt8.max)
            case .UnaryOperation(let symbol,_, _):
                let (descriptionOperand, remainingOps, _) = description(remainingOps)
                return("\(symbol)(\(descriptionOperand))", remainingOps, op.precedence)
            case .BinaryOperation(let symbol, _, _,_):
                let (descriptionOperand, remainingOps, precedenceOperand) = binaryOperationToDescription(remainingOps, symbolOperation: symbol, opUpper: op)
                return (descriptionOperand, remainingOps, precedenceOperand)
            }
        }
        return ("", ops, UInt8.max)
        
    }
    
    func description()  -> String{
        if !opStack.isEmpty {
            var (result,ops,_) = description(opStack)
            var resultTemp = ""
            while !ops.isEmpty {
                resultTemp = result
                (result,ops,_) = description(ops)
                result = result + "," + resultTemp  
            }
            return result
        }
        return ""
    }
    
    private func variableToEvaluateOrReportErrors(symbolVariable:String,remainingOps:[Op])->(Result,[Op]){
        if let varValue = variableValues[symbolVariable]{
            return (.Value(varValue),remainingOps)
        }
        return(.Error("\(symbolVariable) не установлена"),remainingOps)
    }
    
    private func unaryOperationToEvaluateOrReportErrors(operation:Double->Double,errorTest:(Double->String?)?,ops:[Op])->(Result,[Op]){
        
        let operandEvaluation = evaluateOrReportErrors(ops)
        switch operandEvaluation.result{
        case .Value(let operand):
            if let errMessage = errorTest?(operand){
                return (.Error(errMessage),ops)
            }
            return (.Value(operation(operand)),operandEvaluation.remainingOps)
            
        case .Error(let errMessage):
            return (.Error(errMessage),ops)
        }
    }
    
    private func binaryOperationToEvaluateOrReportErrors(operation:(Double,Double)->Double,errorTest:(Double->String?)?,remainingOps:[Op])->(result:Result,ops:[Op]){
        
        let op1Evaluation = evaluateOrReportErrors(remainingOps)
        switch op1Evaluation.result{
        case .Value(let operand1):
            let op2Evaluation = evaluateOrReportErrors(op1Evaluation.remainingOps)
            switch op2Evaluation.result{
            case .Value(let operand2):
                if let errMessage = errorTest?(operand1){
                    return (.Error(errMessage),op1Evaluation.remainingOps)
                }
                return (.Value(operation(operand1,operand2)),op2Evaluation.remainingOps)
            case .Error(let errMessage):
                return (.Error(errMessage),op1Evaluation.remainingOps)
            }
        case .Error(let errMessage):
            return (.Error(errMessage),remainingOps)
        }
    }
    
    private func evaluateOrReportErrors(ops:[Op])->(result:Result,remainingOps:[Op]){
        if !ops.isEmpty{
            let (remainingOps,op) = copyArrayAndTakeTopStack(ops)
            switch op{
            case .Operand(let operand): return(.Value(operand),remainingOps)
            case .Constant(_, let operation): return (.Value(operation()),remainingOps)
            case .Variable(let variable): let (result,remainingOps) = variableToEvaluateOrReportErrors(variable,remainingOps: remainingOps)
                return (result,remainingOps)
            case .UnaryOperation(_, let operation,let errorTest): let (result,remainingOps) = unaryOperationToEvaluateOrReportErrors(operation,errorTest: errorTest,ops: remainingOps)
                return (result,remainingOps)
            case .BinaryOperation(_,_, let operation,let errorTest): let (result,remainingOps) = binaryOperationToEvaluateOrReportErrors(operation,errorTest: errorTest,remainingOps: remainingOps)
                return (result,remainingOps)
            }
        }
        return (.Error("Мало операндов"),ops)
    }
    
    func evaluateOrReportErrors()->Result{
        if !opStack.isEmpty{
            return evaluateOrReportErrors(opStack).result
        }
        return .Value(0)
    }
    
    


    
}
// мы можем использовать NSNumberFormatter со специальными свойствами при
// выводе результатов на display. В случае больших чисел нам нужны разделители
// групп цифр, если после точки выводится очень много знаков, то мы бы хотели
// ограничиться 10 знаками после точки, некоторые функции, например, √
// может возвращать значение Nan при отрицательном аргументе и нам надо
// указать, что это ошибка Error. Мы получаем NSNumberFormatter со
// специальными свойствами при помощи функции numberFormatter()

// Если два вызова то перед именем функции ставим модификатор class
// Почему ?

//http://bestkora.com/IosDeveloper/kak-sozdat-nsnumberformatter-singleton-v-swift/
class CalculatorFormatter: NSNumberFormatter {
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init() {
        super.init()
        self.locale = NSLocale.currentLocale()
        self.numberStyle = .DecimalStyle
        self.maximumFractionDigits = 10
        self.notANumberSymbol = "Error"
        self.groupingSeparator = " "
        
    }
    
    // Swift 1.2 or above
    static let sharedInstance = CalculatorFormatter()
    
    // Swift 1.1
    /*    class var sharedInstance: CalculatorFormatter {
    struct Static {
    static let instance = CalculatorFormatter()
    }
    return Static.instance
    }*/
    
}
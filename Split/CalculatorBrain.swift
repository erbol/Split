import Foundation

class CalculatorBrain: enumStack {
    
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
    
    typealias PropertyList = AnyObject

    
    var program:PropertyList { // guaranteed to be a Property List
        get {
            return opStack.map{$0.description}
        }
        set{
            // Предпологается, что мы получаем математическое выражение в виде стека
            if let opSymbols = newValue as? Array<String> {
                // Очищаем стек
                var newOpStack = [Op]()
                // Загружаем в стек выражения символы операций, операндов или переменной M
                for opSymbol in opSymbols {
                    if let op = knownOps[opSymbol]{
                        newOpStack.append(op)
                    } else if let operand = formatter.numberFromString(opSymbol)?.doubleValue {
                        newOpStack.append(.Operand(operand))
                    } else {
                        newOpStack.append(.Variable(opSymbol))
                    }
                }
                opStack = newOpStack
            }
        }
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
            if knownOps[symbol] != nil {
                opStack.append(knownOps[symbol]!)
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
        //println(opStack)
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

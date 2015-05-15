import Foundation
// Чтобы работать с CG (Core graphic) нужно импортировать UIKit
import UIKit

class StringToStack: enumStack{
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
    
    
    // Массив куда помещается входная строка input
    var parse = [Character]()
    // Массив для хранения данных для построения кривой
    var data = [CGPoint]()
    // Массив для хранения символов операций и значений их приоритетов
    private var stack = [Oper]()

    
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
                if knownOps["π"] != nil {
                    opStack += [knownOps["π"]!]
                }
            case "e":
                if knownOps["e"] != nil {
                    opStack += [knownOps["e"]!]
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
            let o = stack.removeLast()
            if let operation = knownOps[stack.removeLast().description]{
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
            
            if let o = total.toDouble(){
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

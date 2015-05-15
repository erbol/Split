import Foundation

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

extension String {
    func toDouble() -> Double? {
        // numberFromString это метод класса NSNumberFormatter, он извлекает из строки число
        // возвращает либо число либо nil
        // Этот метод имеет свойство doubleValue
        return NSNumberFormatter().numberFromString(self)?.doubleValue
    }
}

// Текст расширения взят со страницы http://overcram.com/questions/?qid=192606


extension UInt8 {
    func odd() -> Bool {
        if self % 2 == 0{
            return false
        }else{
            return true
        }
    }
}


import UIKit

let formatter = CalculatorFormatter()

class MasterViewController: UIViewController {



    
    // Метка для ввода данных
    @IBOutlet weak var display: UILabel!
    
    
    @IBOutlet weak var point: UIButton!
    
    
    // Если false, значит калькулятор не находится в состоянии ввода операнда
    var userIsInTheMiddleOfTypingANumber: Bool = false
    
    var userMadeOperation = false
    // NSNumberFormatter().decimalSeparator дает символ "локальной" плавающей точки
    let decimalSeparator = formatter.decimalSeparator
    
    @IBOutlet weak var history: UILabel!
    
    var brain = CalculatorBrain()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Создаем надпись(Title) на кнопке в соответствии с локальным символом для плавающей точки
        point.setTitle(decimalSeparator, forState: UIControlState.Normal)
    }
    
    @IBAction func signDigit(sender: UIButton) {
        
        if userIsInTheMiddleOfTypingANumber {
            if (display.text!.rangeOfString("-") != nil) {
                display.text = dropFirst(display.text!)
            } else {
                display.text = "-" + display.text!
            }
        } else {
            operate(sender)
        }
    }
    
    
    @IBAction func enterMToDictionary(sender: UIButton) {
        if displayValue != nil {
            brain.nonPrivateAPI("enterVariable",operand:displayValue!)
            
            userIsInTheMiddleOfTypingANumber = true
        }
    }
    
    
    @IBAction func Clear(sender: UIButton) {
        
        display.text="0"
        userIsInTheMiddleOfTypingANumber = false
        history.text = ""
        brain.nonPrivateAPI("clearArray")
        
    }
    
    @IBAction func backspace(sender: UIButton) {
        // Разрешенно удалять цифры только если вводится значение операнда
        // т.е. userIsInTheMiddleOfTypingANumber == true
        // Нельзя изменять значение результата вычислений
        if userIsInTheMiddleOfTypingANumber{
            
            if count(display.text!) > 1{
                
                display.text = dropLast(display.text!)
                
            }else{
                userIsInTheMiddleOfTypingANumber = false
                // Получаем стек и отображаем в метке history
                displayResult = brain.evaluateOrReportErrors()
                
            }
        }else{
            brain.nonPrivateAPI("undo")
            displayResult = brain.evaluateOrReportErrors()
        }
    }
    
    // Метод для вставки новой цифры на дисплей
    @IBAction func appendDigit(sender: UIButton) {
        let digit = sender.currentTitle!
        
        // Чтобы не было двух точек в числе
        if ((display.text!.rangeOfString(".") != nil)  && (digit == ".")) {
            return
        }
        
        
        
        if userIsInTheMiddleOfTypingANumber {
            // продолжаем ввод операнда
            display.text = display.text! + digit
            // Убираем ведущие нули
            if (display.text!.rangeOfString(".") == nil){
                display.text = "\(display.text!.toInt()!)"
            }
            
        } else {
            display.text = digit
            
            // Убираем ведущие нули
            if (display.text!.rangeOfString(".") == nil){
                display.text = "\(display.text!.toInt()!)"
            }
            // Начинаем ввод операнда
            userIsInTheMiddleOfTypingANumber = true
        }
    }
    
    // Метод для выполнения нужной операции над данными
    @IBAction func operate(sender: UIButton) {
        
        
        
        // Закончили ввод операнда
        if userIsInTheMiddleOfTypingANumber{
            enter()
        }
        // Помещаем в operation символ операции взятый с кнопки
        if sender.currentTitle != nil {
            brain.nonPrivateAPI("performOperation",symbol: sender.currentTitle!)
            displayResult = brain.evaluateOrReportErrors()
        }
        
    }
    
    
    
    
    // Добавляем в стек элемент как результат ввода и выполнения операции
    @IBAction func enter() {
        userMadeOperation = false
        
        userIsInTheMiddleOfTypingANumber = false
        
        // Non-private method MODEL
        if displayValue != nil {
            brain.nonPrivateAPI("pushOperand", operand:displayValue!)
        }
        
        displayResult = brain.evaluateOrReportErrors()
        
    }
    
    
    var displayValue: Double?{
        // Вычисляем значение для displayValue
        get{
            if let displayText = display.text {
                return CalculatorFormatter.sharedInstance.numberFromString(displayText)?.doubleValue
            }else{
                return nil
            }
        }
    }
    
    
    var displayResult: CalculatorBrain.Result = .Value(0.0){
        didSet{
            
            display.text = displayResult.description
            userIsInTheMiddleOfTypingANumber = false
            let result = brain.description + " = "
            history.text = result
            
        }
        
    }

    // MARK: - Segues

    // Переходим к DetailView
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        var destination = segue.destinationViewController as? UIViewController
        if let nc = destination as? UINavigationController {
            destination = nc.visibleViewController
        }
        if let gvc = destination as? GraphViewController {
            if let identifier = segue.identifier {
                switch identifier {
                case "showDetail":
                    println("")
                    //gvc.title = brain.description == "" ? "Graph" : brain.description.componentsSeparatedByString(", ").last
                    gvc.program = brain.program
                default:
                    break
                }
            }
        }
    }
    
}


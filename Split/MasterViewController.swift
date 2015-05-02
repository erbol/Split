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

import UIKit

class MasterViewController: UIViewController {


    // Задаем переменные для обмена данными
    var detailViewController: DetailViewController? = nil
    var objects = [AnyObject]()
    //-------------------------------------------

    // Начало кода Calculator
    //-------------------------------------------
    
    // Метка для ввода данных
    @IBOutlet weak var display: UILabel!
    
    
    @IBOutlet weak var point: UIButton!
    
    
    // Если false, значит калькулятор не находится в состоянии ввода операнда
    var userIsInTheMiddleOfTypingANumber: Bool = false
    
    var userMadeOperation = false
    // NSNumberFormatter().decimalSeparator дает символ "локальной" плавающей точки
    let decimalSeparator = NSNumberFormatter().decimalSeparator
    
    @IBOutlet weak var history: UILabel!
    
    var brain = CalculatorBrain()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Создаем надпись(Title) на кнопке в соответствии с локальным символом для плавающей точки
        point.setTitle(decimalSeparator, forState: UIControlState.Normal)
    }
    
    @IBAction func sigmDigit(sender: UIButton) {
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
        if let number = displayValue {
            brain.nonPrivateAPI("enterVariable",operand:number)
            //brain.enterVar(number)
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
                display.text = ""
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
        if let operation = sender.currentTitle{
            brain.nonPrivateAPI("performOperation",symbol: operation)
            displayResult = brain.evaluateOrReportErrors()
        }
        
    }
    
    
    
    
    // Добавляем в стек элемент как результат ввода и выполнения операции
    @IBAction func enter() {
        userMadeOperation = false
        
        userIsInTheMiddleOfTypingANumber = false
        
        // Non-private method MODEL
        if let value = displayValue{
            brain.nonPrivateAPI("pushOperand", operand:value)
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
            let result = brain.description() + " = "
            history.text = result
            
        }
        
    }
    // Конец кода Calculator
//-------------------------------------

    // ??
    override func awakeFromNib() {
        super.awakeFromNib()
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            //self.clearsSelectionOnViewWillAppear = false
            self.preferredContentSize = CGSize(width: 320.0, height: 600.0)
        }
    }


    // MARK: - Segues

    // Переходим к DetailView
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        //println(segue.identifier!)
        // Проверяем идентификатор объекта который дал команду
        if segue.identifier == "showDetail" {
            
            //
            //let object = "Hello erbol"
            
            
            let controller = (segue.destinationViewController as! UINavigationController).topViewController as! DetailViewController
            
            //controller.detailItem = object
            //controller.erbol1()
            // Задаем значения для переменных detailController
            controller.str = brain.description()
            println(controller.str)
            if let slaid = labSlaider.text{
                controller.scale = CGFloat(slaid.toInt()!)
            }
            
            //controller.erbol = "Hello"
            // ??
            controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
            // ??
            controller.navigationItem.leftItemsSupplementBackButton = true
            

        }
    }
    // Устанавливаем значение для scale
    @IBOutlet weak var labSlaider: UILabel!
    
    @IBOutlet weak var slaider: UISlider!
    

    
    @IBAction func scaleVal(sender: UISlider) {
        labSlaider.text = String(format: "%.0f", slaider.value)
    }
    
}


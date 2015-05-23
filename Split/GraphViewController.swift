//
//  GraphViewController.swift
//  CalculatorBrain
//
//  Created by Tatiana Kornilova on 5/6/15.
//  Copyright (c) 2015 Tatiana Kornilova. All rights reserved.
//

import UIKit

class GraphViewController: UIViewController, GraphViewDataSource, UIPopoverPresentationControllerDelegate {
    
    @IBOutlet weak var graphView: GraphView! { didSet {
        
        graphView.dataSource = self
        
        graphView.addGestureRecognizer(UIPinchGestureRecognizer(target: self,
                                                                action: "zoom:"))
        graphView.addGestureRecognizer(UIPanGestureRecognizer(target: self,
                                                              action: "move:"))
        let tap = UITapGestureRecognizer(target: self, action: "center:")
        tap.numberOfTapsRequired = 2
        graphView.addGestureRecognizer(tap)
        
        let tap1 = UITapGestureRecognizer(target: self, action: "coordinatesPoint:")
        tap1.numberOfTapsRequired = 1
        graphView.addGestureRecognizer(tap1)
        
        resetStatistics()
        
        if !resetOrigin {
            graphView.origin = origin
        }
        graphView.scale = scale

        }
    }
  
 
    private var brain = CalculatorBrain()
    private struct Keys {
        static let Scale = "GraphViewController.Scale"
        static let Origin = "GraphViewController.Origin"
        
        static let SegueIdentifier = "Show Statistics"
    }
    
    typealias PropertyList = AnyObject
    var program: PropertyList? { didSet {
        brain.nonPrivateAPI("enterVariable",operand:0)
        brain.program = program!
        
        }
    }
    var calculateStatictics = true
    


// dataSource метод протокола GraphViewDataSource
    func y(x: CGFloat) -> CGFloat? {
        brain.nonPrivateAPI("enterVariable",operand: Double (x))
        //brain.setVariable("M", value: Double (x))
        
        if let y = brain.evaluate()  {
            // С помощью функции min выбираем из двух величин minValue и y минимальную
            if calculateStatictics {
                //println("erbol")
                if let minValue = statistics["min"] {
                    statistics["min"] = min(minValue, y)
                } else {
                    statistics["min"] = y
                }
            
                if let maxValue = statistics["max"] {
                    statistics["max"] = max(maxValue, y)
                } else {
                    statistics["max"] = y
                }
                // Суммируем все Y по точкам
                // Считаем количество точек
                if let avgValue = statistics["avg"] {
                    if let avgNum = statistics["avgNum"]{
                        statistics["avg"] = statistics["avg"]! + y
                        // min , max , avg сбрасывают значения после функцией resetStatistics
                        // avgNum сбрасывается функцией finishStatistics
                        statistics["avgNum"] = statistics["avgNum"]! + 1
                    }
                } else {
                    statistics["avg"] = y
                    statistics["avgNum"] = 1
                }
            }
            return CGFloat(y)
        }
        
        return nil

    }
    
    private let defaults = NSUserDefaults.standardUserDefaults()
    
    // Зачем нужна эта функция ???
    private var resetOrigin: Bool {
        get {
            if let originArray = defaults.objectForKey(Keys.Origin) as? [CGFloat] {
                return false
            }
            return true
        }
    }
    
    var scale: CGFloat {
        get { return defaults.objectForKey(Keys.Scale) as? CGFloat ?? 50.0 }
        set { defaults.setObject(newValue, forKey: Keys.Scale) }
    }
    
    private var origin: CGPoint {
        get {
            var origin = CGPoint()
            if let originArray = defaults.objectForKey(Keys.Origin) as? [CGFloat] {
                origin.x = originArray.first!
                origin.y = originArray.last!
            }
            return origin
        }
        set {
            defaults.setObject([newValue.x, newValue.y], forKey: Keys.Origin)
        }
    }

    // Изменяем параметр scale
    func zoom(gesture: UIPinchGestureRecognizer) {
        calculateStatictics = true
        graphView.zoom(gesture)
        if gesture.state == .Ended {
            resetStatistics()
            scale = graphView.scale
            // Центр координат при выполнении операции zoom в общем случае изменяется
            
            origin = graphView.origin
        }
    }
    // Сдвигаем центр координат
    func move(gesture: UIPanGestureRecognizer) {
        calculateStatictics = true
        graphView.move(gesture)
        if gesture.state == .Ended {
            
            resetStatistics()
            //println("reset")
            origin = graphView.origin
        }
    }
    // Сдвигаем центр координат
    func center(gesture: UITapGestureRecognizer) {
        calculateStatictics = true
        graphView.center(gesture)
        if gesture.state == .Ended {
            resetStatistics()
            origin = graphView.origin
        }
    }
    
    // Сдвигаем центр координат
    func coordinatesPoint(gesture: UITapGestureRecognizer) {
        
        calculateStatictics = false
        graphView.coordinatesPoint(gesture)
        
        
        
        if gesture.state == .Ended {
            //drawGrapic = true
            //origin = graphView.origin
        }

    }

    // Создаем словарь который будет содержать пары ключ-значение
    // min, max, avg, avgNum - ключи
    private var statistics = [String: Double]()
    private func resetStatistics() {
        statistics["min"] = nil
        statistics["max"] = nil
        statistics["avg"] = nil
    }
    // Вычмсляем значение avg
    private func finishStatistics() {
        if let num = statistics["avgNum"] {
            if let avgValue = statistics["avg"] {
                statistics["avg"] = avgValue / num
                
                // 
                statistics["avgNum"] = nil
            }
        }
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifer = segue.identifier {
            switch identifer {
            case Keys.SegueIdentifier:
                if let tvc = segue.destinationViewController as? StatisticsViewController {
                    if let ppc = tvc.popoverPresentationController {
                        ppc.delegate = self
                    }
                    
                    // Сбрасываем значения величины avgNum при переходе от окна калькулятора к окну графика
                    finishStatistics()
                    var texts = [String]()
                    for (key, value) in statistics {
                        let valueToStr = String(format: "%.4f", value)
                        texts += ["\(key) = \(valueToStr)"]
                    }
                    tvc.text = texts.count > 0 ? "\n".join(texts) : "none"
                }
            default: break
            }
        }
    }
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        
        return UIModalPresentationStyle.None
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        // После показа статистик сбрасываем avgNum
        
        resetStatistics()
    }

/*
    func y(x: CGFloat) -> CGFloat? {
          return cos (1.0/x ) * x
    }
*/
}


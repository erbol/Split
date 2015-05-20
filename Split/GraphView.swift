//
//  Graph.swift
//  CalculatorBrain
//

import UIKit

protocol GraphViewDataSource: class {
    func y(x: CGFloat) -> CGFloat?
}

@IBDesignable
class GraphView: UIView {
  
    
    
    let axesDrawer = AxesDrawer(color: UIColor.blueColor())
    /*
    private var graphCenter: CGPoint {
        return convertPoint(center, fromView: superview)
    }
    */
    weak var dataSource: GraphViewDataSource?

    var pointClick = CGPoint.zeroPoint { didSet { setNeedsDisplay() } }
    var show = true { didSet { setNeedsDisplay() } }
    var strShow = "" { didSet { setNeedsDisplay() } }
    @IBInspectable
    var scale: CGFloat = 50.0 { didSet { setNeedsDisplay() } }
    // Перевод слова origin. 1) происхождение. 2) возникновение. 3) начало. 4) источник. 5) первоисточник. 6) первопричина. 7) корень дерева ...
    // origin это координаты на экране в пикселах точки отсчета системы координат
    
    var origin: CGPoint {
        
        get {
            var origin = originRelativeToCenter
            println(originRelativeToCenter)
            if geometryReady {
                // center - центр фрейма
                //println(center.x)
                origin.x += center.x
                origin.y += center.y
            }
            return origin
        }
        set {
            var origin = newValue
            if geometryReady {
                origin.x -= center.x
                origin.y -= center.y
            }
            originRelativeToCenter = origin
        }
    }

    @IBInspectable
    var lineWidth: CGFloat = 1.0 { didSet { setNeedsDisplay() } }
    @IBInspectable
    var color: UIColor = UIColor.blackColor() { didSet { setNeedsDisplay() } }
    
    // originRelativeToCenter - расстояние от origin до центра окна в пикселах
    private var originRelativeToCenter: CGPoint = CGPoint() { didSet { setNeedsDisplay() } }
    // geometryReady имеет значение false только один раз в тот момент когда переходим в окно GRAPHVIEWCONTROLLER
    private var geometryReady = false

    
    override func drawRect(rect: CGRect) {
        if !geometryReady && originRelativeToCenter != CGPointZero {
            // С помощью originHelper вычисляем origin (c помощью метода set)
            var originHelper = origin
            geometryReady = true
            origin = originHelper
        }
        
        axesDrawer.contentScaleFactor = contentScaleFactor

        axesDrawer.drawAxesInRect(bounds, origin: origin, pointsPerUnit: scale)
        drawCurveInRect(bounds, origin: origin, pointsPerUnit: scale)

        if !show && strShow != ""{strShow = ""}
        if show {drawText(strShow)
        drawCircle(pointClick)
        }

        
    }
    
    func drawCurveInRect(bounds: CGRect, origin: CGPoint, pointsPerUnit: CGFloat){
        color.set()
        let path = UIBezierPath()
        path.lineWidth = lineWidth
        var point = CGPoint()
        
        var firstValue = true
        for var i = 0; i <= Int(bounds.size.width * contentScaleFactor); i++ {
            point.x = CGFloat(i) / contentScaleFactor
            if let y = dataSource?.y((point.x - origin.x) / scale) {
                if !y.isNormal && !y.isZero {
                    firstValue = true
                    continue
                }
                point.y = origin.y - y * scale
                if firstValue {
                    path.moveToPoint(point)
                    firstValue = false
                } else {
                    path.addLineToPoint(point)
                }
            } else {
                firstValue = true
            }
        }
        path.stroke()
        
    }
    
    var snapshot:UIView?
    
    func zoom(gesture: UIPinchGestureRecognizer) {
        pointClick.x = -20
        strShow = ""
        switch gesture.state {
        case .Began:
            snapshot = self.snapshotViewAfterScreenUpdates(false)
            snapshot!.alpha = 0.8
            self.addSubview(snapshot!)
        case .Changed:
            let touch = gesture.locationInView(self)
            snapshot!.frame.size.height *= gesture.scale
            snapshot!.frame.size.width *= gesture.scale
            snapshot!.frame.origin.x = snapshot!.frame.origin.x * gesture.scale + (1 - gesture.scale) * touch.x
            snapshot!.frame.origin.y = snapshot!.frame.origin.y * gesture.scale + (1 - gesture.scale) * touch.y
            gesture.scale = 1.0
        case .Ended:
            let changedScale = snapshot!.frame.height / self.frame.height
            scale *= changedScale
            origin.x = origin.x * changedScale + snapshot!.frame.origin.x
            origin.y = origin.y * changedScale + snapshot!.frame.origin.y
            
            snapshot!.removeFromSuperview()
            snapshot = nil
        default: break
        }
    }
    
    func move(gesture: UIPanGestureRecognizer) {
        pointClick.x = -20
        strShow = ""
        switch gesture.state {
        case .Began:
            snapshot = self.snapshotViewAfterScreenUpdates(false)
            snapshot!.alpha = 0.8
            self.addSubview(snapshot!)
        case .Changed:
            let translation = gesture.translationInView(self)
            snapshot!.center.x += translation.x
            snapshot!.center.y += translation.y
            gesture.setTranslation(CGPointZero, inView: self)
        case .Ended:
            origin.x += snapshot!.frame.origin.x
            origin.y += snapshot!.frame.origin.y
            snapshot!.removeFromSuperview()
            snapshot = nil
        default: break
        }
    }
    
    func center(gesture: UITapGestureRecognizer) {
        pointClick.x = -20
        strShow = ""
        if gesture.state == .Ended {
            origin = gesture.locationInView(self)
        }
    }
    
    
    func center1(gesture: UITapGestureRecognizer) {
        if gesture.state == .Ended && show{
            let point = gesture.locationInView(self)
            pointClick.x = point.x
            let x = (point.x - origin.x) / scale
            let stringX = String(format: "%.2f", x)
            
            let y = dataSource?.y(x)
            
            pointClick.y = origin.y - y! * scale
            
            let stringY = String(format: "%.2f", y!)
            strShow = "X = \(stringX), Y = \(stringY)"

        }
    }
    
    func drawText(str: String){
        
    
        
        let coordRect = CGRectMake(self.bounds.width/30 , self.bounds.height*1/50, 200, 50)


        let font = UIFont(name: "Arial", size: 18)
        let textStyle = NSMutableParagraphStyle.defaultParagraphStyle()
        let textColor = UIColor(red: 0, green: 0, blue: 1, alpha: 1)
        //UIColor(red: 0.175, green: 0.458, blue: 0.431, alpha: 1)
        
        
        let numberOneAttributes = [
            NSFontAttributeName: font!,
            NSForegroundColorAttributeName: textColor
        ]
        str.drawInRect(coordRect,
            withAttributes:numberOneAttributes)
        
        
        
        
    }
    
    func drawCircle(pointClick : CGPoint){
        if pointClick.y.isNormal {
            let context = UIGraphicsGetCurrentContext()
            CGContextSetLineWidth(context, 1.0)
            CGContextSetStrokeColorWithColor(context,
            UIColor.blueColor().CGColor)

            let rectangle = CGRectMake(pointClick.x - 5,pointClick.y - 5,10,10)
            CGContextAddEllipseInRect(context, rectangle)
            CGContextStrokePath(context)
        }
    }


}

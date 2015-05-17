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
    
    private var graphCenter: CGPoint {
        return convertPoint(center, fromView: superview)
    }
    
    weak var dataSource: GraphViewDataSource?

    var pointClick = CGPoint.zeroPoint { didSet { setNeedsDisplay() } }
    var show = true { didSet { setNeedsDisplay() } }
    var strShow = "" { didSet { setNeedsDisplay() } }
    @IBInspectable
    var scale: CGFloat = 50.0 { didSet { setNeedsDisplay() } }
    var origin: CGPoint? { didSet { setNeedsDisplay() }}
    @IBInspectable
    var lineWidth: CGFloat = 2.0 { didSet { setNeedsDisplay() } }
    @IBInspectable
    var color: UIColor = UIColor.blackColor() { didSet { setNeedsDisplay() } }

    
    override func drawRect(rect: CGRect) {
        origin =  origin ?? graphCenter
        
        axesDrawer.contentScaleFactor = contentScaleFactor

        axesDrawer.drawAxesInRect(bounds, origin: origin!, pointsPerUnit: scale)
        drawCurveInRect(bounds, origin: origin!, pointsPerUnit: scale)

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
    
    func scale(gesture: UIPinchGestureRecognizer) {
        pointClick.x = -20
        strShow = ""
        if gesture.state == .Changed {
            scale *= gesture.scale
            gesture.scale = 1.0
        }
    }
    
    func originMove(gesture: UIPanGestureRecognizer) {
        pointClick.x = -20
        strShow = ""
        switch gesture.state {
        case .Ended: fallthrough
        case .Changed:
            let translation = gesture.translationInView(self)
            if translation != CGPointZero {
                origin?.x += translation.x
                origin?.y += translation.y
                gesture.setTranslation(CGPointZero, inView: self)
            }
        default: break
        }
    }
    
    func origin(gesture: UITapGestureRecognizer){


        if gesture.state == .Ended {
            origin = gesture.locationInView(self)
            
        }
        pointClick.x = -20
        strShow = ""

    }
    
    func origin1(gesture: UITapGestureRecognizer) {
        if gesture.state == .Ended && show{
            let point = gesture.locationInView(self)
            pointClick.x = point.x
            let x = (point.x - origin!.x) / scale
            let stringX = String(format: "%.2f", x)
            
            let y = dataSource?.y(x)
            
            pointClick.y = origin!.y - y! * scale
            
            let stringY = String(format: "%.2f", y!)
            strShow = "X = \(stringX), Y = \(stringY)"

        }
    }
    
    func drawText(str: String){
        
    
        
        let coordRect = CGRectMake(self.bounds.width/15 , self.bounds.height*1/15, 200, 50)


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
            CGContextSetLineWidth(context, 2.0)
            CGContextSetStrokeColorWithColor(context,
            UIColor.blueColor().CGColor)

            let rectangle = CGRectMake(pointClick.x - 7.5,pointClick.y - 7.5,15,15)
            CGContextAddEllipseInRect(context, rectangle)
            CGContextStrokePath(context)
        }
    }


}

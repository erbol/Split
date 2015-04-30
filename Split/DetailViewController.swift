

import UIKit

class DetailViewController: UIViewController {
    
    
    
    @IBOutlet weak var imageView: UIImageView!




    
    
    let graph = CalculatorGraphic()
    var contentScaleFactor: CGFloat = 1// ???
    let scale: CGFloat = 1.0
    var str = "M*sin(M*0.03)"
    //let str = "M*M/4"
    //let scale: CGFloat = 20.0 для функции "M*M/5"
    var origin = CGPoint.zeroPoint
    var rect = CGRect()
    //let rect = CGRectMake(0, 0, view.frame.maxX , view.frame.maxY)
    
    
    // Переменная detailItem
    var detailItem: AnyObject? {
        didSet {
            // Update the view.
            self.configureView()
        }
    }
    
    func configureView() {
        // Update the user interface for the detail item.
        if let detail: AnyObject = self.detailItem {
            /*
            if let label = self.textDetail {
                label.text = detail.description
            }
*/
        }
    }

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.configureView()
        
        let panGesture = UIPanGestureRecognizer(target: self, action: Selector("recognizePanGesture:"))
        view.addGestureRecognizer(panGesture)
        
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: Selector("recognizeDoubleTapGesture:"))
        doubleTapGesture.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTapGesture)
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: Selector("recognizePinchGesture:"))
        view.addGestureRecognizer(pinchGesture)
        
        if view.bounds.width >= view.frame.width {
            origin = CGPoint(x: view.frame.midX   , y: view.frame.midY  )
            rect = CGRect(x: 0, y: 0, width: view.frame.maxX , height: view.frame.maxY)
            
        }else{
            
            origin = CGPoint(x: view.bounds.midX   , y: view.bounds.midY  )
            rect = CGRect(x: 0, y: 0, width:  view.bounds.size.width, height: view.bounds.size.height)
            //rect = CGRect(x: view.bounds.size.width - 320, y: view.bounds.size.height - 30,width:  350, height: 30)
            
        }
        
        
        
        
        //origin = CGPoint(x: view.frame.midX   , y: view.frame.midY  )
        //rect = CGRect(x: 0, y: 0, width: view.frame.maxX , height: view.frame.maxY)
        
        draw()
    }
    
    func draw(){
        
        //imageView.image = nil
        
        // Вычисляем функцию по точкам на оси Х внутри rect и рисуем график
        
        //let rect = CGRectMake(0, 0, self.view.bounds.maxX , self.view.bounds.maxY)
        var size = CGSize.zeroSize
        
        if view.bounds.width >= view.frame.width {
            
            rect = CGRect(x: 0, y: 0, width: view.frame.maxX , height: view.frame.maxY)
            size = self.view.frame.size
            //origin = CGPoint(x: self.view.frame.midX   , y: self.view.frame.midY  )
            //println(1)
            
        }else{
            rect = CGRect(x: 0, y: 0, width:  view.bounds.size.width, height: view.bounds.size.height)
            size = self.view.bounds.size
            //origin = CGPoint(x: self.view.bounds.midX   , y: self.view.bounds.midY  )
            //println(2)
        }
        
        //println(size)
        //println(self.origin)
        
        
        
        
        
        
        UIGraphicsBeginImageContext(size)
        
        let context = UIGraphicsGetCurrentContext()
        
        
        // Рисуем график
        drawGraphicFunction(context)
        // Рисуем оси координат внутри rect
        drawAxes(context)
        
        drawText(str)
        //imageView. = UIGraphicsGetImageFromCurrentImageContext()
        imageView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
    
    
    func drawGraphicFunction( context : CGContext){
        
        // Строим стек для расчета функции
        graph.parseString(str)
        // Для создания графика функции надо определить диапазоны отрицательных и положительных значений
        // Известны положения двух точек
        // original - точка отсчета рисуемых на view осей системы координат
        // rect.original - точка отсчета системы координат прямоугольника области построения графика
        
        
        
        CGContextSetLineWidth(context, 1.0)
        CGContextSetStrokeColorWithColor(context,
            UIColor.blueColor().CGColor)
        
        
        // расстояние по оси х от левой границы rect до точки начала координат рисуемых осей
        // В нашем случае rect.origin.x всегда равно нулю
        // Положение точки origin задается относительно rect.origin
        // Поэтому если origin находится левее rect.origin left будет положительным
        // и наоборот если origin находится правее rect.origin то left будет отрицательным
        let left:Int = Int((rect.minX - origin.x))
        //println(left)
        
        // расстояние по оси х от точки начала координат рисуемых осей до правой границы прямоугольника построения
        
        let right:Int = Int((rect.maxX - origin.x))
        
        // Рассчитываем функцию
        var data = graph.graphData(left,right: right, scale: scale)
        
        CGContextBeginPath(context)
        
        // Рисуем функцию
        while !data.isEmpty {
            let point = data.removeAtIndex(0)
            //println(point.x)
            //println(point.y)
            if (point.x == CGFloat(left)/scale) {
                //----------------------------------------------
                CGContextMoveToPoint(context, point.x*scale+origin.x, -point.y*scale+origin.y)
            }
            else {
                CGContextAddLineToPoint(context, point.x*scale+origin.x, -point.y*scale+origin.y)
            }
        }
        
        CGContextStrokePath(context)
        //CGContextClosePath(context)
        
    }
    
    
    func drawText(str: String){
        let nameFunction = "Y = " + str
        let ratio = CGFloat(view.frame.width/view.bounds.width)
        //println(ratio)
        
        var nameFunctionRect = CGRect()
        if view.bounds.width >= view.frame.width {
            nameFunctionRect = CGRect(x: view.frame.width/10 , y: view.frame.height*9/10 , width: 350, height: 30)
            
        }else{
            nameFunctionRect = CGRect(x: view.bounds.size.width/10, y: (view.bounds.size.height)*9/10, width:  350, height: 30)
            
            
        }
        //let font = UIFont(name: "Academy Engraved LET", size: sizeFont)
        let font = UIFont(name: "Arial", size: 20)
        let textStyle = NSMutableParagraphStyle.defaultParagraphStyle()
        
        let numberOneAttributes = [
            NSFontAttributeName: font!]
        nameFunction.drawInRect(nameFunctionRect,
            withAttributes:numberOneAttributes)
        
        
    }
    
    func drawAxes(context : CGContext){
        let bounds = rect
        
        AxesDrawer(contentScaleFactor: contentScaleFactor)
            .drawAxesInRect(bounds, origin: origin, pointsPerUnit: scale, context : context)
    }
    
    func recognizePanGesture(sender: UIPanGestureRecognizer)
    {
        /*
        var initialCenter = CGPoint.zeroPoint
        if (sender.state == UIGestureRecognizerState.Began)
        {
        initialCenter = sender.view!.center
        }
        let translation = sender.translationInView(sender.view!) //[sender translationInView:sender.view]
        let ratio = CGFloat(view.frame.width/view.bounds.width)
        sender.view!.center = CGPointMake((initialCenter.x + translation.x)/ratio,
        (initialCenter.y + translation.y)/ratio)
        origin = CGPoint(x: sender.view!.center.x  , y: sender.view!.center.y  )
        */
        
        //let location:CGPoint = sender.locationInView(self.view)
        
        var translate = sender.translationInView(view)
        if sender.state == UIGestureRecognizerState.Ended {
            // 1
            let velocity = sender.velocityInView(view)
            let magnitude = sqrt((velocity.x * velocity.x) + (velocity.y * velocity.y))
            let slideMultiplier = magnitude / 200
            //println("magnitude: \(magnitude), slideMultiplier: \(slideMultiplier)")
            
            // 2
            let slideFactor = 0.1 * slideMultiplier     //Увеличьте для большего скольжения
            // 3
            var finalPoint = CGPoint(x:sender.view!.center.x + (velocity.x * slideFactor),
                y:sender.view!.center.y + (velocity.y * slideFactor))
            // 4
            finalPoint.x = min(max(finalPoint.x, 0), self.view.frame.size.width)
            finalPoint.y = min(max(finalPoint.y, 0), self.view.frame.size.height)
            
            
            origin.x  = (origin.x + translate.x)
            origin.y = (origin.y + translate.y)
            
            
            // 5
            UIView.animateWithDuration(Double(slideFactor * 2),
                delay: 0,
                
                // 6
                options: UIViewAnimationOptions.CurveEaseOut,
                
                animations: { self.draw()},
                
                completion: nil)
        }
        
        
        /*
        let ratio = CGFloat(view.frame.width/view.bounds.width)
        var loc1 = CGPoint.zeroPoint
        var loc2 = CGPoint.zeroPoint
        if (sender.state == UIGestureRecognizerState.Began)
        {
        loc1 = sender.locationInView(self.view)
        }
        
        
        if sender.state == UIGestureRecognizerState.Ended {
        loc2 = sender.locationInView(self.view)
        origin = CGPoint(x: (origin.x + loc2.x - loc1.x)/ratio  , y: (origin.y + loc2.y - loc1.y)/ratio  )
        
        }
        
        draw()
        */
        
    }
    
    func recognizeDoubleTapGesture(sender: UITapGestureRecognizer)
    {
        
        let location:CGPoint = sender.locationInView(self.view)
        //println(location)
        //println(view.bounds.size)
        //println(view.frame.size)
        
        let ratio = CGFloat(view.frame.width/view.bounds.width)
        //println(ratio)
        if view.bounds.width >= view.frame.width {
            origin = CGPoint(x: location.x*ratio   , y: location.y*ratio  )
        }else{
            origin = CGPoint(x: location.x   , y: location.y  )
        }
        //println(origin)
        //origin = CGPoint(x: location.x   , y: location.y  )
        //println(origin)
        
        
        draw()
        
        
    }
    
    func recognizePinchGesture(sender: UIPinchGestureRecognizer)
    {
        //println("fdfd")
        //sender.view!.transform = CGAffineTransformScale(self.view.transform, sender.scale, sender.scale)
        
        if (sender.state == UIGestureRecognizerState.Began)
        {
            //println(sender.scale)
        }
        
        
        
        view!.transform = CGAffineTransformScale(self.view.transform, sender.scale, sender.scale)
        
        if sender.state == UIGestureRecognizerState.Ended {
            //println(self.view.bounds.size.width)
            //println(view.bounds.size.width)
            
            
            
            
            //println(self.view.frame.width)
            //println(view.frame.width)
            
            
        }
        
        sender.scale = 1
        //println(self.origin)
        
        
        
        
        //println(location)
        //origin = CGPoint(x: location.x   , y: location.y  )
        
        //draw(origin)
        
        
    }

    


}


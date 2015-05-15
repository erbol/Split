//
//  AxesDrawer.swift
//  Calculator
//
//  Created by CS193p Instructor.
//  Copyright (c) 2015 Stanford University. All rights reserved.
//

import UIKit

class AxesDrawer
{
    private struct Constants {
        static let HashmarkSize: CGFloat = 6
    }
    
    var color = UIColor.blueColor()
    // Минамальное количество точек на метку
    // Hashmark - особые метки
    var minimumPointsPerHashmark: CGFloat = 40//40
    var contentScaleFactor: CGFloat = 1 // set this from UIView's contentScaleFactor to position axes with maximum accuracy
    
    convenience init(color: UIColor, contentScaleFactor: CGFloat) {
        self.init()
        self.color = color
        self.contentScaleFactor = contentScaleFactor
    }
    
    convenience init(color: UIColor) {
        self.init()
        self.color = color
    }
    
    convenience init(contentScaleFactor: CGFloat) {
        self.init()
        self.contentScaleFactor = contentScaleFactor
    }
    
    // this method is the heart of the AxesDrawer
    // it draws in the current graphic context's coordinate system
    // therefore origin and bounds must be in the current graphics context's coordinate system
    // pointsPerUnit is essentially the "scale" of the axes
    // e.g. if you wanted there to be 100 points along an axis between -1 and 1,
    //    you'd set pointsPerUnit to 50
    
    // Этот метод является сердцем AxesDrawer
    // Это привлекает в системе координат текущего графического контекста в
    // Поэтому происхождение и границы должны быть в настоящее время графический контекст системы координат
    // PointsPerUnit, по существу, "масштаб" из осей
    // Например, если вы хотели, чтобы 100 баллов по оси между -1 и 1,
    // Вы установите pointsPerUnit до 50
    
    
    // Рисуем оси и вызываем функцию drawHashmarksInRect которая рисует шкалу на осях в заданном масштабе и цифры возле делений шкалы
    func drawAxesInRect(bounds: CGRect, origin: CGPoint, pointsPerUnit: CGFloat)
    {
        // Исходно минимальное и максимальное значение для шкалы осей координат берем размер окна в пикселах
        // Затем с помощью множителя scale (pointsPerUnit) можем масштабировать значения меток шкалы 
        
        //let offset = CGSizeMake(10, 10)
        
        // Сохраняем предыдущий контекст
        // Зачем нужно сохранять предыдущий контекст ?
        // Что предыдущий контекст теряет если мы выполним какие то рисунки ?
        // Может быть в context хранится информация о толщине кисти , цвете и так далее
        CGContextSaveGState(UIGraphicsGetCurrentContext())
        
        //  Задаем тень для осей координат
        // "Не смотрятся" тени на рисунке
        /*
        CGContextSetShadowWithColor(context,
        offset,
        20,
        UIColor.grayColor().CGColor)
        */
        
        color.set()
        let path = UIBezierPath()
        // origin - координаты точки начала отсчета рисуемой системы координат
        path.moveToPoint(CGPoint(x: bounds.minX, y: align(origin.y)))
        path.addLineToPoint(CGPoint(x: bounds.maxX, y: align(origin.y)))
        path.moveToPoint(CGPoint(x: align(origin.x), y: bounds.minY))
        path.addLineToPoint(CGPoint(x: align(origin.x), y: bounds.maxY))
        path.stroke()
        // Рисуем метки на осях и цифры около них
        drawHashmarksInRect(bounds, origin: origin, pointsPerUnit: abs(pointsPerUnit))
        // Восстанавливаем предыдущий контекст
        CGContextRestoreGState(UIGraphicsGetCurrentContext())
        
    }
    
    // the rest of this class is private
    // Рисуем метки на осях и цифры около них
    private func drawHashmarksInRect(bounds: CGRect, origin: CGPoint, pointsPerUnit: CGFloat)
    {
        // Проверяем, что хотя бы одна из осей координат проходит через фрейм (bounds), прямоугольник в котором происходит рисование
        // Если да то рисуем метки и их обозначение
        if ((origin.x >= bounds.minX) && (origin.x <= bounds.maxX)) || ((origin.y >= bounds.minY) && (origin.y <= bounds.maxY))
        {
            // figure out how many units each hashmark must represent
            // to respect both pointsPerUnit and minimumPointsPerHashmark
            
            //println("origin.x = \(origin.x)")
            //println("bounds.minX = \(bounds.minX)")
            //println("bounds.maxX = \(bounds.maxX)")
            
            // Получаем цену деления в единицах шкалы, в юнитах
            var unitsPerHashmark = minimumPointsPerHashmark / pointsPerUnit
            //println("unitsPerHashmark = \(unitsPerHashmark)")
            if unitsPerHashmark < 1 {
                // функция ceil округляет к целому числу, в сторону большего целого значения
                unitsPerHashmark = pow(10, ceil(log10(unitsPerHashmark)))
                //println("ceil(log10(unitsPerHashmark)) = \(ceil(log10(unitsPerHashmark)))")
            } else {
                // floor - округление
                unitsPerHashmark = floor(unitsPerHashmark)
                //println("unitsPerHashmark = \(unitsPerHashmark)")
            }
            
            // для scale = 1 => pointsPerHashmark = 40
            // Получаем цену деления шкалы в пикселах
            let pointsPerHashmark = pointsPerUnit * unitsPerHashmark
            
            // figure out which is the closest set of hashmarks (radiating out from the origin) that are in bounds
            // выяснить, что является близким набор hashmarks (излучающий из происхождения), которые находятся в пределах
            var startingHashmarkRadius: CGFloat = 1
            // Если начало координат не находится внутри фрейма
            // ???
            if !CGRectContainsPoint(bounds, origin) {
                
                let leftx = max(origin.x - bounds.maxX, 0)
                //println("leftx = \(max(origin.x - bounds.maxX, 0))")
                let rightx = max(bounds.minX - origin.x, 0)
                //println("rightx = \(max(bounds.minX - origin.x, 0))")
                let downy = max(origin.y - bounds.minY, 0)
                //println("downy = \(max(origin.y - bounds.minY, 0))")
                let upy = max(bounds.maxY - origin.y, 0)
                //println("upy = \(max(bounds.maxY - origin.y, 0))")
                // Определили startingHashmarkRadius как минимум из минимумов min(min(leftx, rightx), min(downy, upy))
                startingHashmarkRadius = min(min(leftx, rightx), min(downy, upy)) / pointsPerHashmark + 1
                //println("min(leftx, rightx) = \(min(leftx, rightx))")
                //println("min(downy, upy) = \(min(downy, upy))")
                //println("min = \(min(min(leftx, rightx), min(downy, upy)) / pointsPerHashmark)")
                //println("startingHashmarkRadius = \(startingHashmarkRadius)")
            }
            
            // now create a bounding box inside whose edges those four hashmarks lie
            // Теперь создать ограничивающий прямоугольник(квадрат) внутри которого края этих четырех hashmarks направлениях
            let bboxSize = pointsPerHashmark * startingHashmarkRadius * 2
            //println("pointsPerHashmark = \(pointsPerHashmark)")
            //println("startingHashmarkRadius = \(startingHashmarkRadius)")
            var bbox = CGRect(center: origin, size: CGSize(width: bboxSize, height: bboxSize))
            
            // formatter for the hashmark labels
            //let formatter = NSNumberFormatter()
            formatter.maximumFractionDigits = Int(round(-log10(Double(unitsPerHashmark))))
            formatter.minimumIntegerDigits = 1
            
            // radiate the bbox out until the hashmarks are further out than the bounds
            // Цикл продолжается до тех пор пока хотя бы одна сторона квадрата bbox находится внутри прямоугольника bounds
            
            // bounds - это прямоугольник соотвествующий размерам фрейма в котором происходит создание графика
            while !CGRectContainsRect(bbox, bounds)
            {
                // Вычисляем число (origin.x-bbox.minX)/pointsPerUnit, конвертируем в строку
                let label = formatter.stringFromNumber((origin.x-bbox.minX)/pointsPerUnit)!
                //println(label)
                // Проверяем находится ли крайняя левая точка квадрата внутри фрейма bounds
                // Если да то рисуем метку и ее обозначение label
                if let leftHashmarkPoint = alignedPoint(x: bbox.minX, y: origin.y, insideBounds:bounds) {
                    drawHashmarkAtLocation(leftHashmarkPoint, .Top("-\(label)"))
                    // leftHashmarkPoint - координата метки и лейбла
                }
                // Проверяем находится ли крайняя правая точка квадрата внутри фрейма bounds
                if let rightHashmarkPoint = alignedPoint(x: bbox.maxX, y: origin.y, insideBounds:bounds) {
                    drawHashmarkAtLocation(rightHashmarkPoint, .Top(label))
                }
                // Проверяем находится ли крайняя верхняя точка квадрата внутри фрейма bounds
                if let topHashmarkPoint = alignedPoint(x: origin.x, y: bbox.minY, insideBounds:bounds) {
                    drawHashmarkAtLocation(topHashmarkPoint, .Left(label))
                }
                // Проверяем находится ли крайняя нижняя точка квадрата внутри фрейма bounds
                if let bottomHashmarkPoint = alignedPoint(x: origin.x, y: bbox.maxY, insideBounds:bounds) {
                    drawHashmarkAtLocation(bottomHashmarkPoint, .Left("-\(label)"))
                }
                // Метод inser объекта Rect изменяет его высоту и ширину
                // отрицательные значения -pointsPerHashmark создают больший прямоугольник,
                // охватывающий предыдущий
                
                // Увеличиваем размер квадрата на величину pointsPerHashmark
                //println("pointsPerHashmark = \(pointsPerHashmark)")
                bbox.inset(dx: -pointsPerHashmark, dy: -pointsPerHashmark)
                
                //println("bbox.width = \(bbox.width)")
            }
        }
    }
    // Передаем функции координаты метки и ее текстовое обозначение
    private func drawHashmarkAtLocation(location: CGPoint, _ text: AnchoredText)
    {
        var dx: CGFloat = 0, dy: CGFloat = 0
        switch text {
        case .Left: dx = Constants.HashmarkSize / 2
        case .Right: dx = Constants.HashmarkSize / 2
        case .Top: dy = Constants.HashmarkSize / 2
        case .Bottom: dy = Constants.HashmarkSize / 2
        }
        
        //  Рисуем метки на осях
        let path = UIBezierPath()
        path.moveToPoint(CGPoint(x: location.x-dx, y: location.y-dy))
        path.addLineToPoint(CGPoint(x: location.x+dx, y: location.y+dy))
        path.stroke()
        
        //  Цифры рисуем возле меток на осях
        text.drawAnchoredToPoint(location, color: color)
    }
    
    private enum AnchoredText
    {
        case Left(String)
        case Right(String)
        case Top(String)
        case Bottom(String)
        
        static let VerticalOffset: CGFloat = 3// отступ от оси по вертикали
        static let HorizontalOffset: CGFloat = 6
        
        func drawAnchoredToPoint(location: CGPoint, color: UIColor) {
            // Задаем атрибуты для текста
            let textColor = UIColor(red: 0.175, green: 0.458, blue: 0.431, alpha: 1)
            let attributes = [
                NSFontAttributeName : UIFont.preferredFontForTextStyle(UIFontTextStyleFootnote) ,
                //NSFontAttributeName : UIFont.systemFontOfSize(29.0),
                //NSForegroundColorAttributeName : color
                NSForegroundColorAttributeName : textColor
            ]
            
            var textRect = CGRect(center: location, size: text.sizeWithAttributes(attributes))
            switch self {
            case Top: textRect.origin.y += textRect.size.height / 2 + AnchoredText.VerticalOffset
            case Left: textRect.origin.x += textRect.size.width / 2 + AnchoredText.HorizontalOffset
            case Bottom: textRect.origin.y -= textRect.size.height / 2 + AnchoredText.VerticalOffset
            case Right: textRect.origin.x -= textRect.size.width / 2 + AnchoredText.HorizontalOffset
            }
            
            // Собственно инструкция для рисования текста
            text.drawInRect(textRect, withAttributes: attributes)
        }
        
        var text: String {
            switch self {
            case Left(let text): return text
            case Right(let text): return text
            case Top(let text): return text
            case Bottom(let text): return text
            }
        }
    }
    
    // we want the axes and hashmarks to be exactly on pixel boundaries so they look sharp
    // setting contentScaleFactor properly will enable us to put things on the closest pixel boundary
    // if contentScaleFactor is left to its default (1), then things will be on the nearest "point" boundary instead
    // the lines will still be sharp in that case, but might be a pixel (or more theoretically) off of where they should be
    
    // Зачем нужен метод alignedPoint ?
    // Возвращает или nil или точку point
    // Проверяем содержится ли точка заданная аргументоми #x: CGFloat, y: CGFloat
    // в прямоугольнике insideBounds
    private func alignedPoint(#x: CGFloat, y: CGFloat, insideBounds: CGRect? = nil) -> CGPoint?
    {
        let point = CGPoint(x: align(x), y: align(y))
        if let permissibleBounds = insideBounds {
            // Узнаем содержится ли точка point в прямоугольнике permissibleBounds
            if (!CGRectContainsPoint(permissibleBounds, point)) {
                return nil
            }
        }
        return point
    }
    
    // Зачем нужен метод align ?
    //  Суть в том что округляем число coordinate с заданной точность
    // Допустим coordinate = 10.4213 и contentScaleFactor = 100
    // Тогда умножая coordinate на 100 получим 1042.13, удаляем дробную часть
    // получам 1042 и делим на 100
    // Получаем 10.42 , то есть coordinate с точностью до двух знаков
    // после запятой
    private func align(coordinate: CGFloat) -> CGFloat {
        return round(coordinate * contentScaleFactor) / contentScaleFactor
    }
}
/*
extension CGRect
{
    init(center: CGPoint, size: CGSize) {
        self.init(x: center.x-size.width/2, y: center.y-size.height/2, width: size.width, height: size.height)
    }
}
*/

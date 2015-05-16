//
//  GraphViewController.swift
//  CalculatorBrain
//
//  Created by Tatiana Kornilova on 5/6/15.
//  Copyright (c) 2015 Tatiana Kornilova. All rights reserved.
//

import UIKit

class GraphViewController: UIViewController, GraphViewDataSource {
    
    @IBOutlet weak var graphView: GraphView! { didSet {
        
        graphView.dataSource = self
        
        graphView.addGestureRecognizer(UIPinchGestureRecognizer(target: graphView,
                                                                action: "scale:"))
        graphView.addGestureRecognizer(UIPanGestureRecognizer(target: graphView,
                                                              action: "originMove:"))
        let tap = UITapGestureRecognizer(target: graphView, action: "origin:")
        tap.numberOfTapsRequired = 2
        graphView.addGestureRecognizer(tap)
        
        let tap1 = UITapGestureRecognizer(target: graphView, action: "origin1:")
        tap1.numberOfTapsRequired = 1
        graphView.addGestureRecognizer(tap1)
        

        updateUI()
        }
    }
    
    
    @IBAction func Coordinate(sender: UIButton) {
        
        if let o = showHide.titleLabel?.text{
            if o == "Show" {
                graphView.show = true
                showHide.setTitle("Hide", forState: UIControlState.Normal)
                
            }else{
                graphView.show = false
                showHide.setTitle("Show", forState: UIControlState.Normal)
                
            }
        }
        
    }
    
    @IBOutlet weak var showHide: UIButton!
    
    

    
 
    private var brain = CalculatorBrain()
    
    typealias PropertyList = AnyObject
    var program: PropertyList? { didSet {
        brain.nonPrivateAPI("enterVariable",operand:0)
        brain.program = program!
        updateUI()
        }
    }
    
    func updateUI() {
        //graphView?.setNeedsDisplay()
        title = brain.description()
    }

// dataSource метод протокола GraphViewDataSource
    func y(x: CGFloat) -> CGFloat? {
        brain.nonPrivateAPI("enterVariable",operand: Double (x))
        //brain.setVariable("M", value: Double (x))
        if let y = brain.evaluate() {
            return CGFloat(y)
        }
        return nil

    }
/*
    func y(x: CGFloat) -> CGFloat? {
          return cos (1.0/x ) * x
    }
*/
}


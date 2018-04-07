//
//  ViewController.swift
//  SARAppleMapsDrawView
//
//  Created by Saravanan Vijayakumar on 21/03/18.
//  Copyright © 2018 Saravanan Vijayakumar. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var mapCanvas: SARAppleMapsCanvas!
    @IBOutlet weak var penButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        mapCanvas.polygonDrawn = { polygon in
            self.penButtonTapped(self.penButton)
            print("polygon: \(polygon)")
            print(polygon.points())
            print("polygon.interiorPolygons: \(String(describing: polygon.interiorPolygons))")
        }
    }
    
    @IBAction func penButtonTapped(_ sender: Any) {
        if mapCanvas.mapState == .Draw {
            mapCanvas.disableDrawing()
            penButton.isSelected = false
        }
        else {
            mapCanvas.enableDrawing()
            penButton.isSelected = true
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}


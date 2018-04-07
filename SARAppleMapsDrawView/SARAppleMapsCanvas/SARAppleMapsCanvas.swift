//
//  SARAppleMapsCanvas.swift
//  SARAppleMapsDrawView
//
//  Created by Saravanan Vijayakumar on 21/03/18.
//  Copyright © 2018 Saravanan Vijayakumar. All rights reserved.
//


import Foundation
import MapKit

enum MapState {
    case Draw, Pan
}

class SARCoordinate: NSCopying {
    var coordinate: CLLocationCoordinate2D!
    var coordinatePoint: CGPoint!
    
    init(withCoordinate coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = SARCoordinate(withCoordinate: self.coordinate)
        copy.coordinatePoint = self.coordinatePoint
        return copy
    }
    
}

class SARAppleMapsCanvas: UIView, MKMapViewDelegate {
    var mapView: MKMapView!
    var mapState: MapState = .Pan {
        didSet {
            changeUserInteraction()
        }
    }
    
    //Map Related Objects
    var allCoordinates: [SARCoordinate]!
    var polylines: [MKPolyline]!
    var polygon: MKPolygon!
    var polygonDrawn: ((MKPolygon)->Void)?
    var mapViewFinishedLoading: (()->Void)?
    var userLocationUpdated: ((MKUserLocation?)->Void)?
    var viewEnabled: (()->Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        initialize()
    }
    
    func initialize() {
        let _ = MKUserTrackingButton(mapView: mapView)
        polylines = [MKPolyline]()
        allCoordinates = [SARCoordinate]()
        //        return
        
        if mapView == nil {
            mapView = MKMapView(frame: self.bounds)
            mapView.showsUserLocation = true
            self.addSubview(mapView)
            mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        }
        
        mapView.setCenter(
            CLLocationCoordinate2D(latitude: 45.5076, longitude: -122.6736),
            animated: false)
        
        mapView.delegate = self
        
    }
    
    func currentLocation() -> CLLocation? {
        return mapView.userLocation.location
    }
    
    //    MARK: Other Methods
    func enableDrawing() {
        mapState = .Draw
        mapView.isUserInteractionEnabled = false
        mapView.removeAllPolylines()
        mapView.removePolygon()
        polygon = nil
//        polygon.getCoordinates(polygon.points(), range: NSRange.init(location: 0, length: polygon.pointCount))
    }
    
    func disableDrawing() {
        mapState = .Pan
        allCoordinates.removeAll()
        mapView.isUserInteractionEnabled = true
    }
    
    //    MARK: MapView Delegates
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKCircle {
            let renderer = MKCircleRenderer(overlay: overlay)
            renderer.fillColor = UIColor.black.withAlphaComponent(0.5)
            renderer.strokeColor = UIColor.blue
            renderer.lineWidth = 2
            return renderer
            
        } else if overlay is MKPolyline {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = UIColor.orange
            renderer.lineWidth = 3
            return renderer
        } else if overlay is MKPolygon {
            let renderer = MKPolygonRenderer(polygon: overlay as! MKPolygon)
            renderer.fillColor = UIColor.black.withAlphaComponent(0.5)
            renderer.strokeColor = UIColor.orange
            renderer.lineWidth = 2
            return renderer
        }

        
        return MKOverlayRenderer()
    }
    
    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        if let callback = mapViewFinishedLoading {
            callback()
        }
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        
        if let callback = userLocationUpdated {
            callback(userLocation)
        }
        
        print("didUpdate userLocation: \(userLocation)")
        mapView.setCenter((mapView.userLocation.location?.coordinate)!, animated: true)
    }
    
    //    MARK: Other Methods
    func changeUserInteraction() {
        if mapState == .Draw {
            mapView.isUserInteractionEnabled = false
        }
        else {
            mapView.isUserInteractionEnabled = true
        }
        if let callback = viewEnabled {
            callback()
        }
    }
    
    func handleCoordinate(coordinate: CLLocationCoordinate2D) {
        let polyline = mapView.addCoordinate(coordinate: coordinate, replaceLastObject: false, inCoordinates: &allCoordinates!)
        polylines.append(polyline)
        
    }
    
    func drawPolygon() {
        completePolygon()
//        optimizeWithHull()
        
        let points:[CLLocationCoordinate2D] = allCoordinates.coordinatesArray_CLLocationCoordinates()
        let polygon = MKPolygon(coordinates: points, count: allCoordinates.count)
        self.polygon = polygon
        mapView.add(polygon)
        
        if let callback = polygonDrawn {
            callback(polygon)
        }
        
    }
    
    
    //Duplicating & Adding the first coordinate as the last one
    func completePolygon() {
        if allCoordinates.count > 0 {
            let firstCoordinate = allCoordinates[0]
            let lastCoordinate = firstCoordinate.copy()
            allCoordinates.append(lastCoordinate as! SARCoordinate)
        }
    }
    
}

extension SARAppleMapsCanvas {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if mapState == .Pan {
            return
        }
        handleTouch(touch: touches.first!)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if mapState == .Pan {
            return
        }
        handleTouch(touch: touches.first!)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if mapState == .Pan {
            return
        }
        handleTouch(touch: touches.first!)
        print("touches.count: \(touches.count)")
        
        drawPolygon()
//        drawPolygonUsingGeoSwift()
    }
    
    func handleTouch(touch: UITouch) {
        let location = touch.location(in: mapView)
        let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
        
        handleCoordinate(coordinate: coordinate)
    }
    
}

extension MKMapView {
    func addCoordinate(coordinate: CLLocationCoordinate2D, replaceLastObject replaceLast:Bool, inCoordinates  coordinates:inout [SARCoordinate]) -> MKPolyline {
        if replaceLast && coordinates.count > 0 {
            coordinates.removeLast()
        }
        let coord = SARCoordinate(withCoordinate: coordinate)
        let point = convert(coord.coordinate, toPointTo: self)
        coord.coordinatePoint = point
        
        coordinates.append(coord)
        
        let points:[CLLocationCoordinate2D] = coordinates.coordinatesArray_CLLocationCoordinates()
        
        let polyline = MKPolyline(coordinates: points, count: coordinates.count)
        self.add(polyline)
        
        return polyline
    }
    
    func removeAllPolylines() {
        for overlay in self.overlays {
            if overlay is MKPolyline {
                self.remove(overlay)
            }
        }
    }
    
    func removePolygon() {
        for overlay in self.overlays {
            if overlay is MKPolygon {
                self.remove(overlay)
            }
        }
    }
    
}

extension CGPoint {
    func distance(from point:CGPoint) -> Float {
        let xDist = self.x - point.x
        let yDist = self.y - point.y
        return Float(sqrt((xDist * xDist) + (yDist * yDist)))
    }
}

extension CLLocationCoordinate2D {
    func distanceInKM(from coordinate: CLLocationCoordinate2D) -> Float {
        let selfLocation = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let distance = selfLocation.distance(from: location)/1000
        return Float(distance)
    }
}

extension Array where Iterator.Element: SARCoordinate {
    func coordinatesArray_CLLocationObjects() -> [CLLocation] {
        var coordsArray = [CLLocation]()
        for coordObj in self {
            let location = CLLocation(latitude: coordObj.coordinate.latitude, longitude: coordObj.coordinate.longitude)
            coordsArray.append(location)
        }
        return coordsArray
    }
    
    func coordinatesArray_CLLocationCoordinates() -> [CLLocationCoordinate2D] {
        var points = [CLLocationCoordinate2D]()
        for (_, coordObj) in self.enumerated() {
            points.append(coordObj.coordinate)
        }
        return points
    }
    
    func coordinatesStringArray() -> String {
        var stringArray = "POLYGON(("
        for (i, coord) in self.enumerated() {
            stringArray.append("\(coord.coordinate.longitude) \(coord.coordinate.latitude)")
            if i < self.count-1 {
                stringArray.append(", ")
            }
        }
        stringArray.append("))")
        return stringArray
    }
}


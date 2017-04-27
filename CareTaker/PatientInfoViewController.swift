//
//  PatientInfoViewController.swift
//  CareTaker
//
//  Created by Chris Fischer on 4/9/17.
//  Copyright © 2017 Chris Fischer. All rights reserved.
//

import UIKit
import MapKit
import FirebaseDatabase
import FirebaseAuth

class PatientInfoViewController: UIViewController, MKMapViewDelegate, UIGestureRecognizerDelegate {
    
    var isStartUp: Bool = true
    
    var patient: Patient? {
        didSet {
            guard let patient = patient else { return }
            
            // set up references
            self.locationRef = FIRDatabase.database().reference().child("users").child(patient.UID).child("lastLocation")
            self.statusRef = FIRDatabase.database().reference().child("users").child(patient.UID).child("status")
            self.timeRef = FIRDatabase.database().reference().child("users").child(patient.UID).child("timeLastActive")
        }
    }
    
    // database refs
    var locationRef: FIRDatabaseReference?
    var statusRef: FIRDatabaseReference?
    var timeRef: FIRDatabaseReference?
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var expandMapButton: UIButton!
    
    let currLocAnnotation = MKPointAnnotation()
    
    // constraints
    var isFullScreen = false
    var mapViewFullScreenConstraint: NSLayoutConstraint?
    @IBOutlet var mapViewHalfScreenConstraint: NSLayoutConstraint!
    var expandButtonLargeConstraint: NSLayoutConstraint?
    @IBOutlet var expandButtonSmallConstraint: NSLayoutConstraint!
    
    // labels
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var appStatusLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var lastLocationLabel: UILabel!
    @IBOutlet weak var timeView: UIStackView!
    
    var gestureRecognizer: UITapGestureRecognizer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        //set up full screen map mode
        mapViewFullScreenConstraint = NSLayoutConstraint(item: mapView, attribute: .top, relatedBy: .equal, toItem: topLayoutGuide, attribute: .bottom, multiplier: 1.0, constant: 0)
        mapViewFullScreenConstraint?.isActive = false
        
        // Set up expand button
        expandMapButton.layer.cornerRadius = 3
        expandButtonLargeConstraint = NSLayoutConstraint(item: expandMapButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 110)
        expandButtonLargeConstraint?.isActive = false
        
        // Change nav bar title to patient name
        navigationItem.title = (patient?.firstName)! + " " + (patient?.lastName)!
        
        // Set location total to patient's name
        currLocAnnotation.title = (patient?.firstName)! + " " + (patient?.lastName)!
        
        // Set up map
        gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        gestureRecognizer!.delegate = self
        mapView.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(annotationDragged(_:)), name: NSNotification.Name(rawValue: annotationDraggedKey), object: nil)
        
        // Set up edit mode
        setUpEditMode()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        locationRef?.observe(.value, with: { snapshot in
            if let lastLocation = snapshot.value as? [String: Double] {
                let lastLat = lastLocation["latitude"]
                let lastLong = lastLocation["longitude"]
                guard let latitude = lastLat, let longitude = lastLong else { return }
                let currLoc = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                self.currLocAnnotation.coordinate = currLoc
                if self.isStartUp {
                    self.mapView.addAnnotation(self.currLocAnnotation)
                    let region = MKCoordinateRegion(center: currLoc, span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005))
                    self.mapView.setRegion(region, animated: true)
                    self.isStartUp = false
                }
                if self.boundaryPolygon != nil {
                    self.updateLocationLabel(polygon: self.boundaryPolygon!)
                }
            }
        })
        statusRef?.observe(.value, with: { snapshot in
            if let status = snapshot.value as? String {
                // update status label
                switch status {
                case "active" :
                    self.timeView.isHidden = true
                    UIView.animate(withDuration: 0.2) {
                        self.view.layoutIfNeeded()
                    }
                    
                    self.statusLabel.text = "Active"
                    self.statusLabel.textColor = Colors.green
                    self.appStatusLabel.text = "Logged in"
                    self.appStatusLabel.textColor = Colors.green
                    break
                case "away" :
                    self.timeView.isHidden = false
                    UIView.animate(withDuration: 0.2) {
                        self.view.layoutIfNeeded()
                    }
                    self.statusLabel.text = "Away from phone"
                    self.statusLabel.textColor = Colors.red
                    self.appStatusLabel.text = "Logged in"
                    self.appStatusLabel.textColor = Colors.green
                    break
                case "loggedOut" :
                    self.statusLabel.text = "Unknown"
                    self.statusLabel.textColor = Colors.red
                    self.appStatusLabel.text = "Logged out"
                    self.appStatusLabel.textColor = Colors.red
                    break
                default :
                    break
                }
            }
        })
        timeRef?.observe(.value, with: { snapshot in
            if self.statusLabel.text != "Active" {
                self.timeView.isHidden = false
                UIView.animate(withDuration: 0.2) {
                    self.view.layoutIfNeeded()
                }
            }
            if let time = snapshot.value as? Int {
                let date = Date(timeIntervalSince1970: TimeInterval(time))
                let formater = DateFormatter()
                formater.dateFormat = "MMM d, h:mm a"
                self.timeLabel?.text = formater.string(from: date)
                self.timeLabel.textColor = Colors.red
            } else {
                self.timeLabel.textColor = Colors.red
            }
        })
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        locationRef?.removeAllObservers()
        statusRef?.removeAllObservers()
        timeRef?.removeAllObservers()
    }
    
    func isLocationInBoundary(coord: CLLocationCoordinate2D, boundary: MKPolygon) -> Bool {
        let polygonRenderer = MKPolygonRenderer(polygon: boundary)
        let currentMapPoint: MKMapPoint = MKMapPointForCoordinate(coord)
        let polygonViewPoint: CGPoint = polygonRenderer.point(for: currentMapPoint)
        
        return polygonRenderer.path.contains(polygonViewPoint)
    }
    
    func updateLocationLabel(polygon: MKPolygon) {
        if self.points.count <= 1 {
            lastLocationLabel?.text = ActivityStates.noGeofence.rawValue
            lastLocationLabel?.textColor = Colors.red
        } else {
            
            if isLocationInBoundary(coord: currLocAnnotation.coordinate, boundary: polygon) {
                lastLocationLabel?.text = ActivityStates.inside.rawValue
                lastLocationLabel?.textColor = Colors.green
            } else {
                lastLocationLabel?.text = ActivityStates.outside.rawValue
                lastLocationLabel?.textColor = Colors.red
            }
        }
    }
    
    // MARK: - IBActions
    
    @IBAction func expandMapTapped(_ sender: Any) {
        toggleMapContraints()
    }
    
    func toggleMapContraints() {
        if (!isFullScreen) {
            self.mapViewHalfScreenConstraint?.isActive = false
            self.mapViewFullScreenConstraint?.isActive = true
            self.expandButtonSmallConstraint?.isActive = false
            self.expandButtonLargeConstraint?.isActive = true
            UIView.animate(withDuration: 0.25) {
                self.view.layoutIfNeeded()
            }
            expandMapButton.setTitle("Collapse Map", for: .normal)
            isFullScreen = true
        } else {
            self.mapViewFullScreenConstraint?.isActive = false
            self.mapViewHalfScreenConstraint?.isActive = true
            self.expandButtonLargeConstraint?.isActive = false
            self.expandButtonSmallConstraint?.isActive = true
            UIView.animate(withDuration: 0.25) {
                self.view.layoutIfNeeded()
            }
            expandMapButton.setTitle("Expand Map", for: .normal)
            isFullScreen = false
        }
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destination = segue.destination as? EditPatientViewController
        if let editViewController = destination {
            editViewController.patient = patient
        }
    }
    
    // MARK: - Adding points
    
    var points = [CLLocationCoordinate2D]()
    var overLays = [MKOverlay]()
    var annotations = [CircleAnnotation]()
    
    var currDraggedCoord: CLLocationCoordinate2D?
    
    func handleTap(_ gestureReconizer: UILongPressGestureRecognizer) {
        
        let location = gestureReconizer.location(in: mapView)
        let coordinate = mapView.convert(location,toCoordinateFrom: mapView)
        points.append(coordinate)
        
        // draw line
        if points.count > 1 {
            
            let lastPoint = points[points.count - 1]
            let sndLastPoint = points[points.count - 2]
            
            let arr = [lastPoint, sndLastPoint]
            let polyline = MKPolyline(coordinates: arr, count: 2)
            overLays.append(polyline)
            self.mapView.add(polyline)
        }
        
        // Add annotation
        let annotation = CircleAnnotation(coordinate: coordinate)
        mapView.addAnnotation(annotation)
        annotations.append(annotation)
    }
    
    // MARK: - MK Renderer
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation.coordinate.latitude == currLocAnnotation.coordinate.latitude && annotation.coordinate.longitude == currLocAnnotation.coordinate.longitude {
            
            let reuseIdentifier = "userAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)
            
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }
            
            annotationView?.image = #imageLiteral(resourceName: "location_icon")
            annotationView?.centerOffset = CGPoint(x: 0, y: -Double((annotationView?.image?.size.height)!) / 2);
            
            return annotationView
        } else {
            
            let reuseIdentifier = "circleAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)
            
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
                annotationView?.canShowCallout = false
            } else {
                annotationView?.annotation = annotation
            }
            
            annotationView?.isDraggable = true
            
            let pinImage = #imageLiteral(resourceName: "circle_annotation")
            let size = CGSize(width: 14, height: 14)
            UIGraphicsBeginImageContext(size)
            pinImage.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            annotationView?.image = resizedImage
            
            return annotationView
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let line = MKPolylineRenderer(overlay: overlay)
            
            line.strokeColor = .white
            line.lineWidth = 4
            
            return line
        } else if overlay is MKPolygon {
            let polygon = MKPolygonRenderer(overlay: overlay)
            polygon.strokeColor = .white
            polygon.fillColor = UIColor(red: 141/255.0, green: 174/255.0, blue: 237/255.0, alpha: 0.3)
            polygon.lineWidth = 4
            
            return polygon
        }
        return MKOverlayRenderer()
    }
    
    // MARK: - Dragging
    
    func annotationDragged(_ notification: NSNotification) {
        guard currDraggedCoord != nil else { return }
        
        if let tuple = notification.userInfo?["coord"] as? CGPoint {
            
            let coordinate = mapView.convert(tuple,toCoordinateFrom: mapView)
            
            // update line overlays
            for i in 0...points.count-1 {
                if points[i].latitude == currDraggedCoord!.latitude && points[i].longitude == currDraggedCoord!.longitude {
                    if i < points.count-1  && i > 0 {
                        mapView.removeOverlays([overLays[i-1],overLays[i]])
                        let fstOverLay = MKPolyline(coordinates: [points[i-1], points[i]], count: 2)
                        let sndOverLay = MKPolyline(coordinates: [points[i], points[i+1]], count: 2)
                        overLays[i-1] = fstOverLay
                        overLays[i] = sndOverLay
                        mapView.add(fstOverLay)
                        mapView.add(sndOverLay)
                    } else if i == points.count-1 {
                        // last point
                        mapView.removeOverlays([overLays[i-1]])
                        let fstOverLay = MKPolyline(coordinates: [points[i-1], points[i]], count: 2)
                        overLays[i-1] = fstOverLay
                        mapView.add(fstOverLay)
                    } else if i == 0 {
                        // first point
                        mapView.removeOverlays([overLays[i]])
                        let sndOverLay = MKPolyline(coordinates: [points[i], points[i+1]], count: 2)
                        overLays[i] = sndOverLay
                        mapView.add(sndOverLay)
                    }
                    
                    points[i] = coordinate
                    currDraggedCoord = coordinate
                    
                    break
                }
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        switch newState {
        case .starting:
            view.dragState = .dragging
            currDraggedCoord = view.annotation?.coordinate
            break
        case .ending, .canceling:
            view.dragState = .none
            break
        default: break
        }
    }
    
    // MARK: - Edit mode
    
    var isEditMode = false
    
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var clearBoundaryButton: RoundedButton!
    @IBOutlet weak var removePatientButton: UIButton!
    @IBOutlet weak var detailsStackView: UIStackView!
    
    @IBOutlet weak var containerStackView: UIStackView!
    
    var mapViewEditScreenConstraint: NSLayoutConstraint?
    
    var boundaryPolygon: MKPolygon?
    
    // called on view did load
    func setUpEditMode() {
        // reset
        points.removeAll()
        overLays.removeAll()
        boundaryPolygon = nil
        
        mapViewEditScreenConstraint = NSLayoutConstraint(item: mapView, attribute: .top, relatedBy: .equal, toItem: containerStackView, attribute: .bottom, multiplier: 1.0, constant: 15)
        mapViewEditScreenConstraint?.isActive = false
        
        // get geofence points
        let ref = FIRDatabase.database().reference().child("users").child(patient!.UID).child("geoFence")
        ref.observeSingleEvent(of: .value, with: { snapshot in
            let pointsArr = snapshot.value as? [[String: Double]]
            
            guard pointsArr != nil else { return }
            
            for i in 0...pointsArr!.count-1 {
                let dict = pointsArr![i]
                
                let lat = dict["lat"]
                let long = dict["long"]
                let coord = CLLocationCoordinate2D(latitude: lat!, longitude: long!)
                
                self.points.append(coord)
                
                // make annotion
                let annotation = CircleAnnotation(coordinate: coord)
                self.annotations.append(annotation)
                
                if self.points.count >= 2 {
                    // draw poly lines between the points
                    let polyline = MKPolyline(coordinates: [self.points[i], self.points[i-1]], count: 2)
                    self.overLays.append(polyline)
                }
            }
            
            // draw polygon
            let poly = MKPolygon(coordinates: self.points, count: self.points.count)
            self.boundaryPolygon = poly
            self.mapView.add(poly)
        })
        
    }
    
    @IBAction func editTapped(_ sender: Any) {
        if !isEditMode {
            isEditMode = true
            editButton.title = "Done"
            editButton.style = .done
            detailsStackView.isHidden = true
            removePatientButton.isHidden = false
            clearBoundaryButton.isHidden = false
            expandMapButton.isHidden = true
            
            mapView.addGestureRecognizer(gestureRecognizer!)
            
            mapViewEditScreenConstraint?.isActive = true
            mapViewHalfScreenConstraint.isActive = false
            mapViewFullScreenConstraint?.isActive = false
            UIView.animate(withDuration: 0.25) {
                self.view.layoutIfNeeded()
            }
            UIView.animate(withDuration: 0.2) {
                self.view.layoutIfNeeded()
            }
            mapView.addAnnotations(self.annotations)
            mapView.addOverlays(overLays)
            if boundaryPolygon != nil {
                mapView.removeOverlays([boundaryPolygon!])
            }
        } else {
            isEditMode = false
            editButton.title = "Edit"
            editButton.style = .plain
            detailsStackView.isHidden = false
            removePatientButton.isHidden = true
            clearBoundaryButton.isHidden = true
            expandMapButton.isHidden = false
            
            mapView.removeGestureRecognizer(gestureRecognizer!)
            
            mapViewEditScreenConstraint?.isActive = false
            mapViewHalfScreenConstraint.isActive = true
            mapViewFullScreenConstraint?.isActive = false
            expandMapButton.setTitle("Expand Map", for: .normal)
            isFullScreen = false
            UIView.animate(withDuration: 0.2) {
                self.view.layoutIfNeeded()
            }
            mapView.removeAnnotations(self.annotations)
            mapView.removeOverlays(overLays)
            let poly = MKPolygon(coordinates: points, count: points.count)
            boundaryPolygon = poly
            mapView.add(poly)
            
            // save points to firebase
            savePoints()
            
            updateLocationLabel(polygon: poly)
        }
    }
    
    func savePoints() {
        let ref = FIRDatabase.database().reference().child("users").child(patient!.UID).child("geoFence")
        ref.removeValue()
        var pointsToUpdate = [[String: Double]]()
        for point in points {
            let dict = ["lat": point.latitude, "long": point.longitude]
            pointsToUpdate.append(dict)
        }
        ref.setValue(pointsToUpdate)
    }
    
    @IBAction func clearBoundary(_ sender: Any) {
        let alert = UIAlertController(title: "Remove all geofence points?", message: "This cannot be undone.", preferredStyle: UIAlertControllerStyle.alert)
        let yes = UIAlertAction(title: "Yes", style: UIAlertActionStyle.default, handler: { action in
            self.mapView.removeOverlays(self.overLays)
            self.mapView.removeAnnotations(self.annotations)
            self.points.removeAll()
            self.overLays.removeAll()
            self.annotations.removeAll()
            self.boundaryPolygon = nil
            
        })
        let no = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(yes)
        alert.addAction(no)
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Remove Patient
    
    let userId = FIRAuth.auth()?.currentUser?.uid
    
    @IBAction func removePatient(_ sender: Any) {
        
        let alert = UIAlertController(title: "Remove this patient?", message: "You can always add them back, but your location geofence will be lost.", preferredStyle: UIAlertControllerStyle.alert)
        let yes = UIAlertAction(title: "Yes", style: UIAlertActionStyle.default, handler: { action in
            // remove value
            let ref = FIRDatabase.database().reference().child("users").child(self.userId!).child("patients")
            ref.observeSingleEvent(of: .value, with: { snapshot in
                for (key, value) in snapshot.value as! [String: String] {
                    if value == self.patient!.UID {
                        ref.child(key).removeValue()
                        return
                    }
                }
            })
            // remove saved geofence
            let geoFenceRef = FIRDatabase.database().reference().child("users").child(self.patient!.UID).child("geoFence")
            geoFenceRef.removeValue()
            
            self.performSegue(withIdentifier: "patientDeleted", sender: nil)
        })
        let no = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(yes)
        alert.addAction(no)
        self.present(alert, animated: true, completion: nil)
        
    }
    
    
    
}

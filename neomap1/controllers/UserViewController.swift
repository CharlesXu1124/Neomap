//
//  ViewController.swift
//  neomap1
//
//  Created by Ananya Jajoo on 12/28/20.
//

import UIKit
import Firebase
import MapKit
import Alamofire
import SwiftyJSON

class UserViewController: UIViewController, UIGestureRecognizerDelegate, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    var username: String!
    //Declare database instance
    let db = Firestore.firestore()
    var email: String!
    var latitude: Double!
    var longitude: Double!
    var coordinates: [CLLocationCoordinate2D] = []
    
    // base64 encoded image stream
    var imageTaken: UIImage!
    var strBase64: String = ""
    
    var userHasImage: Bool! = false
    
    @IBOutlet weak var imageView: UIImageView!
    
    
    @IBOutlet weak var locationField: UILabel!
    
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var usernameField: UILabel!
    
    @IBOutlet weak var captionField: UITextView!
    
    var imagePicker = UIImagePickerController()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //print(usernameField.text ?? "null value")
        
        
        loadUsername()
        usernameField.text = ""
        
        let longTapGesture = UILongPressGestureRecognizer(target: self, action: #selector(longTap))
        mapView.addGestureRecognizer(longTapGesture)
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        let myColor = UIColor.black
        captionField.layer.borderColor = myColor.cgColor
        captionField.layer.cornerRadius = 7
        captionField.layer.borderWidth = 5
        
        imagePicker.delegate = self
    }
    
    @objc func longTap(sender: UIGestureRecognizer){
        print("long tap")
        if sender.state == .began {
            let locationInView = sender.location(in: mapView)
            let locationOnMap = mapView.convert(locationInView, toCoordinateFrom: mapView)
            addToMap(location: locationOnMap)
            latitude = locationOnMap.latitude
            longitude = locationOnMap.longitude
            print("latitude: \(latitude), longitude: \(longitude)")
            performRequest(withLat: latitude, withLong: longitude)
        }
    }
    
    func performRequest(withLat latitude: Double, withLong longitude: Double){
        let headers: HTTPHeaders = [
            "Authorization": "prj_live_pk_3d1dff29f680dff29dadf58c7d56f05fc4506403",
        ]
        let url = "https://api.radar.io/v1/geocode/reverse?coordinates=\(latitude),\(longitude)"
        
        AF.request(url, method: .get, headers: headers ).validate().responseData { response in
            switch response.result {
            case .success(let value):
                //print(String(data: value, encoding: .utf8)!)
                if let json = response.data {
                    do{
                        let data = try JSON(data: json)
                        let locationJSON = data["addresses"][0]["formattedAddress"]
                        //print("location: \(location)")
                        self.locationField.text = "\(locationJSON)"
                        //self.location = self.locationField.text
                    }
                    catch{
                        print("JSON Error")
                    }

                }
            case .failure(let error):
                print(error)
            }
        }
    }

    func addToMap(location: CLLocationCoordinate2D){
            let annotation = MKPointAnnotation()
            annotation.coordinate = location
            //annotation.title = "Some Title"
            //annotation.subtitle = "Some Subtitle"
            self.mapView.addAnnotation(annotation)
    }
    
    
    
    func loadUsername() {
        db.collection("usersInfo").getDocuments() { [self] (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    //print("\(document.documentID) => \(document.data())")
                    
                    if document.data()["email"] as? String == email {
                        self.username = document.data()["username"]! as? String
                        let postLatitude = document.data()["latitude"] as? Double
                        
                    }
                }
            }
            
            usernameField.text = "Welcome back! \(username!)"
            usernameField.textColor = UIColor.purple
            lookUpPin()
        }
    }
    
    func loadPostOnMap(withLatitude lat: Double, withLongitude lon: Double) {
        addToMap(location: CLLocationCoordinate2D(latitude: lat, longitude: lon))
    }
    
    @IBAction func showUsername(_ sender: UIButton) {
        performSegue(withIdentifier: "portfolioSegue", sender: self)
    }
    
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if let secondViewController = segue.destination as? PortfolioViewController {
            secondViewController.email = email
            secondViewController.username = username
            //secondViewController.location = location
        }
    }

    @IBAction func postButton(_ sender: UIButton) {
        // create user post struct
        var userPost = Post(location: self.locationField.text, caption: self.captionField.text, latitude: latitude, longitude: longitude, username: username, postTime: NSDate().timeIntervalSince1970, withImage: false, image: nil)
        if userHasImage {
            userPost.withImage = true
            userPost.image = strBase64
        }
        
        
        if self.captionField.text == ""{
            let alert = UIAlertController(title: "Post Error", message: "Post cannot be empty", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                  switch action.style{
                  case .default:
                        print("default")

                  case .cancel:
                        print("cancel")

                  case .destructive:
                        print("destructive")
            }}))
            self.present(alert, animated: true, completion: nil)
        }
        else{
            addPost(withPost: userPost)
            
            self.captionField.text = ""
            //self.locationField.text = ""
        }
    }
    
    func addPost(withPost userPost: Post){
        var ref: DocumentReference? = nil
        if userHasImage {
            ref = db.collection("userPost").addDocument(data: [
                "location": userPost.location!,
                "caption": userPost.caption!,
                "latitude": userPost.latitude!,
                "longitude": userPost.longitude!,
                "username": username!,
                "postTime": userPost.postTime!,
                "withImage": true,
                "image": strBase64
            ]) { err in
                if let err = err {
                    print("Error adding document: \(err)")
                } else {
                    print("Document added with ID: \(ref!.documentID)")
                }
            }
        } else {
            ref = db.collection("userPost").addDocument(data: [
                "location": userPost.location!,
                "caption": userPost.caption!,
                "latitude": userPost.latitude!,
                "longitude": userPost.longitude!,
                "username": username!,
                "postTime": userPost.postTime!,
                "withImage": false,
            ]) { err in
                if let err = err {
                    print("Error adding document: \(err)")
                } else {
                    print("Document added with ID: \(ref!.documentID)")
                }
            }
        }
        userHasImage = false
        
    }
    
    func lookUpPin(){
        db.collection("userPost").getDocuments() { [self] (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    //print("\(document.documentID) => \(document.data())")
                    
                    if document.data()["username"] as? String == username {
                        let latitude = document.data()["latitude"]! as? Double
                        let longitude = document.data()["longitude"]! as? Double
                        
                        let coordinate = CLLocationCoordinate2D(latitude: latitude!, longitude: longitude!)
                        addToMap(location: coordinate)
                    }
                }
            }
        }
    }
    
    
    
    @IBAction func uploadImage(_ sender: UIButton) {
        openLibrary()
    }
    
    @IBAction func takeScreenshot(_ sender: UIButton) {
        openCamera()
    }

    func imagePickerController(_ picker: UIImagePickerController,
    didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey :
    Any]) {
        if let img = info[.originalImage] as? UIImage {
            self.imageView.image = img
            self.dismiss(animated: true, completion: nil)
            print("image found")
            imageTaken = img
            userHasImage = true
        }
        else {
            print("error")
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
        imageView.isHidden = true
        
        let imageData: NSData = imageTaken.jpeg(.lowest)! as NSData
        strBase64 = imageData.base64EncodedString(options: [])
        
    }

    func openCamera() {
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = false
        imagePicker.showsCameraControls = true
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    func openLibrary() {
        imagePicker.sourceType = .photoLibrary
        self.present(imagePicker, animated: true, completion: nil)
    }
}

extension UIImage {
    enum JPEGQuality: CGFloat {
        case lowest  = 0
        case low     = 0.25
        case medium  = 0.5
        case high    = 0.75
        case highest = 1
    }

    /// Returns the data for the specified image in JPEG format.
    /// If the image object’s underlying image data has been purged, calling this function forces that data to be reloaded into memory.
    /// - returns: A data object containing the JPEG data, or nil if there was a problem generating the data. This function may return nil if the image has no data or if the underlying CGImageRef contains data in an unsupported bitmap format.
    func jpeg(_ jpegQuality: JPEGQuality) -> Data? {
        return jpegData(compressionQuality: jpegQuality.rawValue)
    }
}

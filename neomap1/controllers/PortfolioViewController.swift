//
//  ViewController.swift
//  neomap1
//
//  Created by Ananya Jajoo on 12/28/20.
//

import UIKit
import Firebase

class PortfolioViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, ARDisplayDelegate {
    
    
    
    var email: String!
    var username: String!
    
    //
    var imageTaken: UIImage!
    var selectedLatitude: Double!
    var selectedLongitude: Double!
    
    var currentCell: PostCell!

    let db = Firestore.firestore()
    var post: [Post] = []
    
    @IBOutlet weak var postInfoTable: UITableView!
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return post.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Unselect the row, and instead, show the state with a checkmark.
        tableView.deselectRow(at: indexPath, animated: false)
        
        guard postInfoTable.cellForRow(at: indexPath) != nil else { return }
        
        
        
        // Update the selected item to indicate whether the user packed it or not.
        let item = post[indexPath.row]
        
        selectedLatitude = item.latitude
        selectedLongitude = item.longitude
        if item.withImage {
            imageTaken = item.postImage
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(email ?? "null email")
        
        postInfoTable.delegate = self
        postInfoTable.dataSource = self
        
        
        //postInfoTable.register(UITableViewCell.self, forCellReuseIdentifier: "CustomCell")
        postInfoTable.register(UINib(nibName: "PostCell", bundle: nil), forCellReuseIdentifier: "ReusableCell")
        lookUpInfo()
    }
    
    func segueFunction() {
        self.performSegue(withIdentifier: "ARSegue", sender: self)
    }
    
    @IBAction func backToUser(_ sender: UIButton) {
        performSegue(withIdentifier: "backToUserSegue", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let secondViewController = segue.destination as? UserViewController {
            secondViewController.email = email
            secondViewController.username = username
            //secondViewController.location = location
        }
        
        if let secondViewController = segue.destination as? UINavigationController {
            let arViewController = secondViewController.topViewController as! ARViewController
            arViewController.email = email
            arViewController.username = username
            arViewController.imageTaken = imageTaken
            arViewController.latitude = selectedLatitude
            arViewController.longitude = selectedLongitude
        }
    }

    func lookUpInfo() {
        db.collection("userPost").getDocuments() { [self] (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    //print("\(document.documentID) => \(document.data())")
                    
                    DispatchQueue.main.async {
                        if document.data()["username"] as? String == username {
                            let location = document.data()["location"]! as? String
                            let caption = document.data()["caption"]! as? String
                            let postTime = document.data()["postTime"] as? Double
                            let userHasImage = document.data()["withImage"] as? Bool
                            
                            var userPost = Post(location: location, caption: caption, latitude: nil, longitude: nil, username: username, postTime: postTime, withImage: false, image: nil)
                            if userHasImage! {
                                let postImageStr = document.data()["image"] as? String
                                if let decodedData = NSData(base64Encoded: postImageStr!, options: []),
                                   let decodedImage = UIImage(data: decodedData as Data) {
                                    userPost.postImage = decodedImage
                                    //imageTaken = decodedImage
                                }
                                
                                userPost.withImage = true

                            }
                            
                            post.append(userPost)
                            self.postInfoTable.reloadData()
                        }
                    }
                }
            }
        }
    }
    
    func imageForBase64String(_ strBase64: String) -> UIImage? {

        do{
            let imageData = try Data(contentsOf: URL(string: strBase64)!)
            let image = UIImage(data: imageData)
            return image!
        }
        catch{
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        let postItem = post[indexPath.row]
        currentCell = postInfoTable.dequeueReusableCell(withIdentifier: "ReusableCell", for: indexPath) as? PostCell
        
        currentCell.delegate = self
        
        if postItem.withImage {
            currentCell.postImage.image = postItem.postImage
            
        } else {
            currentCell.postImage.isHidden = true
        }
        
        
        let postTimeInterval = TimeInterval(postItem.postTime!)
        let postTime = NSDate(timeIntervalSince1970: TimeInterval(postTimeInterval))
        
        currentCell.captionField.text = "Caption: \(postItem.caption!)"
        currentCell.locationField.text = "Location: \(postItem.location!)"
        currentCell.postTimeField.text = "Post Time: \(postTime)"
        
        
        
        return currentCell
    }
    
    @IBAction func showLiveUpdates(_ sender: UIButton) {
        self.performSegue(withIdentifier: "ARSegue", sender: self)
    }
    
}

extension String {
    func base64Encoded() -> String? {
        return data(using: .utf8)?.base64EncodedString()
    }
    func base64Decoded() -> String? {
        var st = self;
        if (self.count % 4 <= 3) && (self.count % 4 >= 1) {
            st += String(repeating: "=", count: (4 - self.count % 4))
        }
        guard let data = Data(base64Encoded: st) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

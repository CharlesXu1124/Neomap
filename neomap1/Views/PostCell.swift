//
//  PostCell.swift
//  neomap1
//
//  Created by Ananya Jajoo on 12/30/20.
//

//
//  ViewController.swift
//  neomap1
//
//  Created by Ananya Jajoo on 12/28/20.
//
import UIKit

protocol ARDisplayDelegate {
    func segueFunction() //this function will be in your receiving class
}

class PostCell: UITableViewCell{
    
    @IBOutlet weak var captionField: UILabel!
    
    @IBOutlet weak var locationField: UILabel!
    
    @IBOutlet weak var blankField: UILabel!
    
    @IBOutlet weak var postTimeField: UILabel!
    
    @IBOutlet weak var postImage: UIImageView!
    
    var delegate: ARDisplayDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    @IBAction func playInAR(_ sender: UIButton) {
        print("ready to segue")
        delegate?.segueFunction()
    }
}

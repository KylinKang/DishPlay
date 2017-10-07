//
//  ViewController.swift
//  DishPlay
//
//  Created by Jiaxiao Zhou on 10/6/17.
//  Copyright © 2017 CalHack. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import Alamofire
import TesseractOCR
import SwiftyJSON


class ViewController: UIViewController, ARSCNViewDelegate, G8TesseractDelegate{

    
    @IBOutlet weak var sceneView: ARSCNView!
    
    @IBOutlet weak var textView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        
        // Set the scene to the view
        sceneView.scene = scene
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ViewController.handleTap(gestureReconize:)))
        view.addGestureRecognizer(tapGesture)

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    var dishName: String = "" {
        willSet {
            // run the image grapping thing
            let headers = [
                "Ocp-Apim-Subscription-Key": "293bdc29ef6540749d2db90d239bdc0e"
            ]
            var requestParams = [String:AnyObject]()
            requestParams["q"] = newValue as AnyObject?
            requestParams["count"] = 10 as AnyObject?
            requestParams["safeSearch"] = "Strict" as AnyObject?
            
            Alamofire.request("https://api.cognitive.microsoft.com/bing/v7.0/images/search",
              parameters: requestParams,
              encoding: URLEncoding.default, headers: headers).responseJSON {
                (response:DataResponse<Any>) in
                
                switch(response.result) {
                case .success(_):
                    
                    
                    if let JSON = response.result.value as? [String: Any] {
                        //print(JSON)
                        //take URLs from the json into an ImagesURLsArray
                        let value = JSON["value"] as? [[String: AnyObject]]
                        //for imageValue in value! {
                        if let imageValue = value {
                            if imageValue.count > 0 {
                                self.imageURL = URL(string: (imageValue[0]["contentUrl"] as? String)!)
                                /*Alamofire.download((imageValue["contentUrl"] as? String)!)
                                 .responseData { response in
                                 if let data = response.result.value {
                                 let image = UIImage(data: data)
                                 }
                                 }*/
                                //}
                            }
                        }
                    }  else {
                        print("error with response.result.value")}
                case .failure(_):
                    if let errorNum = response.response?.statusCode {
                        let stringErrorNum = "{\"error\": \(errorNum)}"
                        print(stringErrorNum)
                    }
                }
            }
        }
    }
    
    var imageURL: URL? {
        didSet {
            fetchImage()
        }
    }
    
    private func fetchImage() {
        if let url = imageURL {
            let urlContents = try? Data(contentsOf: url)
            if let imageData = urlContents {
                image = UIImage(data: imageData)
                print(image)
                //self.performSegue(withIdentifier: "fromARtoImage", sender: self)
            }
        }
    }
    
    private var image: UIImage?
    
    
    @objc
    func handleTap(gestureReconize: UITapGestureRecognizer) {
        guard sceneView.session.currentFrame != nil else {
            return
        }
        //guard let pointOfView = sceneView.pointOfView else { return }
        
        let image = sceneView.snapshot()
        let scale: CGFloat = image.size.width / sceneView.frame.size.width
        let rect: CGRect = CGRect(x: textView.frame.origin.x, y: textView.frame.origin.y-sceneView.frame.origin.y, width: textView.frame.size.width, height: textView.frame.size.height)
        let croppedImage = image.crop(rect:rect, scale: scale)
        // use Azure computer vision API
        /*
        var ocrParameters = [String:String]()
        ocrParameters["url"] = "https://i.stack.imgur.com/vrkIj.png"
        let headers = [
            "Content-Type": "application/json",
            "Ocp-Apim-Subscription-Key": "1b87ea699b16400c804b43a377a82484"
        ]
        Alamofire.request("https://westcentralus.api.cognitive.microsoft.com/vision/v1.0/ocr", method: .post, parameters: [:], encoding: "{\"url\":\"https://i.stack.imgur.com/vrkIj.png\"}", headers: headers).responseJSON {
            (response:DataResponse<Any>) in
            
            switch(response.result) {
                case .success(_):
                    if let JSON = response.result.value as? [String: Any] {
                        print(JSON)
                    }
                case .failure(_):
                    if let errorNum = response.response?.statusCode {
                        let stringErrorNum = "{\"error\": \(errorNum)}"
                        print(stringErrorNum)
                    }
            }
        }*/
        
        if let tessract = G8Tesseract(language: "eng") {
            tessract.delegate = self
            
            tessract.image = croppedImage
            tessract.recognize()
            print("Recognized text: \(tessract.recognizedText)")
            
            dishName = tessract.recognizedText.trim()
        }
        //let imagePlane = SCNPlane(width: sceneView.bounds.width / 6000, height: sceneView.bounds.height / 6000)
        //imagePlane.firstMaterial?.
        //imagePlane.
        
    }
    
    func progressImageRecognition(for tesseract: G8Tesseract!) {
        print("Reconigtion progress: \(tesseract.progress) %")
    }

    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}

extension String {
    func trim() -> String {
        return self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
}

extension UIImage {
    func crop( rect: CGRect, scale: CGFloat) -> UIImage {
        var rect = rect
        rect.origin.x*=scale
        rect.origin.y*=scale
        rect.size.width*=scale
        rect.size.height*=scale
 
        let imageRef = self.cgImage!.cropping(to: rect)
        let image = UIImage(cgImage: imageRef!)
        return image
    }
}

extension String: ParameterEncoding {
    
    public func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        var request = try urlRequest.asURLRequest()
        request.httpBody = data(using: .utf8, allowLossyConversion: false)
        return request
    }
    
}

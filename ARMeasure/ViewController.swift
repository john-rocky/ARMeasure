//
//  ARViewController.swift
//  CapturedObjectViewer
//
//  Created by DAISUKEMAJIMA on 2022/01/17.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSessionDelegate {
    
    var sceneView:ARSCNView!
    var trackingStateOK: Bool = false

    let sphereNode = SCNNode(geometry: SCNSphere(radius: 0.01))
    var tappedPointNodeOrigin: SCNNode?
    var tappedPointNodeDest: SCNNode?
    var lineNode = SCNNode()
    var objectNode: SCNNode!
    
    var distanceLabel = UILabel()
    let coachingOverlayView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView = ARSCNView(frame: view.bounds)
        view.addSubview(sceneView)
        
        sceneView.scene.rootNode.addChildNode(lineNode)
        
        distanceLabel.text = ""
        distanceLabel.frame = CGRect(x: 0, y: view.bounds.maxY - 200, width: view.bounds.width, height: 200)
        view.addSubview(distanceLabel)
        distanceLabel.textColor = .red
        distanceLabel.textAlignment = .center
        distanceLabel.numberOfLines = 3
        distanceLabel.font = .systemFont(ofSize: 40, weight: .bold)
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tap(recognizer:))))
        setupCoachingOverlay()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let worldtracking = ARWorldTrackingConfiguration()
        sceneView.session.run(worldtracking, options: [.removeExistingAnchors])
        sceneView.session.delegate = self
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        switch camera.trackingState {
        case .normal:
            coachingOverlayView.isHidden = true
            trackingStateOK = true
            distanceLabel.text = "Displays the distance\n between the two touched points"
        default:
            coachingOverlayView.isHidden = false
            trackingStateOK = false
        }
    }
    
    @objc func tap(recognizer: UITapGestureRecognizer) {
        guard trackingStateOK == true else { return }

//        guard let query = sceneView.raycastQuery(from: recognizer.location(in: sceneView), allowing: .estimatedPlane, alignment: .any) else {return}
//        let results = sceneView.session.raycast(query)
//        guard let position = results.first?.worldTransform else {return}
        //        let worldCoordinates = simd_float3(x: position.columns.3.x, y: position.columns.3.y, z: position.columns.3.z)
        let hitTestResults = sceneView.hitTest(recognizer.location(in: sceneView),types:[.estimatedHorizontalPlane,.estimatedVerticalPlane])
        guard let result = hitTestResults.first else { return }
        let worldCoordinates = simd_float3(x: result.worldTransform.columns.3.x, y: result.worldTransform.columns.3.y, z: result.worldTransform.columns.3.z)
        
        guard tappedPointNodeOrigin != nil else {
            tappedPointNodeOrigin = sphereNode.clone()
            tappedPointNodeOrigin?.geometry?.materials.first?.diffuse.contents = UIColor.red
            sceneView.scene.rootNode.addChildNode(tappedPointNodeOrigin!)
            tappedPointNodeOrigin?.simdWorldPosition = worldCoordinates
            return
        }
        
        if tappedPointNodeDest != nil {
            tappedPointNodeDest?.removeFromParentNode()
            lineNode.removeFromParentNode()
            tappedPointNodeDest = nil
            

            tappedPointNodeOrigin?.simdWorldPosition = worldCoordinates
        } else {
            tappedPointNodeDest = sphereNode.clone()
            tappedPointNodeDest?.geometry?.materials.first?.diffuse.contents = UIColor.red
            tappedPointNodeDest?.simdWorldPosition = worldCoordinates
            sceneView.scene.rootNode.addChildNode(tappedPointNodeDest!)
            
            let distance = distance(tappedPointNodeOrigin!.simdWorldPosition, tappedPointNodeDest!.simdWorldPosition)
            distanceLabel.text = String(floor(distance*10000)/100) + "cm"
            print(distance)
            let lineNode = lineBetweenNodes(positionA: tappedPointNodeOrigin!.worldPosition, positionB: tappedPointNodeDest!.worldPosition, inScene: sceneView.scene)
            lineNode.geometry?.materials.first?.readsFromDepthBuffer = false
            
            sceneView.scene.rootNode.addChildNode(lineNode)
            self.lineNode.removeFromParentNode()
            self.lineNode = lineNode
        }
        
        
    }
    
    func lineBetweenNodes(positionA: SCNVector3, positionB: SCNVector3, inScene: SCNScene) -> SCNNode {
        let vector = SCNVector3(positionA.x - positionB.x, positionA.y - positionB.y, positionA.z - positionB.z)
        let distance = sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
        let midPosition = SCNVector3 (x:(positionA.x + positionB.x) / 2, y:(positionA.y + positionB.y) / 2, z:(positionA.z + positionB.z) / 2)

        let lineGeometry = SCNCylinder()
        lineGeometry.radius = 0.005
        lineGeometry.height = CGFloat(distance)
        lineGeometry.radialSegmentCount = 5
        lineGeometry.firstMaterial!.diffuse.contents = UIColor.red

        let lineNode = SCNNode(geometry: lineGeometry)
        lineNode.position = midPosition
        lineNode.look (at: positionB, up: inScene.rootNode.worldUp, localFront: lineNode.worldUp)
    
        return lineNode
    }
    
    func setupCoachingOverlay(){
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 200))
        label.text = "If the app can't detect the tapped surface,\nMove the device to understand the environment"
        label.numberOfLines = 3
        label.textAlignment = .center
        label.textColor = .white
        view.addSubview(label)
    }
    
}

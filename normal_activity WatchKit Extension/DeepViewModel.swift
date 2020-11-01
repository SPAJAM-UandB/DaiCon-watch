//
//  DeepViewModel.swift
//  normal_activity WatchKit Extension
//
//  Created by koki-ta on 2020/09/27.
//

import Foundation
import AVFoundation

import CoreLocation
import CoreML

import MapKit

import CoreMotion


struct ModelConstants{
    static let predictionWindowSize = 20
    static let sensorsUpdateInterval = 1.0 / 10.0
    static let stateInLength = 400
}
 
class DeepViewModel : NSObject, ObservableObject, CLLocationManagerDelegate {
    
    internal var audioPlayer: AVAudioPlayer!
    internal var datasound: AVAudioPlayer!
    internal var kamehameha_sound: AVAudioPlayer!
    internal var nature_sound: AVAudioPlayer!
    internal var memo_sound: AVAudioPlayer!
    private var audioRecorder: AVAudioRecorder!
    let motionManager = CMMotionManager()
        
    @Published var activity_name:[String : Double] = ["label":0.0]
    @Published var label:String = "Standing"
    @Published var select_label:String = ""
    
    
    private let settings           = [
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
        AVSampleRateKey: 44100,
        AVNumberOfChannelsKey: 2,
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue]
    
    
    let activityClassificationModel =  jphackclassifer_5()

    let accelDataX = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let accelDataY = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let accelDataZ = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)

    let gyroDataX = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let gyroDataY = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let gyroDataZ = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)

    var stateOutput = try! MLMultiArray(shape:[ModelConstants.stateInLength as NSNumber], dataType: MLMultiArrayDataType.double)
    
    private var nature_state:Bool = false
    private var memo_state:Bool = false
    private var passlabel:[String] = ["","","","",""]
    
    
    override init(){
        super.init()
    }

    func record_start(){
        motionManager.deviceMotionUpdateInterval = ModelConstants.sensorsUpdateInterval
        
        motionManager.startDeviceMotionUpdates( to: OperationQueue.current!, withHandler:{
            deviceManager, error in
            let gyr: CMRotationRate = deviceManager!.rotationRate
            let acc: CMAcceleration = deviceManager!.userAcceleration
            
            
            self.accelDataX[[ModelConstants.predictionWindowSize - 1] as [NSNumber]] = NSNumber(value: acc.x)
            self.accelDataY[[ModelConstants.predictionWindowSize - 1] as [NSNumber]] = NSNumber(value: acc.y)
            self.accelDataZ[[ModelConstants.predictionWindowSize - 1] as [NSNumber]] = NSNumber(value: acc.z)
            self.gyroDataX[[ModelConstants.predictionWindowSize - 1] as [NSNumber]]  = NSNumber(value: gyr.x)
            self.gyroDataY[[ModelConstants.predictionWindowSize - 1] as [NSNumber]]  = NSNumber(value: gyr.y)
            self.gyroDataZ[[ModelConstants.predictionWindowSize - 1] as [NSNumber]]  = NSNumber(value: gyr.z)
            
            for i in 1..<ModelConstants.predictionWindowSize {
                self.accelDataX[i-1] = self.accelDataX[i]
                self.accelDataY[i-1] = self.accelDataY[i]
                self.accelDataZ[i-1] = self.accelDataZ[i]
                self.gyroDataX[i-1]  = self.gyroDataX[i]
                self.gyroDataY[i-1]  = self.gyroDataY[i]
                self.gyroDataZ[i-1]  = self.gyroDataZ[i]
            }
            
            let modelPrediction = try! self.activityClassificationModel.prediction(acclX: self.accelDataX, acclY: self.accelDataY, acclZ: self.accelDataZ, gyroX: self.gyroDataX, gyroY: self.gyroDataY, gyroZ: self.gyroDataZ, stateIn: nil)
            
            self.label = modelPrediction.label
            print(modelPrediction.labelProbability)
            self.activity_name = modelPrediction.labelProbability
            
            for i in 1..<5 {
                self.passlabel[i-1] = self.passlabel[i]
            }
            
            self.passlabel[4] = modelPrediction.label
            
            if self.passlabel[0] == "Abs" && self.passlabel[1] == "Abs" && self.passlabel[2] == "Abs" && self.passlabel[3] == "Abs" && self.passlabel[4] == "Abs" && self.nature_state == false{
                self.nature_state = true
            }else if self.passlabel[0] == "Not muscle" && self.passlabel[1] == "Not muscle" && self.passlabel[2] == "Not muscle" && self.nature_state == true{
                self.nature_state = false
                self.m_sound()
            }
        })
    }
    
    func record_end(){
        motionManager.stopDeviceMotionUpdates()
        if self.nature_state == true{
            self.nature_state = false
        }else if self.memo_state == true{
            self.memo_state = false
        }
    }
    
    func kame_sound(){
        guard let audioPath = Bundle.main.path(forResource: "kamehameha", ofType:"mp3") else{
            return print("error")
        }
        let path = URL(fileURLWithPath: audioPath)
        kamehameha_sound = try! AVAudioPlayer(contentsOf: path)
        kamehameha_sound.volume = 1.0
        kamehameha_sound.play()
    }
    
    func m_sound(){
        guard let audioPath = Bundle.main.path(forResource: "memo", ofType:"mp3") else{
            return print("error")
        }
        let path = URL(fileURLWithPath: audioPath)
        memo_sound = try! AVAudioPlayer(contentsOf: path)
        memo_sound.volume = 1.0
        memo_sound.play()
    }
    func n_sound(){
        guard let audioPath = Bundle.main.path(forResource: "nature", ofType:"mp3") else{
            return print("error")
        }
        let path = URL(fileURLWithPath: audioPath)
        nature_sound = try! AVAudioPlayer(contentsOf: path)
        nature_sound.volume = 1.0
        nature_sound.play()
    }
}

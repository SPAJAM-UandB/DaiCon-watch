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

struct Sound_List: Identifiable {
    var id = UUID()     // ユニークなIDを自動で設定
    var name : String
}


 
class DeepViewModel : NSObject, ObservableObject, CLLocationManagerDelegate {
    
    internal var audioPlayer: AVAudioPlayer!
    internal var datasound: AVAudioPlayer!
    internal var kamehameha_sound: AVAudioPlayer!
    internal var nature_sound: AVAudioPlayer!
    internal var memo_sound: AVAudioPlayer!
    private var audioRecorder: AVAudioRecorder!
    let motionManager = CMMotionManager()
    let locationManager = CLLocationManager()
        
    @Published var activity_name:[String : Double] = ["label":0.0]
    @Published var label:String = "Standing"
    @Published var filename:String = ""
    @Published var select_filename:String = ""
    @Published var select_state:Bool = false
    @Published var select_latitude : Double = 0.0
    @Published var select_longitude: Double = 0.0
    @Published var select_label:String = ""
    
    
    @Published var latitude : Double = 0.0
    @Published var longitude: Double = 0.0
    
    @Published var region = MKCoordinateRegion(center: .init(latitude: 0.0, longitude: 0.0), latitudinalMeters: 200, longitudinalMeters: 200)
    
    @Published var sound_lists = [
        Sound_List(name: "")
    ]
    
    @Published var file_names:[String] = []
    
    
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
        self.delete_all_files()
        self.setup_locationmanager()
        self.setup_passfile()
    }
    
    
    func setup_passfile(){
        let filenames:[String] = FileManager.default.subpaths(atPath: NSHomeDirectory() + "/Documents/CSV/")!
        for filename in filenames{
            self.sound_lists.append(Sound_List(name: String(filename.split(separator: ".")[0])))
        }
    }
    
    func set_filename(){
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy_MM_dd_HH_mm_ss"
        let now = Date()
        self.filename = formatter.string(from: now)
    }

    func get_audio_filename(file_name:String) -> URL {
        let docspath = URL(string: NSHomeDirectory() + "/Documents/Audio/")!
        let music_path: String = file_name + ".m4a"
        let audiopath = docspath.appendingPathComponent(music_path)
        
        return audiopath
    }
    
    internal func play(file_name:String) {
        let music_path = URL(string: NSHomeDirectory() + "/Documents/Audio/" + file_name + ".m4a")!
        
        do{
            datasound = try AVAudioPlayer(contentsOf: music_path)
            datasound.volume = 1.0
            datasound.play()
        }catch{
            print("fail")
        }
    }
    
    func delete_file(filename:String){
        do{
            try FileManager.default.removeItem(atPath: NSHomeDirectory() + "/Documents/CSV/" + filename + ".csv")
            try FileManager.default.removeItem(atPath: NSHomeDirectory() + "/Documents/Audio/" + filename + ".m4a")
        }catch{
            print("error")
        }
    }
    
    func setup_locationmanager() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.activityType    = .fitness
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.delegate        = self
        //        locationManager.distanceFilter = 5
    }
    
    func locationManager(_ manager: CLLocationManager,didUpdateLocations locations: [CLLocation]){
        self.latitude  = locations.last!.coordinate.latitude
        self.longitude = locations.last!.coordinate.longitude
    }
    
    func set_select_location(){
        do {
            try self.select_latitude  = Double(String(contentsOfFile: NSHomeDirectory() + "/Documents/CSV/" + self.select_filename + ".csv").split(separator: ",")[0])!
            try self.select_longitude = Double(String(contentsOfFile: NSHomeDirectory() + "/Documents/CSV/" + self.select_filename + ".csv").split(separator: ",")[1])!
        }catch{
            print("Fail!")
        }
    }
    
    func get_icon(filename:String) ->String{
        do {

            let label = try String(String(contentsOfFile: NSHomeDirectory() + "/Documents/CSV/" + filename + ".csv").split(separator: ",")[2])
            return label
        }catch{
//            print("Fail !!!")
            return "fail"
        }
    }
    
    func delete_all_files(){
        let csvpath = NSHomeDirectory() + "/Documents/CSV"
        let csvnames = try! FileManager.default.contentsOfDirectory(atPath: csvpath)

        for fileName in csvnames {
            let filePathName = "\(csvpath)/\(fileName)"
            try! FileManager.default.removeItem(atPath: filePathName)
        }

        let audiopath = NSHomeDirectory() + "/Documents/Audio"
        let audionames = try! FileManager.default.contentsOfDirectory(atPath: audiopath)

        for fileName in audionames {
            let filePathName = "\(audiopath)/\(fileName)"
            try! FileManager.default.removeItem(atPath: filePathName)
        }
        
        let csv_directory   = NSHomeDirectory() + "/Documents/CSV"
        let audio_directory = NSHomeDirectory() + "/Documents/Audio"
        try! FileManager.default.createDirectory(atPath:   csv_directory, withIntermediateDirectories: true, attributes: nil)
        try! FileManager.default.createDirectory(atPath: audio_directory, withIntermediateDirectories: true, attributes: nil)
    }
    

    func record_start(){
        
        locationManager.startUpdatingLocation()
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
            
//            if self.passlabel[0] == "start_listen" && self.passlabel[1] == "start_listen" && self.passlabel[2] == "start_listen" && self.passlabel[3] == "start_listen" && self.passlabel[4] == "start_listen" && self.nature_state == false && self.memo_state == false{
//
//                self.n_sound()
//                self.set_filename()
//
//                let session = AVAudioSession.sharedInstance()
//                try! session.setCategory(AVAudioSession.Category.playAndRecord)
//                try! session.setActive(true)
//
//                self.audioRecorder = try! AVAudioRecorder(url: self.get_audio_filename(file_name: self.filename), settings: self.settings)
//                self.audioRecorder.record()
//
//                self.nature_state = true
//
//            }else if self.passlabel[0] == "start_memo" && self.passlabel[1] == "start_memo" && self.passlabel[2] == "start_memo" && self.passlabel[3] == "start_memo" && self.passlabel[4] == "start_memo" && self.nature_state == false && self.memo_state == false{
//
//                self.m_sound()
//                self.set_filename()
//
//                let session = AVAudioSession.sharedInstance()
//                try! session.setCategory(AVAudioSession.Category.playAndRecord)
//                try! session.setActive(true)
//
//                self.audioRecorder = try! AVAudioRecorder(url: self.get_audio_filename(file_name: self.filename), settings: self.settings)
//                self.audioRecorder.record()
//
//                self.memo_state = true
//
//            }else if (self.passlabel[0] == "end_listen" || self.passlabel[0] == "end_memo") && (self.passlabel[1] == "end_listen" || self.passlabel[1] == "end_memo") && (self.passlabel[2] == "end_listen" || self.passlabel[2] == "end_memo") && (self.passlabel[3] == "end_listen" || self.passlabel[3] == "end_memo") && (self.passlabel[4] == "end_listen" || self.passlabel[4] == "end_memo") && self.nature_state == true{
//
//                self.audioRecorder.stop()
//                self.sound_lists.append(Sound_List(name: self.filename))
//                self.save_file(label:"nature")
//                self.n_sound()
//                self.nature_state = false
//
//            }else if (self.passlabel[0] == "end_listen" || self.passlabel[0] == "end_memo") && (self.passlabel[1] == "end_listen" || self.passlabel[1] == "end_memo") && (self.passlabel[2] == "end_listen" || self.passlabel[2] == "end_memo") && (self.passlabel[3] == "end_listen" || self.passlabel[3] == "end_memo") && (self.passlabel[4] == "end_listen" || self.passlabel[4] == "end_memo") && self.memo_state == true{
//
//                self.audioRecorder.stop()
//                self.sound_lists.append(Sound_List(name: self.filename))
//                self.save_file(label:"memo")
//                self.m_sound()
//                self.memo_state = false
//
//            }else if self.passlabel[0] == "kamehameha" && self.passlabel[1] == "kamehameha" && self.passlabel[2] == "kamehameha" && self.passlabel[3] == "kamehameha" && self.passlabel[4] == "kamehameha" && self.nature_state == false && self.memo_state == false{
//
//                self.kame_sound()
//            }
        })
    }
    
    func record_end(){
        motionManager.stopDeviceMotionUpdates()
        locationManager.stopUpdatingLocation()
        if self.nature_state == true{
            
            self.sound_lists.append(Sound_List(name: self.filename))
            self.save_file(label:"nature")
            self.n_sound()
            self.nature_state = false
            
        }else if self.memo_state == true{
            
            self.audioRecorder.stop()
            self.sound_lists.append(Sound_List(name: self.filename))
            self.save_file(label:"memo")
            self.m_sound()
            self.memo_state = false
            
        }
    }
    
    func save_file(label:String){
        let filePath = NSHomeDirectory() + "/Documents/CSV/" + self.filename + ".csv"
        let recortText = "\(self.latitude),\(self.longitude),\(label)"
        try! recortText.write(toFile: filePath, atomically: true, encoding: String.Encoding.utf8)
        print(recortText)
    }
    
    func pon_sound(){
        guard let audioPath = Bundle.main.path(forResource: "pon", ofType:"mp3") else{
            return print("error")
        }
        let path = URL(fileURLWithPath: audioPath)
        audioPlayer = try! AVAudioPlayer(contentsOf: path)
        audioPlayer.volume = 1.0
        audioPlayer.play()
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

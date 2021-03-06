//
//  ViewController.swift
//  Audio_Mission
//
//  Created by hyeonsik on 2022/05/09.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVAudioPlayerDelegate, AVAudioRecorderDelegate {
    
    var audioPlayer : AVAudioPlayer! // AVAudioPlayer 인스턴스 변수
    var audioFile : URL! // 재생할 오디오의 파일명 변수
    let MAX_VOLUME : Float = 10.0
    var progressTimer : Timer! // 타이머를 위한 변수
    let timePlayerSelector : Selector = #selector(ViewController.updatePlayTime)
    let timeRecordSelector : Selector = #selector(ViewController.updateRecordTime)
    
    @IBOutlet var pvProgressPlay: UIProgressView!
    @IBOutlet var lbCurrentTime: UILabel!
    @IBOutlet var lbEndTime: UILabel!
    
    @IBOutlet var btnPlay: UIButton!
    @IBOutlet var btnPause: UIButton!
    @IBOutlet var btnStop: UIButton!
    
    @IBOutlet var slVilume: UISlider!
    
    @IBOutlet var btnRecord: UIButton!
    @IBOutlet var lbRecordTime: UILabel!
    
    var audioRecorder : AVAudioRecorder! // 인스턴스 추가
    var isRecordMode = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        selectAndioFile()
        if !isRecordMode {
            initPlay()
            btnRecord.isEnabled = false
            lbRecordTime.isEnabled = false
        }
        else {
            initRecord()
        }
    }
    
    func selectAndioFile() {
        // 녹음 했는데 재생 파일에 겹쳐서 저장되면 안 되기 때문에
        if !isRecordMode {
            // 재생 모드일 때는 오피오 파일 재생
            audioFile = Bundle.main.url(forResource: "Sicilian_Breeze", withExtension: "mp3") // 추가한 오디오 설정
        }
        else {
            let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            audioFile = documentDirectory.appendingPathComponent("recordFile.m4a")
        }
    }
    
    func initRecord() {
        let recordSettings = [
            AVFormatIDKey : NSNumber(value: kAudioFormatAppleLossless as UInt32),
            AVEncoderAudioQualityKey : AVAudioQuality.max.rawValue,
            AVEncoderBitRateKey : 320000,
            AVNumberOfChannelsKey : 2,
            AVSampleRateKey : 44100.0] as [String : Any]
        do {
            audioRecorder = try AVAudioRecorder(url: audioFile, settings: recordSettings)
        } catch let error as NSError {
            print("Reeoe-initRecord : \(error)")
        }
        
        audioRecorder.delegate = self
        
        // 초기화 하는 부분
        slVilume.value = 1.0
        audioPlayer.volume = slVilume.value
        lbEndTime.text = convertNSTimeInterval2String(0)
        lbCurrentTime.text = convertNSTimeInterval2String(0)
        setPlayButtons(false, pause: false, stop: false)
        
        let session = AVAudioSession.sharedInstance()
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let error as NSError {
            print(" Error-setCategory : \(error)")
        }
        do {
            try session.setActive(true)
        } catch let error as NSError {
            print(" Error-setActive : \(error)")
        }
    }
    
    func initPlay() {
        //오디오 재생을 초기화
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioFile)
        } catch let error as NSError {
            print("Error-initPlay : \(error)")
        }
        
        slVilume.maximumValue = MAX_VOLUME
        slVilume.value = 1.0
        pvProgressPlay.progress = 0
        
        audioPlayer.delegate = self
        audioPlayer.prepareToPlay() // 실행
        audioPlayer.volume = slVilume.value
        
        lbEndTime.text = convertNSTimeInterval2String(audioPlayer.duration)
        lbCurrentTime.text = convertNSTimeInterval2String(0)
        
        setPlayButtons(true, pause: false, stop: false)
    }
    
    func setPlayButtons(_ play:Bool, pause:Bool, stop:Bool) {
        btnPlay.isEnabled = play
        btnPause.isEnabled = pause
        btnStop.isEnabled = stop
        
    }
    
    func convertNSTimeInterval2String(_ time: TimeInterval) -> String {
        //00:00 형태로 바꾸기 위해 값을 받아서 문자열로 리턴
        let min = Int(time/60)
        let sec = Int(time.truncatingRemainder(dividingBy: 60)) // time을 60으로 나눈 나머지 값을 정수로 전환
        let strTime = String(format: "%02d:%02d", min, sec)
        return strTime
        
    }

    @IBAction func btnAudioPlay(_ sender: UIButton) {
        audioPlayer.play()
        setPlayButtons(false, pause: true, stop: true)
        
        //Timer.scheduledTimer() 를 통해서 0.1초 간격으로 타이머를 생성
        progressTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: timePlayerSelector, userInfo: nil, repeats: true)
    }
    
    @objc func updatePlayTime() {
        //재생시간을 나타냄
        lbCurrentTime.text = convertNSTimeInterval2String(audioPlayer.currentTime)
        // 프로그래스 뷰의 진행 상황을 표시
        pvProgressPlay.progress = Float(audioPlayer.currentTime/audioPlayer.duration)
    }
    
    @IBAction func btnAudioPause(_ sender: UIButton) {
        audioPlayer.pause()
        setPlayButtons(true, pause: false, stop: true)
    }
    @IBAction func btnAudioStop(_ sender: UIButton) {
        audioPlayer.stop()
        audioPlayer.currentTime = 0
        lbCurrentTime.text = convertNSTimeInterval2String(0)
        setPlayButtons(true, pause: false, stop: false)
        progressTimer.invalidate() // 타이머를 무효화
    }
    
    @IBAction func slChangeVolume(_ sender: UISlider) {
        audioPlayer.volume = slVilume.value
    }
    
    func audioPlaterDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        // 재생이 끝나면 맨 처음 상태로 돌아가는 함수
        progressTimer.invalidate()
        setPlayButtons(true, pause: false, stop: false)
        
    }

    @IBAction func swRecordMode(_ sender: UISwitch) {
        if sender.isOn {
            audioPlayer.stop()
            audioPlayer.currentTime = 0
            lbRecordTime!.text = convertNSTimeInterval2String(0)
            isRecordMode = true
            btnRecord.isEnabled = true
            lbRecordTime.isEnabled = true
        }
        else {
            isRecordMode = false
            btnRecord.isEnabled = false
            lbRecordTime.isEnabled = false
            lbRecordTime.text = convertNSTimeInterval2String(0)
        }
        selectAndioFile()
        if !isRecordMode {
            initPlay()
        }
        else {
            initRecord()
        }
    }
    
    
    @IBAction func btnRecord(_ sender: UIButton) {
        if (sender as AnyObject).titleLabel?.text == "Record" {
            audioRecorder.record()
            (sender as AnyObject).setTitle("Stop", for: UIControl.State())
            progressTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: timeRecordSelector, userInfo: nil, repeats: true)
        } else {
            audioRecorder.stop()
            progressTimer.invalidate()
            (sender as AnyObject).setTitle("Record", for: UIControl.State())
            btnRecord.isEnabled = true
            initPlay()
        }
    }
    
    @objc func updateRecordTime() {
        lbRecordTime.text = convertNSTimeInterval2String(audioRecorder.currentTime)
    }
}


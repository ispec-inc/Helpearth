//
//  ViewController.swift
//  Helpearth
//
//  Created by 中嶋裕也 on 2021/11/30.
//

import UIKit
import CoreNFC
import RxSwift
import RxCocoa
import RxGesture

class ViewController: UIViewController {
    
    let disposedBag = DisposeBag()
    @IBOutlet weak var writeBtn: UIButton!
    @IBOutlet weak var label: UILabel!

    var session: NFCNDEFReaderSession?
    var message: NFCNDEFMessage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setLayout()
        bind()
    }
    
    func setLayout() {
        writeBtn.layer.cornerRadius = 10
        writeBtn.titleLabel?.font = UIFont(name: "NotoSansJP-Regular", size: 12)
    }
    
    func bind() {
        
    }
    
    @IBAction func write(_ sender: Any) {
        startSession()
    }
    
    func startSession() {
        guard NFCNDEFReaderSession.readingAvailable else { return }
        session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        session?.alertMessage = "NFCタグをiPhone上部に近づけてください．"
        session?.begin()
    }
    
    func stopSession(alert: String = "", error: String = "") {
        session?.alertMessage = alert
        if error.isEmpty {
            session?.invalidate()
        } else {
            session?.invalidate(errorMessage: error)
        }
    }
    
    func tagRemovalDetect(_ tag: NFCNDEFTag) {
        session?.connect(to: tag) { (error: Error?) in
            if error != nil || !tag.isAvailable {
                self.session?.restartPolling()
                return
            }
            DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + .milliseconds(500), execute: {
                self.tagRemovalDetect(tag)
            })
        }
    }
    
}

extension ViewController: NFCNDEFReaderSessionDelegate {
    
    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        Swift.print(error.localizedDescription)
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        if tags.count > 1 {
            session.alertMessage = "読み込ませるNFCタグは1枚にしてください。"
            tagRemovalDetect(tags.first!)
            return
        }
        let tag = tags.first!
        session.connect(to: tag) { (error) in
            if error != nil {
                session.restartPolling()
                return
            }
        }
        
        tag.queryNDEFStatus { (status, capacity, error) in
            if status == .notSupported || status == .readOnly {
                self.stopSession(error: "このNFCタグは読み取れません")
                return
            }
            let urlPayload = NFCNDEFPayload.wellKnownTypeURIPayload(string: URLBuilder.getURL())!
            self.message = NFCNDEFMessage(records: [urlPayload])
            if self.message!.length > capacity {
                self.stopSession(error: "このNFCタグは読み取れません")
                return
            }
            tag.writeNDEF(self.message!) { (error) in
                if error != nil {
                    self.stopSession(error: error!.localizedDescription)
                } else {
                    self.stopSession(alert: "書き込み成功")
                }
            }
        }
    }

}

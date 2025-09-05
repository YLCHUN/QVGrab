//
//  TouchMonitor.swift
//  TouchMonitor
//
//  Created by Cityu on 2025/8/25.
//

import UIKit
import ObjectiveC

public protocol TouchMonitorDelegate {
    func touchesBegan(_ monitor: TouchMonitor, touches: Set<UITouch>, with event: UIEvent?)
    func touchesMoved(_ monitor: TouchMonitor, touches: Set<UITouch>, with event: UIEvent?)
    func touchesEnded(_ monitor: TouchMonitor, touches: Set<UITouch>, with event: UIEvent?)
    func touchesCancelled(_ monitor: TouchMonitor, touches: Set<UITouch>, with event: UIEvent?)
}
public extension TouchMonitorDelegate {
    func touchesBegan(_ monitor: TouchMonitor, touches: Set<UITouch>, with event: UIEvent?) { }
    func touchesMoved(_ monitor: TouchMonitor, touches: Set<UITouch>, with event: UIEvent?)  { }
    func touchesEnded(_ monitor: TouchMonitor, touches: Set<UITouch>, with event: UIEvent?)  { }
    func touchesCancelled(_ monitor: TouchMonitor, touches: Set<UITouch>, with event: UIEvent?)  { }
}

fileprivate protocol TouchMonitorGestureRecognizerDelegate:AnyObject  {
    func touchesBegan(_ tmgr: TouchMonitorGestureRecognizer, touches: Set<UITouch>, with event: UIEvent?)
    func touchesMoved(_ tmgr: TouchMonitorGestureRecognizer, touches: Set<UITouch>, with event: UIEvent?)
    func touchesEnded(_ tmgr: TouchMonitorGestureRecognizer, touches: Set<UITouch>, with event: UIEvent?)
    func touchesCancelled(_ tmgr: TouchMonitorGestureRecognizer, touches: Set<UITouch>, with event: UIEvent?)
}



fileprivate class TouchMonitorGestureRecognizer : UIGestureRecognizer, UIGestureRecognizerDelegate {
    weak var touchDelegate: (any TouchMonitorGestureRecognizerDelegate)?
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return true
    }

    func gestureRecognized() {
        self.state = .cancelled;
        self.reset()
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        self.touchDelegate?.touchesBegan(self, touches: touches, with: event)
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        self.touchDelegate?.touchesMoved(self, touches: touches, with: event)
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        self.gestureRecognized()
        self.touchDelegate?.touchesEnded(self, touches: touches, with: event)
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesCancelled(touches, with: event)
        self.gestureRecognized()
        self.touchDelegate?.touchesCancelled(self, touches: touches, with: event)
    }
}

final public class TouchMonitor : TouchMonitorGestureRecognizerDelegate {
    private lazy var mgr:TouchMonitorGestureRecognizer = {
        let mgr = TouchMonitorGestureRecognizer()
        mgr.delegate = mgr
        mgr.touchDelegate = self
        mgr.cancelsTouchesInView = false
        mgr.delaysTouchesBegan = false
        mgr.delaysTouchesEnded = false
        return mgr
    }()
    public init() {
        
    }
    public var view:UIView? {
        willSet {
            self.view?.removeGestureRecognizer(self.mgr)
        }
        didSet {
            self.view?.addGestureRecognizer(self.mgr)
        }
    }
    public var delegate:TouchMonitorDelegate?
    public var enabled:Bool {
        get {
            self.mgr.isEnabled
        }
        set {
            self.mgr.isEnabled = newValue
        }
    }
    
    fileprivate func touchesBegan(_ tmgr: TouchMonitorGestureRecognizer, touches: Set<UITouch>, with event: UIEvent?) {
        self.delegate?.touchesBegan(self, touches: touches, with: event)
    }
    fileprivate func touchesMoved(_ tmgr: TouchMonitorGestureRecognizer, touches: Set<UITouch>, with event: UIEvent?) {
        self.delegate?.touchesMoved(self, touches: touches, with: event)
    }
    fileprivate func touchesEnded(_ tmgr: TouchMonitorGestureRecognizer, touches: Set<UITouch>, with event: UIEvent?) {
        self.delegate?.touchesEnded(self, touches: touches, with: event)
    }
    fileprivate func touchesCancelled(_ tmgr: TouchMonitorGestureRecognizer, touches: Set<UITouch>, with event: UIEvent?) {
        self.delegate?.touchesCancelled(self, touches: touches, with: event)
    }
}

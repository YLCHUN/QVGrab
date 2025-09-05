//
//  PlayerViewController.swift
//  QVGrab
//
//  Created by Cityu on 2025/4/5.
//

import UIKit
import AVKit
import AVFoundation
import MediaPlayer
import KVOController
import SnapKit

/**
 * 视频播放器视图控制器
 * 继承自AVPlayerViewController，提供视频播放功能
 * 支持播放进度的保存和恢复
 */
class PlayerViewController: AVPlayerViewController {
    
    /// 视频URL地址
    var videoURL: URL? {
        didSet {
            if videoURL != oldValue {
                _videoId = nil // 清空缓存的视频ID
            }
        }
    }
    
    /// 时间观察者，用于监听播放进度
    private var timeObserver: Any?
    
    /// 是否正在播放
    private var isPlaying: Bool = false
    
    /// 进度管理器
    private var progressDBM: PProgressDBM?
    
    /// 播放完成观察者
    private var playbackFinishedObserver: NSObjectProtocol?
    
    /// 播放错误观察者
    private var playbackErrorObserver: NSObjectProtocol?
    
    /// KVO控制器
    private var coreKvo: FBKVOController?
    private var _videoId: String?
    
    /// 是否允许自动旋转（根据视频宽高比决定）
    private var allowAutoRotation: Bool = false
    /// 视频宽高比
    private var videoAspectRatio: CGFloat = 0
    
    /// 手势相关属性
    private var panGestureRecognizer: UIPanGestureRecognizer?
    private var initialBrightness: CGFloat = 0
    private var initialVolume: CGFloat = 0
    private var initialPlaybackTime: TimeInterval = 0
    private var volumeSliderView: UIView?
    private var brightnessSliderView: UIView?
    private var progressSliderView: UIView?
    private var volumeLabel: UILabel?
    private var brightnessLabel: UILabel?
    private var progressLabel: UILabel?
    /// 音量控制相关
    private var volumeView: MPVolumeView?
    private var volumeSlider: UISlider?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupKVOController()
        setupProgressDBM()
        setupPlayer()
        setupOrientationNotification()
        setupGestureRecognizers()
        setupVolumeSliderView()
        setupBrightnessSliderView()
        setupProgressSliderView()
        delegate = self // 设置代理
    }
    
    private func setupOrientationNotification() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(orientationDidChange(_:)),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }
    
    @objc private func orientationDidChange(_ notification: Notification) {
        guard allowAutoRotation else { return }
        
        let deviceOrientation = UIDevice.current.orientation
        let interfaceOrientation = UIInterfaceOrientation(rawValue: deviceOrientation.rawValue)!
        
        if deviceOrientation.isValidInterfaceOrientation {
            if deviceOrientation.isLandscape {
                // 如果视频宽高比大于1，则自动横屏
                if videoAspectRatio > 1.0 {
                    setNeedsStatusBarAppearanceUpdate()
                    UIDevice.current.setValue(interfaceOrientation.rawValue, forKey: "orientation")
                }
            } else if deviceOrientation == .portrait {
                // 竖屏时恢复正常方向
                setNeedsStatusBarAppearanceUpdate()
                UIDevice.current.setValue(interfaceOrientation.rawValue, forKey: "orientation")
            }
        }
    }
    
    override var shouldAutorotate: Bool {
        return allowAutoRotation
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if !allowAutoRotation {
            return .portrait
        }
        return .allButUpsideDown
    }
    
    private func setupKVOController() {
        coreKvo = FBKVOController(observer: self)
    }
    
    private func setupProgressDBM() {
        progressDBM = PProgressDBM.dbm(withTable: "video_progress")
    }
    
    // MARK: - 手势相关方法
    
    /**
     * 设置手势识别器
     */
    private func setupGestureRecognizers() {
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        view.addGestureRecognizer(panGestureRecognizer!)
    }
    
    /**
     * 设置音量调节视图
     */
    private func setupVolumeSliderView() {
        volumeSliderView = UIView()
        volumeSliderView?.backgroundColor = UIColor(white: 0, alpha: 0.8)
        volumeSliderView?.layer.cornerRadius = 10
        volumeSliderView?.isHidden = true
        view.addSubview(volumeSliderView!)
        
        // 音量标签
        volumeLabel = UILabel()
        volumeLabel?.textColor = UIColor.white
        volumeLabel?.font = UIFont.systemFont(ofSize: 14)
        volumeLabel?.textAlignment = .center
        volumeSliderView?.addSubview(volumeLabel!)
        
        // 设置约束
        volumeSliderView?.snp.makeConstraints { make in
            make.center.equalTo(view)
            make.width.equalTo(120)
            make.height.equalTo(80)
        }
        
        volumeLabel?.snp.makeConstraints { make in
            make.center.equalTo(volumeSliderView!)
            make.left.right.equalTo(volumeSliderView!)
        }
        
        // 初始化音量控制
        setupVolumeControl()
    }
    
    /**
     * 检查是否处于横屏状态
     */
    private func isLandscape() -> Bool {
        return UIApplication.shared.statusBarOrientation.isLandscape
    }
    
    /**
     * 设置音量控制
     */
    private func setupVolumeControl() {
        // 创建MPVolumeView并隐藏它（我们只需要它的slider）
        volumeView = MPVolumeView()
        volumeView?.isHidden = true
        view.addSubview(volumeView!)
        
        // 设置约束确保MPVolumeView在正确位置
        volumeView?.snp.makeConstraints { make in
            make.center.equalTo(view)
            make.width.height.equalTo(1) // 最小尺寸
        }
        
        // 延迟查找音量滑块，确保MPVolumeView完全加载
        DispatchQueue.main.async {
            self.findVolumeSlider()
        }
    }
    
    /**
     * 查找音量滑块
     */
    private func findVolumeSlider() {
        // 查找音量滑块
        for view in volumeView!.subviews {
            if let slider = view as? UISlider {
                volumeSlider = slider
                break
            }
        }
        
        // 如果找到了滑块，设置其样式
        if let slider = volumeSlider {
            slider.minimumValue = 0.0
            slider.maximumValue = 1.0
            print("音量滑块初始化成功，当前值: \(slider.value)")
        } else {
            print("警告：未能找到音量滑块，尝试延迟查找")
            // 如果第一次没找到，再试一次
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.findVolumeSlider()
            }
        }
    }
    
    /**
     * 设置亮度调节视图
     */
    private func setupBrightnessSliderView() {
        brightnessSliderView = UIView()
        brightnessSliderView?.backgroundColor = UIColor(white: 0, alpha: 0.8)
        brightnessSliderView?.layer.cornerRadius = 10
        brightnessSliderView?.isHidden = true
        view.addSubview(brightnessSliderView!)
        
        // 亮度标签
        brightnessLabel = UILabel()
        brightnessLabel?.textColor = UIColor.white
        brightnessLabel?.font = UIFont.systemFont(ofSize: 14)
        brightnessLabel?.textAlignment = .center
        brightnessSliderView?.addSubview(brightnessLabel!)
        
        // 设置约束
        brightnessSliderView?.snp.makeConstraints { make in
            make.center.equalTo(view)
            make.width.equalTo(120)
            make.height.equalTo(80)
        }
        
        brightnessLabel?.snp.makeConstraints { make in
            make.center.equalTo(brightnessSliderView!)
            make.left.right.equalTo(brightnessSliderView!)
        }
    }
    
    /**
     * 设置播放进度调节视图
     */
    private func setupProgressSliderView() {
        progressSliderView = UIView()
        progressSliderView?.backgroundColor = UIColor(white: 0, alpha: 0.8)
        progressSliderView?.layer.cornerRadius = 10
        progressSliderView?.isHidden = true
        view.addSubview(progressSliderView!)
        
        // 进度标签
        progressLabel = UILabel()
        progressLabel?.textColor = UIColor.white
        progressLabel?.font = UIFont.systemFont(ofSize: 14)
        progressLabel?.textAlignment = .center
        progressSliderView?.addSubview(progressLabel!)
        
        // 设置约束
        progressSliderView?.snp.makeConstraints { make in
            make.center.equalTo(view)
            make.width.equalTo(150)
            make.height.equalTo(80)
        }
        
        progressLabel?.snp.makeConstraints { make in
            make.center.equalTo(progressSliderView!)
            make.left.right.equalTo(progressSliderView!)
        }
    }
    
    /**
     * 处理滑动手势
     */
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        // 只在横屏时启用手势
        guard isLandscape() else { return }
        
        // 检查手势是否在有效区域内（避免与播放器控制栏冲突）
        let location = gesture.location(in: view)
        let translation = gesture.translation(in: view)
        
        // 如果手势在底部区域（播放器控制栏区域），则不处理
        let screenHeight = view.bounds.size.height
        if location.y > screenHeight * 0.8 {
            return
        }
        
        switch gesture.state {
        case .began:
            // 记录初始值
            initialBrightness = UIScreen.main.brightness
            initialVolume = getSystemVolume()
            initialPlaybackTime = CMTimeGetSeconds(player?.currentTime() ?? CMTime.zero)
            
            // 在手势开始时，先隐藏所有调节视图，等待方向判断
            volumeSliderView?.isHidden = true
            brightnessSliderView?.isHidden = true
            progressSliderView?.isHidden = true
            
        case .changed:
            // 判断手势方向
            let horizontalDistance = abs(translation.x)
            let verticalDistance = abs(translation.y)
            
            // 需要一定的移动距离才判断方向，避免误触
            if horizontalDistance < 10 && verticalDistance < 10 {
                return
            }
            
            if horizontalDistance > verticalDistance {
                // 水平滑动 - 调节播放进度
                if progressSliderView?.isHidden == true {
                    progressSliderView?.isHidden = false
                    updateProgressLabel(initialPlaybackTime)
                }
                
                let screenWidth = view.bounds.size.width
                let progress = translation.x / screenWidth // 向右滑动前进，向左滑动后退
                
                let duration = CMTimeGetSeconds(player?.currentItem?.duration ?? CMTime.zero)
                let newTime = max(0.0, min(duration, initialPlaybackTime + (progress * duration)))
                
                // 实时更新播放位置
                let seekTime = CMTimeMakeWithSeconds(newTime, preferredTimescale: 1)
                player?.seek(to: seekTime, toleranceBefore: .zero, toleranceAfter: .zero)
                updateProgressLabel(newTime)
            } else {
                // 垂直滑动 - 调节音量和亮度
                let screenHeight = view.bounds.size.height
                let progress = -translation.y / screenHeight // 向上滑动增加，向下滑动减少
                
                let screenWidth = view.bounds.size.width
                if location.x < screenWidth / 2 {
                    // 左侧 - 调节亮度
                    if brightnessSliderView?.isHidden == true {
                        brightnessSliderView?.isHidden = false
                        updateBrightnessLabel(initialBrightness)
                    }
                    let newBrightness = max(0.0, min(1.0, initialBrightness + progress))
                    UIScreen.main.brightness = newBrightness
                    updateBrightnessLabel(newBrightness)
                } else {
                    // 右侧 - 调节音量
                    if volumeSliderView?.isHidden == true {
                        volumeSliderView?.isHidden = false
                        updateVolumeLabel(initialVolume)
                    }
                    let newVolume = max(0.0, min(1.0, initialVolume + progress))
                    setSystemVolume(newVolume)
                    updateVolumeLabel(newVolume)
                }
            }
            
        case .ended, .cancelled:
            // 隐藏调节视图
            UIView.animate(withDuration: 0.3, animations: {
                self.volumeSliderView?.alpha = 0
                self.brightnessSliderView?.alpha = 0
                self.progressSliderView?.alpha = 0
            }) { finished in
                self.volumeSliderView?.isHidden = true
                self.brightnessSliderView?.isHidden = true
                self.progressSliderView?.isHidden = true
                self.volumeSliderView?.alpha = 1
                self.brightnessSliderView?.alpha = 1
                self.progressSliderView?.alpha = 1
            }
            
        default:
            break
        }
    }
    
    /**
     * 更新音量标签
     */
    private func updateVolumeLabel(_ volume: CGFloat) {
        let volumePercent = Int(volume * 100)
        volumeLabel?.text = "音量: \(volumePercent)%"
    }
    
    /**
     * 更新亮度标签
     */
    private func updateBrightnessLabel(_ brightness: CGFloat) {
        let brightnessPercent = Int(brightness * 100)
        brightnessLabel?.text = "亮度: \(brightnessPercent)%"
    }
    
    /**
     * 更新播放进度标签
     */
    private func updateProgressLabel(_ currentTime: TimeInterval) {
        let duration = CMTimeGetSeconds(player?.currentItem?.duration ?? CMTime.zero)
        if duration > 0 {
            let currentMinutes = Int(currentTime) / 60
            let currentSeconds = Int(currentTime) % 60
            let totalMinutes = Int(duration) / 60
            let totalSeconds = Int(duration) % 60
            
            progressLabel?.text = String(format: "%02d:%02d / %02d:%02d", currentMinutes, currentSeconds, totalMinutes, totalSeconds)
        } else {
            progressLabel?.text = "00:00 / 00:00"
        }
    }
    
    /**
     * 获取系统音量
     */
    private func getSystemVolume() -> CGFloat {
        if let slider = volumeSlider {
            return CGFloat(slider.value)
        }
        // 备用方案：从音频会话获取
        let audioSession = AVAudioSession.sharedInstance()
        return CGFloat(audioSession.outputVolume)
    }
    
    /**
     * 设置系统音量
     */
    private func setSystemVolume(_ volume: CGFloat) {
        if let slider = volumeSlider {
            // 确保在主线程中设置音量
            DispatchQueue.main.async {
                let oldValue = slider.value
                slider.value = Float(volume)
                // 触发值变化事件
                slider.sendActions(for: .valueChanged)
                print("音量调节: \(oldValue) -> \(volume)")
            }
        } else {
            print("警告：音量滑块未初始化")
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        cleanupPlayer()
    }
    
    /**
     * 清理播放器资源
     * 移除时间观察者和停止播放
     */
    private func cleanupPlayer() {
        // 移除时间观察者
        if let timeObserver = timeObserver, let player = player {
            player.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        
        // 移除播放完成观察者
        if let observer = playbackFinishedObserver {
            NotificationCenter.default.removeObserver(observer)
            playbackFinishedObserver = nil
        }
        
        // 移除播放错误观察者
        if let observer = playbackErrorObserver {
            NotificationCenter.default.removeObserver(observer)
            playbackErrorObserver = nil
        }
        
        // 移除所有KVO观察
        coreKvo?.unobserveAll()
        
        // 停止播放
        player?.pause()
        player = nil
    }
    
    /**
     * 设置播放器
     * 创建播放器实例并配置相关属性
     */
    private func setupPlayer() {
        guard let videoURL = videoURL else { return }
        
        // 清理旧的播放器资源
        cleanupPlayer()
        
        // 设置音频会话
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback)
            try audioSession.setActive(true)
        } catch {
            print("Failed to set audio session: \(error.localizedDescription)")
        }
        
        // 创建播放项和播放器
        let playerItem = AVPlayerItem(url: videoURL)
        player = AVPlayer(playerItem: playerItem)
        
        // 获取视频宽高比
        if let videoTrack = playerItem.asset.tracks(withMediaType: .video).first {
            let naturalSize = videoTrack.naturalSize
            videoAspectRatio = naturalSize.width / naturalSize.height
            // 如果视频宽高比大于1，说明是横向视频，允许自动旋转
            allowAutoRotation = (videoAspectRatio > 1.0)
        }
        
        // 添加时间观察者，用于跟踪播放进度
        timeObserver = player?.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 1), queue: .main) { [weak self] time in
            self?.updateProgress()
        }
        
        // 使用KVOController观察播放器状态
        coreKvo?.observe(player, keyPath: "status", options: .new) { [weak self] observer, object, change in
            self?.handlePlayerStatusChange()
        }
        
        // 使用KVOController观察播放项状态
        coreKvo?.observe(playerItem, keyPath: "status", options: .new) { [weak self] observer, object, change in
            self?.handlePlayerItemStatusChange()
        }
        
        // 添加播放完成通知观察
        playbackFinishedObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] notification in
            self?.handlePlaybackFinished()
        }
        
        // 添加播放错误通知观察
        playbackErrorObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] notification in
            let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error
            self?.handlePlaybackError(error)
        }
    }
    
    /**
     * 处理播放器状态变化
     */
    private func handlePlayerStatusChange() {
        guard let player = player else { return }
        
        switch player.status {
        case .readyToPlay:
            // 播放器已准备好，具体播放控制由 handlePlayerItemStatusChange 处理
            break
        case .failed:
            handlePlaybackError(player.error)
            break
        case .unknown:
            print("Player status unknown")
            break
        @unknown default:
            break
        }
    }
    
    /**
     * 处理播放项状态变化
     */
    private func handlePlayerItemStatusChange() {
        guard let playerItem = player?.currentItem else { return }
        
        switch playerItem.status {
        case .readyToPlay:
            let savedProgress = getVideoProgress()
            if savedProgress > 0 {
                let seekTime = CMTimeMakeWithSeconds(savedProgress, preferredTimescale: 1)
                player?.seek(to: seekTime)
            }
            player?.play()
            isPlaying = true
            
        case .failed:
            handlePlaybackError(playerItem.error)
            
        case .unknown:
            print("Player item status unknown")
            
        @unknown default:
            break
        }
    }
    
    /**
     * 处理播放完成
     */
    private func handlePlaybackFinished() {
        isPlaying = false
        // 保存最终进度
        if let duration = player?.currentItem?.duration {
            saveVideoProgress(CMTimeGetSeconds(duration))
        }
        // 重置播放位置
        player?.seek(to: CMTime.zero)
        // 可以在这里添加播放完成后的UI更新或其他操作
    }
    
    /**
     * 处理播放错误
     */
    private func handlePlaybackError(_ error: Error?) {
        isPlaying = false
        if let error = error {
            print("Playback error: \(error.localizedDescription)")
        }
        // 可以在这里添加错误提示UI或其他错误处理逻辑
    }
    
    /**
     * 更新播放进度
     * 当视频正在播放时，每秒更新一次进度
     */
    private func updateProgress() {
        guard isPlaying else { return }
        
        if let currentTime = player?.currentTime {
            let currentSeconds = CMTimeGetSeconds(currentTime())
            saveVideoProgress(currentSeconds)
        }
    }
    
    // MARK: - 视频进度相关方法
    
    /**
     * 获取视频唯一标识符
     * 对于本地文件：使用文件路径获取文件唯一标识符
     * 对于网络URL：去掉域名部分（包括http://或https://），对剩余部分进行哈希
     */
    private var videoId: String {
        if _videoId == nil {
            _videoId = Self.videoId(videoURL!)
        }
        return _videoId!
    }
    
    static func videoId(_ videoURL: URL) -> String {
        // 检查是否是本地文件URL
        if videoURL.isFileURL {
            let filePath = videoURL.path
            if !filePath.isEmpty {
                // 获取文件属性
                var fileStat = stat()
                if stat(filePath, &fileStat) == 0 {
                    // 使用文件的 inode 和 device id 组合作为唯一标识符
                    let fileIdentifier = "\(fileStat.st_ino)_\(fileStat.st_dev)"
                    return fileIdentifier
                }
            }
        }
        
        // 对于网络URL，去掉域名部分
        let urlString = videoURL.absoluteString
        if let url = URL(string: urlString) {
            // 获取域名后的部分（包括路径、参数等）
            let pathAndQuery = String(urlString.dropFirst(url.host!.count + url.scheme!.count + 3)) // +3 for ://
            if !pathAndQuery.isEmpty {
                return String(pathAndQuery.hashValue)
            }
        }
        
        // 如果无法处理，则使用完整URL的哈希值
        return String(urlString.hashValue)
    }
    
    /**
     * 保存视频播放进度
     * @param progress 当前播放进度（秒）
     */
    private func saveVideoProgress(_ progress: TimeInterval) {
        let videoId = self.videoId
        if !videoId.isEmpty {
            // 获取视频总时长
            if let duration = player?.currentItem?.duration {
                let durationSeconds = CMTimeGetSeconds(duration)
                if durationSeconds > 0 {
                    // 将时间位置转换为百分比（0-1）
                    let progressPercentage = CGFloat(progress / durationSeconds)
                    progressDBM?.setProgress(progressPercentage, forKey: videoId)
                }
            }
        }
    }
    
    /**
     * 获取视频播放进度
     * @return 上次保存的播放进度（秒）
     */
    private func getVideoProgress() -> TimeInterval {
        let videoId = self.videoId
        if !videoId.isEmpty {
            // 获取保存的进度百分比
            let progressPercentage = progressDBM?.progress(forKey: videoId) ?? 0
            // 将百分比转换为时间位置
            if let duration = player?.currentItem?.duration {
                let durationSeconds = CMTimeGetSeconds(duration)
                return TimeInterval(progressPercentage) * durationSeconds
            }
        }
        return 0.0
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        cleanupPlayer()
        
        // 清理手势相关资源
        if let panGesture = panGestureRecognizer {
            view.removeGestureRecognizer(panGesture)
        }
        
        // 清理音量控制资源
        volumeView?.removeFromSuperview()
    }
}

// MARK: - AVPlayerViewControllerDelegate

extension PlayerViewController: AVPlayerViewControllerDelegate {
    
//    /**
//     * 当用户点击播放器控制栏上的"完成"按钮时调用
//     * 返回true允许播放器关闭，返回false阻止关闭
//     */
//    func playerViewControllerShouldDismiss(_ playerViewController: AVPlayerViewController) -> Bool {
//        // 保存当前进度
//        if let currentItem = player?.currentItem {
//            saveVideoProgress(CMTimeGetSeconds(player?.currentTime ?? CMTime.zero))
//        }
//        return true
//    }
//    
//    /**
//     * 当播放器即将关闭时调用
//     */
//    func playerViewControllerWillBeginDismissalTransition(_ playerViewController: AVPlayerViewController) {
//        // 保存当前进度
//        if let currentItem = player?.currentItem {
//            saveVideoProgress(CMTimeGetSeconds(player?.currentTime ?? CMTime.zero))
//        }
//    }
//    
//    /**
//     * 当播放器完成关闭动画时调用
//     */
//    func playerViewControllerDidEndDismissalTransition(_ playerViewController: AVPlayerViewController) {
//        // 清理资源
//        cleanupPlayer()
//    }
    
    /**
     * 当播放器即将开始全屏过渡时调用
     */
    func playerViewControllerWillBeginFullScreenTransition(_ playerViewController: AVPlayerViewController) {
        // 可以在这里处理进入全屏前的逻辑
    }
    
    /**
     * 当播放器完成全屏过渡时调用
     */
    func playerViewControllerDidEndFullScreenTransition(_ playerViewController: AVPlayerViewController) {
        // 可以在这里处理进入全屏后的逻辑
    }
    
    /**
     * 当播放器即将退出全屏时调用
     */
    func playerViewControllerWillBeginExitFullScreenTransition(_ playerViewController: AVPlayerViewController) {
        // 可以在这里处理退出全屏前的逻辑
    }
    
    /**
     * 当播放器完成退出全屏时调用
     */
    func playerViewControllerDidEndExitFullScreenTransition(_ playerViewController: AVPlayerViewController) {
        // 可以在这里处理退出全屏后的逻辑
    }
}

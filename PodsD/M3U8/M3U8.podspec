Pod::Spec.new do |s|
    s.name             = 'M3U8'
    s.version          = '0.0.1'
    s.summary          = 'M3U8 Swift implementation with FFmpeg support.'
    
    s.description      = <<-DESC
    M3U8 Swift pod with FFmpeg integration for video processing and TS merging.
    DESC
    
    s.homepage         = 'http://gitlab.com/ylchun/M3U8'
    s.author           = { 'ylchun' => 'ylchun@gitlab.com' }
    
    s.ios.deployment_target = '12.0'
    s.static_framework = true
    s.swift_version = '5.0'

    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.source           = { :git => 'git@gitlab.com:ylchun/M3U8.git', :tag => s.version.to_s }
    s.source_files = 'Classes/**/*'
    
    s.vendored_frameworks = 'Frameworks/TSFdn.framework'
    
    # 如果需要链接系统框架，可以添加：
    # s.frameworks = 'Foundation', 'UIKit'
    
    # 如果需要链接系统库，可以添加：
    # s.libraries = 'c++', 'z'
    
end

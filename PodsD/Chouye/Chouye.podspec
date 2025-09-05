Pod::Spec.new do |s|
    s.name             = 'Chouye'
    s.version          = '0.0.1'
    s.summary          = 'A dynamic library for light/dark mode management.'
    s.description  = <<-DESC
                    详细描述：Chouye 是一个用于管理 iOS 明暗模式切换的动态库，支持自动适配系统主题。
                    DESC

    
    s.author           = { 'ylchun' => 'youlianchunios@163.com' }
    s.license      = { :type => "MIT", :file => "LICENSE" }

    s.homepage         = 'https://github.com/YLCHUN/Chouye'
    s.source           = { :git => "git@github.com:YLCHUN/Chouye.git", :tag => s.version.to_s }

    s.ios.deployment_target = '12.0'
    s.swift_version = '5.0'
    s.static_framework = true

    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.source           = { :git => 'git@gitlab.com:ylchun/Chouye.git', :tag => s.version.to_s }
    s.source_files = 'Sources/**/*.swift'


end

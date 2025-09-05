Pod::Spec.new do |s|
    s.name             = 'FileBrowse'
    s.version          = '0.0.1'
    s.summary          = 'FileBrowse.'
    
    s.description      = <<-DESC
    FileBrowse pod.
    DESC
    
    s.homepage         = 'http://gitlab.com/ylchun/FileBrowse'
    s.author           = { 'ylchun' => 'ylchun@gitlab.com' }
    
    s.ios.deployment_target = '12.0'
    s.static_framework = true
    s.swift_version = '5.0'

    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.source           = { :git => 'git@gitlab.com:ylchun/FileBrowse.git', :tag => s.version.to_s }
    s.source_files = 'Classes/**/*'
    s.resource_bundles = {
        'FileBrowse' => ['Assets/*']
    }
    
end

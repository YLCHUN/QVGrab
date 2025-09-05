Pod::Spec.new do |s|
    s.name             = 'JSScript'
    s.version          = '0.0.1'
    s.summary          = 'JSScript.'
    
    s.description      = <<-DESC
    WKScript pod.
    DESC
    
    s.homepage         = 'http://gitlab.com/ylchun/JSScript'
    s.author           = { 'ylchun' => 'ylchun@gitlab.com' }
    
    s.ios.deployment_target = '12.0'
    s.static_framework = true

    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.source           = { :git => 'git@gitlab.com:ylchun/JSScript.git', :tag => s.version.to_s }
    s.source_files = 'Classes/**/*'
    s.resource_bundles = {
        'JSScript' => ['Assets/*']
    }
end

Pod::Spec.new do |s|
    s.name             = 'LithUI'
    s.version          = '0.0.1'
    s.summary          = 'LithUI.'
    
    s.description      = <<-DESC
    LithUI pod.
    DESC
    
    s.homepage         = 'http://gitlab.com/ylchun/LithUI'
    s.author           = { 'ylchun' => 'ylchun@gitlab.com' }
    
    s.ios.deployment_target = '12.0'
    s.static_framework = true

    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.source           = { :git => 'git@gitlab.com:ylchun/LithUI.git', :tag => s.version.to_s }
    s.source_files = 'Classes/**/*.swift'
    s.resource_bundles = {
        'LithUI' => ['Assets/*']
    }
    
    #Category
    s.subspec 'Category' do |ss|
      ss.source_files = 'Classes/Category/**/*.swift'
      ss.dependency 'Chouye'
    end

    
    s.swift_version = '5.0'
    s.dependency 'Chouye'
end

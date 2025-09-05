Pod::Spec.new do |s|
  # 基础信息
  s.name         = "ffmpeg-ios"
  s.version      = "6.0"
  s.summary      = "FFmpeg iOS Shared Framework"
  s.description  = <<-DESC
    Includes FFmpeg with dav1d, fontconfig, freetype, fribidi, gmp, gnutls, 
    kvazaar, lame, libass, libilbc, libtheora, libvorbis, libvpx, libwebp, 
    zimg, libxml2, opencore-amr, opus, shine, snappy, soxr, speex, twolame 
    and vo-amrwbenc libraries enabled.
  DESC
  s.homepage     = "https://ffmpeg.org"
  s.license      = { :type => "LGPL-3.0", :file => "LICENSE" }
  s.author       = { "ARTHENICA" => "ffmpeg@ffmpeg.com" }
  
  # 平台与兼容性
  s.platform     = :ios, "12.0"
  s.requires_arc = true
  
  # 依赖库
  s.libraries    = "z", "bz2", "c++", "iconv"
  
  # 框架依赖
  s.framework    = "AudioToolbox", "AVFoundation", "CoreMedia", "VideoToolbox"
  
  # 资源与源文件
  s.source       = { :path => "xcframework" }
  
  # 嵌入的框架
  s.vendored_frameworks = "xcframework/libavcodec.xcframework", "xcframework/libavdevice.xcframework", "xcframework/libavfilter.xcframework", "xcframework/libavformat.xcframework", "xcframework/libavutil.xcframework", "xcframework/libswresample.xcframework", "xcframework/libswscale.xcframework"

  # 安装钩子
  s.prepare_command = <<-CMD
    if [ ! -d "#{s.source[:path]}" ]; then
      echo "错误: 未找到解压后的框架目录 '#{s.source[:path]}'"
      echo "解决方案: 从github上下载文件放到podspec所在目录下，地址: git@github.com:YLCHUN/ffmpeg-ios.git"
      exit 1
    fi
  CMD

end

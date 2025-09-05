#!/bin/bash

# 获取脚本自身目录，确保产物输出在脚本同级目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 需要先安装 ImageMagick: brew install imagemagick

# 创建图标目录
mkdir -p "$SCRIPT_DIR/FileIcons.xcassets"

# 定义马卡龙风格背景色和前景色
bg_colors_FileExtensionTypeUnknown="#F0F0F0"
bg_colors_FileExtensionTypeDirectory="#E0E0E0"
bg_colors_FileExtensionTypeImage="#FFD1DC"
bg_colors_FileExtensionTypeVideo="#B5EAD7"
bg_colors_FileExtensionTypeAudio="#C7CEEA"
bg_colors_FileExtensionTypePlainText="#FFE4E1"
bg_colors_FileExtensionTypeFormattedText="#FFB6C1"
bg_colors_FileExtensionTypeArchive="#D8BFD8"
bg_colors_FileExtensionTypeFont="#F0E68C"
bg_colors_FileExtensionTypePackage="#98FB98"
bg_colors_FileExtensionTypeDatabase="#87CEEB"
bg_colors_FileExtensionTypeExecutable="#FFA07A"
bg_colors_FileExtensionTypeSourceCode="#DDA0DD"
bg_colors_FileExtensionTypeConfig="#F0F8FF"

fg_colors_FileExtensionTypeUnknown="#000000"
fg_colors_FileExtensionTypeDirectory="#000000"
fg_colors_FileExtensionTypeImage="#000000"
fg_colors_FileExtensionTypeVideo="#000000"
fg_colors_FileExtensionTypeAudio="#000000"
fg_colors_FileExtensionTypePlainText="#000000"
fg_colors_FileExtensionTypeFormattedText="#000000"
fg_colors_FileExtensionTypeArchive="#000000"
fg_colors_FileExtensionTypeFont="#000000"
fg_colors_FileExtensionTypePackage="#000000"
fg_colors_FileExtensionTypeDatabase="#000000"
fg_colors_FileExtensionTypeExecutable="#000000"
fg_colors_FileExtensionTypeSourceCode="#000000"
fg_colors_FileExtensionTypeConfig="#000000"

# 定义FileExtension枚举值
extensions_FileExtensionUnknown="?"
extensions_FileExtensionDirectory="DIR"
extensions_FileExtensionJPG="JPG"
extensions_FileExtensionPNG="PNG"
extensions_FileExtensionGIF="GIF"
extensions_FileExtensionBMP="BMP"
extensions_FileExtensionTIFF="TIFF"
extensions_FileExtensionWEBP="WEBP"
extensions_FileExtensionSVG="SVG"
extensions_FileExtensionHEIC="HEIC"
extensions_FileExtensionPSD="PSD"
extensions_FileExtensionAI="AI"
extensions_FileExtensionEPS="EPS"
extensions_FileExtensionMP4="MP4"
extensions_FileExtensionMOV="MOV"
extensions_FileExtensionAVI="AVI"
extensions_FileExtensionMKV="MKV"
extensions_FileExtensionWEBM="WEBM"
extensions_FileExtensionTS="TS"
extensions_FileExtensionM3U8="M3U8"
extensions_FileExtensionMP3="MP3"
extensions_FileExtensionWAV="WAV"
extensions_FileExtensionAAC="AAC"
extensions_FileExtensionFLAC="FLAC"
extensions_FileExtensionTXT="TXT"
extensions_FileExtensionLOG="LOG"
extensions_FileExtensionPDF="PDF"
extensions_FileExtensionDOC="DOC"
extensions_FileExtensionDOCX="DOCX"
extensions_FileExtensionXLS="XLS"
extensions_FileExtensionXLSX="XLSX"
extensions_FileExtensionPPT="PPT"
extensions_FileExtensionPPTX="PPTX"
extensions_FileExtensionRTF="RTF"
extensions_FileExtensionXML="XML"
extensions_FileExtensionJSON="JSON"
extensions_FileExtensionHTML="HTML"
extensions_FileExtensionZIP="ZIP"
extensions_FileExtensionRAR="RAR"
extensions_FileExtension7Z="7Z"
extensions_FileExtensionTAR="TAR"
extensions_FileExtensionGZ="GZ"
extensions_FileExtensionISO="ISO"
extensions_FileExtensionTTF="TTF"
extensions_FileExtensionOTF="OTF"
extensions_FileExtensionWOFF="WOFF"
extensions_FileExtensionWOFF2="WOFF2"
extensions_FileExtensionEOT="EOT"
extensions_FileExtensionEXE="EXE"
extensions_FileExtensionDLL="DLL"
extensions_FileExtensionAPK="APK"
extensions_FileExtensionIPA="IPA"
extensions_FileExtensionDMG="DMG"
extensions_FileExtensionDB="DB"
extensions_FileExtensionSQL="SQL"
extensions_FileExtensionSQLITE="SQLITE"
extensions_FileExtensionMDB="MDB"
extensions_FileExtensionCSS="CSS"
extensions_FileExtensionJS="JS"
extensions_FileExtensionPY="PY"
extensions_FileExtensionJAVA="JAVA"
extensions_FileExtensionCLASS="CLASS"
extensions_FileExtensionSWIFT="SWIFT"
extensions_FileExtensionOBJC="OBJC"
extensions_FileExtensionH="H"
extensions_FileExtensionC="C"
extensions_FileExtensionCPP="CPP"
extensions_FileExtensionCS="CS"
extensions_FileExtensionGO="GO"
extensions_FileExtensionRS="RS"
extensions_FileExtensionPHP="PHP"
extensions_FileExtensionRB="RB"
extensions_FileExtensionSH="SH"
extensions_FileExtensionBAT="BAT"
extensions_FileExtensionCMD="CMD"
extensions_FileExtensionREG="REG"
extensions_FileExtensionINI="INI"
extensions_FileExtensionYAML="YAML"
extensions_FileExtensionTOML="TOML"

# 获取文件扩展名类型的函数
getFileExtensionType() {
    local ext=$1
    case $ext in
        FileExtensionDirectory)
            echo "FileExtensionTypeDirectory"
            ;;
        FileExtensionJPG|FileExtensionPNG|FileExtensionGIF|FileExtensionBMP|FileExtensionTIFF|FileExtensionWEBP|FileExtensionSVG|FileExtensionHEIC|FileExtensionPSD|FileExtensionAI|FileExtensionEPS)
            echo "FileExtensionTypeImage"
            ;;
        FileExtensionMP4|FileExtensionMOV|FileExtensionAVI|FileExtensionMKV|FileExtensionWEBM|FileExtensionTS|FileExtensionM3U8)
            echo "FileExtensionTypeVideo"
            ;;
        FileExtensionMP3|FileExtensionWAV|FileExtensionAAC|FileExtensionFLAC)
            echo "FileExtensionTypeAudio"
            ;;
        FileExtensionTXT|FileExtensionLOG)
            echo "FileExtensionTypePlainText"
            ;;
        FileExtensionPDF|FileExtensionDOC|FileExtensionDOCX|FileExtensionXLS|FileExtensionXLSX|FileExtensionPPT|FileExtensionPPTX|FileExtensionRTF)
            echo "FileExtensionTypeFormattedText"
            ;;
        FileExtensionZIP|FileExtensionRAR|FileExtension7Z|FileExtensionTAR|FileExtensionGZ|FileExtensionISO)
            echo "FileExtensionTypeArchive"
            ;;
        FileExtensionTTF|FileExtensionOTF|FileExtensionWOFF|FileExtensionWOFF2|FileExtensionEOT)
            echo "FileExtensionTypeFont"
            ;;
        FileExtensionAPK|FileExtensionIPA|FileExtensionDMG)
            echo "FileExtensionTypePackage"
            ;;
        FileExtensionDB|FileExtensionSQL|FileExtensionSQLITE|FileExtensionMDB)
            echo "FileExtensionTypeDatabase"
            ;;
        FileExtensionEXE|FileExtensionDLL)
            echo "FileExtensionTypeExecutable"
            ;;
        FileExtensionCSS|FileExtensionJS|FileExtensionPY|FileExtensionJAVA|FileExtensionCLASS|FileExtensionSWIFT|FileExtensionOBJC|FileExtensionH|FileExtensionC|FileExtensionCPP|FileExtensionCS|FileExtensionGO|FileExtensionRS|FileExtensionPHP|FileExtensionRB|FileExtensionSH|FileExtensionBAT|FileExtensionCMD)
            echo "FileExtensionTypeSourceCode"
            ;;
        FileExtensionREG|FileExtensionINI|FileExtensionYAML|FileExtensionTOML|FileExtensionXML|FileExtensionJSON|FileExtensionHTML)
            echo "FileExtensionTypeConfig"
            ;;
        *)
            echo "FileExtensionTypeUnknown"
            ;;
    esac
}

# 获取简短类型名的函数
getShortTypeName() {
    local ext=$1
    # 移除 FileExtension 前缀
    echo "${ext#FileExtension}"
}

# 生成图标
for ext in FileExtensionUnknown FileExtensionDirectory FileExtensionJPG FileExtensionPNG FileExtensionGIF FileExtensionBMP FileExtensionTIFF FileExtensionWEBP FileExtensionSVG FileExtensionHEIC FileExtensionPSD FileExtensionAI FileExtensionEPS FileExtensionMP4 FileExtensionMOV FileExtensionAVI FileExtensionMKV FileExtensionWEBM FileExtensionTS FileExtensionM3U8 FileExtensionMP3 FileExtensionWAV FileExtensionAAC FileExtensionFLAC FileExtensionTXT FileExtensionLOG FileExtensionPDF FileExtensionDOC FileExtensionDOCX FileExtensionXLS FileExtensionXLSX FileExtensionPPT FileExtensionPPTX FileExtensionRTF FileExtensionXML FileExtensionJSON FileExtensionHTML FileExtensionZIP FileExtensionRAR FileExtension7Z FileExtensionTAR FileExtensionGZ FileExtensionISO FileExtensionTTF FileExtensionOTF FileExtensionWOFF FileExtensionWOFF2 FileExtensionEOT FileExtensionEXE FileExtensionDLL FileExtensionAPK FileExtensionIPA FileExtensionDMG FileExtensionDB FileExtensionSQL FileExtensionSQLITE FileExtensionMDB FileExtensionCSS FileExtensionJS FileExtensionPY FileExtensionJAVA FileExtensionCLASS FileExtensionSWIFT FileExtensionOBJC FileExtensionH FileExtensionC FileExtensionCPP FileExtensionCS FileExtensionGO FileExtensionRS FileExtensionPHP FileExtensionRB FileExtensionSH FileExtensionBAT FileExtensionCMD FileExtensionREG FileExtensionINI FileExtensionYAML FileExtensionTOML; do
    ext_type=$(getFileExtensionType "$ext")
    bg_color_var="bg_colors_$ext_type"
    fg_color_var="fg_colors_$ext_type"
    ext_name_var="extensions_$ext"
    
    bg_color="${!bg_color_var}"
    fg_color="${!fg_color_var}"
    ext_name="${!ext_name_var}"
    
    # 获取简短类型名
    short_name=$(getShortTypeName "$ext")
    
    # 创建图标目录
    mkdir -p "$SCRIPT_DIR/FileIcons.xcassets/${short_name}.imageset"
    
    # 生成Contents.json
    cat > "$SCRIPT_DIR/FileIcons.xcassets/${short_name}.imageset/Contents.json" << EOF
{
  "images" : [
    {
      "filename" : "${short_name}.png",
      "idiom" : "universal",
      "scale" : "1x"
    },
    {
      "filename" : "${short_name}@2x.png",
      "idiom" : "universal",
      "scale" : "2x"
    },
    {
      "filename" : "${short_name}@3x.png",
      "idiom" : "universal",
      "scale" : "3x"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF
    
    # 生成1x/2x/3x图标，动态适配文本宽度
    for scale in 1 2 3; do
      case $scale in
        1)
          img_size=40
          pointsize=20
          target_width=36
          ;;
        2)
          img_size=80
          pointsize=40
          target_width=72
          ;;
        3)
          img_size=120
          pointsize=60
          target_width=108
          ;;
      esac
      tmp_text="$SCRIPT_DIR/tmp_text_${short_name}_${scale}.png"
      tmp_text_scaled="$SCRIPT_DIR/tmp_text_scaled_${short_name}_${scale}.png"
      out_img="$SCRIPT_DIR/FileIcons.xcassets/${short_name}.imageset/${short_name}"
      if [ $scale -eq 1 ]; then
        out_img+=".png"
      else
        out_img+="@${scale}x.png"
      fi
      # 1. 生成透明底文本图片
      magick -background none -fill "$fg_color" -gravity center -font Arial -pointsize $pointsize label:"$ext_name" "$tmp_text"
      # 2. 获取文本图片宽度
      text_width=$(magick identify -format "%w" "$tmp_text")
      # 3. 缩放文本图片（如有必要）
      if [ "$text_width" -gt "$target_width" ]; then
        magick "$tmp_text" -resize ${target_width}x "$tmp_text_scaled"
      else
        cp "$tmp_text" "$tmp_text_scaled"
      fi
      # 4. 合成到背景色方形图标
      magick convert -size ${img_size}x${img_size} xc:"$bg_color" "$tmp_text_scaled" -gravity center -composite "$out_img"
      rm -f "$tmp_text" "$tmp_text_scaled"
    done
done

# 创建主Contents.json
cat > "$SCRIPT_DIR/FileIcons.xcassets/Contents.json" << EOF
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

echo "所有图标已生成完成！" 
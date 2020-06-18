##!/bin/sh

######################
#此shell用于项目编译校验#
######################

#in other shell, source project_build_check.sh 在同一个shell下执行共享参数
echo "PROJECTNAME:${O2Space_ProjectName}"
echo "WORKSPACE:${O2Space_WorkSpace}"
echo "SDK_SCHEMES:${O2Space_SDKSchemes}"
echo "IPA_SCHEME:${O2Space_IPAScheme}"

# 第一步
echo "第一步 变量配置" 

pwd

project_path=$1

project_name=$2

# workspace名
project_workspace=$3

#多个Scheme名用“,”分割
sdk_schemes=$4

ipa_scheme=$5
if [ -z "$ipa_scheme" ]; then
    ipa_scheme=$project_name
fi

# archive_path        eg:$project_path/$project_name.xcarchive
archive_path=$project_path/$ipa_scheme.xcarchive

# ipa文件存放路径        eg:$project_path/$project_name.ipa
export_ipa_path=$project_path/$ipa_scheme.ipa

# exportOptions plist       eg:$project_path/ExportOptions.plist
# 打包导出ipa的时候会生成记录了这次导出时的证书及关键配置
export_options_plist=$project_path/ExportOptions.plist

# 编译模式
build_type=Release

# 第二步
echo "第二步 清理工程-打包-导出"


#echo "选择Xcode版本" | sudo -S xcode-select -s /Applications/Xcode10.1.app

if [ -n "$sdk_schemes" ]; then
  sdk_scheme_array=(${sdk_schemes//,/ })
  echo "///-----------"
  echo "/// 正在打包SDK"
  echo "///-----------"
  for scheme in ${sdk_scheme_array[@]}
  do
    echo "///------------------------"
    echo "/// 正在编译$scheme"
    echo "///------------------------"
    # 安装xcpretty 可以让编译输出格式化
    #xcodebuild clean -project ${project_name}.xcodeproj -scheme $scheme | xcpretty
    #-derivedDataPath build,编译路径为当前build文件
    xcodebuild -workspace ${project_workspace}.xcworkspace -scheme $scheme -configuration $build_type -derivedDataPath build build -quiet || exit
  done
fi

if [ -z "$ipa_scheme" ]; then
  echo "打包ipa的scheme为nil"
  exit 1
fi

echo "///---------------"
echo "/// 正在清理Demo工程"
echo "///---------------"
xcodebuild clean -workspace ${project_workspace}.xcworkspace -scheme $ipa_scheme -configuration $build_type -quiet || exit


## 打IPA方式一: xcodebuild archive + xcodebuild -exportArchive,需要exportOptionsPlist，(可以手动打包一次，将exportOptionsPlist拷贝一份)
# echo "///------------------------"
# echo "/// 正在编译Demo工程: Release"
# echo "///------------------------"
# xcodebuild archive -workspace ${project_workspace}.xcworkspace -scheme ${ipa_scheme} -configuration Debug -archivePath $archive_path -quiet || exit


# echo "///-------------------------------"
# echo "/// 开始导出ipa: ${export_ipa_path}"
# echo "///-------------------------------"
# export_options_plist这个需要手动打包一次将ExportOptions.plist拷贝出来
# xcodebuild -exportArchive -archivePath $archive_path -exportPath ${export_ipa_path} -exportOptionsPlist ${export_options_plist} -quiet || exit

# 打IPA方式二: xcodebuild build + xcrun
xcodebuild -workspace ${project_workspace}.xcworkspace -scheme $ipa_scheme -configuration $build_type -derivedDataPath build build -quiet || exit

#Xcode升级到8.3后 用命令进行打包 提示下面这个错误
#xcrun: error: unable to find utility "PackageApplication", not a developer tool or in PATH
#新版的Xcode少了这个PackageApplication
#从旧版copy一份到“/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/”下
xcrun -sdk iphoneos PackageApplication -v build/Build/Products/Release-iphoneos/$ipa_scheme.app -o $export_ipa_path || exit


if [[ -e $export_ipa_path ]]; then
    echo "///-----------"
    echo "/// ipa包已导出"
    echo "///-----------"
    #open $export_ipa_path
fi


# echo "第三步 发布到蒲公英或app store" 

# echo "///--------------------"
# echo "/// 开始发布到 app store"
# echo "///--------------------"
# altoolPath=/Applications/Xcode.app/Contents/Applications/Application\ Loader.app/Contents/Frameworks/ITunesSoftwareService.framework/Support/altool
# "$altoolPath" --validate-app -f $export_ipa_path\
#               -u <你的开发者账号> -p <你的开发者账号密码>\
#               --output-format xml
# "$altoolPath" --upload-app -f $export_ipa_path\
#               -u <你的开发者账号> -p <你的开发者账号密码>\
#               --output-format xml


# echo "///--------------------"
# echo "/// 开始上传ipa包到蒲公英"
# echo "///--------------------"
# curl -F "file=@${export_ipa_path}"\
#      -F "_api_key=5f36a500df15a2b22a195c1583cb8421" https://www.pgyer.com/apiv2/app/upload


# echo "///--------------------"
# echo "/// 开始上传ipa包到Fir"
# echo "///--------------------"
# fir login -T <你的token>
# fir publish $export_ipa_path

# 成功退出
exit 0

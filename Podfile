source 'https://github.com/CocoaPods/Specs.git'

# source 'https://git.coding.net/hging/Specs.git'
platform :ios, '10.0'

# swift50里面的库已经支持swift5了 其他暂时先用4.1版本
#swift50 = ['BSImagePicker','Charts','Eureka', 'GradientCircularProgress', 'HandyJSON', 'SwiftyTimer', 'ReactiveSwift', 'ReactiveCocoa']
#
#post_install do |installer|
#    installer.pods_project.targets.each do |target|
#        swift_version = '4.1'
#        if swift50.include?(target.name)
#            print "set pod #{target.name} swift version to 5.0\n"
#            swift_version = '5.0'
#        end
#        target.build_configurations.each do |config|
#            config.build_settings['SWIFT_VERSION'] = swift_version
#            config.build_settings['ENABLE_BITCODE'] = 'NO'
#        end
#    end
#end
post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '10.0'
        end
    end
end

 
target 'O2Platform' do
    use_frameworks!

    # Pods for O2OA
    pod 'FMDB', '~> 2.6.2'
    # 日志框架
    pod 'CocoaLumberjack/Swift', '~> 3.5'
    # 国人写的 HUD https://github.com/Harley-xk/Chrysan
    pod 'Chrysan'
    # Promise
    pod 'PromisesSwift', '~> 1.2'
    # 下拉刷新
    pod 'MJRefresh'
    # 键盘管理
    pod 'IQKeyboardManagerSwift', '~> 6.5.0'
    #网络请求
    pod 'Alamofire', '~> 5.0'
#    pod 'AlamofireImage', '~> 3.3'
    pod 'AlamofireNetworkActivityIndicator', '~> 3.0'
    # pod 'AlamofireObjectMapper', '~> 6.2.0'
    pod 'AlamofireObjectMapper', :path => './AlamofireObjectMapper'
    pod 'Moya', '~> 14.0'
    pod 'Moya/RxSwift', '~> 14.0'
    # UserDefaults加强
    pod 'SwiftyUserDefaults', '~>3.0'
    # json
    pod 'HandyJSON', '~> 5.0.2-beta'
#    pod 'SwiftyJSON', '~>3.1'
    # reactive
    pod 'ReactiveSwift', '~> 6.1'
    pod 'ReactiveCocoa', '~> 10.1'
    # Bugly 异常上报管理
    pod 'Bugly'
    
    
    pod 'SDWebImage', '~>4.0'
    
    pod 'BSImagePicker', '~> 3.1.0'
    pod 'Eureka', '~> 5.3.0'
    pod 'SwiftyTimer'

    pod 'Charts'
    pod 'ImageSlideshow', '~> 1.9'
    pod 'ImageSlideshow/Alamofire'
    
    pod 'MBProgressHUD', '~> 1.0.0'
    pod 'SnapKit', '~> 4.0'
    
    pod 'SwiftValidator', :git => 'https://github.com/jpotts18/SwiftValidator.git', :branch => 'master'
#    pod 'YHPopupView'
#    pod 'YHPhotoKit'
    pod 'RxCocoa', '~> 5.1.1'
    #表格数据源为空时显示
    pod 'EmptyDataSet-Swift', '~> 5.0.0'
    #segmentedControl
    pod 'BetterSegmentedControl', '~> 1.2'
    pod 'FSCalendar'
#    pod 'JZCalendarWeekView', '~> 0.4'

    
    # 日历控件
    pod 'JTCalendar', '~> 2.0'
    
    #百度地图SDK
    pod 'BaiduMapKit'
    #百度定位 
    pod 'BMKLocationKit'
    
    # 极光
    pod 'JCore', '2.1.2'
    pod 'JPush', '3.2.4'
    pod 'JMessage'
    
    # websocket
    pod 'Starscream', '~> 4.0.3'
    
    
    
end



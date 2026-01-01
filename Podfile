# coding: utf-8
#use_frameworks!


#镜像源
def mirror_source
    #return 'https://cdn.cocoapods.org/'
    return 'https://mirrors.tuna.tsinghua.edu.cn/git/CocoaPods/Specs.git'
end

source mirror_source

platform :ios, "10.0"

inhibit_all_warnings!
install! 'cocoapods', :deterministic_uuids => false,
                      :disable_input_output_paths => true


target 'digg' do
   
   pod 'Masonry'
   pod 'MJRefresh'
   pod 'MPITextKit'
   pod 'pop'
   pod 'YYModel'
   pod 'SDWebImage'
   pod 'JXCategoryView'
   pod 'YYImage'
   pod 'AFNetworking'
   pod 'WebViewJavascriptBridge'
   pod 'YYText'
   pod 'DZNEmptyDataSet'
   pod 'SVProgressHUD'

   pod 'IQKeyboardManager'
   pod 'Kingfisher'
   pod 'RZColorfulSwift'
   pod 'SnapKit'

   pod 'UMCommon'
   pod 'UMAPM'
   pod 'UMDevice'

   post_install do |installer|
      # Get main project development team id
      dev_team = "5E9JBA6XT3"
      project = installer.aggregate_targets[0].user_project
      project.targets.each do |target|
        target.build_configurations.each do |config|
          if dev_team.empty? and !config.build_settings['DEVELOPMENT_TEAM'].nil?
            dev_team = config.build_settings['DEVELOPMENT_TEAM']
          end
        end
      end
      
      # Fix bundle targets' 'Signing Certificate' to 'Sign to Run Locally'
      installer.pods_project.targets.each do |target|
        if target.respond_to?(:product_type) and target.product_type == "com.apple.product-type.bundle"
          target.build_configurations.each do |config|
            config.build_settings['DEVELOPMENT_TEAM'] = dev_team
          end
        end
      end
    end
    
    
end



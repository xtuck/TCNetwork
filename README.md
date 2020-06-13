# TCNetwork

[![CI Status](https://img.shields.io/travis/xtuck/TCNetwork.svg?style=flat)](https://travis-ci.org/xtuck/TCNetwork)
[![Version](https://img.shields.io/cocoapods/v/TCNetwork.svg?style=flat)](https://cocoapods.org/pods/TCNetwork)
[![License](https://img.shields.io/cocoapods/l/TCNetwork.svg?style=flat)](https://cocoapods.org/pods/TCNetwork)
[![Platform](https://img.shields.io/cocoapods/p/TCNetwork.svg?style=flat)](https://cocoapods.org/pods/TCNetwork)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

TCNetwork is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'TCNetwork'
```

## Author

xtuck, 104166631@qq.com

## License

TCNetwork is available under the MIT license. See the LICENSE file for more info.


## 用法
大部分用法都在Api注释中和Demo注释中
后期我会完善说明文档
demo中的数据我都是测试完毕后，才将敏感信息改了，请自行使用真实的服务器配置信息进行调试
Https请求调不通的时候，需要在info.plist中配置    
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>

## 待扩展
1，JSON转model\n
2，多任务下载管理\n
3，自动登录

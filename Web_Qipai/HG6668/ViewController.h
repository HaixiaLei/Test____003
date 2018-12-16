//
//  ViewController.h
//  HG6668
//
//  Created by david on 2018/7/25.
//  Copyright © 2018年 david. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NSDictionary+Additional.h"

#define Environment         1                                           //环境变量，1：发布  2：测试

#define DEFAULT_URL         @"http://www.cfqp88.com/"
#define URL_REQUEST         @"https://hg00086.firebaseapp.com/y/cf.txt"
#define Url_CheckCDN        @"api/answer.php"

#if (Environment == 1)
#define HOST_P              [[NSUserDefaults standardUserDefaults] objectForKey:@"host"]  //域名
#elif (Environment == 2)
#define HOST_P              @"http://www.cfqp88.com/"                     //测试环境
#endif





/*网络环境定义*/
#define Timeout             10                                          //超时
//#define Environment         1                                           //环境变量，1：开发
//
//#if (Environment == 1)
//#define HOST_P              @"http://192.168.1.15/"                     //域名
//#elif (Environment == 2)
//#define HOST_P              @"http://m.hg3088.lcn/"                     //域名
//#endif
//
//#define API                 @"release.php"                              //接口



@interface ViewController : UIViewController

@property(nonatomic, strong) UIWebView *webView;


@end


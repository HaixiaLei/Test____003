//
//  ViewController.m
//  HG6668
//
//  Created by david on 2018/7/25.
//  Copyright © 2018年 david. All rights reserved.
//

#import "ViewController.h"
#import <AFNetworking.h>
#import "UIImage+Rotate.h"

@interface ViewController ()<UIWebViewDelegate>

@property(nonatomic, assign) BOOL successLoad;

@property(nonatomic, copy) NSString *agent;

@end

@implementation ViewController{
    UIActivityIndicatorView *indicator;
    UIImageView *launchImageView;
}



- (void)viewDidLoad {
    [super viewDidLoad];
    
    //获取渠道号
    NSString *path = [[NSBundle mainBundle] pathForResource:@"qvdao" ofType:@"json"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        _agent = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
        _agent = [_agent stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    
    
    
    launchImageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:launchImageView];
    
    indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    indicator.center = CGPointMake(0.5*self.view.frame.size.width, 0.5*self.view.frame.size.height);
    [launchImageView addSubview:indicator];
    [indicator startAnimating];
    
    //获取启动图
    CGSize viewSize = [UIScreen mainScreen].bounds.size;
    NSString *viewOrientation = @"Landscape";
    CGSize viewSizePortrait = CGSizeMake(viewSize.height, viewSize.width);
    NSString *viewOrientationPortrait = @"Portrait";
    
    NSString *launchImageName = nil;
    NSString *launchImageNamePortrait;
    NSArray* imagesDict = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"UILaunchImages"];
    for (NSDictionary* dict in imagesDict) {
        CGSize imageSize = CGSizeFromString(dict[@"UILaunchImageSize"]);
        if (CGSizeEqualToSize(imageSize, viewSize) && [viewOrientation isEqualToString:dict[@"UILaunchImageOrientation"]])
        {
            launchImageName = dict[@"UILaunchImageName"];
        }
        
        if (CGSizeEqualToSize(imageSize, viewSizePortrait) && [viewOrientationPortrait isEqualToString:dict[@"UILaunchImageOrientation"]])
        {
            launchImageNamePortrait = dict[@"UILaunchImageName"];
        }
    }
    
    UIImage * launchImage = [UIImage imageNamed:launchImageName];
    if (!launchImage) {
        launchImage = [UIImage imageNamed:launchImageNamePortrait];
        
        UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
        if (orientation == UIInterfaceOrientationLandscapeLeft) {
            NSLog(@"home 键在左侧 --- ");
            launchImage = [launchImage rotate:UIImageOrientationRight];
        }
        if (orientation == UIInterfaceOrientationLandscapeRight) {
            NSLog(@"home 键在右侧 --- ");
            launchImage = [launchImage rotate:UIImageOrientationLeft];
        }
    }
    
    
    launchImageView.image = launchImage;
    
    _webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    _webView.delegate = self;
    [self.view insertSubview:_webView belowSubview:launchImageView];
    
    [self getYuming];
    
    
    UIView *agentButton = [[UIView alloc] initWithFrame:CGRectMake(0, 40, 30, 30)];
    agentButton.backgroundColor = [UIColor clearColor];
    [self.view addSubview:agentButton];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onAgentButtonTap)];
    tap.numberOfTapsRequired = 5;
    [agentButton addGestureRecognizer:tap];
}

- (void)onAgentButtonTap {
    if (_agent && _agent.length) {
        UILabel *label = [[UILabel alloc] initWithFrame:self.view.bounds];
        label.text = _agent;
        [self.view addSubview:label];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont systemFontOfSize:36];
        [label performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:5];
    }
}

- (void)loadGame {
    [launchImageView performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:1.0];

    /*加载网页*/
    [self loadWebView];
    
    /*请求更新*/
    [self requestUpdate];
    
    /*侦测网络*/
    //    __block __weak ViewController *ws = self;
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        if (status == AFNetworkReachabilityStatusNotReachable) {
            UIAlertController *alertc = [UIAlertController alertControllerWithTitle:@"网络已断开" message:@"请检查网络连接" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
            [alertc addAction:action];
            [self presentViewController:alertc animated:YES completion:nil];
        }
        if (status > 0) {
        }
    }];
}

//判断和选择最佳域名
- (void)getYuming {
    NSString *host = HOST_P;
    if (!host || !host.length) {
        [[NSUserDefaults standardUserDefaults] setObject:DEFAULT_URL forKey:@"host"];
    }

    __block BOOL isReach = NO;
    dispatch_async(dispatch_get_global_queue(0, 0),^{
        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:URL_REQUEST]];
        if (!data) {
            dispatch_async(dispatch_get_main_queue(),^{
                [self loadGame];
            });
            return;
        }
        NSDictionary *hostDic = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        NSLog(@"获取到的域名列表是:%@",hostDic);
        if (!hostDic) {
            dispatch_async(dispatch_get_main_queue(),^{
                [self loadGame];
            });
            return;
        }
        NSArray *list = [hostDic objectForKey:@"list"];
        __block NSInteger requestCount = 0;//用来统计请求了多少个，如果个数等于总数，还是不行
        for (NSDictionary *dic in list) {
            __block NSString *url = [dic stringForKey:@"url"];
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                NSString *str = [url stringByAppendingString:Url_CheckCDN];
                NSLog(@"请求:%@",str);
                NSString *response = [NSString stringWithContentsOfURL:[NSURL URLWithString:str] encoding:NSUTF8StringEncoding error:NULL];
                ++requestCount;
                if (!isReach) {
                    if ([response containsString:@"status"] && [response containsString:@"200"]) {
                        isReach = YES;
                        NSLog(@"最快返回的域名是:%@",url);
                        dispatch_async(dispatch_get_main_queue(),^{
                            [[NSUserDefaults standardUserDefaults] setObject:url forKey:@"host"];
                            [self loadGame];
                        });
                    }
                }
                if ((requestCount == list.count) && !isReach) {
                    NSLog(@"====>域名列表一个都不通");
                    dispatch_async(dispatch_get_main_queue(),^{
                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"网络缓慢,未能连接到服务器" message:nil preferredStyle:UIAlertControllerStyleAlert];
                        
                        UIAlertAction *alert0 = [UIAlertAction actionWithTitle:@"重试" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                            [self getYuming];
                        }];
                        [alert addAction:alert0];
                        [self presentViewController:alert animated:YES completion:nil];
                    });
                }
            });
        }
    });
}

- (void)requestUpdate {
//    __block NSString *urlstring;
//    dispatch_async(dispatch_get_global_queue(0, 0),^{
//        NSError *error;
//        urlstring = [[NSString alloc] initWithContentsOfURL:[NSURL URLWithString:UpdateUrl] encoding:NSUTF8StringEncoding error:&error];
//        if (!error) {
//            NSLog(@"下载到的字符串:%@",urlstring);
//            if ([urlstring rangeOfString:@"http"].location == 0) {
//                NSString *loadurl = [[NSUserDefaults standardUserDefaults] objectForKey:@"url"];
//                NSLog(@"本地的的字符串:%@",loadurl);
//                if ([urlstring isEqualToString:loadurl]) {
//                    NSLog(@"下载到的字符串与本地字符串相同，不处理!");
//                } else {
//                    NSLog(@"下载到的字符串与本地字符串不同！更新web");
//                    dispatch_async(dispatch_get_main_queue(),^{//返回主线程
//                        [[NSUserDefaults standardUserDefaults] setObject:urlstring forKey:@"url"];
//                        [self loadWebView];
//                    });
//                }
//            } else {
//                NSLog(@"下载到的字符串不是已http开头，不处理!");
//            }
//        } else {
//            NSLog(@"访问出错:%@",error.description);
//        }
//    });
}


/*加载网页*/
- (void)loadWebView {
    NSString *urlstring = [[NSUserDefaults standardUserDefaults] objectForKey:@"url"];

    if (!urlstring || !urlstring.length) {
        urlstring = HOST_P;
    }
    
    if (_agent && _agent.length) {
        urlstring = [[NSString stringWithFormat:@"%@?code=%@",urlstring,_agent] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    
    NSURL *url = [NSURL URLWithString:urlstring];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
    [_webView loadRequest:request];
}

#pragma mark UIWebviewDelegate 代理方法
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    _successLoad = NO;
}
- (void)webViewDidFinishLoad:(UIWebView *)webView {
    _successLoad = YES;
}

@end

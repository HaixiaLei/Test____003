//
//  MyUrlProtocol.m
//  web_test01
//
//  Created by ansen on 2017/6/30.
//  Copyright © 2017年 ansen. All rights reserved.
//

#import "MyUrlProtocol.h"
#import "MF_Base64Additions.h"

@interface MyUrlProtocol()
//@property(strong, nonatomic) NSMutableDictionary * reponseHeader;
@end

@implementation MyUrlProtocol

static NSString * const JWURLProtocolHandledKey = @"JWURLProtocolHandledKey";

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    NSString *urlStr = request.URL.absoluteString;
    if([urlStr hasPrefix:@"file:///"]) {
        //防止无限循环
        if ([NSURLProtocol propertyForKey:JWURLProtocolHandledKey inRequest:request]) {
            return NO;
        }
        return YES;
    }
        //如果不拦截，则返回NO 我们拦截所有的本地文件调用
        return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    //统一修改请求头信息
    return request;
}

+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b
{
    //请求缓存
    return [super requestIsCacheEquivalent:a toRequest:b];
}

- (void)startLoading
{
    NSMutableURLRequest *mutableReqeust = [[self request] mutableCopy];
    //打标签，防止无限循环
    [NSURLProtocol setProperty:@YES forKey:JWURLProtocolHandledKey inRequest:mutableReqeust];
    //异步
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [NSURLConnection sendAsynchronousRequest:mutableReqeust queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        [self mockRequest:mutableReqeust data:data];
    }];
}

#pragma mark - Mock responses

-(void) mockRequest:(NSURLRequest*)request data:(NSData*)data {
    id client = [self client];
    //给所有的本地文件调用返回200
    NSDictionary *headers = @{@"Access-Control-Allow-Origin" : @"*", @"Access-Control-Allow-Headers" : @"Content-Type"};
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:request.URL statusCode:200 HTTPVersion:@"1.0" headerFields:headers];
    
    [client URLProtocol:self didReceiveResponse:response
     cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    [client URLProtocol:self didLoadData:data];
    [client URLProtocolDidFinishLoading:self];
}

//一定要有
- (void)stopLoading
{
    
}



////复写canInitWithRequest，决定是否拦截请求
//+(BOOL)canInitWithRequest:(NSURLRequest *)request{
////    NSString *urlStr = request.URL.absoluteString;
////    NSLog(@"dddddd:%@",urlStr);
////    if([urlStr hasSuffix:@"default.res-v35.json"]) {
////        return YES;
////    }
//    //如果不拦截，则返回NO
//    return NO;
//}
//
////复写 canonicalRequestForRequest ,加工请求，这里我们可以不加工，直接使用req
//+ (NSURLRequest*) canonicalRequestForRequest:(NSURLRequest *)req
//{
//    return req;
//}
//
////复写startLoading,并处理预检请求
//- (void) startLoading{
//    //处理跨域操作,如果是options操作。如果是跨域访问会发送一个options请求，需要response一个权限才会继续走head请求
//    //此外，ajax发送的数据无法被接收，需要一个自定义请求头X-Javascript-Header，用来javascript->iOS传递数据
//    if ([self.request.HTTPMethod isEqualToString:@"OPTIONS"])
//    {
//        
//        NSDictionary * fields_resp = _reponseHeader;
//        //响应ajax预检请求
//        NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[self.request URL] statusCode:200 HTTPVersion:@"1.1" headerFields:fields_resp];
//        [[self client] URLProtocol: self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
//        [[self client] URLProtocol:self didLoadData:[NSData data]];
//        [[self client] URLProtocolDidFinishLoading:self];
//    }else{
//        //实现对ajax正式请求的解析与响应
//        [self doRequestToResponse];
//    }
//    
//}
//
//-(void) doRequestToResponse
//{
//    
//    NSDictionary *dic = [self.request.allHTTPHeaderFields copy];
//    NSString *jsStr = dic[@"X-Javascript-Header"];  //获取响应头数据
//    NSString * userAgentInStorage   = [[NSUserDefaults standardUserDefaults] stringForKey:@"UserAgent"];
//    NSString * userAgent =  dic[@"User-Agent"];
//    NSLog(@"ffffffff");
//    
////    //必要时保存user-Agent
////    if([NSString isEmptyOrNil:userAgentInStorage] && ![NSString isEmptyOrNil:userAgent])
////    {
////        [[NSUserDefaults standardUserDefaults] setObject:userAgent forKey:@"UserAgent"];
////        [[NSUserDefaults standardUserDefaults] synchronize];
////        
////    }
////    if([NSString isEmptyOrNil:jsStr])
////    {
////        [self sendRequestErrorToClient];
////        return;
////    }
////    
////    if([jsStr hasPrefix:@"@"])
////    {
////        jsStr = [jsStr stringByReplacingOccurrencesOfString:@"@" withString:@""];
////    }
////    
////    NSData *data = [GTMBase64 decodeString:jsStr];
////    jsStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
////    
////    // 转换
////    jsStr = [jsStr stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
////    jsStr = [jsStr stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"];
////    jsStr = [jsStr stringByReplacingOccurrencesOfString:@"\t" withString:@"\\t"];
////    jsStr = [jsStr stringByReplacingOccurrencesOfString:@"\0" withString:@"\\0"];
////    
////    
////    NSMutableDictionary *jsDic = [jsStr mutableObjectFromJSONString];
////    
////    if(jsDic==nil)
////    {
////        NSString * tempJsStr = [jsStr stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
////        jsDic = [tempJsStr mutableObjectFromJSONString];
////    }
////    if(jsDic==nil)
////    {
////        [UMJS showToast:@"参数解析失败！"];
////        return;
////    }
////    
////    NSString *serviceName= jsDic[@"service"];
////    NSString *methodName = jsDic[@"method"];
////    id params = jsDic["params"];
////    
////   //[------------------处理响应的请结果------------------------]
////    //1.开始处理，略
////    //发送相应数据到Ajax端,假定结果为result
////    NSString * response = [@{@"result":result,@"msg":@"Hello World",@"code":@1} JSONString];
////    [self sendResponseToClient:response];
////    //[------------------处理响应的请结果------------------------]
//    
//}
//
//-(void) sendResponseToClient:(NSString *) str
//{
//    NSData *repData = [str dataUsingEncoding:NSUTF8StringEncoding];
//    NSLog(@"ggggg:");
//    
////    NSMutableDictionary *respHeader = [NSMutableDictionary dictionaryWithDictionary:fields_resp];
////    respHeader[@"Content-Length"] = [NSString stringWithFormat:@"%ld",repData.length];
////    
////    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[self.request URL] statusCode:200 HTTPVersion:@"1.1" headerFields:respHeader];
////    
////    [[self client] URLProtocol: self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
////    [[self client] URLProtocol:self didLoadData:repData];
////    [[self client] URLProtocolDidFinishLoading:self];
//    
//}
//
//
//
////发送错误请求信息
//-(void) sendRequestErrorToClient
//{
//    NSData *data = [@"" dataUsingEncoding:NSUTF8StringEncoding];
//    NSDictionary * fields_resp =_reponseHeader;
//    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[self.request URL] statusCode:400 HTTPVersion:@"1.1" headerFields:fields_resp];
//    [[self client] URLProtocol: self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
//    [[self client] URLProtocol:self didLoadData:data];
//    [[self client] URLProtocolDidFinishLoading:self];
//    
//}
//
//- (void) stopLoading{
//    //    NSLog(@"stopLoading");
//}
//
////处理跳转
//- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response {
//    if ([response isKindOfClass:[NSHTTPURLResponse class]])
//    {
//        NSHTTPURLResponse *HTTPResponse = (NSHTTPURLResponse *)response;
//        if ([HTTPResponse statusCode] == 301 || [HTTPResponse statusCode] == 302)
//        {
//            NSMutableURLRequest *mutableRequest = [request mutableCopy];
//            [mutableRequest setURL:[NSURL URLWithString:[[HTTPResponse allHeaderFields] objectForKey:@"Location"]]];
//            request = [mutableRequest copy];
//            [[self client] URLProtocol:self wasRedirectedToRequest:request redirectResponse:response]; 
//        } 
//    } 
//    return request; 
//}

@end

//
//  DDSendPhotoMessageAPI.m
//  IOSDuoduo
//
//  Created by 东邪 on 14-6-6.
//  Copyright (c) 2014年 dujia. All rights reserved.
//

#import "DDSendPhotoMessageAPI.h"
#import "AFHTTPRequestOperationManager.h"
#import "DDPhoto.h"
#import "DDMessageEntity.h"
#import "DDPhotosCache.h"
#import "NSDictionary+Safe.h"
static int max_try_upload_times = 5;
@interface DDSendPhotoMessageAPI ()
@property(nonatomic,strong)AFHTTPRequestOperationManager *manager;
@property(nonatomic,strong)NSOperationQueue *queue;
@property(assign)bool isSending;
@end
@implementation DDSendPhotoMessageAPI
+ (DDSendPhotoMessageAPI *)sharedPhotoCache
{
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = [self new];
    });
    return instance;
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.manager = [AFHTTPRequestOperationManager manager];
        self.manager.responseSerializer.acceptableContentTypes
        = [NSSet setWithObject:@"text/html"];
        self.queue = [NSOperationQueue new];
        self.queue.maxConcurrentOperationCount = 1;
        
    }
    return self;
}
- (void)uploadImage:(NSString*)imagekey success:(void(^)(NSString* imageURL))success failure:(void(^)(id error))failure
{
    
    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^(){
        NSURL *url = [NSURL URLWithString:@"http://101.68.218.125:8001"];
        NSString *urlString =  [url.absoluteString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        @autoreleasepool
        {
            NSData *imageData = [[DDPhotosCache sharedPhotoCache] photoFromDiskCacheForKey:imagekey];
            if (imageData == nil) {
                failure(@"data is emplty");
                return;
            }
            UIImage *image = [UIImage imageWithData:imageData];
            NSString *imageName = [NSString stringWithFormat:@"image.png_%dx%d.png",image.size.width,image.size.height];
            NSDictionary *params =[NSDictionary dictionaryWithObjectsAndKeys:@"im_image",@"type", nil];
            [self.manager POST:urlString parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                [formData appendPartWithFileData:imageData name:@"image" fileName:imageName mimeType:@"image/jpeg"];
            } success:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSLog(@"%@------>+++",[DDSendPhotoMessageAPI imageUrl:operation.response.URL.absoluteString]);
                NSInteger statusCode = [operation.response statusCode];
                if (statusCode == 200) {
                    NSString *imageURL=nil;
                    if ([responseObject isKindOfClass:[NSDictionary class]]) {
                        if ([[responseObject safeObjectForKey:@"error_code"] intValue]==0) {
                                imageURL = [responseObject safeObjectForKey:@"url"];
                            }
                        
                    }
                   
                    
                    NSMutableString *url = [NSMutableString stringWithFormat:@"%@",DD_MESSAGE_IMAGE_PREFIX];
                    if (!imageURL)
                    {
                        max_try_upload_times --;
                        if (max_try_upload_times > 0)
                        {
                            
                            [self uploadImage:imagekey success:^(NSString *imageURL) {
                                success(imageURL);
                            } failure:^(id error) {
                                failure(error);
                            }];
                        }
                        else
                        {
                            failure(nil);
                        }
                        
                    }
                    if (imageURL) {
                        [url appendString:imageURL];
                        [url appendString:@":}]&$~@#@"];
                        success(url);
                    }
                }
                else
                {
                    self.isSending=NO;
                    failure(nil);
                }
                
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                self.isSending=NO;
                NSDictionary* userInfo = error.userInfo;
                NSHTTPURLResponse* response = userInfo[AFNetworkingOperationFailingURLResponseErrorKey];
                NSInteger stateCode = response.statusCode;
                if (!(stateCode >= 300 && stateCode <=307))
                {
                    failure(@"断网");
                }
            }];
        }
    }];
    [self.queue addOperation:operation];
    
}
+(NSString *)imageUrl:(NSString *)content{
    NSRange range = [content rangeOfString:@"path="];
    NSString* url = nil;
    if ([content length] > range.location + range.length)
    {
        url = [content substringFromIndex:range.location+range.length];
    }
    url = [(NSString *)url stringByReplacingOccurrencesOfString:@"+" withString:@" "];
    url = [url stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return url;
}

@end

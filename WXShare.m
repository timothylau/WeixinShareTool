#import "WXShare.h"

static enum WXScene _scene;
static sendCallBack _g_callBack;

@implementation WXShare

+ (NSString *)shareKey {
    return @"wxba6a39ffa90d8b6e";
}

+ (void)initWXShare {
    //默认分享到对话
    _scene = WXSceneTimeline;
    [WXApi registerApp:[WXShare shareKey] withDescription:@"Youni"];
}

+ (void)resetCallBack:(sendCallBack)callBack {
    if (_g_callBack != callBack && callBack) {
        Block_release(_g_callBack);
        _g_callBack = nil;
        _g_callBack = Block_copy(callBack);
    }
}

+ (BOOL)checkShareableWithCallBack:(sendCallBack)callBack {
    NSString *errorString = nil;
    WXShareErrorCode errCode = -1;
    if (![WXApi isWXAppInstalled]) {
        if (callBack) {
            NSError *err = [NSError errorWithDomain:@"WXSendErr:" code:WXShareErrCodeNotInstalled userInfo:@{@"reason":@"没有安装微信"}];
            callBack(err, NO);
        }
        return NO;
    } else if (![WXApi isWXAppSupportApi]) {
        if (callBack) {
            NSError *err = [NSError errorWithDomain:@"WXSendErr:" code:WXShareErrCodeNotSupport userInfo:@{@"reason":@"微信当前版本不支持分享"}];
            callBack(err, NO);
        }
        return NO;
    }
    return YES;
}

+ (void)shareText:(NSString *)text withCallBack:(sendCallBack)callBack {
    if (![self checkShareableWithCallBack:callBack]) {
        return;
    }
    [self resetCallBack:callBack];
    NSUInteger length = [[text dataUsingEncoding:NSUTF8StringEncoding] length];
    NSString *errorString = nil;
    WXShareErrorCode errCode = -1;
    if (length == 0) {
        errorString = @"不能发送空数据";
    }else if (length > 10 * 1024 * 1024) {
        errCode = WXShareErrCodeTextTooLong;
        errorString = @"不能发送超过10M的数据";
    }else {
        SendMessageToWXReq *req = [[[SendMessageToWXReq alloc] init] autorelease];
        req.text = text;
        req.bText = YES;
        req.scene = _scene;
        BOOL isSuccess = [WXApi sendReq:req];
        if (!isSuccess) {
            errCode = WXShareErrCodeUnkonwn;
            errorString = @"未知原因发送错误";
        }
    }
    if (callBack && errorString) {
        NSError *err = [NSError errorWithDomain:@"WXSendErr:" code:errCode userInfo:@{@"reason":errorString}];
        callBack(err, NO);
    }
}

+ (void)shareImage:(UIImage *)image previewImage:(UIImage *)previewImage withCallBack:(sendCallBack)callBack {
    if (![self checkShareableWithCallBack:callBack]) {
        return;
    }
    [self resetCallBack:callBack];
    NSString *errorString = nil;
    WXShareErrorCode errCode = -1;
    NSUInteger preImageLength = [UIImagePNGRepresentation(previewImage) length];
    NSUInteger imageLength = [UIImagePNGRepresentation(image) length];
    if (!([image isKindOfClass:[UIImage class]] || [previewImage isKindOfClass:[UIImage class]])) {
        errorString = @"发送的不是图片";
    }else if (preImageLength > 32 * 1024) {
        errCode = WXShareErrCodePreImgTooBig;
        errorString = @"预览图片大小不能超过32K";
    }else if (imageLength > 10 * 1024 * 1024) {
        errCode = WXShareErrCodeImgTooBig;
        errorString = @"图片大小不能超过10M";
    }else {
        WXMediaMessage *message = [WXMediaMessage message];
        [message setThumbImage:previewImage];
        
        WXImageObject *ext = [WXImageObject object];
        ext.imageData = UIImagePNGRepresentation(image);
        
        message.mediaObject = ext;
        
        SendMessageToWXReq *req = [[[SendMessageToWXReq alloc] init]autorelease];
        req.bText = NO;
        req.message = message;
        req.scene = _scene;
        BOOL isSuccess = [WXApi sendReq:req];
        if (!isSuccess) {
            errCode = WXShareErrCodeUnkonwn;
            errorString = @"未知原因发送错误";
        }
    }
    
    if (callBack && errorString) {
        NSError *err = [NSError errorWithDomain:@"WXSendErr:" code:errCode userInfo:@{@"reason":errorString}];
        callBack(err, NO);
    }
}

+ (void)shareWebPage:(NSString *)webPageUrl withTitle:(NSString *)title description:(NSString *)description andCallBack:(sendCallBack)callBack {
    [self shareWebPage:webPageUrl withTitle:title description:description thumbImage:nil andCallBack:callBack];
}

+ (void)shareWebPage:(NSString *)webPageUrl withTitle:(NSString *)title description:(NSString *)description thumbImage:(UIImage *)thumbImage andCallBack:(sendCallBack)callBack {
    if (![self checkShareableWithCallBack:callBack]) {
        return;
    }
    [self resetCallBack:callBack];
    NSString *errorString = nil;
    WXShareErrorCode errCode = -1;
    NSString *shareTitle = @"";
    NSString *shareDescription = @"";
    if (title) {
        shareTitle = title;
    }
    if (description) {
        shareDescription = description;
    }
    if (!webPageUrl && webPageUrl.length == 0) {
        errCode = WXShareErrCodeWebUrlIsNull;
        errorString = @"网页链接地址错误";
    } else {
        WXMediaMessage *message = [WXMediaMessage message];
        [message setTitle:shareTitle];
        [message setDescription:shareDescription];
        
        if (thumbImage) {
            NSData  *imageData    = UIImageJPEGRepresentation(thumbImage, 0.6);
            double   factor       = 1.0;
            double   adjustment   = 1.0 / sqrt(2.0);  // or use 0.8 or whatever you want
            CGSize   size         = thumbImage.size;
            CGSize   currentSize  = size;
            UIImage *currentImage = thumbImage;
            
            while (imageData.length > (1024 * 32))
            {
                factor      *= adjustment;
                currentSize  = CGSizeMake(roundf(size.width * factor), roundf(size.height * factor));
                currentImage = [thumbImage resizedImage:currentSize interpolationQuality:kCGInterpolationLow];
                imageData    = UIImageJPEGRepresentation(currentImage, kCGInterpolationLow);
            }
            NSData *thumbData = imageData;
            [message setThumbData:thumbData];
        } else {
            UIImage *image = [UIImage imageNamed:@"Icon.png"];
            NSData *imageData    = UIImageJPEGRepresentation(image, kCGInterpolationLow);
            [message setThumbData:imageData];
        }
        
        WXWebpageObject *webPageObject = [WXWebpageObject object];
        webPageObject.webpageUrl = webPageUrl;
        
        message.mediaObject = webPageObject;
        
        SendMessageToWXReq* req = [[[SendMessageToWXReq alloc] init]autorelease];
        req.bText = NO;
        req.message = message;
        req.scene = _scene;
        BOOL isSuccess = [WXApi sendReq:req];
        if (!isSuccess) {
            errCode = WXShareErrCodeUnkonwn;
            errorString = @"未知原因发送错误";
        }
    }
    if (callBack && errorString) {
        NSError *err = [NSError errorWithDomain:@"WXSendErr:" code:errCode userInfo:@{@"reason":errorString}];
        callBack(err, NO);
    }
}

+ (void)changeSence:(enum WXScene)scene {
    _scene = scene;
}

+ (void)onResp:(BaseResp *)resp {
    if ([resp isKindOfClass:[SendMessageToWXResp class]]) {
        if (_g_callBack) {
            NSString *errorString = @"发送成功";
            NSError *err = [NSError errorWithDomain:@"WXSendErr:" code:resp.errCode userInfo:@{@"reason":errorString}];
            BOOL success = resp.errCode == WXShareSuccess;
            _g_callBack(err, success);
        }
    }
}

+ (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    return  [WXApi handleOpenURL:url delegate:self];
}

+ (BOOL)shouldBeHandledByWXSDK:(NSURL *)url {
    NSString *urlString = [url absoluteString];
    return [urlString rangeOfString:[WXShare shareKey]].location != NSNotFound;
}

+ (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [WXApi handleOpenURL:url delegate:self];
}

+ (NSString *)errStringWithError:(NSError *)err {
    if ([err.domain isEqualToString:@"WXSendErr:"]) {
        return [err.userInfo objectForKey:@"reason"];
    }
    return @"unknown error";
}

@end

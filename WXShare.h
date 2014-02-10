#import <Foundation/Foundation.h>
#import "WXApi.h"

typedef void (^sendCallBack) (NSError *, BOOL isSuccess);

typedef enum {
    WXShareSuccess              = 0,        /**< 成功    */
    WXShareErrCodeUnkonwn       = -100,     /**< 未知原因错误 */
    WXShareErrCodeCommon        = -1,       /**< 普通错误类型    */
    WXShareErrCodeUserCancel    = -2,       /**< 用户点击取消并返回    */
    WXShareErrCodeSentFail      = -3,       /**< 发送失败    */
    WXShareErrCodeAuthDeny      = -4,       /**< 授权失败    */
    WXShareErrCodeUnsupport     = -5,       /**< 微信不支持    */
    WXShareErrCodeTextTooLong   = -6,       /**< 文字内容太长 */
    WXShareErrCodePreImgTooBig  = -7,       /**< 预览图片太大 */
    WXShareErrCodeImgTooBig     = -8,       /**< 图片太大 */
    WXShareErrCodeNotInstalled  = -9,       /**< 没有安装微信 */
    WXShareErrCodeNotSupport    = -10,      /**< 微信当前版本不支持分享 */
    WXShareErrCodeWebUrlIsNull    = -11,      /**< 网页链接地址错误 */
} WXShareErrorCode;

@interface WXShare : NSObject
/*
 must be called befor use
 */
+ (void)initWXShare;

/*
 share text to weixin 
 NOTE:text content must be in (0:10K]
 */
+ (void)shareText:(NSString *)text withCallBack:(sendCallBack)callBack;

/*
 share image to weixin
 */
+ (void)shareImage:(UIImage *)image previewImage:(UIImage *)previewImage withCallBack:(sendCallBack)callBack;

/*
 share web url to weixin
 */
+ (void)shareWebPage:(NSString *)webPageUrl withTitle:(NSString *)title description:(NSString *)description andCallBack:(sendCallBack)callBack;

+ (void)shareWebPage:(NSString *)webPageUrl withTitle:(NSString *)title description:(NSString *)description thumbImage:(UIImage *)thumbImage andCallBack:(sendCallBack)callBack;


/*
 切换分享的目标
 */
+ (void)changeSence:(enum WXScene)scene;

/*
 called by wxsdk after send message to wx
 */
+ (void)onResp:(BaseResp *)resp;

/*
 这个url是否应该被wxSDK处理
 */
+ (BOOL)shouldBeHandledByWXSDK:(NSURL *)url;
/*
 handle URL open from weixin after send wx message
 */
+ (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation;

/*
 should just be used for NSError returned by WXShare
 */
+ (NSString *)errStringWithError:(NSError *)err;

@end

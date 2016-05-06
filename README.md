# DynamicPatchManager
开源自己封装的JSPatch库,实现自动下载自动执行补丁等

##返回当前脚本
- (NSString *)decryptPatchScript;

##执行本地MainBundle中的脚本
- (void)evaluateScriptInMainBundleForName:(NSString *)name type:(NSString *)type;

##执行已经请求的最新脚本，Block返回脚本信息
- (void)excutePatchScript:(DynamicPatchReturnBlock)completeBlock;

##请求最新脚本，Block返回脚本信息
- (void)requestPatchScriptWithCompleteBlock:(DynamicPatchReturnBlock)completeBlock;



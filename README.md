# IM_XMPP
使用了XMPPFrame和JFKit工具；



# 使用

- 配置`OTCIMCenter+Server.m`的ip和port
```
- (NSString*) serverHost {
    // APNetworkClientAPIBaseURLString = @"http://192.168.1.120:8889"
    NSRange httpRange = [APNetworkClientAPIBaseURLString rangeOfString:@"http://"];
    NSString* ip = [APNetworkClientAPIBaseURLString substringFromIndex:httpRange.location + httpRange.length];
    NSRange portRange = [ip rangeOfString:@":"];
    ip = [ip substringToIndex:portRange.location];
    return ip;
}
- (int16_t) serverPort {
    return 5222;
}

```

- 对接后台的异步上传图片接口
```
/**
 上传图片
 */
- (void)uploadIMImage:(UIImage *)image success:(SuccessCallback)success failure:(FailureCallback)failure
            serverFailure:(ServerFailureCallback)sFailure;
```

- 对接后台的用户信息(昵称、头像等)查询接口

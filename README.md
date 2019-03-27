# ESPJPhoneSDK
简单封装拨打电话功能的sdk
typedef NS_ENUM(NSUInteger, ESPJPhoneCallStatus) {
    ESPJPhoneCallStatus_NULL=0,           /**< 在发送或接收邀请之前*/
    ESPJPhoneCallStatus_CALLING,          /**< 发出邀请后*/
    ESPJPhoneCallStatus_INCOMING,         /**< 收到邀请后*/
    ESPJPhoneCallStatus_EARLY,            /**< 响应*/
    ESPJPhoneCallStatus_CONNECTING,       /**< 呼叫中*/
    ESPJPhoneCallStatus_CONFIRMED,        /**< 接通*/
    ESPJPhoneCallStatus_DISCONNECTED,     /**< 挂断*/
};


/**
 所有的sipserver事件都会回调此方法
 @param message 返回消息对象
 */
- (void)onEventMessageHandler:(ESPMessage *)message;


/**
 通话状态的变化 可根据onEventMessageHandler获取通话的信息
 */
- (void)onCallStatusChanged:(ESPJPhoneCallStatus)callStatus;


/**
 创建SUA
 SUA初始化配置
 在appDelegate中进行
 */
-(BOOL)startESPJSUA;

/*
 * @brief 注册分机
 * @param sipServerUrl - sipServer服务器地址
 * @param dnNumber - 分机号码
 * @param dnPassword - 分机密码
 */
-(BOOL)ESClientRegister:(NSString *)sipServerUrl dnNumber:(NSString*)dnNumber dnPassword:(NSString*)dnPassword;

/*
 * @brief 分机取消注册
 */
-(BOOL)ESClientUnRegister;


/*
 * @brief 拨打
 * @param phoneNumber - 呼叫的号码
 */
-(BOOL)ESClientMakeCall:(NSString*)phoneNumber;

/*
 * @brief 接听
 * @param connId - 呼叫标识
 */
-(BOOL)ESClientAnswerCall:(NSString*)connId;

/*
 * @brief 挂断
 * @param connId - 呼叫标识
 */
-(BOOL)ESClientReleaseCall:(NSString*)connId;

/*
 * @brief 保持
 * @param connId - 呼叫标识
 */
-(void)ESClientHoldCall:(NSString*)connId;

/*
 * @brief 取回保持
 * @param connId - 呼叫标识
 */
-(void)ESClientRetriveCall:(NSString*)connId;

/*
 * @brief 转接
 * @param phoneNumber - 转接号码
 * @param connId - 呼叫标识
 */
-(void)ESClientReferCall:(NSString* )phoneNumber connId:(NSString*)connId;


/*
 * @brief 会议通话
 * @param phoneNumber - 邀请会议号码
 * @param connId - 呼叫标识
 */
-(void)ESClientConferenceCall:(NSString* )phoneNumber;


/**
 挂断
 @param callid - 呼叫标识
 @param requestMessage - 结束语
 */
-(void)ESClientHangup:(NSInteger)callid requestMessage:(NSString*)requestMessage;



/**
 登出
 */
-(BOOL)ESClientLogOut;

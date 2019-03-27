//
//  SocketRocketUtility.m
//  
//
//  Created by 赖长宽 on 2017/9/13.
//
//

#import "SocketRocketUtility.h"
#import "SRWebSocket.h"
#import <UIKit/UIKit.h>
#import "ESAFNetworking.h"
@interface SocketRocketUtility()<SRWebSocketDelegate>
{
    int _index;
    NSString *_sessionId;
    NSTimeInterval reConnectTime;
    AFHTTPSessionManager*   manger;
    NSString * _connId;
    NSString * _connId2;
    BOOL  isS;

}

@property (nonatomic,strong) SRWebSocket *socket;
@property (nonatomic,strong)     NSTimer * heartBeat;

@end
@implementation SocketRocketUtility

+(SocketRocketUtility *)instance{
    static SocketRocketUtility *Instance = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        Instance = [[SocketRocketUtility alloc] init];
    });
    return Instance;
}

//开启连接
-(void)socketOpen{
    
    if (self.socket) {
        return;
    }
    [self getseoonid];

}
//关闭连接
-(void)socketClose{
    if (self.socket){
        [self.socket close];
        self.socket = nil;
        //断开连接时销毁心跳
        [self destoryHeartBeat];
    }
}

#pragma mark - socket delegate
- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
    NSLog(@"连接成功，可以与服务器交流了,同时需要开启心跳");
    if ([self.CTIserver rangeOfString:@"http://"].location == NSNotFound)
self.CTIserver=[NSString stringWithFormat:@"http://%@",self.CTIserver];
    
    [self online];
    //每次正常连接的时候清零重连时间
    reConnectTime = 0;
    //开启心跳
    [self initHeartBeat];
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"" object:nil];
    
    [self performSelector:@selector(yanchi) withObject:nil afterDelay:0.3];
    
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error
{
    NSLog(@"连接失败，这里可以实现掉线自动重连，要注意以下几点");
    NSLog(@"1.判断当前网络环境，如果断网了就不要连了，等待网络到来，在发起重连");
    NSLog(@"2.判断调用层是否需要连接，例如用户都没在聊天界面，连接上去浪费流量");
//    NSLog(@"3.连接次数限制，如果连接失败了，重试10次左右就可以了，不然就死循环了。)";
          _socket = nil;
          //连接失败就重连
          [self reConnect];
}
          
- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean
{
    //NSString *strlog=[NSString stringWithFormat:@"被关闭连接，code:%ld,reason:%@,wasClean:%d",(long)code,reason,wasClean];
        //断开连接 同时销毁心跳
              [self socketClose];
//    UIAlertView * alert = [[UIAlertView alloc]initWithTitle:@"websocket被关闭了" message:strlog delegate:self cancelButtonTitle:nil otherButtonTitles:@"确定", nil];
//    [alert show];
    
}
/*该函数是接收服务器发送的pong消息，其中最后一个是接受pong消息的，
     在这里就要提一下心跳包，一般情况下建立长连接都会建立一个心跳包，
     用于每隔一段时间通知一次服务端，客户端还是在线，这个心跳包其实就是一个ping消息，
     我的理解就是建立一个定时器，每隔十秒或者十五秒向服务端发送一个ping消息，这个消息可是是空的
 */
-(void)webSocket:(SRWebSocket *)webSocket didReceivePong:(NSData *)pongPayload{
              
              NSString *reply = [[NSString alloc] initWithData:pongPayload encoding:NSUTF8StringEncoding];
              NSLog(@"reply===%@",reply);
}
          
- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message
{
//收到服务器发过来的数据 这里的数据可以和后台约定一个格式 我约定的就是一个字符串 收到以后发送通知到外层 根据类型 实现不同的操作
    NSData *jsonData = [message dataUsingEncoding:NSUTF8StringEncoding];
    
    NSError *err;
    
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                         
                                                        options:NSJSONReadingMutableContainers
                         
                                                          error:&err];
    NSLog(@"-++++%@",dic);
    
    if (dic[@"data"][@"call"]&&!isS) {
        
      _connId=dic[@"data"][@"call"][@"connId"];
        NSLog(@"00000111111_connId%@",_connId);

        
    }else if (dic[@"data"][@"call"]&&isS){
        
        _connId2=dic[@"data"][@"call"][@"connId"];
        NSLog(@"00000111112_connId2%@",_connId2);
    }
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"socketdidReceiveMessage" object:nil userInfo:dic];

    });
}
          
#pragma mark - methods
          //重连机制
- (void)reConnect
    {
        [self socketClose];
        
        //超过一分钟就不再重连 所以只会重连5次 2^5 = 64
        if (reConnectTime > 64) {
            return;
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(reConnectTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.socket = nil;
            [self socketOpen];
        });
        
        //重连时间2的指数级增长
        if (reConnectTime == 0) {
            reConnectTime = 2;
        }else{
            reConnectTime *= 2;
        }
}
          
          //初始化心跳
- (void)initHeartBeat
    {
        dispatch_async(dispatch_get_main_queue(), ^{
           
            //__weak typeof(self) weakSelf = self;
            //心跳设置为3分钟，NAT超时一般为5分钟
            self.heartBeat=[NSTimer timerWithTimeInterval:30 target:self selector:@selector(xintiaohttp) userInfo:nil repeats:YES];
            
            
//           self.heartBeat = [NSTimer scheduledTimerWithTimeInterval:30 repeats:YES block:^(NSTimer * _Nonnull timer) {
//                [self xintiaohttp];
//
//                //和服务端约定好发送什么作为心跳标识，尽可能的减小心跳包大小
//                [weakSelf sendData:@"heart"];
//            }];
            [[NSRunLoop currentRunLoop]addTimer:self.heartBeat forMode:NSRunLoopCommonModes];
            
        });

    }
          
          //取消心跳
- (void)destoryHeartBeat
    {
//        dispatch_main_async_safe(^{
            if (self.heartBeat) {
                [self.heartBeat invalidate];
                self.heartBeat = nil;
            }
//        });
    }
          
          //pingPong机制
- (void)ping{
            [self.socket sendPing:nil];
}
          
          
#define WeakSelf(ws) __weak __typeof(&*self)weakSelf = self
- (void)sendData:(id)data {
              
              WeakSelf(ws);
              dispatch_queue_t queue =  dispatch_queue_create("zy", NULL);
              
              dispatch_async(queue, ^{
                  if (weakSelf.socket != nil) {
                      // 只有 SR_OPEN 开启状态才能调 send 方法啊，不然要崩
                      if (weakSelf.socket.readyState == SR_OPEN) {
                          [weakSelf.socket send:data];    // 发送数据
                          
                      } else if (weakSelf.socket.readyState == SR_CONNECTING) {
                          NSLog(@"正在连接中，重连后其他方法会去自动同步数据");
                          // 每隔2秒检测一次 socket.readyState 状态，检测 10 次左右
                          // 只要有一次状态是 SR_OPEN 的就调用 [ws.socket send:data] 发送数据
                          // 如果 10 次都还是没连上的，那这个发送请求就丢失了，这种情况是服务器的问题了，小概率的
                          [self reConnect];
                          
                      } else if (weakSelf.socket.readyState == SR_CLOSING || weakSelf.socket.readyState == SR_CLOSED) {
                          // websocket 断开了，调用 reConnect 方法重连
                          [self reConnect];
                      }
                  } else {
                      NSLog(@"没网络，发送失败，一旦断网 socket 会被我设置 nil 的");
                  }
              });
}
-(void)dealloc{
              [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)xintiaohttp
{
                    [self sendData:@"heart"];
    
    if ([self.CTIserver rangeOfString:@"http://"].location == NSNotFound) {
        
        self.CTIserver=[NSString stringWithFormat:@"http://%@",self.CTIserver];

    } else {
//        NSLog(@"string 包含 martin");
    }

    NSString* strurl=[NSString stringWithFormat:@"%@/api/v1/me/heart/%@/%@",self.CTIserver,self.userName,self.CTIName];
    
    [manger GET:strurl parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
        
        
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
                        NSLog(@"heart");
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
      
        NSLog(@"%@",error);
    }];
    
    
    
}
-(void)getseoonid
{

    manger=[AFHTTPSessionManager manager];
    
    manger.requestSerializer = [AFJSONRequestSerializer serializer];
    
    
    manger.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", @"text/html",@"text/plain", nil];

    
    NSDictionary* dic=@{@"operationName":@"StartContactCenterSession",@"channels":@[@"voice"],@"place":_userName,@"loginCode":_CTIName};
    NSString * uri=[NSString stringWithFormat:@"%@/api/v1/me",[NSString stringWithFormat:@"http://%@", self.CTIserver]];

    [manger POST:uri parameters:dic progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
    
        self->_sessionId=responseObject[@"sessionId"];
        [self lianjiesession];
        NSLog(@"-sessionId%@", responseObject);

    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        NSLog(@"getseoonid%@",error);
        
    }];

   
}
-(void)lianjiesession
{
    
    NSString * socketurl=[NSString stringWithFormat:@"ws://%@/websocket/softphone/%@",self.CTIserver,_sessionId];
    //SRWebSocketUrlString 就是websocket的地址
    self.socket = [[SRWebSocket alloc] initWithURLRequest:
                   [NSURLRequest requestWithURL:[NSURL URLWithString:socketurl]]];
    
    self.socket.delegate = self;   //SRWebSocketDelegate 协议
    [self.socket open];     //open 就是直接连接了
//    [self performSelector:@selector(yanchi) withObject:nil afterDelay:0.5];
    
}
-(void)yanchi
{


}
-(void)online
{
    
    NSDictionary* dic=@{@"operationName":@"Online"};
    NSString * strurl=[NSString stringWithFormat:@"%@/api/v1/me/channel/voice/%@",self.CTIserver,_sessionId];
    
    NSLog(@"strurl%@",strurl);
    [manger POST:strurl parameters:dic progress:^(NSProgress * _Nonnull uploadProgress) {
        
        
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        [self ready];
        
        NSLog(@"-online%@", responseObject);
        
        if (self.block) {
            
            self.block(responseObject);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        
        
    }];
    
    
}
-(void)ready
{
    
    NSDictionary* dic=@{@"operationName":@"Ready"};
    NSString * strurl=[NSString stringWithFormat:@"%@/api/v1/me/channel/voice/%@",self.CTIserver,_sessionId];
    
    [manger POST:strurl parameters:dic progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        NSLog(@"-----%@", error);
        
    }];


}
-(void)notReady
{
   
   
    NSDictionary* dic=@{@"operationName":@"NotReady"};
    NSString * strurl=[NSString stringWithFormat:@"%@/api/v1/me/channel/voice/%@",self.CTIserver,_sessionId];
    
    [manger POST:strurl parameters:dic progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        NSLog(@"notReadyerror%@",error);
        
    }];

}
-(void)loginOut
{
    NSDictionary* dic=@{@"operationName":@"Offline"};
    NSString * strurl=[NSString stringWithFormat:@"%@/api/v1/me/channel/voice/%@",_CTIserver,_sessionId];
    
    [manger POST:strurl parameters:dic progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        
        
    }];
    
    
    
}


-(void)dialingPhoneNumber:(NSString*)phoneNumber;
{
    NSDictionary* dic=@{@"operationName":@"Dial",@"destination":@{@"phoneNumber":phoneNumber}};


    NSString * strurl=[NSString stringWithFormat:@"%@/api/v1/me/devices/%@/calls",_CTIserver,_sessionId];
    [manger POST:strurl parameters:dic progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        
    } failure:^(NSURLSessionDataTask * _Nullable  task, NSError * _Nonnull error) {
        
        NSLog(@"error%@",error);
        
    }];


}
-(void)answer
{


    NSDictionary* dic=@{@"operationName":@"Answer",@"connId":_connId};
    
    
    NSString * strurl=[NSString stringWithFormat:@"%@/api/v1/me/calls/%@",self.CTIserver,_sessionId];
    
    [manger POST:strurl parameters:dic progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        
        
    } failure:^(NSURLSessionDataTask * _Nullable  task, NSError * _Nonnull error) {
        
        
        
    }];


}
-(void)reject
{
    NSDictionary* dic=@{@"operationName":@"Reject",@"connId":_connId};


    NSString * strurl=[NSString stringWithFormat:@"%@/api/v1/me/calls/%@",self.CTIserver,_sessionId];
    [manger POST:strurl parameters:dic progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        
        
    } failure:^(NSURLSessionDataTask * _Nullable  task, NSError * _Nonnull error) {
        
        
        
    }];

  


}
-(void)hangup
{

    NSDictionary* dic=@{@"operationName":@"Hangup",@"connId":_connId};
    
    
    NSString * strurl=[NSString stringWithFormat:@"%@/api/v1/me/calls/%@",self.CTIserver,_sessionId];
    [manger POST:strurl parameters:dic progress:^(NSProgress * _Nonnull uploadProgress) {
        
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        
        
    } failure:^(NSURLSessionDataTask * _Nullable  task, NSError * _Nonnull error) {
        
        
        
    }];

}
-(void)muteCall
{
    
    NSDictionary* dic=@{@"operationName":@"MuteCall",@"connId":_connId};
    
    
    NSString * strurl=[NSString stringWithFormat:@"%@/api/v1/me/calls/%@",self.CTIserver,_sessionId];
    [manger POST:strurl parameters:dic progress:^(NSProgress * _Nonnull uploadProgress) {
        
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        
        
    } failure:^(NSURLSessionDataTask * _Nullable  task, NSError * _Nonnull error) {
        
        
        
    }];
    
    

}
-(void)unmuteCall
{
    
    NSDictionary* dic=@{@"operationName":@"UnmuteCall",@"connId":_connId};
    
    
    NSString * strurl=[NSString stringWithFormat:@"%@/api/v1/me/calls/%@",self.CTIserver,_sessionId];
    [manger POST:strurl parameters:dic progress:^(NSProgress * _Nonnull uploadProgress) {
        
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        
        
    } failure:^(NSURLSessionDataTask * _Nullable  task, NSError * _Nonnull error) {
        
        
        
    }];
    
    
    
}
/*****************************************************************************
 *  班长功能
 */

// 单步会议
-(void)SingleStepConference:(NSString* )phoneNumber
{
    
    NSDictionary* dic=@{@"operationName":@"SingleStepConference",@"destination":@{
                                @"phoneNumber":phoneNumber
                                },@"connId":_connId};
    
    
    NSString * strurl=[NSString stringWithFormat:@"%@/api/v1/me/calls/%@",self.CTIserver,_sessionId];
    [manger POST:strurl parameters:dic progress:^(NSProgress * _Nonnull uploadProgress) {
        
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        
        
    } failure:^(NSURLSessionDataTask * _Nullable  task, NSError * _Nonnull error) {
        
        
        
    }];
    
    
}

-(void)InitiateConference:(NSString *)phoneNumber
{
    
    NSDictionary* dic=@{@"operationName":@"InitiateConference",@"connId":_connId,@"destination":@{
                                @"phoneNumber":phoneNumber
                                }};
    
    
    NSString * strurl=[NSString stringWithFormat:@"%@/api/v1/me/calls/%@",self.CTIserver,_sessionId];
    
    
    NSLog(@"--------------%@",dic);
    
    
    [manger POST:strurl parameters:dic progress:^(NSProgress * _Nonnull uploadProgress) {
        
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        self->isS=YES;
        
    } failure:^(NSURLSessionDataTask * _Nullable  task, NSError * _Nonnull error) {
        
        
        
    }];
    
    
    
}
// 完成会议
-(void)CompleteConference
{
    if (!isS) return;
    
    NSDictionary* dic=@{@"operationName":@"CompleteConference",@"connId":_connId,@"transferConnId":_connId2};
    
    
    NSString * strurl=[NSString stringWithFormat:@"%@/api/v1/me/calls/%@",self.CTIserver,_sessionId];
    
    
    NSLog(@"--------------%@",dic);
    
    
    [manger POST:strurl parameters:dic progress:^(NSProgress * _Nonnull uploadProgress) {
        
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        self->isS=NO;
        
        
    } failure:^(NSURLSessionDataTask * _Nullable  task, NSError * _Nonnull error) {
        
        
        
    }];
    
    
}
// 单步转接
-(void)SingleStepTransfer:(NSString* )phoneNumber connId:(NSString*)connId
{
    
    if (!_connId) {
        return;
    }
    
    NSDictionary* dic=@{@"operationName":@"SingleStepTransfer",@"destination":@{
                                @"phoneNumber":phoneNumber
                                },@"connId":_connId};
    
    
    NSString * strurl=[NSString stringWithFormat:@"%@/api/v1/me/calls/%@",self.CTIserver,_sessionId];
    [manger POST:strurl parameters:dic progress:^(NSProgress * _Nonnull uploadProgress) {
        
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSLog(@"SingleStepTransfer%@",responseObject);
        
    } failure:^(NSURLSessionDataTask * _Nullable  task, NSError * _Nonnull error) {
        
        NSLog(@"%@",error);
        
    }];
    
    
}
//InitiateTransfer开始转接
//发起开始两步转接请求


-(void)InitiateTransfer:(NSString* )phoneNumber
{
    NSDictionary* dic=@{@"operationName":@"InitiateTransfer",@"connId":_connId,@"destination":@{
                                @"phoneNumber":phoneNumber
                                }};
    
   
    NSString * strurl=[NSString stringWithFormat:@"%@/api/v1/me/calls/%@",self.CTIserver,_sessionId];
    
    
    NSLog(@"--------------%@",dic);
    
    
    [manger POST:strurl parameters:dic progress:^(NSProgress * _Nonnull uploadProgress) {
        
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        self->isS=YES;
        
    } failure:^(NSURLSessionDataTask * _Nullable  task, NSError * _Nonnull error) {
        
        
        
    }];
    
    
}

-(void)CompleteTransfer
{
    if (!isS) return;

    NSDictionary* dic=@{@"operationName":@"CompleteTransfer",@"connId":_connId,@"transferConnId":_connId2};
    
    
    NSString * strurl=[NSString stringWithFormat:@"%@/api/v1/me/calls/%@",self.CTIserver,_sessionId];
    
    
    NSLog(@"--------------%@",dic);
    
    
    [manger POST:strurl parameters:dic progress:^(NSProgress * _Nonnull uploadProgress) {
        
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        self->isS=NO;
        
        
    } failure:^(NSURLSessionDataTask * _Nullable  task, NSError * _Nonnull error) {
        
        
        
    }];
    
    
}
//ListenIn静音监听
-(void)ListenIn
{
    
    NSDictionary* dic=@{@"operationName":@"ListenIn"};
    
    
    NSString * strurl=[NSString stringWithFormat:@"%@/api/v1/me/devices/%@",self.CTIserver,_sessionId];
    [manger POST:strurl parameters:dic progress:^(NSProgress * _Nonnull uploadProgress) {
        
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        
        
    } failure:^(NSURLSessionDataTask * _Nullable  task, NSError * _Nonnull error) {
        
        
        
    }];
    
    
}
//Coach耳语监听
-(void)CoachWithtargetDeviceUri:(NSString *)DeviceUri
{
    NSDictionary* dic=@{@"operationName":@"Coach",@"targetDeviceUri":DeviceUri};
    
    
    NSString * strurl=[NSString stringWithFormat:@"%@/api/v1/me/devices/%@",self.CTIserver,_sessionId];
    [manger POST:strurl parameters:dic progress:^(NSProgress * _Nonnull uploadProgress) {
        
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        
        
    } failure:^(NSURLSessionDataTask * _Nullable  task, NSError * _Nonnull error) {
        
        
        
    }];
    
    
}
//BargeIn强插
-(void)BargeInWithtargetDeviceUri:(NSString *)DeviceUri
{
    
    NSDictionary* dic=@{@"operationName":@"Coach",@"targetDeviceUri":DeviceUri,@"connId":_connId};
    
    
    NSString * strurl=[NSString stringWithFormat:@"%@/api/v1/me/devices/%@",self.CTIserver,_sessionId];
    [manger POST:strurl parameters:dic progress:^(NSProgress * _Nonnull uploadProgress) {
        
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        
        
    } failure:^(NSURLSessionDataTask * _Nullable  task, NSError * _Nonnull error) {
        
        
        
    }];
    
    
    
}
//ForceOut强拆
-(void)ForceOutWithtargetDeviceUri:(NSString *)DeviceUri hasBargeIn:(BOOL)hasBargeIn
{
    
    NSDictionary* dic=@{@"operationName":@"ForceOut",@"targetDeviceUri":DeviceUri,@"connId":_connId,@"hasBargeIn":@(hasBargeIn)};
    
    
    NSString * strurl=[NSString stringWithFormat:@"%@/api/v1/me/devices/%@",self.CTIserver,_sessionId];
    [manger POST:strurl parameters:dic progress:^(NSProgress * _Nonnull uploadProgress) {
        
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        
        
    } failure:^(NSURLSessionDataTask * _Nullable  task, NSError * _Nonnull error) {
        
        
        
    }];
    
    
    
}
//班长取消监听CancelSupervisionMonitoring
-(void)CancelSupervisionMonitoringWithtargetDeviceUri:(NSString *)DeviceUri
{
    NSDictionary* dic=@{@"operationName":@"CancelSupervisionMonitoring",@"targetDeviceUri":DeviceUri};
    
    
    NSString * strurl=[NSString stringWithFormat:@"%@/api/v1/me/devices/%@",self.CTIserver,_sessionId];
    [manger POST:strurl parameters:dic progress:^(NSProgress * _Nonnull uploadProgress) {
        
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        
        
    } failure:^(NSURLSessionDataTask * _Nullable  task, NSError * _Nonnull error) {
        
        
        
    }];
    
    
}
@end

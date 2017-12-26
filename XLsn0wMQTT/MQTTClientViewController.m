
#import "MQTTClientViewController.h"

#define kHost @""///网址IP
#define kPort @""//端口port
#define kTopic @""//主题

@interface MQTTClientViewController () <MQTTSessionManagerDelegate, MQTTSessionDelegate>

@property (strong, nonatomic) MQTTSessionManager *sessionManager;

@end

@implementation MQTTClientViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self addMQTTClient];
}

- (void)addMQTTClient {
    /*
     * MQTTClient: create an instance of MQTTSessionManager once and connect
     * will is set to let the x x xbroker indicate to other subscribers if the connection is lost
     */
    if (!self.sessionManager) {
        self.sessionManager = [[MQTTSessionManager alloc] init];//new
        self.sessionManager.delegate = self;//delegate
        self.sessionManager.subscriptions = @{@"topic" : @2};
        
        /// connect to IP
        [self.sessionManager connectTo:@"192.168.1.4" //服务器地址
         
                                  port:1883 //服务端端口号
         
                                   tls:true //是否使用tls协议，mosca是支持tls的，如果使用了要设置成true
         
                             keepalive:60 //心跳时间，单位秒，每隔固定时间发送心跳包
         
                                 clean:false //session是否清除，这个需要注意，如果是false，代表保持登录，如果客户端离线了再次登录就可以接收到离线消息。注意：QoS为1和QoS为2，并需订阅和发送一致
         
                                  auth:true //是否使用登录验证，和下面的user和pass参数组合使用
         
                                  user:@"userName" //用户名
         
                                  pass:@"password" //密码
         
                             willTopic:@"" //下面四个参数用来设置如果客户端异常离线发送的消息，当前参数是哪个topic用来传输异常离线消息，这里的异常离线消息都指的是客户端掉线后发送的掉线消息
         
                                  will:@"" //异常离线消息体。自定义的异常离线消息，约定好格式就可以了
         
                               willQos:0 //接收离线消息的级别 0、1、2
         
                        willRetainFlag:false //只有在为true时，Will Qos和Will Retain才会被读取，此时消息体payload中要出现Will Topic和Will Message具体内容，否则，Will QoS和Will Retain值会被忽略掉
         
                          withClientId:nil]; //客户端id，需要特别指出的是这个id需要全局唯一，因为服务端是根据这个来区分不同的客户端的，默认情况下一个id登录后，假如有另外的连接以这个id登录，上一个连接会被踢下线
    } else {
        [self.sessionManager connectToLast];
    }
    
    /*
     * MQTTCLient: observe the MQTTSessionManager's state to display the connection status
     * add Observer 添加观察者模式  监听sessionManager状态
     */
    [self.sessionManager addObserver:self
                   forKeyPath:@"state"
                      options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                      context:nil];
}


/**
 
 #import "MQTTClient.h"
 设置<MQTTSessionDelegate>
 //初始化一个传输类型的实例
 MQTTCFSocketTransport *transport = [[MQTTCFSocketTransport alloc] init];
 transport.host = @"localhost";
 transport.port = 1883;
 //创建一个任务
 MQTTSession *session = [[MQTTSession alloc] init];
 //设置任务的传输类型
 session.transport = transport;
 //设置任务的代理为当前类
 session.delegate = self;
 //设置登录账号
 session.clientId = @"clientId";
 
 BOOL isSucess =   [session connectAndWaitTimeout:30];  //this is part of the synchronous API
 if(isSucess){
 　//以下部分是订阅一个主题
 [session subscribeToTopic:@"topic" atLevel:2 subscribeHandler:^(NSError *error, NSArray<NSNumber *> *gQoss){
 
 if (error) {
 
 NSLog(@"Subscription failed %@", error.localizedDescription);
 
 } else {
 
 NSLog(@"Subscription sucessfull! Granted Qos: %@", gQoss);
 
 }
 
 }];
 }
 
 //接收数据
 - (void)newMessage:(MQTTSession *)session
 data:(NSData *)data
 onTopic:(NSString *)topic
 qos:(MQTTQosLevel)qos
 retained:(BOOL)retained
 mid:(unsigned int)mid {
 // this is one of the delegate callbacks
 
 NSLog(@"%@",[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil]);
 
 }
 //发送数据  this is part of the asynchronous API
 [session publishAndWaitData:data
 onTopic:@"topic"
 retain:NO
 qos:MQTTQosLevelAtLeastOnce];
 //主动和服务端断开
 [session disconnect];
 
 //取消订阅主题
 [session unsubscribeTopic:@"topic" unsubscribeHandler:^(NSError *error) {
 
 }];

 *///观察者模式监听状态
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    switch (self.sessionManager.state) {
        case MQTTSessionManagerStateClosed:
            // 关闭
            break;
            
        case MQTTSessionManagerStateClosing:
            // 正在关闭
            break;
            
        case MQTTSessionManagerStateConnected:
            // 已经连接
            break;
            
        case MQTTSessionManagerStateConnecting:
            // 正在连接
            break;
            
        case MQTTSessionManagerStateError:
            // 连接错误
            break;
            
        case MQTTSessionManagerStateStarting:
            break;
            
        default:
            break;
    }///mqtt协议本身支持断线重连，另外单独说明此sdk在app退出到后台后自动断开连接，当回到前台时会自动重新连接 ! ! !
}

- (void)disconnect:(id)sender {
    /*
     * MQTTClient: send goodby message and gracefully disconnect
     */
    //发送消息,返回值msgid大于0代表发送成功
    [self.sessionManager sendData:[@"leaves chat" dataUsingEncoding:NSUTF8StringEncoding]
                     topic:@"要往哪个topic发送消息"
                       qos:2
                    retain:FALSE];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    [self.sessionManager disconnect];// 断开连接
    
    //订阅主题。NSDictionary类型，，key 为 Topic vaule 为 QoS
    //self.manager.subscriptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:MQTTQosLevelExactlyOnce] forKey:@"topic"];
    
    self.sessionManager.subscriptions = @{ @"topic" : @2 };
    
    //发送消息,返回值msgid大于0代表发送成功
    UInt16 msgid = [self.sessionManager sendData:[@"msg" dataUsingEncoding:NSUTF8StringEncoding] //要发送的消息体
                                      topic:@"topic" //要往哪个topic发送消息
                                        qos:MQTTQosLevelExactlyOnce //消息级别
                                     retain:false];
    
    NSLog(@"%d", msgid);
}


/**
 
 clean：值为false，服务器必须在客户端断开之后继续存储/保持客户端的订阅状态。这些状态包括：
 存储订阅的消息QoS1和QoS2消息
 正在发送消息期间连接丢失导致发送失败的消息
 以便当客户端重新连接时以上消息可以被重新传递。
 值为true，服务器需要立刻清理连接状态数据。
 
 topic：客户端如果互相通信，必须在同一订阅主题下，即都订阅了同一个topic，客户端之间是没办法直接通讯的。订阅模型显而易见的好处是群发消息的话只需要发布到topic，所有订阅了这个topic的客户端就可以接收到消息了。好比QQ群的群号，你订阅一个topic 就相当于加入了一个群
 
 qos：这个代表消息的传输方式，QoS说明如下：
 0代表“至多一次”，消息发布完全依赖底层 TCP/IP 网络。会发生消息丢失或重复。这一级别可用于如下情况，环境传感器数据，丢失一次读记录无所谓，因为不久后还会有第二次发送。
 1代表“至少一次”，确保消息到达，但消息重复可能会发生。
 2代表“只有一次”，确保消息到达一次。这一级别可用于如下情况，在计费系统中，消息重复或丢失会导致不正确的结果。 备注：由于服务端采用Mosca实现，Mosca目前只支持到QoS 1
 如果发送的是临时的消息，例如给某topic所有在线的设备发送一条消息，丢失的话也无所谓，0就可以了（客户端登录的时候要指明支持的QoS级别，同时发送消息的时候也要指明这条消息支持的QoS级别），如果需要客户端保证能接收消息，需要指定QoS为1，如果同时需要加入客户端不在线也要能接收到消息，那么客户端登录的时候要指定session的有效性，接收离线消息需要指定服务端要保留客户端的session状态。
 ** retain**：true：表示发送的消息需要一直持久保存（不受服务器重启影响），不但要发送给当前的订阅者，并且以后新来的订阅了此Topic name的订阅者会马上得到推送。
 备注：新来乍到的订阅者，只会取出最新的一个RETAIN flag = 1的消息推送。
 false：仅仅为当前订阅者推送此消息。
 假如服务器收到一个空消息体(zero-length payload)、RETAIN = 1、已存在Topic name的PUBLISH消息，服务器可以删除掉对应的已被持久化的PUBLISH消息。
 连接异常中断通知机制
 在建立连接的时候就把 will（遗嘱）写好保存在服务器，一旦客户端出现异常中断，便会触发服务器发布Will Message消息到Will Topic主题上去，通知Will Topic订阅者，对方因异常退出。
 
 will Topic：用来传输异常离线消息的 topic，这里的异常离线消息都指的是客户端掉线后发送的掉线消息
 will：异常离线消息。自定义的异常离线消息，约定好格式就可以了
 willQos：和发布消息固的QoS含义一样
 willRetainFlag：只有在为true时，Will Qos和Will Retain才会被读取，此时消息体中要出现Will Topic和Will Message具体内容，否则，Will QoS和Will Retain值会被忽略掉
 
 
 Client Identifier(客户端ID)
 
 1-23个字符长度，客户端到服务器的全局唯一标志，如果客户端ID超出23个字符长度，服务器需要返回码为2，标识符被拒绝响应的CONNACK消息。
 处理QoS级别1和2的消息ID中，可以使用到。
 必填项。
 Will Topic
 Will Flag值为1，这里便是Will Topic的内容。QoS级别通过Will QoS字段定义，RETAIN值通过Will RETAIN标识，都定义在可变头里面。
 Will Message
 
 Will Flag若设为1，这里便是Will Message定义消息的内容，对应的主题为Will Topic。如果客户端意外的断开触发服务器PUBLISH此消息。
 长度有可能为0。
 在CONNECT消息中的Will Message是UTF-8编码的，当被服务器发布时则作为二进制的消息体。
 User Name
 如果设置User Name标识，可以在此读取用户名称。一般可用于身份验证。协议建议用户名为不多于12个字符，不是必须。
 Password
 如果设置Password标识，便可读取用户密码。建议密码为12个字符或者更少，但不是必须。
 
 
 可变头部
 
 协议名称和协议版本都是固定的。
 
 连接标志(Connect Flags)
 
 一个字节表示，除了第1位是保留未使用，其它7位都具有不同含义。
 
 业务上很重要，对消息总体流程影响很大，需要牢记。
 
 Clean Session
 0，表示如果订阅的客户机断线了，要保存为其要推送的消息（QoS为1和QoS为2），若其重新连接时，需将这些消息推送（若客户端长时间不连接，需要设置一个过期值）。 1，断线服务器即清理相关信息，重新连接上来之后，会再次订阅。
 
 Will Flag
 定义了客户端（没有主动发送DISCONNECT消息）出现网络异常导致连接中断的情况下，服务器需要做的一些措施。
 
 简而言之，就是客户端预先定义好，在自己异常断开的情况下，所留下的最后遗愿（Last Will），也称之为遗嘱（Testament）。 这个遗嘱就是一个由客户端预先定义好的主题和对应消息，附加在CONNECT的可变头部中，在客户端连接出现异常的情况下，由服务器主动发布此消息。
 
 只有在Will Flag位为1时，Will Qos和Will Retain才会被读取，此时消息体payload中要出现Will Topic和Will Message具体内容，否则，Will QoS和Will Retain值会被忽略掉。
 
 Will Qos
 两位表示，和PUBLISH消息固定头部的QoS level含义一样。这里先掠过，到PUBLISH消息再回过头来看看，会更明白些。
 
 若标识了Will Flag值为1，那么Will QoS就会生效，否则会被忽略掉。
 
 Will RETAIN
 如果设置Will Flag，Will Retain标志就是有效的，否则它将被忽略。
 
 当客户端意外断开服务器发布其Will Message之后，服务器是否应该继续保存。这个属性和PUBLISH固定头部的RETAIN标志含义一样，这里先掠过。
 
 User name 和 password Flag：
 用于授权，两者要么为0要么为1，否则都是无效。都为0，表示客户端可自由连接/订阅，都为1，表示连接/订阅需要授权。
 
 Payload/消息体
 
 消息体定义的消息顺序（如上表所示），约定俗成，不得更改，否则将可能引起混乱。
 
 若Will Flag值为0，那么在payload中，Client Identifer后面就不会存在Will Topic和Will Message内容。
 
 若User Name和Password都为0，意味着Payload/消息体中，找不到User Name和password的值，就算有，也是无效。标志决定着是否读取与否。
 
 心跳时间(Keep Alive timer)
 以秒为单位，定义服务器端从客户端接收消息的最大时间间隔。一般应用服务会在业务层次检测客户端网络是否连接，不是TCP/IP协议层面的心跳机制(比如开启SOCKET的SO_KEEPALIVE选项)。 一般来讲，在一个心跳间隔内，客户端发送一个PINGREQ消息到服务器，服务器返回PINGRESP消息，完成一次心跳交互，继而等待下一轮。若客户端没有收到心跳反馈，会关闭掉TCP/IP端口连接，离线。 16位两个字节，可看做一个无符号的short类型值。最大值，2^16-1 = 65535秒 = 18小时。最小值可以为0，表示客户端不断开。一般设为几分钟，比如微信心跳周期为300秒。
 
 

 */
/*
 * MQTTClient: send data to broker
 */
- (void)send:(id)sender {
    [self.sessionManager sendData:[@"传送字符串" dataUsingEncoding:NSUTF8StringEncoding]
                     topic:@"订阅主题"
                       qos:MQTTQosLevelExactlyOnce
                    retain:false];
}

#pragma mark - MQTTSessionManagerDelegate

- (void)handleMessage:(NSData *)data onTopic:(NSString *)topic retained:(BOOL)retained {
    NSString *dataToString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];/// 收到服务器发来的数据 转成字符串
}

#pragma mark - MQTTSessionDelegate

- (void)connectionClosed:(MQTTSession *)session {
    [session connect];///重连
}

@end

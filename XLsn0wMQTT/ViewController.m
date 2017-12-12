
#import "ViewController.h"

#define kHost @""
#define kPort @""
#define kTopic @""

@interface ViewController () <MQTTSessionManagerDelegate>
/*
 * MQTTClient: keep a strong reference to your MQTTSessionManager here
 */
@property (strong, nonatomic) MQTTSessionManager *manager;


@property (strong, nonatomic) NSDictionary *mqttSettings;
@property (strong, nonatomic) NSMutableArray *chat;
@property (weak, nonatomic) IBOutlet UILabel *status;
@property (weak, nonatomic) IBOutlet UITextField *message;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSString *base;
@property (weak, nonatomic) IBOutlet UIButton *connect;
@property (weak, nonatomic) IBOutlet UIButton *disconnect;

@end

@implementation ViewController


/**
 1、 什么是MQTT?
 
 MQTT（MessageQueueing Telemetry Transport Protocol）的全称是消息队列遥感传输协议的缩写，是由IBM公司推出的一种基于轻量级代理的发布/订阅模式的消息传输协议，运行在TCP协议栈之上，为其提供有序、可靠、双向连接的网络连接保证。由于其开放、简单和易于实现所以能够应用在资源受限的环境中，对于M2M和物联网应用程序来说是一个相当不错的选择。
 
 2、 为什么要用MQTT？
 
 MQTT协议是针对如下情况设计的：
 
 M2M（Machine to Machine） communication，机器端到端通信，比如传感器之间的数据通讯 因为是Machine to Machine，需要考虑： Machine，或者叫设备，比如温度传感器，硬件能力很弱，协议要考虑尽量小的资源消耗，比如计算能力和存储等 M2M可能是无线连接，网络不稳定，带宽也比较小
 
 MQTT的特点:
 
 发布/订阅消息模式，提供一对多的消息发布，解除应用程序耦合。这一点很类似于1. 这里是列表文本XMPP，但是MQTT的信息冗余远小于XMPP.
 
 对负载内容屏蔽的消息传输。
 
 使用TCP/IP提供网络连接。主流的MQTT是基于TCP连接进行数据推送的，但是同样有基于UDP的版本，叫做MQTT-SN。这两种版本由于基于不同的连接方式，优缺点自然也就各有不同了。
 
 三种消息传输方式QoS：
 
 0代表“至多一次”，消息发布完全依赖底层 TCP/IP 网络。会发生消息丢失或重复。这一级别可用于如下情况，环境传感器数据，丢失一次读记录无所谓，因为不久后还会有第二次发送。
 
 1代表“至少一次”，确保消息到达，但消息重复可能会发生。
 
 2代表“只有一次”，确保消息到达一次。这一级别可用于如下情况，在计费系统中，消息重复或丢失会导致不正确的结果。 备注：由于服务端采用Mosca实现，Mosca目前只支持到QoS 1
 
 如果发送的是临时的消息，例如给某topic所有在线的设备发送一条消息，丢失的话也无所谓，0就可以了（客户端登录的时候要指明支持的QoS级别，同时发送消息的时候也要指明这条消息支持的QoS级别），如果需要客户端保证能接收消息，需要指定QoS为1，如果同时需要加入客户端不在线也要能接收到消息，那么客户端登录的时候要指定session的有效性，接收离线消息需要指定服务端要保留客户端的session状态。
 
 mqtt基于订阅者模型架构，客户端如果互相通信，必须在同一订阅主题下，即都订阅了同一个topic，客户端之间是没办法直接通讯的。订阅模型显而易见的好处是群发消息的话只需要发布到topic，所有订阅了这个topic的客户端就可以接收到消息了。
 
 发送消息必须发送到某个topic，重点说明的是不管客户端是否订阅了该topic都可以向topic发送了消息，还有如果客户端订阅了该主题，那么自己发送的消息也会接收到。
 
 小型传输，开销很小（固定长度的头部是2字节），协议交换最小化，以降低网络流量。这就是为什么在介绍里说它非常适合“在物联网领域，传感器与服务器的通信，信息的收集”，要知道嵌入式设备的运算能力和带宽都相对薄弱，使用这种协议来传递消息再适合不过了。
 
 使用Last Will和Testament特性通知有关各方客户端异常中断的机制。Last Will：即遗言机制，用于通知同一主题下的其他设备发送遗言的设备已经断开了连接。Testament：遗嘱机制，功能类似于Last Will 。
 */
- (void)viewDidLoad {
    [super viewDidLoad];
    

    NSURL *mqttPlistUrl = [[[NSBundle mainBundle] bundleURL] URLByAppendingPathComponent:@"mqtt.plist"];
    self.mqttSettings = [NSDictionary dictionaryWithContentsOfURL:mqttPlistUrl];
    self.base = self.mqttSettings[@"base"];
    
    /*
     * MQTTClient: create an instance of MQTTSessionManager once and connect
     * will is set to let the broker indicate to other subscribers if the connection is lost
     */
    if (!self.manager) {
        self.manager = [[MQTTSessionManager alloc] init];
        self.manager.delegate = self;
        self.manager.subscriptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:2]
                                                                 forKey:[NSString stringWithFormat:@"%@/#", self.base]];
        [self.manager connectTo:self.mqttSettings[@"host"]
                           port:[self.mqttSettings[@"port"] intValue]
                            tls:[self.mqttSettings[@"tls"] boolValue]
                      keepalive:60
                          clean:true
                           auth:false
                           user:nil
                           pass:nil
                      willTopic:[NSString stringWithFormat:@"%@/%@-%@",
                                 self.base,
                                 [UIDevice currentDevice].name,
                                 self.tabBarItem.title]
                           will:[@"offline" dataUsingEncoding:NSUTF8StringEncoding]
                        willQos:2
                 willRetainFlag:FALSE
                   withClientId:nil];
    } else {
        [self.manager connectToLast];
    }
    
    /*
     * MQTTCLient: observe the MQTTSessionManager's state to display the connection status
     */
    
    [self.manager addObserver:self
                   forKeyPath:@"state"
                      options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                      context:nil];
    
      /*
    self.manager = [[MQTTSessionManager alloc] init];
    self.manager.delegate = self;
    self.manager.subscriptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:MQTTQosLevelExactlyOnce] forKey:[NSString stringWithFormat:@"%@/#", self.base]];
    [self.manager connectTo:@"192.168.1.4" //服务器地址
                         port:1883 //服务端端口号
                          tls:true //是否使用tls协议，mosca是支持tls的，如果使用了要设置成true
                    keepalive:60 //心跳时间，单位秒，每隔固定时间发送心跳包
                        clean:false //session是否清除，这个需要注意，如果是false，代表保持登录，如果客户端离线了再次登录就可以接收到离线消息。注意：QoS为1和QoS为2，并需订阅和发送一致
                         auth:true //是否使用登录验证，和下面的user和pass参数组合使用
                         user:_userName //用户名
                         pass:_passwd //密码
                    willTopic:@"" //下面四个参数用来设置如果客户端异常离线发送的消息，当前参数是哪个topic用来传输异常离线消息，这里的异常离线消息都指的是客户端掉线后发送的掉线消息
                         will:@"" //异常离线消息体。自定义的异常离线消息，约定好格式就可以了
                      willQos:0 //接收离线消息的级别 0、1、2
               willRetainFlag:false //只有在为true时，Will Qos和Will Retain才会被读取，此时消息体payload中要出现Will Topic和Will Message具体内容，否则，Will QoS和Will Retain值会被忽略掉
                 withClientId:nil]; //客户端id，需要特别指出的是这个id需要全局唯一，因为服务端是根据这个来区分不同的客户端的，默认情况下一个id登录后，假如有另外的连接以这个id登录，上一个连接会被踢下线
 */
    

}


/**
 发布订阅模式
 使得消息发布者和订阅者不需要了解对方，发布者和订阅者不需要交互， 发布者无需等待订阅者确认而导致锁定，这和我们iOS中的通知是有区别的，iOS中的通知是同步的。。
 
 主题
 订阅者像订阅通知一样订阅主题，发布者发布主题消息之后，MQTT代理就会将消息推送到相应的订阅者
 
 代理
 作为一个中继站的感觉~，管理连接，处理消息发布和订阅的具体事宜。
 
 服务质量（Quality of Service –QoS）
 0
 “至多一次”，消息发布完全依赖底层 TCP/IP 网络。会发生消息丢失或重复。这一级别可用于如下情况，环境传感器数据，丢失一次读记录无所谓，因为不久后还会有第二次发送。
 至多发送一次，发送即丢弃。没有确认消息，也不知道对方是否收到。
 针对的消息不重要，丢失也无所谓。
 网络层面，传输压力小。
 
 1
 “至少一次”，确保消息到达，但消息重复可能会发生。
 所有QoS level 1都要在可变头部中附加一个16位的消息ID。
 SUBSCRIBE和UNSUBSCRIBE消息使用QoS level 1。
 针对消息的发布，Qos level 1，意味着消息至少被传输一次。
 发送者若在一段时间内接收不到PUBACK消息，发送者需要打开DUB标记为1，然后重新发送PUBLISH消息。因此会导致接收方可能会收到两次PUBLISH消息。针对客户端发布消息到服务器的消息处理流程：
 发布者（客户端/服务器）若因种种异常接收不到PUBACK消息，会再次重新发送PUBLISH消息，同时设置DUP标记为1。接收者以服务器为例，这可能会导致服务器收到重复消息，按照流程，broker（服务器）发布消息到订阅者（会导致订阅者接收到重复消息），然后发送一条PUBACK确认消息到发布者。
 　　在业务层面，或许可以弥补MQTT协议的不足之处：重试的消息ID一定要一致接收方一定判断当前接收的消息ID是否已经接受过，但一样不能够完全确保，消息一定到达了。

 2
 “只有一次”，确保消息到达一次。这一级别可用于如下情况，在计费系统中，消息重复或丢失会导致不正确的结果。
 仅仅在PUBLISH类型消息中出现，要求在可变头部中要附加消息ID。
 　　级别高，通信压力稍大些，但确保了仅仅传输接收一次。
 　　先看协议中流程图，Client -> Server方向，会有一个总体印象：
 Server端采取的方案a和b，都包含了何时消息有效，何时处理消息。两个方案二选一，Server端自己决定。但无论死采取哪一种方式，都是在QoS level 2协议范畴下，不受影响。若一方没有接收到对应的确认消息，会从最近一次需要确认的消息重试，以便整个（QoS level 2）流程打通。
 
 
 
 消息类型
 MQTT协议下拥有14种不同的消息类型
 
 MQTTConnect = 1,  //客户端连接到MQTT代理
 MQTTConnack = 2, //连接确认的消息
 MQTTPublish = 3, //新发布消息
 MQTTPuback = 4, //新发布消息确认
 MQTTPubrec = 5, //消息发布  已记录
 MQTTPubrel = 6, //消息发布  已释放
 MQTTPubcomp = 7,// 消息发布完成
 MQTTSubscribe = 8,//订阅
 MQTTSuback = 9, //订阅回执
 MQTTUnsubscribe = 10,//取消订阅
 MQTTUnsuback = 11,//取消订阅的回执吧
 MQTTPingreq = 12, //心跳消息
 MQTTPingresp = 13,//确认心跳
 MQTTDisconnect = 14 //客户端终止连接
 
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
 
 作者：mark666
 链接：http://www.jianshu.com/p/bcf0251dc181
 來源：简书
 著作权归作者所有。商业转载请联系作者获得授权，非商业转载请注明出处。
 
 */
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    switch (self.manager.state) {
        case MQTTSessionManagerStateClosed:
            self.status.text = @"closed";
            self.disconnect.enabled = false;
            self.connect.enabled = false;
            break;
        case MQTTSessionManagerStateClosing:
            self.status.text = @"closing";
            self.disconnect.enabled = false;
            self.connect.enabled = false;
            break;
        case MQTTSessionManagerStateConnected:
            self.status.text = [NSString stringWithFormat:@"connected as %@-%@",
                                [UIDevice currentDevice].name,
                                self.tabBarItem.title];
            self.disconnect.enabled = true;
            self.connect.enabled = false;
            [self.manager sendData:[@"joins chat" dataUsingEncoding:NSUTF8StringEncoding]
                             topic:[NSString stringWithFormat:@"%@/%@-%@",
                                    self.base,
                                    [UIDevice currentDevice].name,
                                    self.tabBarItem.title]
                               qos:MQTTQosLevelExactlyOnce
                            retain:FALSE];

            break;
        case MQTTSessionManagerStateConnecting:
            self.status.text = @"connecting";
            self.disconnect.enabled = false;
            self.connect.enabled = false;
            break;
        case MQTTSessionManagerStateError:
            self.status.text = @"error";
            self.disconnect.enabled = false;
            self.connect.enabled = false;
            break;
        case MQTTSessionManagerStateStarting:
        default:
            self.status.text = @"not connected";
            self.disconnect.enabled = false;
            self.connect.enabled = true;
            break;
    }///mqtt协议本身支持断线重连，另外单独说明此sdk在app退出到后台后自动断开连接，当回到前台时会自动重新连接 ! ! !
}


- (void)connect:(id)sender {
    /*
     * MQTTClient: connect to same broker again
     */
    
    [self.manager connectToLast];
}

- (void)disconnect:(id)sender {
    /*
     * MQTTClient: send goodby message and gracefully disconnect
     */
    //发送消息,返回值msgid大于0代表发送成功
    [self.manager sendData:[@"leaves chat" dataUsingEncoding:NSUTF8StringEncoding]
                     topic:@"要往哪个topic发送消息"
                       qos:2
                    retain:FALSE];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    [self.manager disconnect];
    
    
    //订阅主题。NSDictionary类型，，key 为 Topic vaule 为 QoS
    //self.manager.subscriptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:MQTTQosLevelExactlyOnce] forKey:@"topic"];
    
    self.manager.subscriptions = @{ @"topic" : @2 };
    
    //发送消息,返回值msgid大于0代表发送成功
    UInt16 msgid = [self.manager sendData:[@"msg" dataUsingEncoding:NSUTF8StringEncoding] //要发送的消息体
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
- (void)send:(id)sender {
    /*
     * MQTTClient: send data to broker
     */
    
    [self.manager sendData:[self.message.text dataUsingEncoding:NSUTF8StringEncoding]
                     topic:[NSString stringWithFormat:@"%@/%@-%@",
                            self.base,
                            [UIDevice currentDevice].name,
                            self.tabBarItem.title]
                       qos:MQTTQosLevelExactlyOnce
                    retain:FALSE];
}

/*
 * MQTTSessionManagerDelegate
 */
- (void)handleMessage:(NSData *)data onTopic:(NSString *)topic retained:(BOOL)retained {
    /*
     * MQTTClient: process received message
     */
    
    NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSString *senderString = [topic substringFromIndex:self.base.length + 1];
    
    [self.chat insertObject:[NSString stringWithFormat:@"%@:\n%@", senderString, dataString] atIndex:0];
    [self.tableView reloadData];
}

- (void)connectionClosed:(MQTTSession *)session{
    NSLog(@"========哈哈哈哈我断了");
    //这里实现断开重连
    [session connect];
}

@end

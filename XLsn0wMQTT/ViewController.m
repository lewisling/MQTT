

#import "ViewController.h"

#define kMQTTServerHost @"iot.eclipse.org"
#define kTopic @"MQTTExample/Message"


@interface ViewController ()
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
    
    NSURL *bundleURL = [[NSBundle mainBundle] bundleURL];
    NSURL *mqttPlistUrl = [bundleURL URLByAppendingPathComponent:@"mqtt.plist"];
    self.mqttSettings = [NSDictionary dictionaryWithContentsOfURL:mqttPlistUrl];
    self.base = self.mqttSettings[@"base"];
    
    self.chat = [[NSMutableArray alloc] init];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.estimatedRowHeight = 150;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    self.message.delegate = self;
    
    
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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
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
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (IBAction)clear:(id)sender {
    [self.chat removeAllObjects];
    [self.tableView reloadData];
}
- (IBAction)connect:(id)sender {
    /*
     * MQTTClient: connect to same broker again
     */
    
    [self.manager connectToLast];
}

- (IBAction)disconnect:(id)sender {
    /*
     * MQTTClient: send goodby message and gracefully disconnect
     */
    [self.manager sendData:[@"leaves chat" dataUsingEncoding:NSUTF8StringEncoding]
                     topic:[NSString stringWithFormat:@"%@/%@-%@",
                            self.base,
                            [UIDevice currentDevice].name,
                            self.tabBarItem.title]
                       qos:MQTTQosLevelExactlyOnce
                    retain:FALSE];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    [self.manager disconnect];
}

- (IBAction)send:(id)sender {
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

/*
 * UITableViewDelegate
 */
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"line"];

    return cell;
}

/*
 * UITableViewDataSource
 */

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.chat.count;
}

@end

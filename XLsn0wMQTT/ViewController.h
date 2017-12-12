

#import <UIKit/UIKit.h>

/*
 * MQTTClient: imports
 * MQTTSessionManager.h is optional
 */
#import <MQTTClient/MQTTClient.h>
#import <MQTTClient/MQTTSessionManager.h>

/*
 * MQTTClient: using your main view controller as the MQTTSessionManagerDelegate
 */
@interface ViewController : UIViewController <MQTTSessionManagerDelegate, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>


@end


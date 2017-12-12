

#import <UIKit/UIKit.h>

/*
 * MQTTClient: using your main view controller as the MQTTSessionManagerDelegate
 */
@interface ViewController : UIViewController <MQTTSessionManagerDelegate, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>


@end


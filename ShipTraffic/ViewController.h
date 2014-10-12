//
//  ViewController.h
//  ShipTraffic
//
//  Created by Sally Kong on 10/10/14.
//  Copyright (c) 2014 Sally Kong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WhirlyGlobeComponent.h"
#import "OptionsViewController.h"

@interface ViewController : UIViewController <WhirlyGlobeViewControllerDelegate>

@property OptionType option;

@end


//
//  OptionsViewController.h
//  ShipTraffic
//
//  Created by Sally Kong on 10/11/14.
//  Copyright (c) 2014 Sally Kong. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {EarthQuakeOption, StadiumOption} OptionType;

@interface OptionsViewController : UITableViewController
@property OptionType optionType;

@end

//
//  OptionsViewController.h
//  cis399project
//
//  Created by Jinah Kim on 2014. 10. 11..
//  Copyright (c) 2014년 Jinah Kim. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {EarthQuakeOption, StadiumOption} OptionType;

@interface OptionsViewController : UITableViewController

@property OptionType optionType;

@end

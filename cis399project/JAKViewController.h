//
//  JAKViewController.h
//  cis399project
//
//  Created by Jinah Kim on 2014. 10. 10..
//  Copyright (c) 2014년 Jinah Kim. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WhirlyGlobeComponent.h"
#import "OptionsViewController.h"

@interface JAKViewController : UIViewController <WhirlyGlobeViewControllerDelegate>

@property OptionType option;

@end

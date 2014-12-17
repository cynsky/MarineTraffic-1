//
//  ViewController.h
//  ShipTraffic
//
//

#import <UIKit/UIKit.h>
#import "WhirlyGlobeComponent.h"
#import "OptionsViewController.h"

@interface ViewController : UIViewController <WhirlyGlobeViewControllerDelegate>

@property OptionType option;
@property (nonatomic) UISlider *slider;
@property (nonatomic) NSMutableArray *vessels;
@property (nonatomic) NSMutableDictionary *vesselDict;
@property (nonatomic) MaplyComponentObject *vesselMarkers1;
@property (nonatomic) MaplyComponentObject *vesselMarkers2;
@property (nonatomic) MaplyComponentObject *vesselMarkers3;

@end


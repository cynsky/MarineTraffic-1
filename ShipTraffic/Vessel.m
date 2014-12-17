//
//  Vessel.m
//  ShipTraffic
//
//  Created by Sally Kong on 11/19/14.
//  Copyright (c) 2014 Sally Kong. All rights reserved.
//

#import "Vessel.h"

@implementation Vessel

- (id)initWithName:(NSString *) vesselName {
    self = [super init];
    if (self) {
        // Any custom setup work goes here
        _name = vesselName;
        _locations = [[NSMutableArray alloc] init];
    }
    return self;
}

- (id)init {
    return [self initWithName:_name];
}

@end

//
//  Vessel.h
//  ShipTraffic
//
//  Created by Sally Kong on 11/19/14.
//  Copyright (c) 2014 Sally Kong. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Vessel : NSObject

@property (nonatomic) NSString *name;
@property (atomic) NSMutableArray *locations;
@property (nonatomic) NSNumber *type;

- (id)initWithName:(NSString *)aModel;
@end

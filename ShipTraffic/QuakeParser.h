//
//  QuakeParser.h
//  ShipTraffic
//
//  Created by Sally Kong on 10/11/14.
//  Copyright (c) 2014 Sally Kong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WhirlyGlobeComponent.h>

@interface QuakeParser : NSObject<NSXMLParserDelegate>

//The markers we're creating
@property (nonatomic) NSMutableArray *markers;

-(id)initWithXMLData: (NSData *)data;

@end

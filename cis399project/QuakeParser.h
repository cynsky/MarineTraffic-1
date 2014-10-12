//
//  QuakeParser.h
//  cis399project
//
//  Created by Jinah Kim on 2014. 10. 11..
//  Copyright (c) 2014년 Jinah Kim. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WhirlyGlobeComponent.h"


@interface QuakeParser : NSObject <NSXMLParserDelegate>

//the markers we're creating
@property (nonatomic) NSMutableArray *markers;

// construct with XML data
-(id)initWithXMLData:(NSData *)data;

@end

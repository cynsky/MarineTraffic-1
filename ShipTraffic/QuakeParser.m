//
//  QuakeParser.m
//  ShipTraffic
//
//  Created by Sally Kong on 10/11/14.
//  Copyright (c) 2014 Sally Kong. All rights reserved.
//

#import "QuakeParser.h"


@implementation QuakeParser
{
    NSString *entryTitle;
    NSString *entryLoc;
    bool entryValid;
    bool titleValid;
    bool locValid;
    
}

-(id)initWithXMLData: (NSData *)data
{
    self = [super init];
    _markers = [NSMutableArray array];
    
    NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData: data];
    xmlParser.delegate = self;
    [xmlParser parse];
    
    return self;
}

-(void)parserDidStartDocument:(NSXMLParser *)parser
{
    
}

-(void)parserDidEndDocument:(NSXMLParser *)parser
{
    
}

-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{

    if([elementName isEqualToString:@"entry"])
    {
        entryValid = true;
        titleValid = false;
        locValid = false;
        entryTitle = nil;
        entryLoc = nil;
        
    } else if([elementName isEqualToString:@"title"])
    {
        titleValid = true;
        
    } else if([elementName isEqualToString:@"georss:point"])
    {
        locValid = true;
    }
}

-(void) parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    if(titleValid)
    {
        entryTitle = string;
    } else if(locValid)
    {
        entryLoc = string;
    }
}

-(void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if([elementName isEqualToString: @"entry"])
    {
        if(entryValid && entryTitle && entryLoc) {
            
            float lon, lat;
            NSScanner *scanner = [NSScanner scannerWithString: entryLoc];
            [scanner scanFloat:&lat];
            [scanner scanFloat:&lon];
            MaplyCoordinate loc = MaplyCoordinateMakeWithDegrees(lon, lat);
            MaplyScreenMarker *marker = [[MaplyScreenMarker alloc] init];
            marker.loc = loc;
            marker.userObject = entryTitle;
            marker.image = [UIImage imageNamed:@"danger-24@2x.png"];
            marker.size = CGSizeMake(20, 20);
            marker.layoutImportance = MAXFLOAT;
            [_markers addObject:marker];

        }
        entryValid = false;
       
    } else if ([elementName isEqualToString:@"title"])
    {
        titleValid = false;
    } else if([elementName isEqualToString:@"georss:point"])
    {
        locValid = false;
    }
}


@end

//
//  VesselParser.m
//  ShipTraffic
//
//  Created by Sally Kong on 10/11/14.
//  Copyright (c) 2014 Sally Kong. All rights reserved.
//

#import "VesselParser.h"

@implementation VesselParser
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
    _cnt = 0;
    
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

-(void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
    NSLog(@"%@", parseError);
}

-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
   
    float lon, lat;
    lon = [[attributeDict objectForKey: @"LONGITUDE"] floatValue];
    lat = [[attributeDict objectForKey: @"LATITUDE"] floatValue];
    MaplyCoordinate loc = MaplyCoordinateMakeWithDegrees(lon, lat);
    MaplyScreenMarker *marker = [[MaplyScreenMarker alloc] init];
    marker.loc = loc;
    marker.image = [UIImage imageNamed:@"ship.png"];
    marker.size = CGSizeMake(20, 20);
    marker.userObject = [attributeDict objectForKey: @"NAME"];
    marker.layoutImportance = MAXFLOAT;
    [_markers addObject:marker];
    _cnt += 1;
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
    if([elementName isEqualToString: @"vessel"])
    {
        
        //NSLog(@"Done with %@", elementName);
    }
}

@end

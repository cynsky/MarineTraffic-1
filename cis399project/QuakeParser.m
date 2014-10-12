//
//  QuakeParser.m
//  cis399project
//
//  Created by Jinah Kim on 2014. 10. 11..
//  Copyright (c) 2014년 Jinah Kim. All rights reserved.
//

#import "QuakeParser.h"

@implementation QuakeParser
{
    bool entryValid;
    bool titleValid;
    bool locValid;
    NSString *entryTitle;
    NSString *entryLoc;
}

-(id)initWithXMLData:(NSData *)data
{
    self = [super init];
    _markers = [NSMutableArray array];
    
    NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:data];
    xmlParser.delegate = self;
    [xmlParser parse];
    
    return self;
}

-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    //NSLog(@"Element: %@", elementName);
    if([elementName isEqualToString:@"entry"])
    {
        entryValid = true;
        titleValid = false;
        locValid = false;
        entryTitle = nil;
        entryLoc = nil;
        
    }
    else if([elementName isEqualToString:@"title"])
    {
        //NSLog(@"Got title");
        titleValid = true;
    }
    else if([elementName isEqualToString:@"georss:point"])
    {
        locValid = true;
    }
}

-(void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    if(titleValid)
    {
        entryTitle = string;
    }else if(locValid)
    {
        entryLoc = string;
    }
}


-(void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if([elementName isEqualToString:@"entry"])
    {
        if (entryValid && entryTitle && entryLoc){
            //NSLog(@"Entry: title =%@, loc = %@", entryTitle,entryLoc);
            float lon, lat;
            NSScanner *scanner = [NSScanner scannerWithString:entryLoc];
            [scanner scanFloat:&lat];
            [scanner scanFloat:&lon];
            MaplyCoordinate loc = MaplyCoordinateMakeWithDegrees(lon, lat);
            
            // make a marker
            MaplyScreenMarker *marker = [[MaplyScreenMarker alloc] init];
            marker.loc = loc;
            marker.image = [UIImage imageNamed:@"danger-24@2x.png"];
            marker.size = CGSizeMake(20,20);
            marker.layoutImportance = MAXFLOAT;
            marker.userObject = entryTitle;
            [_markers addObject:marker];
        }
        entryValid = false;
    }else if([elementName isEqualToString:@"title"])
    {
        titleValid = false;
    }
    else if([elementName isEqualToString:@"georss:point"])
    {
        locValid = false;
    }
    
}

@end

//
//  JAKViewController.m
//  cis399project
//
//  Created by Jinah Kim on 2014. 10. 10..
//  Copyright (c) 2014년 Jinah Kim. All rights reserved.
//

#import "JAKViewController.h"
#import "WhirlyGlobeComponent.h"
#import "QuakeParser.h"

@interface JAKViewController () <WhirlyGlobeViewControllerAnimationDelegate, MaplyPagingDelegate>

@end

@implementation JAKViewController
{
    WhirlyGlobeViewController *theViewC;
    MaplyQuadImageTilesLayer *aerialLayer;
    MaplyComponentObject *selectableObj;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
        
    theViewC = [[WhirlyGlobeViewController alloc] init];
    [self.view addSubview:theViewC.view];
    theViewC.view.frame = self.view.bounds;
    [self addChildViewController:theViewC];
    
    theViewC.delegate = self;
    
    NSString *baseCacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)objectAtIndex:0];
    NSString *aerialTilesCacheDir = [NSString stringWithFormat:@"%@/tiles/",baseCacheDir];
    int maxZoom = 18;
    
    // OSM Data
    MaplyRemoteTileSource *tileSource = [[MaplyRemoteTileSource alloc]initWithBaseURL:@"https://a.tiles.mapbox.com/v3/jina771.jo037hd5/" ext:@"png" minZoom:0 maxZoom:maxZoom];
    tileSource.cacheDir = aerialTilesCacheDir;
    aerialLayer = [[MaplyQuadImageTilesLayer alloc ] initWithCoordSystem:tileSource.coordSys tileSource:tileSource];
    
    [theViewC addLayer:aerialLayer];
    
    
    
    // Create a screen marker
    MaplyScreenMarker *marker = [[MaplyScreenMarker alloc] init];
    marker.loc = MaplyCoordinateMakeWithDegrees(-122.416667, 37.783333);
    marker.image = [UIImage imageNamed:@"alcohol-shop-24@2x.png"];
    marker.size = CGSizeMake(40, 40);
    marker.selectable = YES;
    marker.userObject = @"I'm Here!";
    marker.layoutImportance = MAXFLOAT;
    [theViewC addScreenMarkers:@[marker] desc:@{kMaplyMinVis: @0.0, kMaplyMaxVis: @0.2} mode:MaplyThreadAny];
    
    // Add a red rectangle over SF
    MaplyCoordinate coords[5];
    coords[0] = MaplyCoordinateMakeWithDegrees(-122.516667, 37.783333);
    coords[1] = MaplyCoordinateMakeWithDegrees(-122.516667, 37.883333);
    coords[2] = MaplyCoordinateMakeWithDegrees(-122.416667, 37.883333);
    coords[3] = MaplyCoordinateMakeWithDegrees(-122.416667, 37.783333);
    coords[4] = MaplyCoordinateMakeWithDegrees(-122.516667, 37.783333);
    MaplyVectorObject *sfOutline = [[MaplyVectorObject alloc] initWithAreal:coords numCoords:5 attributes:nil];
    [theViewC addVectors:@[sfOutline] desc:@{kMaplyColor: [UIColor colorWithRed:0.25 green:0.0 blue:0.0 alpha:0.25],
                                             kMaplyFilled: @YES}];
    [theViewC addVectors:@[sfOutline] desc:@{kMaplyColor: [UIColor greenColor]}];
    [theViewC addLoftedPolys:@[sfOutline] key:nil cache:nil desc:@{kMaplyColor: [UIColor colorWithRed: 0.25 green:0.0 blue: 0.0 alpha:0.25],
                                                                   kMaplyLoftedPolyHeight: @0.05}];
    
    MaplyQuadPagingLayer *pageLayer = [[MaplyQuadPagingLayer alloc] initWithCoordSystem:[[MaplySphericalMercator alloc] initWebStandard] delegate:self];
    pageLayer.numSimultaneousFetches = 1;
                                       
    [theViewC addLayer:pageLayer];
    
    
    [theViewC setHeight: 0.1];
    [theViewC animateToPosition:MaplyCoordinateMakeWithDegrees(-122.416667, 37.783333) time:1.0];
    
    switch (_option)
    {
        case EarthQuakeOption:
            [self fetchEarthQuakes];
            break;
        case StadiumOption:
            [self fetchStadiums];
            break;
    }
    
    //[self fetchStadiums];
    //[self fetchEarthQuakes];
    
}

-(void)fetchStadiums
{
    NSString *urlStr = @"https://raw.githubusercontent.com/cageyjames/GeoJSON-Ballparks/master/ballparks.geojson";
    NSURLRequest *urlReq = [NSURLRequest requestWithURL:[NSURL URLWithString:urlStr]];
    
    
    [NSURLConnection sendAsynchronousRequest:urlReq queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError)
    {
        // running after this data comes back
        //NSLog(@"response: %@",response);
        NSError *jsonError = nil;
        id obj = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        if ([obj isKindOfClass:[NSDictionary class]])
        {
            NSDictionary *stadiumDict = obj;
            NSLog(@"Return: %@", stadiumDict);
        }
        
        NSMutableArray *stadiums = [NSMutableArray array];
        MaplyVectorObject *stadiumVec = [MaplyVectorObject VectorObjectFromGeoJSON:data];
        for (MaplyVectorObject *stadium in [stadiumVec splitVectors])
        {
            MaplyScreenMarker *stadiumMarker = [[MaplyScreenMarker alloc] init];
            stadiumMarker.userObject = stadium.attributes[@"Ballpark"];
            stadiumMarker.loc = [stadium center];
            stadiumMarker.image = [UIImage imageNamed:@"baseball-24@2x.png"];
            stadiumMarker.size = CGSizeMake(20, 20);
            stadiumMarker.layoutImportance = MAXFLOAT;
            [stadiums addObject:stadiumMarker];
            
        }
        if([stadiums count] > 0){
            [theViewC addScreenMarkers:stadiums desc:nil];
        }
    }];
}

-(void)fetchEarthQuakes
{
    NSString *urlStr = @"http://earthquake.usgs.gov/earthquakes/catalogs/7day-M2.5.xml";
    NSURLRequest *urlReq = [NSURLRequest requestWithURL:[NSURL URLWithString:urlStr]];
    
    NSData *xmlData = [NSData dataWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"myFile" ofType:@"xml"]];
    
    
    
    [NSURLConnection sendAsynchronousRequest:urlReq queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError)
     {
      //   NSString *feedStr = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
      //   NSLog(@"feed = %@", feedStr);
         QuakeParser *quakeParser = [[QuakeParser alloc] initWithXMLData:data];
         if([quakeParser.markers count] > 0)
         {
             [theViewC addScreenMarkers:quakeParser.markers desc:nil];
         }
     }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)globeViewController:(WhirlyGlobeViewController *)viewC didSelect:(NSObject *)selectedObj atLoc:(MaplyCoordinate)coord onScreen:(CGPoint)screenPt
{
    if(selectableObj){
        [theViewC removeObject:selectableObj];
        selectableObj = nil;
    }
    if([selectedObj isKindOfClass:[MaplyScreenMarker class]])
    {
        MaplyScreenMarker *marker = (MaplyScreenMarker *)selectedObj;
        
        MaplyScreenLabel *label = [[MaplyScreenLabel alloc] init];
        label.text = (NSString *)marker.userObject;
        label.loc = coord;
        
        if(marker.userObject){
            selectableObj = [theViewC addScreenLabels:@[label] desc:@{kMaplyFont: [UIFont systemFontOfSize:12.0]}];
        }
    }
}
                                       
-(int) minZoom
{
    return 6;
}

-(int) maxZoom
{
    return 12;
}

- (void)startFetchForTile:(MaplyTileID)tileID forLayer:(MaplyQuadPagingLayer *)layer{
    MaplyCoordinate ll,ur;
    [layer geoBoundsforTile:tileID ll:&ll ur:&ur];
    
    MaplyScreenLabel *label =[[MaplyScreenLabel alloc] init];
    label.text = [NSString stringWithFormat:@"%d: (%d,%d)",tileID.level,tileID.x,tileID.y];
    MaplyCoordinate mid;
    mid.x = (ll.x+ur.x)/2.0;
    mid.y = (ll.y+ur.y)/2.0;
    label.loc = mid;
    label.selectable = false;
    
    MaplyComponentObject *compObj = [theViewC addScreenLabels:@[label] desc:nil];
    //[layer addData:@[compObj] forTile:tileID];
    [layer addData:@[compObj] forTile:tileID style:MaplyDataStyleReplace];
    [layer tileDidLoad:tileID];
    
    
}
                                       

@end

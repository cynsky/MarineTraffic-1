//
//  ViewController.m
//  ShipTraffic
//
//  Created by Sally Kong on 10/10/14.
//  Copyright (c) 2014 Sally Kong. All rights reserved.
//

#import "ViewController.h"
#import "WhirlyGlobeComponent.h"
#import "QuakeParser.h"
#import "VesselParser.h"
#import "OptionsViewController.h"


@interface ViewController () <WhirlyGlobeViewControllerDelegate, MaplyPagingDelegate>

@end

@implementation ViewController
{
    WhirlyGlobeViewController *theViewC;
    MaplyQuadImageTilesLayer *aerialLayer;
    MaplyComponentObject *selectLabelObj;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    theViewC = [[WhirlyGlobeViewController alloc] init]; //hooking up
    
    //put it in scene
    [self.view addSubview:theViewC.view];
    theViewC.view.frame = self.view.bounds;
    [self addChildViewController:theViewC];
    
    theViewC.delegate = self;
    
    
    //so that you don't load data over and over again, cache it
    NSString *baseCacheDir = [NSSearchPathForDirectoriesInDomains
                              (NSCachesDirectory, NSUserDomainMask,YES) objectAtIndex:0];
    NSString *aerialTilesCacheDir = [NSString stringWithFormat:@"%@/tiles/", baseCacheDir];
    int maxZoom = 18;
    
    //OSM Data
    MaplyRemoteTileSource *tileSource = [[MaplyRemoteTileSource alloc]
                                         initWithBaseURL:@"http://a.tiles.mapbox.com/v3/sallykong.jnojkg14/" ext:@"png" minZoom:0 maxZoom:maxZoom];
    tileSource.cacheDir = aerialTilesCacheDir;
    aerialLayer = [[MaplyQuadImageTilesLayer alloc] initWithCoordSystem:tileSource.coordSys tileSource:tileSource];
    
    [theViewC addLayer:aerialLayer];
    
    float longi = -7.857325;
    float lat = 36.545708;
    
    //Add Vector Object/Polygon
    MaplyCoordinate coords[5];
    float pad = 0.2;
    coords[0] = MaplyCoordinateMakeWithDegrees(longi - pad, lat - pad);
    coords[1] = MaplyCoordinateMakeWithDegrees(longi - pad, lat + pad);
    coords[2] = MaplyCoordinateMakeWithDegrees(longi + pad, lat + pad);
    coords[3] = MaplyCoordinateMakeWithDegrees(longi + pad, lat - pad);
    coords[4] = MaplyCoordinateMakeWithDegrees(longi - pad, lat - pad);

    MaplyVectorObject *sfOutline = [[MaplyVectorObject alloc]
                                    initWithAreal:coords numCoords:5 attributes:nil];
    [theViewC addVectors:@[sfOutline]
                    desc:@{ kMaplyColor: [UIColor colorWithRed: 0 green: 0 blue: 0 alpha: 0.5],
                            kMaplyFilled: @YES}];
   /* [theViewC addLoftedPolys:@[sfOutline] 
                key:nil cache: nil desc:@{
                kMaplyColor: [UIColor colorWithRed: 1 green:1 blue:1 alpha: 0.5],
                kMaplyLoftedPolyHeight: @0.05, }];*/
    

    MaplyQuadPagingLayer *pageLayer = [[MaplyQuadPagingLayer alloc]
                                       initWithCoordSystem:[[MaplySphericalMercator alloc] initWebStandard]
                                       delegate:self];
   
    [theViewC addLayer:pageLayer];
    
    /*Screen Marker (can be used for ship icons)
    MaplyScreenMarker *marker = [[MaplyScreenMarker alloc] init];
    //degrees input but in marker loc it will be radians longitude, latitude
    marker.loc = MaplyCoordinateMakeWithDegrees(longi, lat);
    marker.image = [UIImage imageNamed:@"ship.png"];
    marker.size = CGSizeMake(20, 20);
    marker.selectable = YES;
    marker.userObject = @"iShip";
    marker.layoutImportance = MAXFLOAT;
    [theViewC addScreenMarkers:@[marker]
                          desc:@{
                                 kMaplyMinVis:@0.0,
                                 kMaplyMaxVis:@3.0,
                                 }
                          mode:MaplyThreadAny];*/
                                    
    //1 = radius of the earth
    [theViewC setHeight: 1.0];
    [theViewC setKeepNorthUp: YES];
    [theViewC animateToPosition:MaplyCoordinateMakeWithDegrees(-7.857325, 36.545708) time: 2.0];
    
    switch (_option)
    {
        case EarthQuakeOption:
            [self fetchEarthquakes];
            break;
        case StadiumOption:
            [self fetchVessels];
            break;
    }
}

-(void) fetchVessels
{
    NSData *xmlData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle]
                                                      pathForResource:@"sampleData" ofType:@"xml"]];
    
    VesselParser *vesselParser = [[VesselParser alloc] initWithXMLData:xmlData];
    if([vesselParser.markers count] > 0)
    {
        [theViewC addScreenMarkers:vesselParser.markers desc: nil];
    }

}

//how to fetch data
- (void) fetchStadiums
{
 
    NSString *urlStr = @"https://raw.githubusercontent.com/cageyjames/GeoJSON-Ballparks/master/ballparks.geojson";
    NSURLRequest *urlReq = [NSURLRequest requestWithURL:[NSURL URLWithString: urlStr]];
    [NSURLConnection sendAsynchronousRequest:urlReq queue:[NSOperationQueue mainQueue]
                           completionHandler: ^(NSURLResponse* response, NSData *data, NSError *connectionError)
     {
         //NSLog(@"response: %@", response);
         NSError *jsonError = nil;
         id obj = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
         if ([obj isKindOfClass:[NSDictionary class]])
              {
                  //NSDictionary *stadiumDict = obj;
                  //NSLog(@"return: %@", stadiumDict);
              }
         
         NSMutableArray *stadiums = [NSMutableArray array];
         MaplyVectorObject *stadiumVec = [MaplyVectorObject VectorObjectFromGeoJSON:data];
         for (MaplyVectorObject *stadium in [stadiumVec splitVectors])
         {
             MaplyScreenMarker *stadiumMarker = [[MaplyScreenMarker alloc] init];
             stadiumMarker.loc = [stadium center];
             stadiumMarker.userObject = stadium.attributes[@"Ballpark"];
             stadiumMarker.image = [UIImage imageNamed:@"ship.png"];
             stadiumMarker.size = CGSizeMake(24,24);
             stadiumMarker.layoutImportance = MAXFLOAT;
             [stadiums addObject:stadiumMarker];
         }
         
         if([stadiums count] > 0)
         {
             [theViewC addScreenMarkers:stadiums desc:nil];
         }
     }];
}

- (void) fetchEarthquakes
{
    NSString *urlStr = @"http://earthquake.usgs.gov/earthquakes/catalogs/7day-M2.5.xml";
    NSURLRequest *urlReq = [NSURLRequest requestWithURL:[NSURL URLWithString: urlStr]];
    [NSURLConnection sendAsynchronousRequest:urlReq queue:[NSOperationQueue mainQueue]
                           completionHandler: ^(NSURLResponse* response, NSData *data, NSError *connectionError)
     {
         NSString *feedStr = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
        // NSLog(@"feed = %@", feedStr);
         QuakeParser *quakeParser = [[QuakeParser alloc] initWithXMLData:data];
         if([quakeParser.markers count] > 0)
         {
             [theViewC addScreenMarkers:quakeParser.markers desc: nil];
         }
     }];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


//for displaying labels when something is selected
- (void)globeViewController:(WhirlyGlobeViewController *)viewC didSelect:(NSObject *)selectedObj atLoc:(MaplyCoordinate)coord onScreen:(CGPoint)screenPt
{
    if(selectLabelObj)
    {
        [theViewC removeObject:selectLabelObj];
        selectLabelObj = nil;
    }
    
    if([selectedObj isKindOfClass:[MaplyScreenMarker class]])
    {
        MaplyScreenMarker *marker = (MaplyScreenMarker *)selectedObj;
        MaplyScreenLabel *label = [[MaplyScreenLabel alloc] init];
        label.text = (NSString *)marker.userObject;
        label.loc = coord;
        
        if(marker.userObject != nil)
        {
            selectLabelObj = [theViewC addScreenLabels:@[label]
                                              desc:@{ kMaplyFont: [UIFont systemFontOfSize:12.0]}];
        }
    }
}

//for quadpageload
- (int)minZoom{
    return 7;
}
- (int)maxZoom{
    return 7;
}

- (void)startFetchForTile:(MaplyTileID)tileID forLayer:(MaplyQuadPagingLayer *)layer
{
    MaplyCoordinate ll, ur;
    [layer geoBoundsforTile:tileID ll:&ll ur:&ur];
    
    
    MaplyComponentObject *compObj = [theViewC addScreenLabels:nil desc:@{
    kMaplyFont: [UIFont systemFontOfSize:(12)]
    }];
    [layer addData:@[compObj] forTile:tileID];
    
    //replace for each label
    [layer addData:@[compObj] forTile:tileID style:MaplyDataStyleReplace];
    [layer tileDidLoad:tileID];
}



@end

//
//  ViewController.m
//  ShipTraffic
//

#import "ViewController.h"
#import "WhirlyGlobeComponent.h"
#import "QuakeParser.h"
#import "VesselParser.h"
#import "OptionsViewController.h"
#import "Vessel.h"


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
    _vessels = [[NSMutableArray alloc] init];
    _vesselDict = [[NSMutableDictionary alloc] init];
    
    //put it in scene
    [self.view addSubview:theViewC.view];
    theViewC.view.frame = self.view.bounds;
    [self addChildViewController:theViewC];
    
    theViewC.delegate = self;
    
    
    //so that you don't load data over and over again, cache it
    NSString *baseCacheDir = [NSSearchPathForDirectoriesInDomains
                              (NSCachesDirectory, NSUserDomainMask,YES) objectAtIndex:0];
    NSString *aerialTilesCacheDir = [NSString stringWithFormat:@"%@/tiles/", baseCacheDir];
    int maxZoom = 15;
    
    //OSM Data
    /*  MaplyRemoteTileSource *tileSource = [[MaplyRemoteTileSource alloc]
     initWithBaseURL:@"http://otile1.mqcdn.com/tiles/1.0.0/sat/" ext:@"jpg" minZoom:0 maxZoom:maxZoom];*/
    MaplyRemoteTileSource *tileSource = [[MaplyRemoteTileSource alloc]
                                         initWithBaseURL:@"https://a.tiles.mapbox.com/v3/sallykong.jnojkg14/" ext:@"png" minZoom:0 maxZoom:maxZoom];
    
    tileSource.cacheDir = aerialTilesCacheDir;
    aerialLayer = [[MaplyQuadImageTilesLayer alloc] initWithCoordSystem:tileSource.coordSys tileSource:tileSource];
    
    [theViewC addLayer:aerialLayer];
    
    
    /* MaplyQuadPagingLayer *pageLayer = [[MaplyQuadPagingLayer alloc]
     initWithCoordSystem:[[MaplySphericalMercator alloc] initWebStandard]
     delegate:self];
     
     [theViewC addLayer:pageLayer];*/
    
    [theViewC setHeight: 1.0];
    [theViewC setKeepNorthUp: YES];
    [theViewC animateToPosition:MaplyCoordinateMakeWithDegrees(-7.857325, 36.545708) time: 2.0];
    
    switch (_option)
    {
        case 0:
            [self fetchType:(@"AntiPollution")];
            break;
        case 1:
            [self fetchType:(@"Fishing")];
            break;
        case 2:
            [self fetchType:(@"Military")];
            break;
        case 3:
            [self fetchType:(@"Sailing")];
            break;
        case 4:
            [self fetchType:(@"Pleasure")];
            break;
        case 5:
            [self fetchType:(@"Rescue")];
            break;
        case 6:
            [self fetchType:(@"Passenger")];
            break;
        case 7:
            [self fetchType:(@"Cargo")];
            break;
        case 8:
            [self fetchType:(@"Tanker")];
            break;
        case 9:
            [self fetchType:(@"Towing")];
            break;
        default:
            [self fetchAll];
            break;
    }
    
    _slider = [[UISlider alloc] initWithFrame:CGRectMake(self.view.frame.size.width * 0.1,
                                                         self.view.frame.size.height * 0.85,
                                                         self.view.frame.size.width * 0.8,
                                                         self.view.frame.size.height * 0.1)];
    [_slider addTarget:self action:@selector(sliderValueChanged:)
      forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:_slider];
    
}

- (IBAction)sliderValueChanged:(UISlider *) slider {
    
    NSUInteger max = 0;
    for(id key in _vesselDict) {
        Vessel *temp = [_vesselDict objectForKey: key];
        if ([temp.locations count] > max) {
            max = [temp.locations count];
        }
    }
    
    slider.minimumValue = 0;
    slider.maximumValue = max - 1;
    
    //create steps for the slider
    for(int i = 0; i < max-1; i++) {
        if(slider.value < i+1) {
            if(slider.value >= i + 0.5) {
                slider.value = i+1;
                break;
            } else {
                slider.value = i;
                break;
            }
        }
    }
    

    NSMutableArray *vesselMarks = [self updatePositions];
    [self fetchCluster:vesselMarks];
   
}

-(NSMutableArray*) updatePositions {
    
    NSUInteger sliderVal = _slider.value;
    [theViewC clearAnnotations];
    
    
    if(_vesselMarkers1 != nil) {
        [theViewC removeObject: _vesselMarkers1];
    }
    if(_vesselMarkers2 != nil) {
        [theViewC removeObject: _vesselMarkers2];
    }
    if(_vesselMarkers3 != nil) {
        [theViewC removeObject: _vesselMarkers3];
    }
    
    
    NSMutableArray *vesselMarks = [NSMutableArray array];
    for(id key in _vesselDict) {
        Vessel * temp = _vesselDict[key];
        
            if([temp.locations count] > sliderVal) {
            MaplyScreenMarker *vesselMarker = [[MaplyScreenMarker alloc] init];
            vesselMarker.loc = MaplyCoordinateMake([temp.locations[(int)(_slider.value)][0] floatValue],
                                                   [temp.locations[(int)(_slider.value)][1] floatValue]);
            vesselMarker.userObject = temp.name;
            vesselMarker.image = [UIImage imageNamed:@"ship-wheel.png"];
            vesselMarker.size = CGSizeMake(24,24);
            vesselMarker.layoutImportance = MAXFLOAT;
            [vesselMarks addObject:vesselMarker];
               
        }
    }
    return vesselMarks;
    //[self fetchCluster:vesselMarks];
}

-(void) fetchCluster: (NSMutableArray *) vesselArray{
    
    int entry = 20;
    
    NSMutableArray *clusteredVesselsCount = [NSMutableArray array];
    for(int i = 0; i < entry*entry; i++){
        NSNumber* zero = [NSNumber numberWithInt:0];
        [clusteredVesselsCount addObject:zero];
    }
    
    NSMutableArray *clusteredVesselsX = [NSMutableArray array];
    for(int i = 0; i < entry*entry; i++){
        NSNumber* zero = [NSNumber numberWithInt:0];
        [clusteredVesselsX addObject:zero];
    }
    
    NSMutableArray *clusteredVesselsY = [NSMutableArray array];
    for(int i = 0; i < entry*entry; i++){
        NSNumber* zero = [NSNumber numberWithInt:0];
        [clusteredVesselsY addObject:zero];
    }
    
    for(int i = 0; i < [vesselArray count]; i++){
        
        MaplyScreenMarker *individual = [vesselArray objectAtIndex:i];
        float x_deg = individual.loc.x * 180.0/M_PI; // longitude radian to degree
        float y_deg = individual.loc.y * 180.0/M_PI; // latitude radian to degree
        // x (longitude) = [-180,180], y (latitude) = [-90,90]
        // subtract lower left corner & divide by total extents of the area
        float x_scale = (x_deg-(-180.0))/360.0;
        float y_scale = (y_deg-(-90.0))/180.0;
        //if(x_scale > entry1) x_scale = entry1;
        //if(y_scale > entry1) y_scale = entry1;
        int index = x_scale * entry * entry + y_scale * entry;
        if(index >= entry*entry){
            index = entry*entry - 1;
        }
        NSNumber* count = [NSNumber numberWithInt:([[clusteredVesselsCount objectAtIndex:index] intValue] + 1)];
        [clusteredVesselsCount replaceObjectAtIndex:index withObject:count];
        NSNumber* x_coor = [NSNumber numberWithFloat:(x_deg + [[clusteredVesselsX objectAtIndex:index] floatValue])];
        [clusteredVesselsX replaceObjectAtIndex:index withObject:x_coor];
        NSNumber* y_coor = [NSNumber numberWithFloat:(y_deg + [[clusteredVesselsY objectAtIndex:index] floatValue])];
        [clusteredVesselsY replaceObjectAtIndex:index withObject:y_coor];
    }
    
    NSMutableArray *clusteredVessels = [NSMutableArray array];
    for(int i = 0; i < [clusteredVesselsCount count]; i++){
        NSNumber *clustered = [clusteredVesselsCount objectAtIndex:i];
        if([clustered intValue] > 0){
            MaplyScreenMarker *vesselMarker = [[MaplyScreenMarker alloc] init];
            //int x = ((i / entry)/(float)entry * 360) + (-180);
            //int y = ((i % entry)/(float)entry * 180) + (-90);
            float x = [[clusteredVesselsX objectAtIndex:i] floatValue];
            float y = [[clusteredVesselsY objectAtIndex:i] floatValue];
            x = x /[clustered floatValue];
            y = y /[clustered floatValue];
            
            vesselMarker.loc = MaplyCoordinateMakeWithDegrees(x, y);
            vesselMarker.userObject = [@"Cluster Size: " stringByAppendingString:[clustered stringValue]];
            vesselMarker.image = [UIImage imageNamed:@"ship-wheel.png"];
            //vesselMarker.size = CGSizeMake(18.0+[clustered intValue]*1.5, 18.0+[clustered intValue]*1.5);
            float widthSize = 18.0+[clustered intValue]*1.5;
            float heightSize = 18.0+[clustered intValue]*1.5;
            if(widthSize > 80.0){
                widthSize = 80.0;
            }
            if(heightSize > 80.0){
                heightSize = 80.0;
            }
            vesselMarker.size = CGSizeMake(widthSize,heightSize);
            
            vesselMarker.layoutImportance = MAXFLOAT;
            
            [clusteredVessels addObject:vesselMarker];
            
        }
    }
    
    entry = 10;
    
    
    NSMutableArray *clusteredVesselsCount2 = [NSMutableArray array];
    for(int i = 0; i < entry*entry; i++){
        NSNumber* zero = [NSNumber numberWithInt:0];
        [clusteredVesselsCount2 addObject:zero];
    }
    
    NSMutableArray *clusteredVesselsX2 = [NSMutableArray array];
    for(int i = 0; i < entry*entry; i++){
        NSNumber* zero = [NSNumber numberWithInt:0];
        [clusteredVesselsX2 addObject:zero];
    }
    
    NSMutableArray *clusteredVesselsY2 = [NSMutableArray array];
    for(int i = 0; i < entry*entry; i++){
        NSNumber* zero = [NSNumber numberWithInt:0];
        [clusteredVesselsY2 addObject:zero];
    }
    
    for(int i = 0; i < [vesselArray count]; i++){
        MaplyScreenMarker *individual = [vesselArray objectAtIndex:i];
        float x_deg = individual.loc.x * 180.0/M_PI; // longitude radian to degree
        float y_deg = individual.loc.y * 180.0/M_PI; // latitude radian to degree
        // x (longitude) = [-180,180], y (latitude) = [-90,90]
        // subtract lower left corner & divide by total extents of the area
        float x_scale = (x_deg-(-180.0))/360.0;
        float y_scale = (y_deg-(-90.0))/180.0;
        //if(x_scale > entry1) x_scale = entry1;
        //if(y_scale > entry1) y_scale = entry1;
        int index = x_scale * entry * entry + y_scale * entry;
        if(index >= entry*entry){
            index = entry*entry - 1;
        }
        NSNumber* count = [NSNumber numberWithInt:([[clusteredVesselsCount2 objectAtIndex:index] intValue] + 1)];
        [clusteredVesselsCount2 replaceObjectAtIndex:index withObject:count];
        NSNumber* x_coor = [NSNumber numberWithFloat:(x_deg + [[clusteredVesselsX2 objectAtIndex:index] floatValue])];
        [clusteredVesselsX2 replaceObjectAtIndex:index withObject:x_coor];
        NSNumber* y_coor = [NSNumber numberWithFloat:(y_deg + [[clusteredVesselsY2 objectAtIndex:index] floatValue])];
        [clusteredVesselsY2 replaceObjectAtIndex:index withObject:y_coor];
    }
    
    NSMutableArray *clusteredVessels2 = [NSMutableArray array];
    for(int i = 0; i < [clusteredVesselsCount2 count]; i++){
        NSNumber *clustered = [clusteredVesselsCount2 objectAtIndex:i];
        if([clustered intValue] > 0){
            MaplyScreenMarker *vesselMarker = [[MaplyScreenMarker alloc] init];
            //int x = ((i / entry)/(float)entry * 360) + (-180);
            //int y = ((i % entry)/(float)entry * 180) + (-90);
            float x = [[clusteredVesselsX2 objectAtIndex:i] floatValue];
            float y = [[clusteredVesselsY2 objectAtIndex:i] floatValue];
            x = x /[clustered floatValue];
            y = y /[clustered floatValue];
            
            vesselMarker.loc = MaplyCoordinateMakeWithDegrees(x, y);
            vesselMarker.userObject = [@"Cluster Size: " stringByAppendingString:[clustered stringValue]];
            vesselMarker.image = [UIImage imageNamed:@"ship-wheel.png"];
            float widthSize = 18.0+[clustered intValue]*1.5;
            float heightSize = 18.0+[clustered intValue]*1.5;
            if(widthSize > 80.0){
                widthSize = 80.0;
            }
            if(heightSize > 80.0){
                heightSize = 80.0;
            }
            vesselMarker.size = CGSizeMake(widthSize,heightSize);
            
            vesselMarker.layoutImportance = MAXFLOAT;
            
            [clusteredVessels2 addObject:vesselMarker];
        }
    }
    
   
    if([vesselArray count] > 0) {
       
        _vesselMarkers1 = [theViewC addScreenMarkers:vesselArray desc:@{
                                                                       kMaplyMinVis:@0.0,
                                                                       kMaplyMaxVis:@0.25,
                                                                       }];
    }
   
    
    if([clusteredVessels count] > 0)
    {
      
        _vesselMarkers2 = [theViewC addScreenMarkers:clusteredVessels desc:@{
                                                                            kMaplyMinVis:@0.25,
                                                                            kMaplyMaxVis:@0.50,
                                                                            }];
    }
    
    if([clusteredVessels2 count] > 0)
    {
    
        _vesselMarkers3 = [theViewC addScreenMarkers:clusteredVessels2 desc:@{
                                                                             kMaplyMinVis:@0.5,
                                                                             kMaplyMaxVis:@1.0,
                                                                             }];
    }
    
    
}


-(void) fetchSampleVessels {
    
    NSData *xmlData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle]
                                                      pathForResource:@"sampleData" ofType:@"xml"]];
    
    VesselParser *vesselParser = [[VesselParser alloc] initWithXMLData:xmlData];
    if([vesselParser.markers count] > 0)
    {
        [theViewC addScreenMarkers:vesselParser.markers desc: nil];
    }
    
}


- (void) fetchAll {
    
    NSString *urlStr = @"http://sallykong.cartodb.com/api/v2/sql?format=GeoJSON&q=SELECT * FROM vesseltraffic ORDER BY time DESC LIMIT 2000";
    NSString *encodedString = [urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURLRequest *urlReq = [NSURLRequest requestWithURL:[NSURL URLWithString:encodedString]];
    [NSURLConnection sendAsynchronousRequest:urlReq queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError)
     {
         //NSLog(@"response: %@", response);
         NSError *jsonError = nil;
         id obj = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
         if ([obj isKindOfClass:[NSDictionary class]])
         {
             //NSDictionary *vesselDict = obj;
             //NSLog(@"return: %@", vesselDict);
         }
         
         MaplyVectorObject *vesselVec = [MaplyVectorObject VectorObjectFromGeoJSON:data];
         for (MaplyVectorObject *vessel in [vesselVec splitVectors])
         {
             MaplyScreenMarker *vesselMarker = [[MaplyScreenMarker alloc] init];
             vesselMarker.loc = [vessel center];
             
             vesselMarker.userObject = vessel.attributes[@"name"];
             vesselMarker.image = [UIImage imageNamed:@"ship-wheel.png"];
             vesselMarker.size = CGSizeMake(24,24);
             vesselMarker.layoutImportance = MAXFLOAT;
             [_vessels addObject:vesselMarker];
             
             
             Vessel *temp = [[Vessel alloc] initWithName: vessel.attributes[@"name"]];
             //NSDict
             if ([_vesselDict objectForKey: vessel.attributes[@"name"]]) {
                 
                 //add another position
                 temp = [_vesselDict objectForKey: vessel.attributes[@"name"]];
                 
                 MaplyCoordinate cent = [vessel center];
                 [temp.locations addObject: @[[[NSNumber alloc] initWithFloat: cent.x],
                                              [[NSNumber alloc] initWithFloat: cent.y]]];
                 _vesselDict[vessel.attributes[@"name"]] = temp;
                 
             } else {
                 
                 //Create Vessel Object
                 MaplyCoordinate cent = [vessel center];
                 [temp.locations addObject: @[[[NSNumber alloc] initWithFloat: cent.x],
                                              [[NSNumber alloc] initWithFloat: cent.y]]];
                 temp.type = vessel.attributes[@"type"];
                 _vesselDict[vessel.attributes[@"name"]] = temp;
                 
                 //First objects on the screen
                 MaplyScreenMarker *vesselMarker = [[MaplyScreenMarker alloc] init];
                 vesselMarker.loc = [vessel center];
                 vesselMarker.userObject = vessel.attributes[@"name"];
                 vesselMarker.image = [UIImage imageNamed:@"ship-wheel.png"];
                 vesselMarker.size = CGSizeMake(24,24);
                 vesselMarker.layoutImportance = MAXFLOAT;
                 [_vessels addObject:vesselMarker];
                 
                 
             }
         }
         
         [self fetchCluster:_vessels];
         
         
         
         
     }];
    
}

- (void) fetchType: (NSString *) typeName {
    
    NSString *urlStr = @"http://sallykong.cartodb.com/api/v2/sql?format=GeoJSON&q=SELECT * FROM vesseltraffic WHERE type";
    NSString *typeNum = @"";
    
    if ([@"Fishing" isEqualToString:typeName]){
        typeNum = @"=30";
        
    } else if ([@"Military" isEqualToString:typeName]) {
        typeNum = @"=35";
        
    } else if ([@"Sailing" isEqualToString:typeName]) {
        typeNum = @"=36";
        
    } else if ([@"Pleasure" isEqualToString:typeName]) {
        typeNum = @"=37";
        
    } else if ([@"Rescue" isEqualToString:typeName]) {
        typeNum = @"=51";
        
    } else if ([@"Towing" isEqualToString:typeName]) {
        typeNum = @"=31";
        
    } else if ([@"Passenger" isEqualToString:typeName]) {
        typeNum = @" BETWEEN 59 AND 70";
        
    } else if ([@"Cargo" isEqualToString:typeName]) {
        typeNum = @" BETWEEN 69 AND 80";
        
    } else if ([@"Tanker" isEqualToString:typeName]) {
        typeNum = @" BETWEEN 79 AND 90";
        
    } else if ([@"AntiPollution" isEqualToString:typeName]) {
        typeNum = @"=54";
    }
    
    urlStr = [urlStr stringByAppendingString:typeNum];
    urlStr = [urlStr stringByAppendingString:@" ORDER BY time DESC"];
    
    NSString *encodedString = [urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURLRequest *urlReq = [NSURLRequest requestWithURL:[NSURL URLWithString:encodedString]];
    [NSURLConnection sendAsynchronousRequest:urlReq queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError)
     {
         NSLog(@"url:%@,response: %@", urlStr, response);
         NSError *jsonError = nil;
         
         if(response != nil) {
             
             id obj = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
             if ([obj isKindOfClass:[NSDictionary class]])
             {
                //NSDictionary *vesselDict = obj;
                //NSLog(@"return: %@", vesselDict);
             } else{
                 NSLog(@"weird");
             }
             
             MaplyVectorObject *vesselVec = [MaplyVectorObject VectorObjectFromGeoJSON:data];
             
             
             for (MaplyVectorObject *vessel in [vesselVec splitVectors])
             {
                 Vessel *temp = [[Vessel alloc] initWithName: vessel.attributes[@"name"]];
                 
                 //NSDict
                 if ([_vesselDict objectForKey: vessel.attributes[@"name"]]) {
                     
                     //add another position
                     temp = [_vesselDict objectForKey: vessel.attributes[@"name"]];
                     
                     MaplyCoordinate cent = [vessel center];
                     [temp.locations addObject: @[[[NSNumber alloc] initWithFloat: cent.x],
                                                  [[NSNumber alloc] initWithFloat: cent.y]]];
                     
                     [_vesselDict setObject: temp forKey:vessel.attributes[@"name"]];
                      
                 } else {
                     
                     //Create Vessel Object
                     MaplyCoordinate cent = [vessel center];
                     [temp.locations addObject: @[[[NSNumber alloc] initWithFloat: cent.x],
                                                  [[NSNumber alloc] initWithFloat: cent.y]]];
                     temp.type = vessel.attributes[@"type"];
                     _vesselDict[vessel.attributes[@"name"]] = temp;
                     
                     //First objects on the screen
                     MaplyScreenMarker *vesselMarker = [[MaplyScreenMarker alloc] init];
                     vesselMarker.loc = [vessel center];
                     vesselMarker.userObject = vessel.attributes[@"name"];
                     vesselMarker.image = [UIImage imageNamed:@"ship-wheel.png"];
                     vesselMarker.size = CGSizeMake(24,24);
                     vesselMarker.layoutImportance = MAXFLOAT;
                     [_vessels addObject:vesselMarker];
                     
                     
                 }
             }
             
             [self fetchCluster:_vessels];
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
            /*selectLabelObj = [theViewC addScreenLabels:@[label]
             desc:@{ kMaplyFont: [UIFont systemFontOfSize:14.0]}];*/
            //annotation
            [theViewC clearAnnotations];
            MaplyAnnotation *annotation = [[MaplyAnnotation alloc] init];
            annotation.title = label.text;
            annotation.subTitle = [NSString stringWithFormat:@"Location:(%.3f,%.3f)", label.loc.x, label.loc.y];
            [theViewC addAnnotation:annotation forPoint:label.loc offset: CGPointMake(label.loc.x, label.loc.y)];
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

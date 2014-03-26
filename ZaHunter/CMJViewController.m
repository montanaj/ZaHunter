//
//  CMJViewController.m
//  ZaHunter
//
//  Created by Claire Jencks on 3/26/14.
//  Copyright (c) 2014 Claire Jencks. All rights reserved.
//

#import "CMJViewController.h"
#import <MapKit/MapKit.h>
#import <Foundation/Foundation.h>

//we are a delegate for this for this object (it'll be telling us what's going on in the universe
@interface CMJViewController ()<CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate>

@property CLLocationManager* coreLocationManager;
@property (strong, nonatomic) IBOutlet UITableView *myTableView;
@property NSMutableArray* restaurants;

@end

@implementation CMJViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.coreLocationManager = [CLLocationManager new];
    //this view controller will be the delegate of the cllprotocol
    self.coreLocationManager.delegate = self;
    
    self.restaurants = [NSMutableArray new];
    
    //turning on the coreLocationManager to start getting updates
    [self.coreLocationManager startUpdatingLocation];
    
    self.coreLocationManager.desiredAccuracy = kCLLocationAccuracyKilometer;
}

//tells us where the phone is (delegate)
-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"%@", error);
    
}
//find out where we are, gives us an array
//locationsssss is the whole earth, and location is the specific 1,000x1,000 square in which it locates you in
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    for (CLLocation *location in locations) {
        if (location.verticalAccuracy < 1000 && location.horizontalAccuracy <1000) {
            //self.myLabel.text = @"Location Found. Reverse Geocoding...";
            [self startReverseGeocode:location];
            [self.coreLocationManager stopUpdatingLocation];
            break;
            
        }
    }
}
//turns coordinates into a string (geocoding is opposite). calling reverse the geocode on this *location
-(void) startReverseGeocode: (CLLocation*) location
{
    
    CLGeocoder* geocoder = [CLGeocoder new];
    //calling a method on geocoder, passing two parameters 'location' and the block (which has an array of placemarks. placemarks is the array of all known places at a coordinate in apples database. (so here if you input a coordinate it would already know what is there).
    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        //self.myLabel.text = [NSString stringWithFormat:@"%@", placemarks.firstObject];
        [self findRestaurants:placemarks.firstObject byType:@"Pizza"];
        //this gives you the first object in the array (which is whatever the jail method does
    }];
    
}

//local search request, searching for things that aren't addresses (like jails, mcdonalds)
//always set a region otherwise it puts you in canada
//gives you back info in blocks (block is a parameter to the overall method)
-(void) findRestaurants: (CLPlacemark *) placemark byType:(NSString*)type
{
    //asking to find anything with the word prison
    //self.title = @"YOU ARE GUILTY";
    MKLocalSearchRequest* request = [MKLocalSearchRequest new];
    request.naturalLanguageQuery = type;
    request.region = MKCoordinateRegionMake(placemark.location.coordinate, MKCoordinateSpanMake(0.1, 0.1));
    
    MKLocalSearch* search = [[MKLocalSearch alloc] initWithRequest:request];
    [search startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error) {
        
        //mapItems is a property of a the MKlocalSearchResponse and set it equal to an array so we can deal with the information
        
        self.restaurants = [NSMutableArray arrayWithArray:response.mapItems];
        NSLog(@"array: %@", self.restaurants);
       
        [self.myTableView reloadData];
    }];
}

//directions from one map item to another
-(void) shortestRoutefromRestaurant: (MKMapItem*) destinationMapItem
{
    MKDirectionsRequest *request = [MKDirectionsRequest new];
    request.source = [MKMapItem mapItemForCurrentLocation];
    request.transportType = MKDirectionsTransportTypeWalking;
    request.destination = destinationMapItem;
    
    MKDirections *directions = [[MKDirections alloc] initWithRequest:request];
    [directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
        
        //you get back a MK Direction type of called response, it has a property called routes which is an array
        //NSArray *routesArray = response.routes;
        //call the view controllers method (self) ((whatever object you are currently in))
        [self findShortestPath:response.routes];
        NSLog(@"%@", response.routes);
    }];
}

-(MKRoute*) findShortestPath: (NSArray*)routes
{
    //creating an variable and setting it eqaul to the first object in routes
    MKRoute* shortestRoute = routes.firstObject;
    //quickest way to go through an array
    //here we're going through the array and finding the minimum. We're saying that if currentRoute (which is set the value of the first object in routes is
    for (MKRoute* currentRoute in routes)
    {
        if (currentRoute.distance < shortestRoute.distance)
        {
            shortestRoute = currentRoute;
            
        }
    
    }
    NSLog(@"%@", shortestRoute);
    return shortestRoute;
}








-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.restaurants.count;
}

-(UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"myTableViewCellReuseID"];
    
    MKMapItem* restaurant = self.restaurants[indexPath.row];
    cell.textLabel.text = restaurant.name;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", restaurant.placemark];
    return cell;
    
}





@end

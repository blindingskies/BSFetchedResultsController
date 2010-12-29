//
//  USStatesAndCities.m
//  BSFetchedResultsControllerExample
//
//  Created by Daniel Thorpe on 23/12/2010.
//  Copyright 2010 Blinding Skies Limited. All rights reserved.
//

#import "USStatesAndCities.h"


@implementation USStatesAndCities

SYNTHESIZE_SINGLETON_FOR_CLASS(USStatesAndCities);

@synthesize states=_states;



- (id)init {
	self = [super init];
	if(self) {
		// Import the US States and their cities from the file
		NSString *path = [[NSBundle mainBundle] pathForResource:@"USStatesAndCities" ofType:@"plist"];
		NSLog(@"loading data at %@", path);
		_states = [[NSDictionary alloc] initWithContentsOfFile:path];
	}
	return self;
}

- (NSDictionary *)randomCity {
	
	NSArray *theStates = [self.states allKeys];
	NSUInteger count = [theStates count];
	NSUInteger randomIndex = (NSUInteger)arc4random() % count;

	// State data
	NSDictionary *stateData = [self.states objectForKey:[theStates objectAtIndex:randomIndex]];
	count = [[stateData objectForKey:@"StateCities"] count];
	randomIndex = (NSUInteger)arc4random() % count;
	NSDictionary *cityData = [[stateData objectForKey:@"StateCities"] objectAtIndex:randomIndex];
	
	return [NSDictionary dictionaryWithObjectsAndKeys:
			[cityData objectForKey:@"CityName"], @"CityName",
			[cityData objectForKey:@"CityPopulation"], @"CityPopulation",			
			[stateData objectForKey:@"StateName"], @"StateName",
			[cityData objectForKey:@"isCapital"], @"isCapital",			
			nil];
	
}

@end

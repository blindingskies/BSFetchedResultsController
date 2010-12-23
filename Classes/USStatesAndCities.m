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

@end

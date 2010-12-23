//
//  USStatesAndCities.h
//  BSFetchedResultsControllerExample
//
//  Created by Daniel Thorpe on 23/12/2010.
//  Copyright 2010 Blinding Skies Limited. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SynthesizeSingleton.h"

@interface USStatesAndCities : NSObject { 
@private
	NSDictionary *_states; 	
}

@property (nonatomic, readonly) NSDictionary *states;

+ (USStatesAndCities *)sharedUSStatesAndCities;
	
@end

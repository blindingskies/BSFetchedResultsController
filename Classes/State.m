#import "State.h"
#import "NSManagedObjectContextAdditions.h"

@implementation State

@dynamic citiesByPopulation;

static NSArray *populationSortDescriptors = nil;

+ (void)initialize {
	if(self == [State class]) {
		NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"population" ascending:NO];
		populationSortDescriptors = [[NSArray arrayWithObject:descriptor] retain];
		[descriptor release];
	}
}	

+ (State *)stateWithName:(NSString *)aStateName inContext:(NSManagedObjectContext *)context {
	NSParameterAssert(aStateName);
	NSParameterAssert(context);
	
	State *aState = [[context fetchObjectsForEntityName:@"State" withPredicate:@"name == %@", aStateName] anyObject];
	
	if(!aState) {
		aState = [State insertInManagedObjectContext:context];
		aState.name = aStateName;
	}
	
	return aState;
}

- (NSArray *)citiesByPopulation {
	return [self.cities sortedArrayUsingDescriptors:populationSortDescriptors];
}

@end

#import "City.h"
#import "NSManagedObjectContextAdditions.h"

@implementation City

+ (BOOL)cityExistsWithName:(NSString *)aString inContext:(NSManagedObjectContext *)context {
	NSParameterAssert(aString);
	NSParameterAssert(context);
	
	City *city = [[context fetchObjectsForEntityName:@"City" withPredicate:@"name == %@", aString] anyObject];
	if (!city) return NO;
	return YES;
}

+ (City *)cityWithName:(NSString *)aString population:(NSNumber *)aNumber inContext:(NSManagedObjectContext *)context {
	NSParameterAssert(aString);
	NSParameterAssert(aNumber);
	NSParameterAssert(context);
	
	City *city = [[context fetchObjectsForEntityName:@"City" withPredicate:@"name == %@", aString] anyObject];
	
	if(!city) {
		city = [City insertInManagedObjectContext:context];
		city.name = aString;
	}	
	
	city.population = aNumber;
	
	return city;
}

@end

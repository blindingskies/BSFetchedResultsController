// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to State.m instead.

#import "_State.h"

@implementation StateID
@end

@implementation _State

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"State" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"State";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"State" inManagedObjectContext:moc_];
}

- (StateID*)objectID {
	return (StateID*)[super objectID];
}




@dynamic name;






@dynamic cities;

	
- (NSMutableSet*)citiesSet {
	[self willAccessValueForKey:@"cities"];
	NSMutableSet *result = [self mutableSetValueForKey:@"cities"];
	[self didAccessValueForKey:@"cities"];
	return result;
}
	





@end

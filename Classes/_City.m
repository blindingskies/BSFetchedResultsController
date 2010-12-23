// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to City.m instead.

#import "_City.h"

@implementation CityID
@end

@implementation _City

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"City" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"City";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"City" inManagedObjectContext:moc_];
}

- (CityID*)objectID {
	return (CityID*)[super objectID];
}




@dynamic population;



- (int)populationValue {
	NSNumber *result = [self population];
	return [result intValue];
}

- (void)setPopulationValue:(int)value_ {
	[self setPopulation:[NSNumber numberWithInt:value_]];
}

- (int)primitivePopulationValue {
	NSNumber *result = [self primitivePopulation];
	return [result intValue];
}

- (void)setPrimitivePopulationValue:(int)value_ {
	[self setPrimitivePopulation:[NSNumber numberWithInt:value_]];
}





@dynamic name;






@dynamic isCapital;



- (BOOL)isCapitalValue {
	NSNumber *result = [self isCapital];
	return [result boolValue];
}

- (void)setIsCapitalValue:(BOOL)value_ {
	[self setIsCapital:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveIsCapitalValue {
	NSNumber *result = [self primitiveIsCapital];
	return [result boolValue];
}

- (void)setPrimitiveIsCapitalValue:(BOOL)value_ {
	[self setPrimitiveIsCapital:[NSNumber numberWithBool:value_]];
}





@dynamic state;

	





@end

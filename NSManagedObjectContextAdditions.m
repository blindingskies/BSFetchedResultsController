//
//  NSManagedObjectContextAdditions.m
//  Covariates
//
//  Created by Daniel Thorpe on 06/03/2009.
//  Copyright 2009 Blinding Skies Limited. All rights reserved.
//

#import "NSManagedObjectContextAdditions.h"

@implementation NSManagedObjectContext (NSManagedObjectContextAdditions)

- (void)deleteAllObjectsOfEntity:(NSString *)entityName {
	NSFetchRequest *fetch = [[[NSFetchRequest alloc] init] autorelease];
	[fetch setEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:self]];
	NSError *error = nil;
	NSArray *result = [self executeFetchRequest:fetch error:&error];
	for(NSManagedObject *obj in result) {
		[self deleteObject:obj];
	}
}

- (NSSet *)fetchObjectsForEntityName:(NSString *)entityName withPredicate:(id)predicateOrString, ... {
	
	NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:self];
    if(!entity) return nil;
	NSFetchRequest *fetch = [[[NSFetchRequest alloc] init] autorelease];
	[fetch setEntity:entity];
	if(predicateOrString) {
		NSPredicate *predicate;
		if([predicateOrString isKindOfClass:[NSString class]]) {
			va_list variableArguments;
			va_start(variableArguments, predicateOrString);
			predicate = [NSPredicate predicateWithFormat:predicateOrString arguments:variableArguments];
			va_end(variableArguments);
		} else {
			NSAssert2([predicateOrString isKindOfClass:[NSPredicate class]], @"Second parameter passed to %s is of unexpected class %s", sel_getName(_cmd), object_getClassName(predicateOrString));
			predicate = (NSPredicate *)predicateOrString;
		}
		[fetch setPredicate:predicate];	
	}
	NSError *error = nil;
	NSArray *results = [self executeFetchRequest:fetch error:&error];
	if(error != nil) {
		[NSException raise:NSGenericException format:@"%@", [error description]];
	}
	return [NSSet setWithArray:results];
}

@end

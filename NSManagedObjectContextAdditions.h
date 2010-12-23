//
//  NSManagedObjectContextAdditions.h
//  Covariates
//
//  Created by Daniel Thorpe on 06/03/2009.
//  Copyright 2009 Blinding Skies Limited. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObjectContext (NSManagedObjectContextAdditions)

- (void)deleteAllObjectsOfEntity:(NSString *)entityName;
- (NSSet *)fetchObjectsForEntityName:(NSString *)entityName withPredicate:(id)predicateOrString, ...;

@end

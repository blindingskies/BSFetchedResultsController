// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to State.h instead.

#import <CoreData/CoreData.h>


@class City;



@interface StateID : NSManagedObjectID {}
@end

@interface _State : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (StateID*)objectID;



@property (nonatomic, retain) NSString *name;

//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;




@property (nonatomic, retain) NSSet* cities;
- (NSMutableSet*)citiesSet;




@end

@interface _State (CoreDataGeneratedAccessors)

- (void)addCities:(NSSet*)value_;
- (void)removeCities:(NSSet*)value_;
- (void)addCitiesObject:(City*)value_;
- (void)removeCitiesObject:(City*)value_;

@end

@interface _State (CoreDataGeneratedPrimitiveAccessors)

- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;




- (NSMutableSet*)primitiveCities;
- (void)setPrimitiveCities:(NSMutableSet*)value;


@end

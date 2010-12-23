// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to City.h instead.

#import <CoreData/CoreData.h>


@class State;





@interface CityID : NSManagedObjectID {}
@end

@interface _City : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (CityID*)objectID;



@property (nonatomic, retain) NSNumber *population;

@property int populationValue;
- (int)populationValue;
- (void)setPopulationValue:(int)value_;

//- (BOOL)validatePopulation:(id*)value_ error:(NSError**)error_;



@property (nonatomic, retain) NSString *name;

//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;



@property (nonatomic, retain) NSNumber *isCapital;

@property BOOL isCapitalValue;
- (BOOL)isCapitalValue;
- (void)setIsCapitalValue:(BOOL)value_;

//- (BOOL)validateIsCapital:(id*)value_ error:(NSError**)error_;




@property (nonatomic, retain) State* state;
//- (BOOL)validateState:(id*)value_ error:(NSError**)error_;




@end

@interface _City (CoreDataGeneratedAccessors)

@end

@interface _City (CoreDataGeneratedPrimitiveAccessors)

- (NSNumber*)primitivePopulation;
- (void)setPrimitivePopulation:(NSNumber*)value;

- (int)primitivePopulationValue;
- (void)setPrimitivePopulationValue:(int)value_;


- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;


- (NSNumber*)primitiveIsCapital;
- (void)setPrimitiveIsCapital:(NSNumber*)value;

- (BOOL)primitiveIsCapitalValue;
- (void)setPrimitiveIsCapitalValue:(BOOL)value_;




- (State*)primitiveState;
- (void)setPrimitiveState:(State*)value;


@end

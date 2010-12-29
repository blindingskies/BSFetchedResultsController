#import "_City.h"

@interface City : _City {}

+ (BOOL)cityExistsWithName:(NSString *)aString inContext:(NSManagedObjectContext *)context;
+ (City *)cityWithName:(NSString *)aString population:(NSNumber *)aNumber inContext:(NSManagedObjectContext *)context;

@end

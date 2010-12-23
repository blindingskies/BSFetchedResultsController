#import "_City.h"

@interface City : _City {}

+ (City *)cityWithName:(NSString *)aString population:(NSNumber *)aNumber inContext:(NSManagedObjectContext *)context;

@end

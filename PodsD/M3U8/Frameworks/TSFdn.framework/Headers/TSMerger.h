//
//  TSMerger.h
//  QVGrab
//
//  Created by Cityu on 2025/4/4.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TSMerger : NSObject
@property (nonatomic, copy, nullable) NSString *dir;

- (void)start;
- (void)stop;
- (void)pause;
- (void)resume;
- (void)clearCache;

+ (instancetype)mergerTsFiles:(NSArray<NSString *> *)tsFiles progress:(void(^)(float p))progress completion:(void(^)(NSString * _Nullable file, NSError * _Nullable error))completion;
@end

@interface TSMerger(Check)
+ (BOOL)isTSFileValid:(NSString *)tsPath;
@end

NS_ASSUME_NONNULL_END

//
//  TSFilter.h
//  QVGrab
//
//  Created by Cityu on 2025/4/4.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * TS流过滤器类
 * 用于分析和分类TS文件的流信息，避免不同流信息导致的视频合成问题
 */
@interface TSFilter : NSObject

/**
 * TS文件路径数组
 */
@property (nonatomic, strong, readonly) NSArray<NSString *> *tsFiles;

/**
 * 创建TS过滤器实例
 * @param tsFiles TS文件路径数组
 * @return TS过滤器实例
 */
+ (instancetype)filterWithTsFiles:(NSArray<NSString *> *)tsFiles;

/**
 * 分析当前实例的TS源并分类
 * @return 分类后的过滤器数组
 */
- (NSArray<TSFilter *> *)filter;

/**
 * 获取当前过滤器的流描述信息
 * @return 流描述字符串
 */
- (NSString *)getStreamDescription;

/**
 * 检查指定文件是否与当前过滤器兼容
 * @param filePath 文件路径
 * @return 是否兼容
 */
- (BOOL)isStreamCompatible:(NSString *)filePath;

@end

NS_ASSUME_NONNULL_END 
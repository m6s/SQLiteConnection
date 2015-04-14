//
// Created by Matthias Schmitt on 4/13/15.
// Copyright (c) 2015 Matthias Schmitt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@class MATSQLiteConnection;
@class MATSQLiteStatement;

typedef NS_ENUM(NSInteger, MATSQLiteDatabaseType) {
    MATSQLiteDatabaseTypeInMemory, MATSQLiteDatabaseTypeTemporary, MATSQLiteDatabaseTypeFile
};

@interface MATSQLiteConnection : NSObject
@property(nonatomic, readonly) struct sqlite3 *conn; // for testing purposes

+ (NSError *)lastErrorForWrappedConnection:(sqlite3 *)conn;

- (BOOL)openInMemoryDatabaseWithError:(NSError *__autoreleasing *)error;

- (BOOL)openTemporaryDatabaseWithError:(NSError *__autoreleasing *)error;

- (BOOL)openDatabaseAtPath:(NSString *)path error:(NSError *__autoreleasing *)error;

- (MATSQLiteStatement *)prepareStatementWithSQL:(NSString *)sql error:(NSError *__autoreleasing *)error;

- (int)affectedRowCount;

- (sqlite3_int64)lastInsertedRowID;

- (NSInputStream *)inputStreamForTable:(NSString *)table
                                column:(NSString *)column
                                 rowID:(sqlite3_int64)rowID
                                 error:(NSError *__autoreleasing *)error;

- (NSOutputStream *)outputStreamForTable:(NSString *)table
                                  column:(NSString *)column
                                   rowID:(sqlite3_int64)rowID
                                   error:(NSError *__autoreleasing *)error;

- (BOOL)executeSQL:(NSString *)sql error:(NSError *__autoreleasing *)error;

- (NSString *)queryTextWithSQL:(NSString *)sql error:(NSError *__autoreleasing *)error;

- (int)queryIntWithSQL:(NSString *)sql error:(NSError *__autoreleasing *)error;

- (sqlite3_int64)queryInt64WithSQL:(NSString *)sql error:(NSError *__autoreleasing *)error;

- (double)queryDoubleWithSQL:(NSString *)sql error:(NSError *__autoreleasing *)error;

- (NSData *)queryBLOBWithSQL:(NSString *)sql error:(NSError *__autoreleasing *)error;

- (NSArray *)querySingleRowWithSQL:(NSString *)sql error:(NSError *__autoreleasing *)error;

- (NSArray *)queryRowsWithSQL:(NSString *)sql error:(NSError *__autoreleasing *)error;
@end

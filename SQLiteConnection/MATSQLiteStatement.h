//
// Created by Matthias Schmitt on 4/14/15.
// Copyright (c) 2015 Matthias Schmitt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@class MATSQLiteConnection;

typedef NS_ENUM(NSInteger, MATSQLiteColumnType) {
    MATSQLiteColumnTypeInteger = SQLITE_INTEGER,
    MATSQLiteColumnTypeDouble = SQLITE_FLOAT,
    MATSQLiteColumnTypeBlob = SQLITE_BLOB,
    MATSQLiteColumnTypeNull = SQLITE_NULL,
    MATSQLiteColumnTypeText = SQLITE_TEXT
};

@interface MATSQLiteStatement : NSObject
@property(nonatomic, readonly, getter=isAfterLastRow) BOOL afterLastRow;
@property(nonatomic, readonly) BOOL evaluated;

- (instancetype)initWithWrappedConnection:(sqlite3 *)conn wrappedStatement:(sqlite3_stmt *)stmt;

- (void)reset;

- (BOOL)clearBindingsWithError:(NSError *__autoreleasing *)error;

- (BOOL)bindInt:(int)intValue toIndex:(int)idx error:(NSError *__autoreleasing *)error;

- (BOOL)bindDouble:(double)doubleValue toIndex:(int)idx error:(NSError *__autoreleasing *)error;

- (BOOL)bindBLOB:(NSData *)data toIndex:(int)idx error:(NSError *__autoreleasing *)error;

- (BOOL)bindNullToIndex:(int)idx error:(NSError *__autoreleasing *)error;

- (BOOL)bindText:(NSString *)text toIndex:(int)idx error:(NSError *__autoreleasing *)error;

- (BOOL)stepWithError:(NSError *__autoreleasing *)error;

- (int)dataCount;

- (int)columnCount;

- (NSString *)columnNameAtIndex:(int)idx error:(NSError *__autoreleasing *)error;

- (MATSQLiteColumnType)columnTypeAtIndex:(int)idx;

- (NSString *)textAtColumnIndex:(int)idx;

- (int)intAtColumnIndex:(int)idx;

- (sqlite3_int64)int64AtColumnIndex:(int)idx;

- (double)doubleAtColumnIndex:(int)idx;

- (NSData *)blobAtColumnIndex:(int)idx;

- (id)objectAtIndexedSubscript:(NSInteger)idx;
@end

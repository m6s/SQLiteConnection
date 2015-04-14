//
// Created by Matthias Schmitt on 4/13/15.
// Copyright (c) 2015 Matthias Schmitt. All rights reserved.
//

#import <sqlite3.h>
#import "MATSQLiteConnection.h"
#import "Constants.h"
#import "MATSQLiteStatement.h"

@implementation MATSQLiteConnection {
    sqlite3 *_conn;
    enum MATSQLiteDatabaseType _databaseType;
}

+ (NSError *)lastErrorForWrappedConnection:(sqlite3 *)conn {
    char const *utf8Message = sqlite3_errmsg(conn);
    NSString *message = [NSString stringWithUTF8String:utf8Message];
    int errorCode = sqlite3_errcode(conn);
//    char const *utf8Description = sqlite3_errstr(_db);
//    NSString *description = [NSString stringWithUTF8String:utf8Description];
    NSString *description = message;
    return [NSError errorWithDomain:MATSQLiteErrorDomain
                               code:errorCode
                           userInfo:@{NSLocalizedDescriptionKey : NSLocalizedString(description, nil),
                                   NSLocalizedFailureReasonErrorKey : NSLocalizedString(message, nil)}];
}

- (BOOL)openInMemoryDatabaseWithError:(NSError *__autoreleasing *)error {
    _databaseType = MATSQLiteDatabaseTypeInMemory;
    return [self openDatabaseWithUTF8Path:":memory:" error:nil];
}

- (BOOL)openTemporaryDatabaseWithError:(NSError *__autoreleasing *)error {
    _databaseType = MATSQLiteDatabaseTypeTemporary;
    return [self openDatabaseWithUTF8Path:"" error:nil];
}

- (BOOL)openDatabaseAtPath:(NSString *)path error:(NSError *__autoreleasing *)error {
    _databaseType = MATSQLiteDatabaseTypeFile;
    return [self openDatabaseWithUTF8Path:[path UTF8String] error:nil];
}

- (BOOL)openDatabaseWithUTF8Path:(char const *)utf8Path error:(NSError *__autoreleasing *)error {
    int sqliteResult = sqlite3_open(utf8Path, &_conn);
    if (sqliteResult != SQLITE_OK) {
        if (error) {
            *error = [MATSQLiteConnection lastErrorForWrappedConnection:_conn];
        }
        return NO;
    }
    return YES;
}

- (MATSQLiteStatement *)prepareStatementWithSQL:(NSString *)sql error:(NSError *__autoreleasing *)error {
    sqlite3_stmt *stmt;
    int sqliteResult = sqlite3_prepare_v2(_conn, [sql UTF8String], -1, &stmt, nil);
    if (sqliteResult != SQLITE_OK) {
        if (error) {
            *error = [MATSQLiteConnection lastErrorForWrappedConnection:_conn];
        }
        return nil;
    }
    return [[MATSQLiteStatement alloc] initWithWrappedConnection:_conn wrappedStatement:stmt];
}

- (int)affectedRowCount {
    return sqlite3_changes(_conn);
}

- (sqlite3_int64)lastInsertedRowID {
    return sqlite3_last_insert_rowid(_conn);
}

- (NSInputStream *)inputStreamForTable:(NSString *)table
                                column:(NSString *)column
                                 rowID:(sqlite3_int64)rowID
                                 error:(NSError *__autoreleasing *)error {
    sqlite3_blob *pBlob = [self blobPointerForTable:table column:column rowId:rowID readWrite:YES error:error];
    if (!pBlob) {
        return nil;
    }
    return nil; //TODO
}

- (NSOutputStream *)outputStreamForTable:(NSString *)table
                                  column:(NSString *)column
                                   rowID:(sqlite3_int64)rowID
                                   error:(NSError *__autoreleasing *)error {
    sqlite3_blob *pBlob = [self blobPointerForTable:table column:column rowId:rowID readWrite:NO error:nil];
    if (!pBlob) {
        return nil;
    }
    return nil; //TODO
}

- (sqlite3_blob *)blobPointerForTable:(NSString *)table
                               column:(NSString *)column
                                rowId:(sqlite3_int64)rowId
                            readWrite:(BOOL)rw
                                error:(NSError *__autoreleasing *)error {
    sqlite3_blob *pBlob;
    char *db = _databaseType == MATSQLiteDatabaseTypeTemporary ? "temp" : "main";
    int sqliteResult = sqlite3_blob_open(_conn, db, [table UTF8String], [column UTF8String], rowId, rw, &pBlob);
    if (sqliteResult != SQLITE_OK) {
        if (error) {
            *error = [MATSQLiteConnection lastErrorForWrappedConnection:_conn];
        }
        return nil;
    }
    return pBlob;
}

- (BOOL)executeSQL:(NSString *)sql error:(NSError *__autoreleasing *)error {
    MATSQLiteStatement *statement = [self prepareStatementWithSQL:sql error:error];
    return statement != nil && [statement stepWithError:error];
}


- (NSString *)queryTextWithSQL:(NSString *)sql error:(NSError *__autoreleasing *)error {
    MATSQLiteStatement *statement = [self prepareStatementWithSQL:sql error:error];
    if (!statement || ![statement stepWithError:error]) {
        return 0;
    }
    return [statement textAtColumnIndex:0];
}

- (int)queryIntWithSQL:(NSString *)sql error:(NSError *__autoreleasing *)error {
    MATSQLiteStatement *statement = [self prepareStatementWithSQL:sql error:error];
    if (!statement || ![statement stepWithError:error]) {
        return 0;
    }
    return [statement intAtColumnIndex:0];
}

- (sqlite3_int64)queryInt64WithSQL:(NSString *)sql error:(NSError *__autoreleasing *)error {
    MATSQLiteStatement *statement = [self prepareStatementWithSQL:sql error:error];
    if (!statement || ![statement stepWithError:error]) {
        return 0;
    }
    return [statement int64AtColumnIndex:0];
}

- (double)queryDoubleWithSQL:(NSString *)sql error:(NSError *__autoreleasing *)error {
    MATSQLiteStatement *statement = [self prepareStatementWithSQL:sql error:error];
    if (!statement || ![statement stepWithError:error]) {
        return 0;
    }
    return [statement doubleAtColumnIndex:0];
}

- (NSData *)queryBLOBWithSQL:(NSString *)sql error:(NSError *__autoreleasing *)error {
    MATSQLiteStatement *statement = [self prepareStatementWithSQL:sql error:error];
    if (!statement || ![statement stepWithError:error]) {
        return 0;
    }
    return [statement blobAtColumnIndex:0];
}

- (NSArray *)querySingleRowWithSQL:(NSString *)sql error:(NSError *__autoreleasing *)error {
    MATSQLiteStatement *statement = [self prepareStatementWithSQL:sql error:error];
    if (!statement || ![statement stepWithError:error]) {
        return 0;
    }
    NSMutableArray *row = [[NSMutableArray alloc] initWithCapacity:[statement columnCount]];
    for (int i = 0; i < [statement columnCount]; ++i) {
        row[i] = statement[i];
    }
    return row;
}

- (NSArray *)queryRowsWithSQL:(NSString *)sql error:(NSError *__autoreleasing *)error {
    MATSQLiteStatement *statement = [self prepareStatementWithSQL:sql error:error];
    if (!statement) {
        return nil;
    }
    NSMutableArray *rows = [[NSMutableArray alloc] init];
    for ([statement stepWithError:error]; !statement.isAfterLastRow; [statement stepWithError:error]) {
        NSMutableArray *row = [[NSMutableArray alloc] initWithCapacity:[statement columnCount]];
        for (int i = 0; i < [statement columnCount]; ++i) {
            row[i] = statement[i];
        }
        [rows addObject:row];
    }
    return rows;
}

- (void)dealloc {
    sqlite3_close(_conn);
}

@end

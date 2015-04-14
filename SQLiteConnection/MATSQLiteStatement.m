//
// Created by Matthias Schmitt on 4/14/15.
// Copyright (c) 2015 Matthias Schmitt. All rights reserved.
//

#import <sqlite3.h>
#import "MATSQLiteStatement.h"
#import "MATSQLiteConnection.h"


static void check_column_index(int idx, BOOL evaluated, BOOL afterLastRow, int columnCount) {
    if (!evaluated) {
        [NSException raise:NSGenericException format:@"accessing column information before evaluating statement"];
    }
    if (afterLastRow) {
        [NSException raise:NSGenericException format:@"accessing column information after last row"];
    }
    if (idx < 0 || idx >= columnCount) {
        [NSException raise:NSRangeException format:@"index %d beyond bounds [0 .. %d]", idx, columnCount];
    }
}

@implementation MATSQLiteStatement {
    sqlite3 *_conn;
    sqlite3_stmt *_stmt;
    BOOL _evaluated;
    BOOL _afterLastRow;
    int _columnCount;
}
@synthesize afterLastRow = _afterLastRow;
@synthesize evaluated = _evaluated;

- (instancetype)initWithWrappedConnection:(sqlite3 *)conn wrappedStatement:(sqlite3_stmt *)stmt {
    self = [super init];
    if (self) {
        _conn = conn;
        _stmt = stmt;
        _afterLastRow = NO;
        _evaluated = NO;
        _columnCount = sqlite3_column_count(_stmt);
    }
    return self;
}

- (void)reset {
    sqlite3_reset(_stmt);
    _afterLastRow = NO;
    _evaluated = NO;
}

- (BOOL)clearBindingsWithError:(NSError *__autoreleasing *)error {
    int sqliteResult = sqlite3_clear_bindings(_stmt);
    if (sqliteResult != SQLITE_OK) {
        if (error) {
            *error = [MATSQLiteConnection lastErrorForWrappedConnection:_conn];
        }
        return NO;
    }
    return YES;
}

- (BOOL)bindInt:(int)intValue toIndex:(int)idx error:(NSError *__autoreleasing *)error {
    int sqliteResult = sqlite3_bind_int(_stmt, idx + 1, intValue);
    if (sqliteResult != SQLITE_OK) {
        if (error) {
            *error = [MATSQLiteConnection lastErrorForWrappedConnection:_conn];
        }
        return NO;
    }
    return YES;
}

- (BOOL)bindDouble:(double)doubleValue toIndex:(int)idx error:(NSError *__autoreleasing *)error {
    int sqliteResult = sqlite3_bind_double(_stmt, idx + 1, doubleValue);
    if (sqliteResult != SQLITE_OK) {
        if (error) {
            *error = [MATSQLiteConnection lastErrorForWrappedConnection:_conn];
        }
        return NO;
    }
    return YES;
}

- (BOOL)bindBLOB:(NSData *)data toIndex:(int)idx error:(NSError *__autoreleasing *)error {
    int sqliteResult = sqlite3_bind_blob(_stmt, idx + 1, data.bytes, (int) data.length, SQLITE_TRANSIENT);
    if (sqliteResult != SQLITE_OK) {
        if (error) {
            *error = [MATSQLiteConnection lastErrorForWrappedConnection:_conn];
        }
        return NO;
    }
    return YES;
}

- (BOOL)bindNullToIndex:(int)idx error:(NSError *__autoreleasing *)error {
    int sqliteResult = sqlite3_bind_null(_stmt, idx + 1);
    if (sqliteResult != SQLITE_OK) {
        if (error) {
            *error = [MATSQLiteConnection lastErrorForWrappedConnection:_conn];
        }
        return NO;
    }
    return YES;
}

- (BOOL)bindText:(NSString *)text toIndex:(int)idx error:(NSError *__autoreleasing *)error {
    int sqliteResult = sqlite3_bind_text(_stmt, idx + 1, [text UTF8String], -1, SQLITE_TRANSIENT);
    if (sqliteResult != SQLITE_OK) {
        if (error) {
            *error = [MATSQLiteConnection lastErrorForWrappedConnection:_conn];
        }
        return NO;
    }
    return YES;
}

- (BOOL)stepWithError:(NSError *__autoreleasing *)error {
    int sqliteResult = sqlite3_step(_stmt);
    switch (sqliteResult) {
        case SQLITE_DONE:
            _afterLastRow = YES;
            break;
        case SQLITE_ROW:
            break;
        default:
            if (error) {
                *error = [MATSQLiteConnection lastErrorForWrappedConnection:_conn];
            }
            return NO;
    }
    _evaluated = YES;
    return YES;
}

- (int)dataCount {
    return sqlite3_data_count(_stmt);
}

- (int)columnCount {
    return _columnCount;
}

- (NSString *)columnNameAtIndex:(int)idx error:(NSError *__autoreleasing *)error {
    char *utf8ColumnName = (char *) sqlite3_column_name(_stmt, idx);
    if (!utf8ColumnName) {
        if (error) {
            *error = [MATSQLiteConnection lastErrorForWrappedConnection:_conn];
        }
        return nil;
    }
    return [NSString stringWithUTF8String:utf8ColumnName];
}

- (MATSQLiteColumnType)columnTypeAtIndex:(int)idx {
    check_column_index(idx, _evaluated, _afterLastRow, _columnCount);
    return sqlite3_column_type(_stmt, idx);
}

- (NSString *)textAtColumnIndex:(int)idx {
    check_column_index(idx, _evaluated, _afterLastRow, _columnCount);
    char *utf8Text = (char *) sqlite3_column_text(_stmt, idx);
    return [NSString stringWithUTF8String:utf8Text];
}

- (int)intAtColumnIndex:(int)idx {
    check_column_index(idx, _evaluated, _afterLastRow, _columnCount);
    return sqlite3_column_int(_stmt, idx);
}

- (sqlite3_int64)int64AtColumnIndex:(int)idx {
    check_column_index(idx, _evaluated, _afterLastRow, _columnCount);
    return sqlite3_column_int64(_stmt, idx); // SELECT rowid FROM TABLE WHERE id = "foo"
}

- (double)doubleAtColumnIndex:(int)idx {
    check_column_index(idx, _evaluated, _afterLastRow, _columnCount);
    return sqlite3_column_double(_stmt, idx);
}

- (NSData *)blobAtColumnIndex:(int)idx {
    check_column_index(idx, _evaluated, _afterLastRow, _columnCount);
    void const *blob = sqlite3_column_blob(_stmt, idx);
    int size = sqlite3_column_bytes(_stmt, idx);
    return [[NSData alloc] initWithBytes:blob length:size];
}

- (id)objectAtIndexedSubscript:(NSInteger)idx {
    if (idx > INT_MAX) {
        [NSException raise:NSRangeException format:@"index %ld exceeds INT_MAX", (long) idx];
    }
    int i = (int) idx;
    MATSQLiteColumnType columnType = [self columnTypeAtIndex:i];
    switch (columnType) {
        case MATSQLiteColumnTypeText:
            return [self textAtColumnIndex:i];
        case MATSQLiteColumnTypeBlob:
            return [self blobAtColumnIndex:i];
        case MATSQLiteColumnTypeDouble: {
            double aDouble = [self doubleAtColumnIndex:i];
            return [NSValue value:&aDouble withObjCType:@encode(double *)];
        };
        case MATSQLiteColumnTypeNull:
            return nil;
        case MATSQLiteColumnTypeInteger: {
            int anInt = [self intAtColumnIndex:i];
            return [NSValue value:&anInt withObjCType:@encode(int *)];
        };
        default:
            abort();
    }
}

- (void)dealloc {
    sqlite3_finalize(_stmt);
}
@end

//
//  Created by Matthias Schmitt on 4/13/15.
//  Copyright (c) 2015 Matthias Schmitt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "SQLiteConnection.h"

@interface SQLiteConnectionTests : XCTestCase

@end

@implementation SQLiteConnectionTests

- (void)testBasicTableCreationAndInsertionAndQuery {
    MATSQLiteConnection *connection = [[MATSQLiteConnection alloc] init];
    XCTAssert([connection openInMemoryDatabaseWithError:nil]);
    MATSQLiteStatement *statement =
            [connection prepareStatementWithSQL:@"CREATE TABLE channels(id INTEGER PRIMARY KEY, remoteID TEXT);"
                                          error:nil];
    XCTAssertNotNil(statement);
    XCTAssert([statement stepWithError:nil]);
    statement = [connection prepareStatementWithSQL:@"INSERT INTO channels VALUES (0, 'bbc');" error:nil];
    XCTAssertNotNil(statement);
    XCTAssert([statement stepWithError:nil]);
    statement = [connection prepareStatementWithSQL:@"SELECT * FROM channels;" error:nil];
    XCTAssertNotNil(statement);
    XCTAssertEqual([statement columnCount], 2);
    XCTAssert([statement stepWithError:nil]);
    XCTAssertEqualObjects([statement textAtColumnIndex:1], @"bbc");
}

- (void)testConvenienceMethods {
    MATSQLiteConnection *connection = [[MATSQLiteConnection alloc] init];
    [connection openInMemoryDatabaseWithError:nil];
    XCTAssert([connection executeSQL:@"CREATE TABLE channels(id INTEGER PRIMARY KEY, remoteID TEXT);" error:nil]);
    XCTAssert([connection executeSQL:@"INSERT INTO channels VALUES (0, 'bbc');" error:nil]);
    NSArray *row = [connection querySingleRowWithSQL:@"SELECT * FROM channels;" error:nil];
    XCTAssertNotNil(row);
    XCTAssertEqual(row.count, 2);
    XCTAssertEqualObjects(row[1], @"bbc");
}

- (void)testStatementBinding {
    MATSQLiteConnection *connection = [[MATSQLiteConnection alloc] init];
    [connection openInMemoryDatabaseWithError:nil];
    [connection executeSQL:@"CREATE TABLE channels(id INTEGER PRIMARY KEY, remoteID TEXT);" error:nil];
    MATSQLiteStatement
            *statement = [connection prepareStatementWithSQL:@"INSERT INTO channels VALUES (0, ?);" error:nil];
    XCTAssertNotNil(statement);
    XCTAssert([statement bindText:@"bbc" toIndex:0 error:nil]);
    XCTAssert([statement stepWithError:nil]);
    XCTAssertEqualObjects([connection queryTextWithSQL:@"SELECT remoteID FROM channels;" error:nil], @"bbc");
}

@end

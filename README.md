# SQLiteConnection (Preview)

SQLiteConnection is a lean Objective-C wrapper around libsqlite.

## Usage

Opening a connection:

```objective-c
MATSQLiteConnection *connection = [[MATSQLiteConnection alloc] init];
[connection openInMemoryDatabaseWithError:nil];
```

Creating and filling a table:

```objective-c
MATSQLiteStatement *statement =
    [connection prepareStatementWithSQL:@"CREATE TABLE channels(id INTEGER PRIMARY KEY, remoteID TEXT)"
                                  error:nil];
[statement stepWithError:nil];

statement = [connection prepareStatementWithSQL:@"INSERT INTO channels VALUES (0, 'bbc')"
                                          error:nil];
[statement stepWithError:nil];
```

Querying:

```objective-c
statement = [connection prepareStatementWithSQL:@"SELECT * FROM channels"
                                          error:nil];
NSLog([statement columnCount]); // output: "2"
[statement stepWithError:nil];
NSLog([statement textAtColumnIndex:1]); // output: "bbc"
```

Convenience methods:

```objective-c
MATSQLiteConnection *connection = [[MATSQLiteConnection alloc] init];
[connection openInMemoryDatabaseWithError:nil];

[connection executeSQL:@"CREATE TABLE channels(id INTEGER PRIMARY KEY, remoteID TEXT)"
                 error:nil];
[connection executeSQL:@"INSERT INTO channels VALUES (0, 'bbc');"
                 error:nil];

NSArray *row = [connection querySingleRowWithSQL:@"SELECT * FROM channels"
                                           error:nil];
NSLog(row.count);
NSLog(row[1]);
```

## License

Copyright (C) 2015 Matthias Schmitt. SQLiteConnection is released under the MIT license.


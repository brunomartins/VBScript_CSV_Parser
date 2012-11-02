# VBScript_CSV_Parser

Quick example
-------------

```vbscript

Dim testParser
Dim xIterator
Dim yIterator
Dim csvArray

set testParser = new CSVParser

csvArray = testParser.CSVArray( "C:\test.csv" )

For xIterator = LBound( csvArray, 1 ) to UBound( csvArray, 1 )

    For yIterator = LBound( csvArray, 2 ) to UBound( csvArray, 2 )

        WScript.Echo( csvArray( xIterator, yIterator ) )

    Next
Next

```

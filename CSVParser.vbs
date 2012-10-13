Option Explicit


'========================================================================
'
'   description     This class's function is to parse a csv file and
'                   return an array containing the same data.
'   
'   property        {bool}  SpaceAllowed    Set to true to allow spaces in
'                                           a csv file without starting
'                                           and ending in double quotes
'
'   property        {char}  EscapeCharacter Use to specify which char should
'                                           be used as an escape character within
'                                           double quoted fields. Default double quotes.
'
'   BNF Shorthand Notation - Representation of assumptions
'   Source: http://www.boyet.com/articles/csvparser.html
'
'	csvFile ::= (csvRecord)* 'EOF'
'	csvRecord ::= csvStringList ('\n' | 'EOF')
'   csvStringList ::= rawString (',' rawString)*
'	rawString := optionalSpaces [rawField optionalSpaces)]
'	optionalSpaces ::= whitespace*
'	whitespace ::= ' ' | '\t'
'	rawField ::= simpleField | quotedField 
'	simpleField ::= (any char except \n, EOF, \t, space, comma or double quote)+
'	quotedField ::= '"' escapedField '"'
'   escapedField ::= subField ('"' '"' subField)*
'	subField ::= (any char except double quote or EOF)+
'   
'========================================================================

Class CSVParser

    ' Objects
    Private fso
    Private file
    Private Records( )
    Private Fields( )
    Private Contents


    ' Settings
    Private AllowSpace 

    ' Char consts
    Private Quote
    Private Comma
    Private TabChar
    Private SpaceChar
    Private EscapeChar
    Private MacLineEnding
    Private UnixLineEnding
    Private WindowsLineEnding
    Private NewLineReplacement
   

    ' Error Messages
    Private FileNotFoundErr
    Private MalformedCSVErr


    Private Sub Class_Initialize

        Comma = ","
        TabChar = vbTab
        SpaceChar = " "
        Quote = Chr( 34 ) 
        EscapeChar = """"
        AllowSpace = True 


        MacLineEnding = vbCr
        UnixLineEnding = vbLf
        WindowsLineEnding = vbCrLf


        ' This should be set to the appropriate platform
        ' i.e. Unix, Mac or Windows
        NewLineReplacement = WindowsLineEnding


        ' CSV Errors
        MalformedCSVErr = "Malformed CSV file"
        FileNotFoundErr = "CSV file not found"

        ReDim Records( 1 )

        Set fso = CreateObject( "Scripting.FileSystemObject" )

    End Sub


    Private Sub Class_Terminate

        Set fso = Nothing 
        Set file = Nothing

    End Sub


    Private Property Let SpaceAllowed( bool )

        AllowSpace = bool 

    End Property


    Private Property Let EscapeCharacter( s )

        EscapeChar = EscapeCharacter

    End Property


    Public Function CSVArray( FullFilePath )
        
        Dim row
        Dim col 
        Dim count
        Dim TrimmedStr


        count = UBound( Records )
        Redim Preserve Fields( count, 0 )


        GetCSVFile( FullFilePath )
        GetCSVRecords( )
        GetRawStrings( )


        For row = 0 to UBound( Records )

            For col = 0 to UBound( Fields, 2 )

                TrimmedStr = GetRawStringValue( Fields( row, col ) )
                Fields( row, col ) = GetRawFieldValue( TrimmedStr )

            Next

        Next

        CSVArray = Fields

    End Function


    Private Function GetCSVFile( filename )

        Dim Unicode


        If Not fso.FileExists( filename ) Then 

            Err.Description = FileNotFoundErr
            Err.Raise 99999

        End If


        GetCSVFile = ""
        If fso.GetFile( filename ).Size = 0 Then Exit Function


        Unicode = OpenAsUnicode( filename )


        On Error Resume Next


        Set file = fso.OpenTextFile( filename, 1 , False, Unicode )
        

        If ErrorLevel <> 0 Then

            Err.Description = FileNotFoundErr
            Err.Raise 99999
        
        End If


        Contents = file.ReadAll
        file.Close

    End Function


    Private Function GetCSVRecords( )

        Dim i
        Dim strLen
        Dim returnArr
        Dim quoteCount
        Dim currentStr
        Dim currentItem
        Dim recogniseNewLines


        strLen = Len( Contents )
        If strLen = 0 Then Exit Function


        Contents = Replace( Contents, WindowsLineEnding, MacLineEnding )
        Contents = Replace( Contents,  UnixLineEnding, MacLineEnding )


        'In case some line endings have been replaced calculate length again
        strLen = Len( Contents )
        quoteCount = 0
        currentItem = 0
        recogniseNewLines = true


        For i = 1 to strLen

            If ( recogniseNewLines And Mid( Contents, i, 1 ) = MacLineEnding )  Then

                If currentItem > Ubound( Records ) Then 

                    ReDim preserve Records( currentItem )

                End If


                Records( currentItem ) = currentStr
                currentStr = ""
                currentItem = currentItem + 1

            ElseIf i = strLen Then 'If string has ended assign currentStr to last array item

                If currentItem > Ubound( Records ) Then Redim preserve Records( currentItem )


                Records( currentItem ) = currentStr
                currentItem = currentItem + 1
                currentStr = ""

            Else

                currentStr = currentStr + Mid( Contents, i, 1 )

            End If


            If Mid( Contents, i, 1 ) = Quote Then

                If recogniseNewLines = True Then 

                    recogniseNewLines = False

                Else

                    recogniseNewLines = True

                End If

            End If

        Next

    End Function


    Private Function GetRawStrings( )

        Dim str
        Dim arr
        Dim row
        Dim col 
        Dim strLen
        Dim colMax
        Dim returnArr
        Dim quoteCount
        Dim currentStr
        Dim recogniseCommas


        Redim Fields( UBound( Records ), 1 )
        

        For col = 0 to UBound( Records )
            

            str = Records( col )
            strLen = Len( str ) 
            quoteCount = 0
            recogniseCommas = true
            colMax = 0


            For row = 1 to strLen

                If recogniseCommas And Mid( str, row, 1 ) = Comma Then

                    If colMax > Ubound( Fields, 2 ) Then 

                        ReDim preserve Fields( UBound( Fields, 1 ), colMax )

                    End If


                    Fields( col, colMax ) = currentStr
                    currentStr = ""
                    colMax = colMax + 1

                ElseIf row = strLen Then 'If string has ended assign currentStr to last array item

                    If colMax > Ubound( Fields, 2 ) Then 

                        ReDim preserve Fields( UBound( Fields, 1 ), colMax )

                    End If

                    Fields( col, colMax ) = currentStr + Mid( str, row, 1 ) 
                    currentStr = ""
                    colMax = colMax + 1

                Else

                    currentStr = currentStr + Mid( str, row, 1 ) 

                End If


                If Mid( str, row, 1 ) = Quote Then

                    If recogniseCommas = True Then

                        recogniseCommas = False

                    Else

                        recogniseCommas = True

                    End If

                End If

            Next

        Next

    End Function


    Private Function GetRawStringValue( RawString ) 'Get Raw Field
        
        Dim startPos
        Dim endPos
        Dim charLen


        GetRawStringValue = ""
        If Len( RawString ) = 0 Then Exit Function


        GetRawStringValue = Trim( RawString )

    End Function


    Private Function GetRawFieldValue( s )

        Dim strLen
        strLen = Len( s )


        If strLen = 0 Then

            GetRawFieldValue = ""
            Exit Function

        End If
        

        If Mid( s, 1, 1 ) = Quote And Mid( s, strLen, 1 ) = Quote  Then

            GetRawFieldValue = GetQuotedField( s )

        Else

            GetRawFieldValue = GetSimpleField( s )

        End If

    End Function


    Private Function GetSimpleField( s )

        Dim i
        Dim temp
        Dim strLen


        GetSimpleField = ""


        'Default value of simpleField already empty string. No need to set value.
        If s = "" Then Exit Function 
        
        
        strLen = Len( s )


        For i = 1 To strLen

            Temp = Mid( s, i, 1 )

            If IsBadSimpleFieldChar( Temp ) Then

                Err.Description = MalformedCSVErr
                Err.Raise 99999

            End If


            GetSimpleField = GetSimpleField + Temp

        Next

    End Function


    Private Function GetQuotedField( s )

        Dim strLen
        Dim arr
        Dim i


        GetQuotedField = ""


        'Default value of GetQuoteField already empty string. No need to set value.
        If s = """""" Then Exit Function 
        
        
        strLen = Len( s )


        'Start on 2 and end one character short to avoid including the double quotes
        For i = 2 To strLen - 1
           
            If Mid( s, i, 2 ) = EscapeChar & Quote Then

                i = i + 1

            End If


            If Mid( s, i, 1 ) = MacLineEnding Then

                GetQuotedField = GetQuotedField + NewLineReplacement

            Else

                GetQuotedField = GetQuotedField + Mid( s, i, 1 ) 

            End If

        Next

    End Function


    Private Function IsBadSimpleFieldChar( c )
        
        IsBadSimpleFieldChar = False


        If IsFieldTerminator( c ) Then IsBadSimpleFieldChar = True


        If AllowSpace = False Then

            If IsSpace( c ) Then IsBadSimpleFieldChar = True

        End If


        If c = Quote Then IsBadSimpleFieldChar = True

    End Function


    Private Function IsFieldTerminator( c )

        IsFieldTerminator = False


        If c = Comma Then IsFieldTerminator = True
        If c = MacLineEnding Then IsFieldTerminator = True

    End Function


    Private Function IsSpace( c )

        IsSpace = False


        If c = SpaceChar Then IsSpace = True
        If c = TabChar Then IsSpace = True

    End Function


    Private Function OpenAsUnicode ( FullFilePath )

        Dim file
        Dim intAsc1Chr
        Dim intAsc2Chr


        OpenAsUnicode = False 'Default


        Set file = fso.OpenTextFile( FullFilePath, 1, False)


        intAsc1Chr = Asc(file.Read(1))
        intAsc2Chr = Asc(file.Read(1))


        file.Close


        ' Check for the BOM character
        If intAsc1Chr = 254 And intAsc2Chr = 255 Then 

            OpenAsUnicode = True '(BE) UTF-16

        ElseIf intAsc1Chr = 255 And intAsc2Chr = 254 Then 

            OpenAsUnicode = True '(LE) UTF-16

        Else

            OpenAsUnicode = False

        End If

    End Function

End Class


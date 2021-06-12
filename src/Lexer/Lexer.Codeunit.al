codeunit 81000 "FS Lexer"
{
    var
        TempLexeme: Record "FS Lexeme" temporary;
        Code: Text;
        CodeLength: Integer;
        Position: Integer;
        LastLexeme: Boolean;

    procedure Analyze(NewCode: Text)
    var
        ProgressDialog: Dialog;
    begin
        ProgressDialog.Open('Analysing...');

        Code := NewCode;
        CodeLength := StrLen(Code);
        Position := 1;

        TempLexeme.Reset();
        TempLexeme.DeleteAll();

        while not EOS() do
            ParseNext();

        TempLexeme.FindFirst();

        ProgressDialog.Close();
    end;

    procedure ShowLexemes()
    var
        Lexemes: Page "FS Lexemes";
    begin
        Lexemes.SetRecords(TempLexeme);
        Lexemes.Run();
    end;

    procedure EOF(): Boolean
    begin
        exit(LastLexeme);
    end;

    procedure GetNextLexeme(var Lexeme: Record "FS Lexeme")
    begin
        Lexeme := TempLexeme;
        LastLexeme := TempLexeme.Next() = 0;
    end;

    procedure PeekNextLexeme(var Lexeme: Record "FS Lexeme")
    begin
        Lexeme := TempLexeme;
    end;

    local procedure ParseNext()
    var
        NextChar: Text[1];
    begin
        while not EOS() and IsWhiteSpace(PeekNext()) do
            ReadNext(); // consume whitespace

        NextChar := PeekNext();

        case true of
            NextChar = '':
                ; // EOS
            NextChar in ['0' .. '9']: // number
                ParseNumber();
            NextChar = '''': // string literal
                ParseStringLiteral();
            NextChar = '"': // symbol
                ParseSymbol();
            NextChar = '/':
                DoParseComment();
            IsOperator(NextChar):
                // FIXME div and mod?
                ParseOperator();
            else // keyword/variable
                ParseSymbol();
        end;
    end;

    local procedure DoParseComment()
    begin
        case PeekNext() + PeekNext(1) of
            '//':
                ParseComment();
            '/*':
                ParseMultilineComment();
            else
                ParseOperator();
        end;
    end;

    local procedure EOS(): Boolean
    begin
        exit(EOS(0));
    end;

    local procedure EOS(i: Integer): Boolean
    begin
        exit(Position + i > CodeLength);
    end;

    local procedure IsWhiteSpace(Char: Text[1]): Boolean
    var
        c: Char;
    begin
        if Char = '' then
            exit(false);

        Evaluate(c, Char);
        case c of
            9, // horizontal tab
            10, // lf
            11, // vertical tab
            12, // form feed
            13, // cr
            32, // space
            160: // non-breaking space
                exit(true);
        end;
        exit(false);
    end;

    local procedure IsEndOfLine(Char: Text[1]): Boolean
    var
        c: Char;
    begin
        if Char = '' then
            exit(true);

        Evaluate(c, Char);
        exit(c = 10);
    end;

    local procedure EndOfMultilineComment(): Boolean
    begin
        exit(PeekNext() + PeekNext(1) = '*/');
    end;

    local procedure PeekNext() Char: Text[1]
    begin
        Char := PeekNext(0);
    end;

    local procedure PeekNext(i: Integer) Char: Text[1]
    begin
        if EOS() then
            exit('');
        Char := Code[Position + i];
    end;

    local procedure ReadNext() Char: Text[1]
    begin
        if EOS() then
            exit('');

        Char := Code[Position];
        Position += 1;
    end;

    local procedure ParseNumber()
    var
        NextChar: Text[1];
        Digit: Integer;
        DecimalPlaces: Integer;
        Number: Decimal;
        IsDecimal: Boolean;
    begin
        IsDecimal := false;

        Evaluate(Number, ReadNext());

        while true do begin
            NextChar := PeekNext();
            if not IsDecimal then
                if NextChar = '.' then begin
                    IsDecimal := true;
                    ReadNext(); // consume .
                    NextChar := PeekNext();
                end;

            case true of
                NextChar = '',
                IsWhiteSpace(NextChar),
                IsOperator(NextChar):
                    break;
            end;

            NextChar := ReadNext();
            if not Evaluate(Digit, NextChar) then
                Error('Unexpected character %1 at position %2.', NextChar, Position);

            if IsDecimal then begin
                DecimalPlaces += 1;
                Number += Digit / Power(10, DecimalPlaces);
            end else begin
                Number *= 10;
                Number += Digit;
            end;
        end;

        if IsDecimal then
            CreateDecimalLexeme(Number)
        else
            CreateIntegerLexeme(Number);
    end;

    local procedure ParseStringLiteral()
    var
        StringLiteral: Text;
    begin
        ReadNext(); // consume '

        while not EOS() and not EndOfStringLiteral() do
            StringLiteral += ReadNext();

        if EOS() then
            Error('Unexpected end of stream, expected %1.', '''');

        ReadNext(); // consume '

        CreateStringLiteralLexeme(StringLiteral);
    end;

    local procedure ParseComment()
    begin
        ReadNext(); // consume /
        ReadNext(); // consume /

        while not IsEndOfLine(PeekNext()) do
            ReadNext();
    end;

    local procedure ParseMultilineComment()
    begin
        ReadNext(); // consume /
        ReadNext(); // consume *

        while not EOS() and not EndOfMultilineComment() do
            ReadNext();

        if EOS() then
            Error('Unexpected end of stream, expected %1.', '*/');

        ReadNext(); // consume *
        ReadNext(); // consume /
    end;

    local procedure ParseOperator() Operator: Enum "FS Operator"
    var
        Char: Text[1];
        NextChar: Text[1];
        Index: Integer;
    begin
        Char := ReadNext();
        NextChar := PeekNext();

        Index := Operator.Names().IndexOf(Char + NextChar);
        if Index = 0 then
            Index := Operator.Names().IndexOf(Char);

        if (Index = 0) and (Char = ',') then
            Operator := Enum::"FS Operator"::comma
        else
            Operator := "FS Operator".FromInteger("FS Operator".Ordinals().Get(Index));

        if Operator.AsInteger() >= 1000 then // two char operator ids are 1000+
            ReadNext(); // consume second part of the operator

        CreateOperatorLexeme(Operator);
    end;

    local procedure IsOperator(Char: Text[1]): Boolean
    begin
        // XXX boolean operator behaviour?
        exit("FS Operator".Names().Contains(Char) or (Char = ','));
    end;

    local procedure IsBooleanValue(Symbol: Text): Boolean
    begin
        exit(Symbol.ToLower() in ['true', 'false']);
    end;

    local procedure IsBooleanOperator(Symbol: Text): Boolean
    begin
        // XXX not pretty
        exit(Symbol.ToLower() in [
                Format("FS Operator"::"and"),
                Format("FS Operator"::"or"),
                Format("FS Operator"::"xor"),
                Format("FS Operator"::"not")
            ]);
    end;

    local procedure IsKeyword(Symbol: Text): Boolean
    begin
        exit("FS Keyword".Names().Contains(Symbol.ToLower()));
    end;

    local procedure EndOfStringLiteral(): Boolean
    var
        NextChar: Text[1];
    begin
        NextChar := PeekNext();
        if NextChar <> '''' then
            exit(false);

        if PeekNext(1) = '''' then begin
            // escaped '
            ReadNext(); // consume '
            exit(false);
        end;

        exit(true);
    end;

    local procedure ParseSymbol()
    var
        Keyword: Enum "FS Keyword";
        Operator: Enum "FS Operator";
        Symbol: Text;
        Quoted: Boolean;
        Index: Integer;
    begin
        Quoted := PeekNext() = '"';
        if Quoted then
            ReadNext(); // consume "

        Symbol := '';
        while not EOS() and not IsSymbolDelimiter(PeekNext(), Quoted) do
            Symbol += ReadNext();

        if Quoted then begin
            if EOS() then
                Error('Unexpected end of stream, expected %1.', '"');
            ReadNext(); // consume "
        end;

        if not Quoted then
            case true of
                IsBooleanValue(Symbol):
                    begin
                        CreateBooleanLexeme(Symbol.ToLower() = 'true');
                        exit;
                    end;
                IsBooleanOperator(Symbol):
                    begin
                        Index := "FS Operator".Names().IndexOf(Symbol.ToLower());
                        Operator := "FS Operator".FromInteger("FS Operator".Ordinals().Get(Index));

                        CreateOperatorLexeme(Operator);
                        exit;
                    end;
                IsKeyword(Symbol):
                    begin
                        Index := "FS Keyword".Names().IndexOf(Symbol.ToLower());
                        Keyword := "FS Keyword".FromInteger("FS Keyword".Ordinals().Get(Index));

                        CreateKeywordLexeme(Symbol, Keyword); // XXX
                        exit;
                    end;
            end;

        CreateSymbolLexeme(Symbol); // XXX
    end;

    local procedure IsSymbolDelimiter(Char: Text[1]; Quoted: Boolean): Boolean
    begin
        if Quoted then
            exit(Char = '"');

        case true of
            IsWhiteSpace(Char),
            IsOperator(Char):
                exit(true);
        end;

        exit(false);
    end;

    // XXX 6.0 regions #region create lexeme methods

    local procedure CreateIntegerLexeme(Value: Integer)
    begin
        CreateLexeme(
            "FS Lexeme Type"::Integer,
            '',
            '',
            false,
            Value,
            "FS Operator"::" ",
            "FS Keyword"::" ");
    end;

    local procedure CreateDecimalLexeme(Value: Decimal)
    begin
        CreateLexeme(
            "FS Lexeme Type"::Decimal,
            '',
            '',
            false,
            Value,
            "FS Operator"::" ",
            "FS Keyword"::" ");
    end;

    local procedure CreateBooleanLexeme(Value: Boolean)
    begin
        CreateLexeme(
            "FS Lexeme Type"::Boolean,
            '',
            '',
            Value,
            0.0,
            "FS Operator"::" ",
            "FS Keyword"::" ");
    end;

    local procedure CreateStringLiteralLexeme(Value: Text)
    begin
        CreateLexeme(
            "FS Lexeme Type"::StringLiteral,
            '',
            Value,
            false,
            0.0,
            "FS Operator"::" ",
            "FS Keyword"::" ");
    end;

    local procedure CreateSymbolLexeme(Name: Text[250])
    begin
        CreateLexeme(
            "FS Lexeme Type"::Symbol,
            Name, // XXX
            '',
            false,
            0.0,
            "FS Operator"::" ",
            "FS Keyword"::" ");
    end;

    local procedure CreateOperatorLexeme(Operator: Enum "FS Operator")
    begin
        CreateLexeme(
            "FS Lexeme Type"::Operator,
            '',
            '',
            false,
            0.0,
            Operator,
            "FS Keyword"::" ");
    end;

    local procedure CreateKeywordLexeme(Name: Text[250]; Keyword: Enum "FS Keyword")
    begin
        CreateLexeme(
            "FS Lexeme Type"::Keyword,
            Name,
            '',
            false,
            0.0,
            "FS Operator"::" ",
            Keyword);
    end;

    local procedure CreateLexeme
    (
        Type: Enum "FS Lexeme Type";
                  Name: Text[250];
    Value: Text;
        BooleanValue: Boolean;
        Number: Decimal;
        Operator: Enum "FS Operator";
                      Keyword: Enum "FS Keyword"
    )
    begin
        TempLexeme.Init();
        TempLexeme."Entry No." := 0;

        TempLexeme.Type := Type;
        TempLexeme.Name := Name;
        TempLexeme.Operator := Operator;
        TempLexeme.Keyword := Keyword;

        TempLexeme.SetTextValue(Value);
        TempLexeme."Number Value" := Number;
        TempLexeme."Boolean Value" := BooleanValue;

        TempLexeme.Insert(true);
    end;

    // #endregion
}
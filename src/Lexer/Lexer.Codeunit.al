codeunit 81000 "FS Lexer"
{
    var
        TempLexeme: Record "FS Lexeme" temporary;
        Code: Text;
        CodeLength: Integer;
        Position: Integer;

    procedure Analyze(NewCode: Text)
    begin
        Code := NewCode;
        CodeLength := StrLen(Code);
        Position := 1;

        TempLexeme.Reset();
        TempLexeme.DeleteAll();

        while not EOS() do
            ParseNext();

        TempLexeme.FindFirst();
    end;

    procedure ShowLexemes()
    var
        Lexemes: Page "FS Lexemes";
    begin
        Lexemes.SetRecords(TempLexeme);
        Lexemes.Run();
    end;

    procedure GetNextLexeme(var Lexeme: Record "FS Lexeme")
    begin
        Lexeme := TempLexeme;
        TempLexeme.Next(); // FIXME EOF detection 
    end;

    procedure PeekNextLexeme(var Lexeme: Record "FS Lexeme")
    begin
        Lexeme := TempLexeme;
    end;

    local procedure ParseNext()
    var
        NextChar: Text[1];
    begin
        while IsWhiteSpace(PeekNext()) do
            ReadNext(); // consume whitespace

        NextChar := PeekNext();

        case true of
            NextChar = '':
                ; // EOS
            NextChar in ['0' .. '9']: // number
                DoParseNumber();
            NextChar = '''': // string literal
                DoParseStringLiteral();
            NextChar = '"': // symbol
                DoParseSymbol();
            NextChar = '/':
                DoParseComment();
            IsOperator(NextChar):
                // peek for div and mod?
                // '-' might be a number?
                DoParseOperator();
            else // keyword/variable
                DoParseSymbol();
        end;
    end;

    // 610319240

    local procedure DoParseNumber()
    var
        Number: Decimal;
        IsDecimal: Boolean;
    begin
        Number := ParseNumber(IsDecimal);

        if IsDecimal then
            CreateLexeme(
                "FS Lexeme Type"::Decimal,
                '',
                '',
                Number,
                "FS Operator"::" ",
                "FS Keyword"::" "
            )
        else
            CreateLexeme(
                "FS Lexeme Type"::Integer,
                '',
                '',
                Number,
                "FS Operator"::" ",
                "FS Keyword"::" "
            );
    end;

    local procedure DoParseStringLiteral()
    var
        String: Text;
    begin
        String := ParseStringLiteral();

        CreateLexeme(
            "FS Lexeme Type"::StringLiteral,
            '',
            String,
            0.0,
            "FS Operator"::" ",
            "FS Keyword"::" "
        );
    end;

    local procedure DoParseSymbol()
    var
        String: Text;
        Keyword: Enum "FS Keyword";
    begin
        String := ParseSymbol(Keyword);

        if Keyword = "FS Keyword"::" " then
            CreateLexeme(
                "FS Lexeme Type"::Symbol,
                String, // XXX
                '',
                0.0,
                "FS Operator"::" ",
                "FS Keyword"::" "
            )
        else
            CreateLexeme(
                "FS Lexeme Type"::Keyword,
                String, // XXX
                '',
                0.0,
                "FS Operator"::" ",
                Keyword
            );
    end;

    local procedure DoParseComment()
    begin
        case PeekNext() + PeekNext(1) of
            '//':
                ParseComment();
            '/*':
                ParseMultilineComment();
            else
                DoParseOperator();
        end;
    end;

    local procedure DoParseOperator()
    var
        Operator: Enum "FS Operator";
    begin
        Operator := ParseOperator();

        CreateLexeme(
            "FS Lexeme Type"::Operator,
            '',
            '',
            0.0,
            Operator,
            "FS Keyword"::" "
        );
    end;


    procedure EOS(): Boolean
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
            exit(true);

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

    local procedure ParseNumber(var IsDecimal: Boolean) Number: Decimal
    var
        NextChar: Text[1];
        Digit: Integer;
        DecimalPlaces: Integer;
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
    end;

    local procedure ParseStringLiteral() StringLiteral: Text
    begin
        ReadNext(); // consume '

        while not EOS() and not EndOfStringLiteral() do
            StringLiteral += ReadNext();

        if EOS() then
            Error('Unexpected end of stream, expected %1.', '''');

        ReadNext(); // consume '
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

        Operator := "FS Operator".FromInteger("FS Operator".Ordinals().Get(Index));

        if Operator.AsInteger() >= 1000 then // two char operator ids are 1000+
            ReadNext(); // consume second part of the operator
    end;

    local procedure IsOperator(Char: Text[1]): Boolean
    begin
        exit("FS Operator".Names().Contains(Char));
    end;

    local procedure IsKeyword(Symbol: Text): Boolean
    begin
        exit("FS Keyword".Names().Contains(LowerCase(Symbol)));
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

    local procedure ParseSymbol
    (
        var Keyword: Enum "FS Keyword"
    ) Symbol: Text
    var
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
            if IsKeyword(Symbol) then begin
                Index := Keyword.Names().IndexOf(LowerCase(Symbol));
                Keyword := "FS Keyword".FromInteger("FS Keyword".Ordinals().Get(Index));
            end;
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


    local procedure CreateLexeme
    (
        Type: Enum "FS Lexeme Type";
        Name: Text[100];
        Value: Text;
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

        TempLexeme.Insert(true);
    end;
}
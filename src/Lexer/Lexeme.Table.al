table 81000 "FS Lexeme"
{
    Caption = 'Lexeme';
    DataClassification = SystemMetadata;
    LookupPageId = "FS Lexemes";
    DrillDownPageId = "FS Lexemes";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(2; Type; Enum "FS Lexeme Type")
        {
            Caption = 'Type';
            DataClassification = SystemMetadata;
        }
        field(3; Name; Text[100])
        {
            Caption = 'Name';
            DataClassification = SystemMetadata;
        }
        field(4; Keyword; Enum "FS Keyword")
        {
            Caption = 'Keyword';
            DataClassification = SystemMetadata;
        }

        field(10; Operator; Enum "FS Operator")
        {
            Caption = 'Operator';
            DataClassification = SystemMetadata;
        }

        field(100; "Text Value"; Text[250])
        {
            Caption = 'Text Value';
            DataClassification = SystemMetadata;
        }
        field(101; "Number Value"; Decimal) // TODO unify name with numeric value?
        {
            Caption = 'Number Value';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 15;
            BlankZero = true;
        }
        field(102; "Text Blob"; Blob)
        {
            Caption = 'Text Blob';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", Type, Name, Operator) { }
        fieldgroup(Brick; "Entry No.", Type, Name, Operator) { }
    }

    trigger OnInsert()
    var
        Lexeme: Record "FS Lexeme";
        TempLexeme: Record "FS Lexeme" temporary;
    begin
        if Rec."Entry No." = 0 then
            if Rec.IsTemporary() then begin
                TempLexeme.Copy(Rec, true);
                // TempLexeme.Reset();
                AssignEntryNo(TempLexeme);
            end else
                AssignEntryNo(Lexeme);
    end;

    local procedure AssignEntryNo(var Lexeme: Record "FS Lexeme")
    begin
        if not Lexeme.FindLast() then
            Lexeme.Init();
        Rec."Entry No." := Lexeme."Entry No." + 1;
    end;

    procedure SetTextValue(Value: Text)
    var
        OutStream: OutStream;
    begin
        Rec."Text Value" := '';
        Clear(Rec."Text Blob");
        if Value = '' then
            exit;

        if StrLen(Value) <= MaxStrLen(Rec."Text Value") then
            Rec."Text Value" := Value
        else begin
            "Text Blob".CreateOutStream(OutStream);
            OutStream.WriteText(Value);
        end;
    end;

    procedure GetTextValue() Value: Text
    var
        InStream: InStream;
        Line: Text;
        CRLF: Text[2];
    begin
        if Rec."Text Value" <> '' then
            Value := rEc."Text Value"
        else begin
            CRLF[1] := 13;
            CRLF[2] := 10;

            "Text Blob".CreateInStream(InStream);
            InStream.ReadText(Value);
            while not InStream.EOS() do begin
                InStream.ReadText(Line);
                Value += CRLF + Line;
            end;
        end;
    end;
}
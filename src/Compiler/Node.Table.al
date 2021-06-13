table 81001 "FS Node"
{
    Caption = 'Node';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(2; Type; Enum "FS Node Type")
        {
            Caption = 'Type';
            DataClassification = SystemMetadata;
        }
        field(3; "Parent Entry No."; Integer)
        {
            Caption = 'Parent Entry No.';
            DataClassification = SystemMetadata;
            TableRelation = "FS Node"."Entry No.";
        }

        field(10; "Function Name"; Text[250])
        {
            Caption = 'Function Name';
            DataClassification = SystemMetadata;
        }
        field(11; "Function No."; Integer)
        {
            Caption = 'Function No.';
            DataClassification = SystemMetadata;
        }

        field(100; Operator; Enum "FS Operator")
        {
            Caption = 'Operator';
            DataClassification = SystemMetadata;
        }
        field(101; "Numeric Value"; Decimal)
        {
            Caption = 'Numeric Value';
            DataClassification = SystemMetadata;
            BlankZero = true;
            DecimalPlaces = 0 : 50;
        }
        field(102; "Boolean Value"; Boolean)
        {
            Caption = 'Boolean Value';
            DataClassification = SystemMetadata;
        }
        field(103; "Text Value"; Text[250])
        {
            Caption = 'Text Value';
            DataClassification = SystemMetadata;
        }
        field(104; "Text Blob"; Blob)
        {
            Caption = 'Text Blob';
            DataClassification = SystemMetadata;
        }
        field(105; "Variable Name"; Text[250])
        {
            Caption = 'Variable Name';
            DataClassification = SystemMetadata;
        }
        field(106; "Property Access"; Boolean)
        {
            Caption = 'Property Access';
            DataClassification = SystemMetadata;
        }

        field(200; "If Condition Node"; Integer)
        {
            Caption = 'If Condition Node';
            DataClassification = SystemMetadata;
        }
        field(201; "If True Statement Node"; Integer)
        {
            Caption = 'If True Statement Node';
            DataClassification = SystemMetadata;
        }
        field(202; "If False Statement Node"; Integer)
        {
            Caption = 'If False Statement Node';
            DataClassification = SystemMetadata;
        }

        field(10000; Indentation; Integer)
        {
            Caption = 'Indetation';
            DataClassification = SystemMetadata;
        }
        field(10001; Order; Integer) // XXX necessary ?
        {
            Caption = 'Order';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(PresentationOrder; Order) { }
    }

    trigger OnInsert()
    var
        Node: Record "FS Node";
        TempNode: Record "FS Node" temporary;
    begin
        if Rec."Entry No." = 0 then
            if Rec.IsTemporary() then begin
                TempNode.Copy(Rec, true);
                AssignEntryNo(TempNode);
            end else
                AssignEntryNo(Node);
    end;

    local procedure AssignEntryNo(var Node: Record "FS Node")
    begin
        if not Node.FindLast() then
            Node.Init();
        Rec."Entry No." := Node."Entry No." + 1;
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
            Value := Rec."Text Value"
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
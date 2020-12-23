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
        field(102; "Variable Name"; Text[100])
        {
            Caption = 'Variable Name';
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
                // TempNode.Reset();
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
}
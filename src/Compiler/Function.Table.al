table 81003 "FS Function"
{
    Caption = 'Function';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(2; Name; Text[250])
        {
            Caption = 'Name';
            DataClassification = SystemMetadata;
        }
        field(10; "Return Type"; Enum "FS Variable Type")
        {
            Caption = 'Return Type';
            DataClassification = SystemMetadata;
        }
        field(11; "Return Variable No."; Integer)
        {
            Caption = 'Return Variable No.';
            DataClassification = SystemMetadata;
        }
        field(12; "Return Variable Name"; Text[250])
        {
            Caption = 'Return Variable Name';
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

    trigger OnInsert()
    var
        Function: Record "FS Function";
        TempFunction: Record "FS Function" temporary;
    begin
        if Rec."Entry No." = 0 then
            if Rec.IsTemporary() then begin
                TempFunction.Copy(Rec, true);
                AssignEntryNo(TempFunction);
            end else
                AssignEntryNo(Function);
    end;

    local procedure AssignEntryNo(var Function: Record "FS Function")
    begin
        if not Function.FindLast() then
            Function.Init();
        Rec."Entry No." := Function."Entry No." + 1;
    end;
}
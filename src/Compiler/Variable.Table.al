table 81002 "FS Variable"
{
    Caption = 'Variable';
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
        field(3; Length; Integer)
        {
            Caption = 'Length';
            DataClassification = SystemMetadata;
            MinValue = 0;
            BlankZero = true;
        }
        field(4; Type; Enum "FS Variable Type")
        {
            Caption = 'Type';
            DataClassification = SystemMetadata;
        }
        field(10; Scope; Option)
        {
            Caption = 'Scope';
            DataClassification = SystemMetadata;
            OptionMembers = Local,Global;
            OptionCaption = 'Local,Global';
        }
        field(11; "Parent Node No."; Integer)
        {
            Caption = 'Parent Node No.';
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
        Variable: Record "FS Variable";
        TempVariable: Record "FS Variable" temporary;
    begin
        if Rec."Entry No." = 0 then
            if Rec.IsTemporary() then begin
                TempVariable.Copy(Rec, true);
                AssignEntryNo(TempVariable);
            end else
                AssignEntryNo(Variable);
    end;

    local procedure AssignEntryNo(var Variable: Record "FS Variable")
    begin
        if not Variable.FindLast() then
            Variable.Init();
        Rec."Entry No." := Variable."Entry No." + 1;
    end;
}
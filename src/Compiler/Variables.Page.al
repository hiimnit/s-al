page 81003 "FS Variables"
{
    Caption = 'Variables';
    PageType = ListPart;
    UsageCategory = None;
    SourceTable = "FS Variable";
    SourceTableTemporary = true;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(Name; Rec.Name)
                {
                    ToolTip = 'Specifies the variable name.';
                    ApplicationArea = All;
                }
                field(Type; Rec.Type)
                {
                    ToolTip = 'Specifies the variable type.';
                    ApplicationArea = All;
                }
                field(Length; Rec.Length)
                {
                    ToolTip = 'Specifies the variable length.';
                    ApplicationArea = All;
                }
            }
        }
    }

    procedure SetRecords(var Variable: Record "FS Variable" temporary)
    begin
        Rec.Reset();
        Rec.DeleteAll();

        if Variable.FindSet() then begin
            repeat
                Rec := Variable;
                Rec.Insert(false);
            until Variable.Next() = 0;

            Rec.FindFirst();
        end;
    end;
}
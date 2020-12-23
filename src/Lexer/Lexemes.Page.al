page 81000 "FS Lexemes"
{
    Caption = 'Lexemes';
    PageType = List;
    UsageCategory = Lists;
    ApplicationArea = All;
    SourceTable = "FS Lexeme";
    SourceTableTemporary = true;

    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the entry number.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the lexeme type.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the lexeme name.';
                }
                field(Keyword; Rec.Keyword)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Keyword.';
                }
                field(Operator; Rec.Operator)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the operator.';
                }
                field("Text Value"; Rec.GetTextValue())
                {
                    Caption = 'Text Value';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the text value.';
                }
                field("Number Value"; Rec."Number Value")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number value.';
                }
            }
        }
    }

    procedure SetRecords(var Lexeme: Record "FS Lexeme" temporary)
    begin
        Rec.Reset();
        Rec.DeleteAll();

        if Lexeme.FindSet() then begin
            repeat
                Rec := Lexeme;
                Rec.Insert(false);
            until Lexeme.Next() = 0;

            Rec.FindFirst();
        end;
    end;
}
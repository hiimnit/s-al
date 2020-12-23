page 81002 "FS Node Tree View"
{
    Caption = 'Node Tree View';
    PageType = List;
    UsageCategory = None;
    SourceTable = "FS Node";
    SourceTableTemporary = true;
    SourceTableView = sorting(Order);
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                ShowAsTree = true;
                TreeInitialState = CollapseAll;
                IndentationColumn = Indentation;
                IndentationControls = "Entry No.", Type;

                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the entry number.';
                    Visible = false;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the entry type.';
                }
                field("Parent Entry No."; Rec."Parent Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the entry parent entry number.';
                }
                field(Operator; Rec.Operator)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the operator.';
                }
                field("Numeric Value"; Rec."Numeric Value")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the numeric value.';
                }
                field("Variable Name"; Rec."Variable Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the variable name.';
                }
            }
        }
    }

    procedure SetRecords(var Node: Record "FS Node" temporary)
    begin
        Rec.Reset();
        Rec.DeleteAll();

        if Node.FindSet() then begin
            repeat
                Rec := Node;
                Rec.Insert(false);
            until Node.Next() = 0;

            Rec.FindFirst();
        end;
    end;
}
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
                IndentationControls = Type;

                field(Type; Rec.Type)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the entry type.';
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the entry number.';
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
        area(FactBoxes)
        {
            part(LocalVariables; "FS Variables")
            {
                Caption = 'Local Variables';
                ApplicationArea = All;
                // TODO filter!
            }
            part(GlobalVariables; "FS Variables")
            {
                Caption = 'Global Variables';
                ApplicationArea = All;
                // TODO filter!
            }
        }
    }

    procedure SetRecords(var Node: Record "FS Node" temporary; var Variable: Record "FS Variable" temporary)
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

        Variable.SetRange(Scope, Variable.Scope::Local);
        CurrPage.LocalVariables.Page.SetRecords(Variable);

        Variable.SetRange(Scope, Variable.Scope::Global);
        CurrPage.GlobalVariables.Page.SetRecords(Variable);
    end;
}
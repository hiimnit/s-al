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
                    StyleExpr = StyleExpr;
                }
                field("Function Name"; Rec."Function Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the function name.';
                    StyleExpr = StyleExpr;
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
            }
        }
        area(FactBoxes)
        {
            part(LocalVariables; "FS Variables")
            {
                Caption = 'Local Variables';
                ApplicationArea = All;
                SubPageLink = "Function No." = field("Function No."); // XXX not visible on "Function" line
            }
            part(GlobalVariables; "FS Variables")
            {
                Caption = 'Global Variables';
                ApplicationArea = All;
            }
        }
    }

    var
        StyleExpr: Text;

    trigger OnAfterGetRecord()
    begin
        case Type of
            "FS Node Type"::Function:
                StyleExpr := 'strong';
            else
                StyleExpr := 'none';
        end;
    end;

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
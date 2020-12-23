page 81001 "FS S/AL"
{
    Caption = 'S/AL';
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Tasks;

    layout
    {
        area(Content)
        {
            group(GroupName)
            {
                group("Code")
                {
                    Caption = 'Code';

                    field("FS Code"; Code)
                    {
                        ShowCaption = false;
                        ApplicationArea = All;
                        MultiLine = true;
                    }
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Analyze)
            {
                Caption = 'Analyze';
                ApplicationArea = All;
                ToolTip = 'Analyzes the code.';
                Image = AnalysisView;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                trigger OnAction()
                var
                    Lexer: Codeunit "FS Lexer";
                begin
                    Lexer.Analyze(Code);
                    Lexer.ShowLexemes();
                end;
            }
            action(Compile)
            {
                Caption = 'Compile';
                ApplicationArea = All;
                ToolTip = 'Analyzes and compiles the code.';
                Image = CompleteLine;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                trigger OnAction()
                var
                    Compiler: Codeunit "FS Compiler";
                begin
                    Compiler.Compile(Code);
                    Compiler.ShowNodeTree();
                end;
            }
        }
    }

    var
        Code: Text;
}
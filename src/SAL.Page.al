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
            usercontrol("FS Monaco Editor"; "FS Monaco Editor")
            {
                ApplicationArea = All;

                trigger Analyze(Code: Text)
                var
                    Lexer: Codeunit "FS Lexer";
                begin
                    Lexer.Analyze(Code);
                    Lexer.ShowLexemes();
                end;

                trigger Compile(Code: Text)
                var
                    Compiler: Codeunit "FS Compiler";
                begin
                    Compiler.Compile(Code);
                    Compiler.ShowNodeTree();
                end;

                trigger Execute(Code: Text)
                var
                    Interpreter: Codeunit "FS Interpreter";
                begin
                    Interpreter.Execute(Code);
                end;
            }
        }
    }
}
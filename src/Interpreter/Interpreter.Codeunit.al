codeunit 81004 "FS Interpreter"
{
    var
        Compiler: Codeunit "FS Compiler";

    procedure Run(Code: Text)
    begin
        Compile(Code);

    end;

    local procedure Compile(Code: Text)
    begin
        Clear(Compiler);
        Compiler.Compile(Code);
    end;
}
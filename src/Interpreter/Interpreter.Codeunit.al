codeunit 81004 "FS Interpreter"
{
    var
        NodeTree: Codeunit "FS Node Tree";

    procedure Execute(Code: Text)
    begin
        Compile(Code);

        ExecuteScript();
    end;

    local procedure Compile(Code: Text)
    var
        Compiler: Codeunit "FS Compiler";
    begin
        Compiler.Compile(Code);
        Compiler.GetNodeTree(NodeTree);
    end;

    local procedure ExecuteScript()
    var
        myInt: Integer;
    begin
        InitGlobalVariables();
        // 0. init globals
        // 1. find + execute OnRun()
        // 2.
    end;

    local procedure InitGlobalVariables()
    var
        TempVariable: Record "FS Variable" temporary;
        x: array[512] of Codeunit "Company Triggers";
    begin

    end;
}

// TODO
// "Call Stack" codeunit
//  - handles variables
//  - has push and pop methods for calling functions
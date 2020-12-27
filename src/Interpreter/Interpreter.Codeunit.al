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
        ProgressDialog: Dialog;
    begin
        ProgressDialog.Open('Executing...');

        InitGlobalVariables();

        // 0. init globals
        // 1. find + execute OnRun()
        // 2.
        NodeTree.GetOnRun(OnRun);
        NodeTree.GetNodes(TempNode);
        // find function entry point
        TempNode.SetRange("Function No.", OnRun."Entry No.");
        TempNode.SetRange(Type, TempNode.Type::Function);
        TempNode.FindFirst();

        ProgressDialog.Close();
    end;

    local procedure InitGlobalVariables()
    var
        TempVariable: Record "FS Variable" temporary;
        x: array[512] of Codeunit "Company Triggers";
    begin
        NodeTree.GetVariables(TempVariable);
        TempVariable.SetRange(Scope, TempVariable.Scope::Global);
        if TempVariable.FindSet() then
            repeat
            // TODO init variables
            until TempVariable.Next() = 0;
    end;


    local procedure ExecuteNode(var TempNode: Record "FS Node" temporary)
    begin
        case TempNode.Type of
            "FS Node Type"::Function: // TODO nope, this is not executed - "Function Call" node will be tho
                                      // TODO "Function Call" will evaluate parameters and then find the "Function call" and execute it with params
                ExecuteFunctionNode(TempNode);
            "FS Node Type"::AssignmentStatement:
                ExecuteAssignementStatementNode(TempNode);
        end;
    end;

    local procedure ExecuteFunctionNode(var TempFunctionNode: Record "FS Node" temporary)
    var
        Function: Record "FS Function";
        TempVariable: Record "FS Variable" temporary;
        TempNode: Record "FS Node" temporary;
    begin
        NodeTree.GetFunction(TempFunctionNode."Function No.", Function);

        // TODO push call stack

        NodeTree.GetVariables(TempVariable);
        TempVariable.SetRange(Scope, TempVariable.Scope::Local);
        TempVariable.SetRange("Function No.", Function."Entry No.");
        if TempVariable.FindSet() then
            repeat
            // TODO init variables
            until TempVariable.Next() = 0;

        // TODO execute node function
        TempNode.Copy(TempFunctionNode, true);
        TempNode.SetRange("Parent Entry No.", TempFunctionNode."Entry No.");
        if TempNode.FindSet() then
            repeat
                ExecuteNode(TempNode);
            until TempNode.Next() = 0;

        // TODO pop call stack
    end;

    local procedure ExecuteAssignementStatementNode(var TempAssignementStatementNode: Record "FS Node" temporary)
    begin
        // 1. execute child expression
        // 2. set variable
    end;
}

// TODO
// "Call Stack" codeunit
//  - handles variables
//  - has push and pop methods for calling functions
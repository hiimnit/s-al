codeunit 81004 "FS Interpreter"
{
    var
        NodeTree: Codeunit "FS Node Tree";
        Memory: Codeunit "FS Memory";

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
        OnRun: Record "FS Function";
        ProgressDialog: Dialog;
    begin
        ProgressDialog.Open('Executing...');

        InitGlobalVariables();

        // 0. init globals
        // 1. find + execute OnRun()
        // 2.
        NodeTree.GetOnRun(OnRun);
        ExecuteFunction(OnRun);

        ProgressDialog.Close();
    end;

    local procedure InitGlobalVariables()
    var
        TempVariable: Record "FS Variable" temporary;
    begin
        NodeTree.GetVariables(TempVariable);
        Memory.InitGlobals(TempVariable);
    end;

    local procedure ExecuteNode(var TempNode: Record "FS Node" temporary): Codeunit "FS Variable"
    var
        Result: Codeunit "FS Variable";
    begin
        case TempNode.Type of
            "FS Node Type"::FunctionCall:
                Result := ExecuteFunctionCallNode(TempNode);
            "FS Node Type"::CompoundStatement:
                ExecuteCompoundStatementNode(TempNode);
            "FS Node Type"::AssignmentStatement:
                ExecuteAssignementStatementNode(TempNode);
            "FS Node Type"::Operation:
                Result := ExecuteOperationNode(TempNode);
            "FS Node Type"::Variable:
                Result := ExecuteVariableNode(TempNode);
            "FS Node Type"::NumericValue:
                Result := SetNumericValue(TempNode);
            "FS Node Type"::TextValue:
                Result := SetTextValue(TempNode);
        end;

        exit(Result);
    end;

    local procedure ExecuteFunctionCallNode(var TempFunctionNode: Record "FS Node" temporary): Codeunit "FS Variable"
    var
        Function: Record "FS Function";
        Result: Codeunit "FS Variable";
    begin
        NodeTree.GetFunction(TempFunctionNode."Variable Name", Function);
        Result := ExecuteFunction(Function);
        exit(Result);
    end;

    local procedure ExecuteFunction(Function: Record "FS Function"): Codeunit "FS Variable"
    var
        TempVariable: Record "FS Variable" temporary;
        TempNode: Record "FS Node" temporary;
        Result: Codeunit "FS Variable";
    begin
        // TODO built-ins?

        NodeTree.GetNodes(TempNode);
        // find function entry point
        TempNode.SetRange(Type, TempNode.Type::Function);
        TempNode.SetRange("Function No.", Function."Entry No.");
        TempNode.FindFirst();

        NodeTree.GetVariables(TempVariable); // TODO get already filtered for function?
        TempVariable.SetRange(Scope, TempVariable.Scope::Local);
        TempVariable.SetRange("Function No.", Function."Entry No.");
        Memory.Push(Function, TempVariable);

        TempNode.Reset();
        TempNode.SetRange("Parent Entry No.", TempNode."Entry No.");
        if TempNode.FindSet() then
            repeat
                ExecuteNode(TempNode);
            until TempNode.Next() = 0;

        Result := Memory.Pop();

        exit(Result);
    end;

    local procedure ExecuteCompoundStatementNode(var TempCompoundStatementNode: Record "FS Node" temporary)
    var
        TempStatementNode: Record "FS Node" temporary;
    begin
        TempStatementNode.Copy(TempCompoundStatementNode, true);
        TempStatementNode.Reset();
        TempStatementNode.SetRange("Parent Entry No.", TempCompoundStatementNode."Entry No.");
        if TempStatementNode.FindSet() then
            repeat
                ExecuteNode(TempStatementNode);
            until TempStatementNode.Next() = 0;
    end;

    local procedure ExecuteAssignementStatementNode(var TempAssignementStatementNode: Record "FS Node" temporary)
    var
        TempChildNode: Record "FS Node" temporary;
        Result: Codeunit "FS Variable";

        tmp: Variant; // TODO tmp
    begin
        // TODO different types of assignment statements (+= -= *= /= ...) - use the operator field

        TempChildNode.Copy(TempAssignementStatementNode, true);
        TempChildNode.Reset();
        TempChildNode.SetRange("Parent Entry No.", TempAssignementStatementNode."Entry No.");
        TempChildNode.FindFirst();

        Result := ExecuteNode(TempChildNode);

        Result.GetValue(tmp);
        Message('%1', tmp);

        Memory.SetVariable(TempAssignementStatementNode."Variable Name", Result);
    end;

    local procedure ExecuteOperationNode(var TempOperationNode: Record "FS Node" temporary): Codeunit "FS Variable"
    var
        TempOperandNode: Record "FS Node" temporary;
        Left, Right : Codeunit "FS Variable";
        Result: Codeunit "FS Variable";
    begin
        TempOperandNode.Copy(TempOperationNode, true);
        TempOperandNode.Reset();
        TempOperandNode.SetRange("Parent Entry No.", TempOperationNode."Entry No.");
        TempOperandNode.FindFirst();
        Left := ExecuteNode(TempOperandNode);
        // TODO test value!

        TempOperandNode.Next(); // TODO test next !
        Right := ExecuteNode(TempOperandNode);
        // TODO test value!

        case TempOperationNode.Operator of
            TempOperationNode.Operator::"+":
                Result.Add(Left, Right);
            TempOperationNode.Operator::"-":
                Result.Subtract(Left, Right);
            TempOperationNode.Operator::"*":
                Result.Multiply(Left, Right);
            TempOperationNode.Operator::"/":
                Result.Divide(Left, Right);
        // TODO and/or/div/mod ...
        end;

        exit(Result);
    end;

    local procedure ExecuteVariableNode(var TempVariableNode: Record "FS Node" temporary): Codeunit "FS Variable"
    begin
        exit(Memory.GetVariable(TempVariableNode."Variable Name"));
    end;

    local procedure SetNumericValue(var TempVariableNode: Record "FS Node" temporary): Codeunit "FS Variable"
    var
        Result: Codeunit "FS Variable";
    begin
        Result.Setup('', Enum::"FS Variable Type"::decimal, 0); // XXX decimal?
        Result.SetValue(TempVariableNode."Numeric Value");
        exit(Result);
    end;

    local procedure SetTextValue(var TempVariableNode: Record "FS Node" temporary): Codeunit "FS Variable"
    var
        Result: Codeunit "FS Variable";
    begin
        Result.Setup('', Enum::"FS Variable Type"::text, 0); // XXX text?
        Result.SetValue(TempVariableNode.GetTextValue());
        exit(Result);
    end;
}

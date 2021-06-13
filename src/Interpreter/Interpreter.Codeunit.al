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
        TempNode: Record "FS Node" temporary;
        ProgressDialog: Dialog;
    begin
        ProgressDialog.Open('Executing...');

        InitGlobalVariables();

        // 0. init globals
        // 1. find + execute OnRun()
        // 2.
        NodeTree.GetOnRun(OnRun);
        NodeTree.GetNodes(TempNode);
        ExecuteFunction(OnRun, TempNode);

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
            "FS Node Type"::BooleanValue:
                Result := SetBooleanValue(TempNode);
            else
                Error('TODO');
        end;

        exit(Result);
    end;

    local procedure ExecuteFunctionCallNode(var TempFunctionNode: Record "FS Node" temporary): Codeunit "FS Variable"
    var
        Function: Record "FS Function";
        Result: Codeunit "FS Variable";
        BuiltInFunction: Enum "FS Built-in Function";
    begin
        if not NodeTree.GetFunction(TempFunctionNode."Variable Name", Function) then begin
            BuiltInFunction := ValidateBuiltInFunction(TempFunctionNode."Variable Name");
            Function."Entry No." := -BuiltInFunction.AsInteger();
            Function.Name := TempFunctionNode."Variable Name";
        end;

        Result := ExecuteFunction(Function, TempFunctionNode);
        exit(Result);
    end;

    local procedure ValidateBuiltInFunction(FunctionName: Text) FunctionId: Enum "FS Built-in Function"
    var
        i, Id : Integer;
    begin
        i := Enum::"FS Built-in Function".Names().IndexOf(FunctionName.ToLower());
        if i = 0 then
            Error('Unknown function %1.', FunctionName);

        Id := Enum::"FS Built-in Function".Ordinals().Get(i);
        FunctionId := Enum::"FS Built-in Function".FromInteger(Id);
    end;

    local procedure ExecuteFunction(Function: Record "FS Function"; var TempFunctionNode: Record "FS Node" temporary): Codeunit "FS Variable"
    var
        TempVariable: Record "FS Variable" temporary;
        TempNode, TempParameterExpressionNode : Record "FS Node" temporary;
        Result: Codeunit "FS Variable";

        ParameterMismatchErr: Label 'Can not call function %1.\\Reason: Parameter count mismatch.', Comment = '%1 = function name';
    begin
        if Function."Entry No." < NodeTree.OnRunFunctionNo() then
            // built-in function handling
            exit(ExecuteBuiltInFunction(Function, TempFunctionNode));

        TempNode.Copy(TempFunctionNode, true);
        TempNode.Reset();
        // find function entry point
        TempNode.SetRange(Type, TempNode.Type::Function);
        TempNode.SetRange("Function No.", Function."Entry No.");
        TempNode.FindFirst();

        NodeTree.GetVariables(TempVariable); // TODO get already filtered for function?
        TempVariable.SetRange(Scope, TempVariable.Scope::Parameter);
        TempVariable.SetRange("Function No.", Function."Entry No.");
        if TempVariable.FindSet() then begin
            TempParameterExpressionNode.Copy(TempFunctionNode, true);
            TempParameterExpressionNode.Reset();
            TempParameterExpressionNode.SetRange("Parent Entry No.", TempFunctionNode."Entry No.");
            TempParameterExpressionNode.FindSet(); // TODO checks

            if TempVariable.Count() <> TempParameterExpressionNode.Count() then
                Error(ParameterMismatchErr, Function.Name);

            repeat
                Result := ExecuteNode(TempParameterExpressionNode);
                Memory.SetParameter(TempVariable, Result);
            until (TempVariable.Next() = 0) or (TempParameterExpressionNode.Next() = 0);
        end;

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

    local procedure ExecuteBuiltInFunction(Function: Record "FS Function"; var TempFunctionNode: Record "FS Node" temporary): Codeunit "FS Variable"
    var
        TempParameterExpressionNode: Record "FS Node" temporary;
        Result: Codeunit "FS Variable";
        LocalMemory: Codeunit "FS Memory";
        i: Integer;
    begin
        TempParameterExpressionNode.Copy(TempFunctionNode, true);
        TempParameterExpressionNode.Reset();
        TempParameterExpressionNode.SetRange("Parent Entry No.", TempFunctionNode."Entry No.");
        if TempParameterExpressionNode.FindSet() then
            repeat
                Result := ExecuteNode(TempParameterExpressionNode);
                Result.SetName(Format(i));
                LocalMemory.AddVariable(Result);

                i += 1;
            until TempParameterExpressionNode.Next() = 0;

        case -Function."Entry No." of
            Enum::"FS Built-in Function"::message.AsInteger():
                case LocalMemory.GetVariableCount() of
                    1:
                        Message(LocalMemory.GetVariable('0').GetValue());
                    2:
                        Message(LocalMemory.GetVariable('0').GetValue(), LocalMemory.GetVariable('1').GetValue());
                    3:
                        Message(LocalMemory.GetVariable('0').GetValue(), LocalMemory.GetVariable('1').GetValue(), LocalMemory.GetVariable('2').GetValue());
                    else
                        Error('Unsupported number of parameters for function %1.', Function.Name);
                end;
            else
                Error('Function %1 is not implemented.', Function.Name);
        end;

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
        Result, Variable : Codeunit "FS Variable";
        VariableName, PropertyName : Text;
    begin
        // TODO different types of assignment statements (+= -= *= /= ...) - use the operator field

        TempChildNode.Copy(TempAssignementStatementNode, true);
        TempChildNode.Reset();
        TempChildNode.SetRange("Parent Entry No.", TempAssignementStatementNode."Entry No.");
        TempChildNode.FindSet();
        VariableName := TempChildNode."Variable Name";
        PropertyName := GetPropertyName(TempChildNode);

        TempChildNode.Next(); // TODO test non zero
        Result := ExecuteNode(TempChildNode);

        if PropertyName <> '' then begin
            Variable := Memory.GetVariable(VariableName);
            Result := SetPropertyValue(Variable, PropertyName, Result);
        end;

        Memory.SetVariable(VariableName, Result);
    end;

    local procedure GetPropertyName(var TempVariableNode: Record "FS Node" temporary): Text
    var
        TempChildNode: Record "FS Node" temporary;
    begin
        TempChildNode.Copy(TempVariableNode, true);
        TempChildNode.Reset();
        TempChildNode.SetRange("Parent Entry No.", TempVariableNode."Entry No.");
        if TempChildNode.FindFirst() then
            exit(TempChildNode."Variable Name");
        exit('');
    end;

    local procedure SetPropertyValue
    (
        Variable: Codeunit "FS Variable";
        PropertyName: Text;
        NewValue: Codeunit "FS Variable"
    ): Codeunit "FS Variable"
    var
        Result: Codeunit "FS Variable";
        RecordRef: RecordRef;
        Value: Variant;
        FieldId: Integer;
    begin
        if Variable.GetType() <> Enum::"FS Variable Type"::record then
            Error('Property Access is not supported for %1', Variable.GetType());

        Variable.GetValue(Value);
        RecordRef := Value;

        FieldId := NodeTree.ValidateField(RecordRef.Number(), PropertyName);

        NewValue.GetValue(Value);
        RecordRef.Field(FieldId).Value(Value);

        Variable.Copy(Result);
        Result.SetValue(RecordRef);
        exit(Result);
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
    var
        TempNode: Record "FS Node" temporary;
        Result: Codeunit "FS Variable";
    begin
        Result := Memory.GetVariable(TempVariableNode."Variable Name");

        if TempVariableNode."Property Access" then begin
            TempNode.Copy(TempVariableNode, true);
            TempNode.Reset();
            TempNode.SetRange("Parent Entry No.", TempVariableNode."Entry No.");
            TempNode.FindFirst();

            case TempNode.Type of
                Enum::"FS Node Type"::Variable:
                    Result := SetPropertyValue(TempNode, Result);
                Enum::"FS Node Type"::FunctionCall:
                    Result := ExecuteMethod(TempNode, Result);
                else
                    Error('Unexpected token.'); // TODO
            end
        end;

        exit(Result);
    end;

    local procedure SetPropertyValue(var TempPropertyNode: Record "FS Node" temporary; var Variable: Codeunit "FS Variable"): Codeunit "FS Variable"
    var
        Result: Codeunit "FS Variable";
        RecordRef: RecordRef;
        Value: Variant;
        Property: Text;
        FieldId: Integer;
    begin
        if Variable.GetType() <> Enum::"FS Variable Type"::record then
            Error('Property Access is not supported for %1', Variable.GetType());

        Property := TempPropertyNode."Variable Name";
        Variable.GetValue(Value);
        RecordRef := Value;

        FieldId := NodeTree.ValidateField(RecordRef.Number(), Property);

        Result.Setup(
            '',
            NodeTree.FieldType2VariableType(RecordRef.Field(FieldId).Type()),
            0,
            0);
        Result.SetValue(RecordRef.Field(FieldId).Value());
        exit(Result);
    end;

    local procedure ExecuteMethod(var TempMethodNode: Record "FS Node" temporary; var Variable: Codeunit "FS Variable"): Codeunit "FS Variable"
    var
        Result: Codeunit "FS Variable";
        RecordRef: RecordRef;
        Value: Variant;
        Method: Text;
        i: Integer;
    begin
        if Variable.GetType() <> Enum::"FS Variable Type"::record then
            Error('Property Access is not supported for %1', Variable.GetType());

        Method := TempMethodNode."Variable Name";
        Variable.GetValue(Value);
        RecordRef := Value;

        case Method.ToLower() of
            'findfirst':
                RecordRef.FindFirst(); // FIXME return value
            'next':
                begin
                    i := RecordRef.Next(); // TODO parameters
                    Result.Setup(Enum::"FS Variable Type"::integer);
                    Result.SetValue(i);
                end;
            'modify':
                RecordRef.Modify(); // FIXME return value + parameters
            'count':
                begin
                    i := RecordRef.Count();
                    Result.Setup(Enum::"FS Variable Type"::integer);
                    Result.SetValue(i);
                end;
            else
                Error('Unsupported method %1.', Method);
        end;

        Value := RecordRef;
        Memory.SetVariable(Variable.GetName(), Value); // FIXME wouldn't Variable.SetValue(Value); be enough?

        exit(Result);
    end;

    local procedure SetNumericValue(var TempVariableNode: Record "FS Node" temporary): Codeunit "FS Variable"
    var
        Result: Codeunit "FS Variable";
    begin
        Result.Setup(Enum::"FS Variable Type"::decimal); // XXX decimal?
        Result.SetValue(TempVariableNode."Numeric Value");
        exit(Result);
    end;

    local procedure SetTextValue(var TempVariableNode: Record "FS Node" temporary): Codeunit "FS Variable"
    var
        Result: Codeunit "FS Variable";
    begin
        Result.Setup(Enum::"FS Variable Type"::text); // XXX text?
        Result.SetValue(TempVariableNode.GetTextValue());
        exit(Result);
    end;

    local procedure SetBooleanValue(var TempVariableNode: Record "FS Node" temporary): Codeunit "FS Variable"
    var
        Result: Codeunit "FS Variable";
    begin
        Result.Setup(Enum::"FS Variable Type"::boolean);
        Result.SetValue(TempVariableNode."Boolean Value");
        exit(Result);
    end;
}

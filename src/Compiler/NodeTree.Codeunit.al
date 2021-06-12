codeunit 81003 "FS Node Tree"
{
    var
        TempNode: Record "FS Node" temporary;
        TempFunction: Record "FS Function" temporary;
        TempVariable: Record "FS Variable" temporary;
        FunctionMapping: Dictionary of [Text, Integer];
        CurrentFunction: Integer;
        Order: Integer;
        Indentation: Integer;

    procedure ShowNodeTree()
    var
        NodeTreeView: Page "FS Node Tree View";
    begin
        NodeTreeView.SetRecords(TempNode, TempVariable);
        NodeTreeView.Run();
    end;

    procedure GetVariables(var VarTempVariable: Record "FS Variable" temporary)
    begin
        VarTempVariable.Copy(TempVariable, true);
    end;

    procedure GetNodes(var VarTempNode: Record "FS Node" temporary)
    begin
        VarTempNode.Copy(TempNode, true);
    end;

    procedure GetOnRun(var OnRun: Record "FS Function")
    begin
        GetFunction(OnRunFunctionNo(), OnRun);
    end;

    procedure GetFunction(FunctionName: Text; var Function: Record "FS Function")
    begin
        GetFunction(FunctionMapping.Get(FunctionName.ToLower()), Function);
    end;

    procedure GetFunction(FunctionNo: Integer; var Function: Record "FS Function")
    begin
        TempFunction.Get(FunctionNo);
        Function := TempFunction;
    end;

    local procedure InitTempNode(ParentNode: Integer)
    begin
        TempNode.Init();
        TempNode."Entry No." := 0;
        TempNode."Parent Entry No." := ParentNode;

        TempNode."Function No." := CurrentFunction;

        TempNode.Indentation := Indentation;
    end;

    local procedure OnRunFunctionNo(): Integer
    begin
        exit(-1);
    end;

    procedure InsertOnRun(Name: Text[250]; var FunctionNo: Integer): Integer
    begin
        FunctionNo := OnRunFunctionNo();
        exit(InsertFunctionLocal(Name, FunctionNo));
    end;

    procedure InsertFunction(Name: Text[250]; var FunctionNo: Integer): Integer
    begin
        FunctionNo := 0;
        exit(InsertFunctionLocal(Name, FunctionNo));
    end;

    local procedure InsertFunctionLocal(Name: Text[250]; var FunctionNo: Integer) FunctionNode: Integer
    begin
        CheckFunctionDefinition(Name);

        TempFunction.Init();
        TempFunction."Entry No." := FunctionNo;
        TempFunction.Name := Name;
        // TODO return type and var name?
        TempFunction.Insert(true);

        CurrentFunction := TempFunction."Entry No.";
        FunctionMapping.Add(Name.ToLower(), CurrentFunction);

        InitTempNode(0);
        TempNode.Type := "FS Node Type"::Function;
        TempNode."Function Name" := Name;
        TempNode."Function No." := CurrentFunction;

        FunctionNo := CurrentFunction;
        FunctionNode := InsertTempNode();
    end;

    local procedure CheckFunctionDefinition(Name: Text[250])
    var
        TempFunctionCopy: Record "FS Function" temporary;
        AlreadyDefinedErr: Label 'Function %1 is already defined.', Comment = '%1 = Function name';
    begin
        TempFunctionCopy.Copy(TempFunction, true);
        TempFunctionCopy.SetRange(Name, Name);
        if not TempFunctionCopy.IsEmpty() then
            Error(AlreadyDefinedErr, Name);
    end;

    procedure InsertIfStatement(ParentNode: Integer): Integer
    begin
        InitTempNode(ParentNode);
        TempNode.Type := "FS Node Type"::IfStatement;

        exit(InsertTempNode());
    end;

    procedure UpdateIfStatement
    (
        IfNode: Integer;
        ConditionNode: Integer;
        TrueNode: Integer;
        FalseNode: Integer
    )
    begin
        TempNode.Get(IfNode);
        TempNode."If Condition Node" := ConditionNode;
        TempNode."If True Statement Node" := TrueNode;
        TempNode."If False Statement Node" := FalseNode;
        TempNode.Modify(true);
    end;

    procedure InsertCompoundStatement(ParentNode: Integer): Integer
    begin
        InitTempNode(ParentNode);
        TempNode.Type := "FS Node Type"::CompoundStatement;

        exit(InsertTempNode());
    end;

    procedure InsertAssignment
    (
        ParentNode: Integer;
        Name: Text[250]
    ): Integer
    begin
        InitTempNode(ParentNode);
        TempNode.Type := "FS Node Type"::AssignmentStatement; // FIXME ?
        TempNode."Variable Name" := Name;

        exit(InsertTempNode());
    end;

    procedure InsertOperation
    (
        ParentNode: Integer;
        Operation: Enum "FS Operator"
    ): Integer
    begin
        InitTempNode(ParentNode);
        TempNode.Type := "FS Node Type"::Operation;
        TempNode.Operator := Operation;

        exit(InsertTempNode());
    end;

    procedure InsertUnaryOperator
    (
        ParentNode: Integer;
        Operator: Enum "FS Operator"
    ): Integer
    begin
        InitTempNode(ParentNode);
        TempNode.Type := "FS Node Type"::UnaryOperator;
        TempNode.Operator := Operator;

        exit(InsertTempNode());
    end;

    procedure InsertNumericValue
    (
        ParentNode: Integer;
        Value: Decimal
    ): Integer
    begin
        InitTempNode(ParentNode);
        TempNode.Type := "FS Node Type"::NumericValue;
        TempNode."Numeric Value" := Value;

        exit(InsertTempNode());
    end;

    procedure InsertBooleanValue
    (
        ParentNode: Integer;
        Value: Boolean
    ): Integer
    begin
        InitTempNode(ParentNode);
        TempNode.Type := "FS Node Type"::BooleanValue;
        TempNode."Boolean Value" := Value;

        exit(InsertTempNode());
    end;

    procedure InsertTextValue
    (
        ParentNode: Integer;
        Value: Text
    ): Integer
    begin
        InitTempNode(ParentNode);
        TempNode.Type := "FS Node Type"::BooleanValue;
        TempNode.SetTextValue(Value);

        exit(InsertTempNode());
    end;

    procedure InsertVariable
    (
        ParentNode: Integer;
        Name: Text[100]
    ): Integer
    begin
        InitTempNode(ParentNode);
        TempNode.Type := "FS Node Type"::Variable;
        TempNode."Variable Name" := Name;

        exit(InsertTempNode());
    end;

    procedure InsertFunctionCall
    (
        ParentNode: Integer;
        Name: Text[100]
    // TODO add parameters
    ): Integer
    begin
        InitTempNode(ParentNode);
        TempNode.Type := "FS Node Type"::FunctionCall;
        TempNode."Variable Name" := Name;

        exit(InsertTempNode());
    end;

    local procedure InsertTempNode() EntryNo: Integer
    begin
        Order += 1;
        TempNode.Order := Order;

        TempNode.Insert(true);

        EntryNo := TempNode."Entry No.";
    end;

    procedure UpdateParent(NodeNo: Integer; NewParentNo: Integer)
    begin
        TempNode.Get(NodeNo);
        if NewParentNo in [TempNode."Entry No.", TempNode."Parent Entry No."] then
            exit;

        TempNode."Parent Entry No." := NewParentNo;
        TempNode.Modify(true);
    end;

    procedure ResetIndentation()
    begin
        Indentation := 0;
    end;

    procedure Indent()
    begin
        Indentation += 1;
    end;

    procedure UnIndent()
    begin
        Indentation -= 1;
    end;

    procedure UpdateOrderAndIndentation(NodeNo: Integer)
    begin
        // TODO also update indentation ?
        TempNode.Get(NodeNo);
        Order := TempNode.Order - 1;
        UpdateOrderAndIndentation(TempNode, Order, TempNode.Indentation + 1);
    end;

    local procedure UpdateOrderAndIndentation
    (
        var TempNode: Record "FS Node" temporary;
        var Order: Integer;
        Indentation: Integer
    )
    var
        TempChildNode: Record "FS Node" temporary;
    begin
        Order += 1;
        TempNode.Order := Order;
        TempNode.Indentation := Indentation;
        TempNode.Modify(true);

        TempChildNode.Copy(TempNode, true);
        TempChildNode.SetRange("Parent Entry No.", TempNode."Entry No.");
        if TempChildNode.FindSet(true) then
            repeat
                UpdateOrderAndIndentation(TempChildNode, Order, Indentation + 1);
            until TempChildNode.Next() = 0;
    end;

    procedure InsertVariableDefinition
    (
        Scope: Enum "FS Variable Scope";
        Name: Text[250];
        Type: Enum "FS Variable Type";
        FunctionNo: Integer
    ): Integer
    begin
        exit(InsertVariableDefinition(Scope, Name, Type, FunctionNo, 0));
    end;

    procedure InsertVariableDefinition
    (
        Scope: Enum "FS Variable Scope";
        Name: Text[250];
        Type: Enum "FS Variable Type";
        FunctionNo: Integer;
        Length: Integer
    ): Integer
    begin
        CheckVariableDefinition(Scope, FunctionNo, Name);

        TempVariable.Init();
        TempVariable."Entry No." := 0;
        TempVariable.Name := Name;
        TempVariable.Type := Type;
        TempVariable."Function No." := FunctionNo;
        TempVariable.Length := Length;
        TempVariable.Scope := Scope;
        TempVariable.Insert(true);

        exit(TempVariable."Entry No.");
    end;

    local procedure CheckVariableDefinition
    (
        Scope: Enum "FS Variable Scope";
        FunctionNo: Integer;
        Name: Text[250]
    )
    var
        TempVariableCopy: Record "FS Variable" temporary;
        AlreadyDefinedErr: Label 'Variable %1 is already defined.', Comment = '%1 = Variable name';
    begin
        TempVariableCopy.Copy(TempVariable, true);
        case Scope of
            Scope::Global:
                TempVariableCopy.SetRange(Scope, Scope);
            Scope::Local,
            Scope::Parameter:
                TempVariableCopy.SetFilter(Scope, '%1|%2', Scope::Local, Scope::Parameter);
        end;
        TempVariableCopy.SetRange("Function No.", FunctionNo);
        TempVariableCopy.SetRange(Name, Name);
        if not TempVariableCopy.IsEmpty() then
            Error(AlreadyDefinedErr, Name);
    end;

    procedure ValidateVariable
    (
        Name: Text[250];
        ParentNode: Integer // TODO rename
    ) VariableType: Enum "FS Variable Type"
    var
        TempVariableCopy: Record "FS Variable" temporary;
    begin
        TempVariableCopy.Copy(TempVariable, true);

        TempVariableCopy.SetRange(Name, Name);
        TempVariableCopy.SetRange(Scope, TempVariableCopy.Scope::Local);
        if not TempVariableCopy.FindFirst() then begin
            TempVariableCopy.SetRange(Scope, TempVariableCopy.Scope::Global);
            if not TempVariableCopy.FindFirst() then
                Error('Unknown variable %1.', Name);
        end;

        VariableType := TempVariableCopy.Type;
    end;
}
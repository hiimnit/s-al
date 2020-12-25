codeunit 81003 "FS Node Tree"
{
    var
        TempNode: Record "FS Node" temporary;
        TempVariable: Record "FS Variable" temporary;
        Order: Integer;

    procedure ShowNodeTree()
    var
        NodeTreeView: page "FS Node Tree View";
    begin
        NodeTreeView.SetRecords(TempNode, TempVariable);
        NodeTreeView.Run();
    end;

    // TODO Order and Indentation!

    local procedure InitTempNode(ParentNode: Integer)
    begin
        TempNode.Init();
        TempNode."Entry No." := 0;
        TempNode."Parent Entry No." := ParentNode;
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
        TempNode.Type := "FS Node Type"::Assignment;
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
        if TempNode."Parent Entry No." = NewParentNo then
            exit;

        TempNode."Parent Entry No." := NewParentNo;
        TempNode.Modify(true);
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

    procedure InsertLocalVariable
    (
        Name: Text[250];
        Type: Enum "FS Variable Type";
        ParentNode: Integer // TODO rename
    )
    begin
        InsertLocalVariable(Name, Type, ParentNode, 0);
    end;

    procedure InsertLocalVariable
    (
        Name: Text[250];
        Type: Enum "FS Variable Type";
        ParentNode: Integer; // TODO rename
        Length: Integer
    )
    begin
        TempVariable.Init();
        TempVariable.Name := Name;
        TempVariable.Type := Type;
        TempVariable."Parent Node No." := ParentNode;
        TempVariable.Length := Length;
        TempVariable.Scope := TempVariable.Scope::Local;
        TempVariable.Insert(true);
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
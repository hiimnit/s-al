codeunit 81003 "FS Node Tree"
{
    var
        TempNode: Record "FS Node" temporary;
        Order: Integer;

    procedure ShowNodeTree()
    var
        NodeTreeView: page "FS Node Tree View";
    begin
        NodeTreeView.SetRecords(TempNode);
        NodeTreeView.Run();
    end;

    // TODO Order and Indentation!

    local procedure InitTempNode()
    begin
        TempNode.Init();
        TempNode."Entry No." := 0;
    end;

    procedure InsertCompoundStatement(): Integer
    begin
        exit(InsertCompoundStatement(0)); // TODO change to 1?
    end;

    procedure InsertCompoundStatement(ParentNode: Integer): Integer
    begin
        InitTempNode();
        TempNode.Type := "FS Node Type"::CompoundStatement;

        exit(InsertTempNode());
    end;

    procedure InsertAssignment
    (
        ParentNode: Integer;
        Name: Text[100]
    ): Integer
    begin
        InitTempNode();
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
        InitTempNode();
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
        InitTempNode();
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
        InitTempNode();
        TempNode.Type := "FS Node Type"::NumericValue;
        TempNode."Numeric Value" := Value;

        exit(InsertTempNode());
    end;

    procedure InsertVariable
    (
        ParentNode: Integer;
        Name: Text[100]
    ): Integer
    begin
        InitTempNode();
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

        TempNode.Validate("Parent Entry No.", NewParentNo);
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
}
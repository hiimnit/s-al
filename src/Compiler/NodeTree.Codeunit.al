codeunit 81003 "FS Node Tree"
{
    var
        TempNode: Record "FS Node" temporary;

    procedure InsertCompoundStatement(): Integer
    begin
        exit(InsertCompoundStatement(0)); // TODO change to 1?
    end;

    procedure InsertCompoundStatement(ParentNode: Integer): Integer
    begin
        TempNode.Init();
        TempNode."Entry No." := 0;
        TempNode.Type := "FS Node Type"::CompoundStatement;
        TempNode.Insert(true);

        exit(TempNode."Entry No.");
    end;

    procedure InsertAssignment
    (
        ParentNode: Integer;
        Name: Text[100]
    ): Integer
    begin
        TempNode.Init();
        TempNode."Entry No." := 0;
        TempNode.Type := "FS Node Type"::Assignment;
        TempNode."Variable Name" := Name;
        TempNode.Insert(true);

        exit(TempNode."Entry No.");
    end;

    procedure InsertOperation
    (
        ParentNode: Integer;
        Operation: Enum "FS Operator"
    ): Integer
    begin
        TempNode.Init();
        TempNode."Entry No." := 0;
        TempNode.Type := "FS Node Type"::Operation;
        TempNode.Operator := Operation;
        TempNode.Insert(true);

        // FIXME add left + right op

        exit(TempNode."Entry No.");
    end;

    procedure InsertUnaryOperator
    (
        ParentNode: Integer;
        Operator: Enum "FS Operator"
    ): Integer
    begin
        TempNode.Init();
        TempNode."Entry No." := 0;
        TempNode.Type := "FS Node Type"::UnaryOperator;
        TempNode.Operator := Operator;
        TempNode.Insert(true);

        exit(TempNode."Entry No.");
    end;

    procedure InsertNumericValue
    (
        ParentNode: Integer;
        Value: Decimal
    ): Integer
    begin
        TempNode.Init();
        TempNode."Entry No." := 0;
        TempNode.Type := "FS Node Type"::NumericValue;
        TempNode."Numeric Value" := Value;
        TempNode.Insert(true);

        exit(TempNode."Entry No.");
    end;

    procedure InsertVariable
    (
        ParentNode: Integer;
        Name: Text[100]
    ): Integer
    begin
        TempNode.Init();
        TempNode."Entry No." := 0;
        TempNode.Type := "FS Node Type"::Variable;
        TempNode."Variable Name" := Name;
        TempNode.Insert(true);

        exit(TempNode."Entry No.");
    end;
}
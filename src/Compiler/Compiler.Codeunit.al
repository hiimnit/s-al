codeunit 81002 "FS Compiler"
{
    var
        Lexer: Codeunit "FS Lexer";
        NodeTree: Codeunit "FS Node Tree";

    procedure Compile(Code: Text)
    begin
        Clear(Lexer);
        Lexer.Analyze(Code);

        // TODO temporary
        CompileCompoundStatement();
    end;

    local procedure CompileCompoundStatement()
    var
        CompoundStatement: Integer;
    begin
        AssertNextLexeme("FS Keyword"::"begin");
        CompoundStatement := NodeTree.InsertCompoundStatement();
        CompileStatment(CompoundStatement);

        while PeekNextLexeme("FS Operator"::";") do begin
            AssertNextLexeme("FS Operator"::";");
            CompileStatment(CompoundStatement);
        end;

        AssertNextLexeme("FS Keyword"::"end");
    end;

    local procedure CompileStatment(CompoundStatement: Integer)
    begin
        case true of
            PeekNextLexeme("FS Lexeme Type"::Symbol):
                CompileAssignment(CompoundStatement);
            else
                NoOp();
        end;
    end;

    local procedure NoOp()
    begin
    end;

    local procedure CompileAssignment(CompoundStatement: Integer)
    var
        Variable: Text[100];
        Assignment: Integer;
    begin
        Variable := ''; // TODO
                        // TODO check variable declaration 

        AssertNextLexeme("FS Operator"::":=");

        Assignment := NodeTree.InsertAssignment(CompoundStatement, Variable); // TODO add expression entry no. ?
        // TODO also add variablenode ?

        CompileExpression(Assignment);
    end;

    local procedure CompileExpression(ParentNode: Integer) Expression: Integer
    var
        Product: Integer;
    begin
        Product := CompileProduct(ParentNode);
        // TODO while ?

        case true of
            PeekNextLexeme("FS Operator"::"+"):
                begin
                    AssertNextLexeme("FS Operator"::"+");
                    // TODO change Factor order/parent
                    Expression := NodeTree.InsertOperation(ParentNode, "FS Operator"::"+");
                    CompileExpression(Expression);
                end;
            PeekNextLexeme("FS Operator"::"-"):
                begin
                    AssertNextLexeme("FS Operator"::"-");
                    // TODO change Factor order/parent
                    Expression := NodeTree.InsertOperation(ParentNode, "FS Operator"::"-");
                    CompileExpression(Expression);
                end;
            else
                Expression := Product;
        end;
    end;

    local procedure CompileProduct(ParentNode: Integer) Product: Integer
    var
        Factor: Integer;
    begin
        Factor := CompileFactor(ParentNode);
        // TODO while ?

        case true of
            PeekNextLexeme("FS Operator"::"*"):
                begin
                    AssertNextLexeme("FS Operator"::"*");
                    // TODO change Factor order/parent
                    Product := NodeTree.InsertOperation(ParentNode, "FS Operator"::"*");
                    CompileExpression(Product);
                end;
            PeekNextLexeme("FS Operator"::"/"):
                begin
                    AssertNextLexeme("FS Operator"::"/");
                    // TODO change Factor order/parent
                    Product := NodeTree.InsertOperation(ParentNode, "FS Operator"::"/");
                    CompileExpression(Product);
                end;
            else
                Product := Factor;
        end;
    end;

    local procedure CompileFactor(ParentNode: Integer): Integer
    var
        myInt: Integer;
    begin
        case true of
            PeekNextLexeme("FS Operator"::"+"),
            PeekNextLexeme("FS Operator"::"-"):
                CompileUnaryOperator(ParentNode);
            PeekNextLexeme("FS Operator"::"("):
                begin
                    AssertNextLexeme("FS Operator"::"(");
                    CompileExpression(ParentNode);
                    AssertNextLexeme("FS Operator"::")");
                end;
            PeekNextLexeme("FS Lexeme Type"::Integer),
            PeekNextLexeme("FS Lexeme Type"::Decimal):
                CompileValue(ParentNode);
            PeekNextLexeme("FS Lexeme Type"::Symbol):
                CompileVariable(ParentNode);
            else
                Error('TODO'); // TODO error message
        end;
    end;

    local procedure CompileUnaryOperator(ParentNode: Integer) UnaryOperator: Integer
    var
        Lexeme: Record "FS Lexeme";
        Operator: Enum "FS Operator";
    begin
        Lexer.GetNextLexeme(Lexeme);

        case Lexeme.Operator of
            "FS Operator"::"+",
            "FS Operator"::"-":
                Operator := Lexeme.Operator;
            else
                Error('TODO'); // TODO error message
        end;

        UnaryOperator := NodeTree.InsertUnaryOperator(ParentNode, Operator);
        CompileUnaryOperator(UnaryOperator); // ?
    end;

    local procedure CompileValue(ParentNode: Integer) Value: Integer
    var
        Lexeme: Record "FS Lexeme";
    begin
        Lexer.GetNextLexeme(Lexeme);
        // TODO checks ?
        Value := NodeTree.InsertNumericValue(ParentNode, Lexeme."Number Value");
    end;

    local procedure CompileVariable(ParentNode: Integer) Variable: Integer
    var
        Lexeme: Record "FS Lexeme";
    begin
        Lexer.GetNextLexeme(Lexeme);
        // TODO checks ?
        Variable := NodeTree.InsertVariable(ParentNode, Lexeme.Name);
    end;

    local procedure PeekNextLexeme(LexemeType: Enum "FS Lexeme Type"): Boolean
    var
        Lexeme: Record "FS Lexeme";
    begin
        Lexer.GetNextLexeme(Lexeme);
        exit(Lexeme.Type = LexemeType);
    end;

    local procedure PeekNextLexeme(Operator: Enum "FS Operator"): Boolean
    var
        Lexeme: Record "FS Lexeme";
    begin
        Lexer.GetNextLexeme(Lexeme);
        exit(Lexeme.Operator = Operator);
    end;

    local procedure PeekNextLexemeType(LexemeType: Enum "FS Lexeme Type"; Keyword: Enum "FS Keyword")
    var
        Lexeme: Record "FS Lexeme";
    begin
        Lexer.GetNextLexeme(Lexeme);
        // TODO
    end;

    local procedure AssertNextLexeme(LexemeType: Enum "FS Lexeme Type")
    begin
        AssertNextLexeme(LexemeType, "FS Keyword"::" ", "FS Operator"::" ");
    end;

    local procedure AssertNextLexeme(Keyword: Enum "FS Keyword")
    begin
        AssertNextLexeme("FS Lexeme Type"::Keyword, Keyword, "FS Operator"::" ");
    end;

    local procedure AssertNextLexeme(Operator: Enum "FS Operator")
    begin
        AssertNextLexeme("FS Lexeme Type"::Operator, "FS Keyword"::" ", Operator);
    end;

    local procedure AssertNextLexeme
    (
        LexemeType: Enum "FS Lexeme Type";
        Keyword: Enum "FS Keyword";
        Operator: Enum "FS Operator"
    )
    var
        Lexeme: Record "FS Lexeme";
    begin
        Lexer.GetNextLexeme(Lexeme);

        if Lexeme.Type <> LexemeType then
            Error('Unexpected lexeme %1, expected %2.', Lexeme.Type, LexemeType);

        if Keyword <> "FS Keyword"::" " then
            if Lexeme.Keyword <> Keyword then
                Error('Unexpected lexeme %1, expected %2.', Lexeme.Keyword, Keyword);

        if Operator <> "FS Operator"::" " then
            if Lexeme.Operator <> Operator then
                Error('Unexpected lexeme %1, expected %2.', Lexeme.Operator, Operator);
    end;
}
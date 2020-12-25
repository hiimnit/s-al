codeunit 81002 "FS Compiler"
{
    var
        Lexer: Codeunit "FS Lexer";
        NodeTree: Codeunit "FS Node Tree";

    procedure Compile(Code: Text)
    begin
        Analyze(Code);

        CompileScript();
    end;

    procedure ShowNodeTree()
    begin
        NodeTree.ShowNodeTree();
    end;

    local procedure CompileScript()
    begin
        // TODO temporary
        AssertNextLexeme("FS Keyword"::"trigger");
        AssertNextLexeme('OnRun');
        AssertNextLexeme("FS Operator"::"(");
        AssertNextLexeme("FS Operator"::")");

        if PeekNextLexeme("FS Keyword"::"var") then
            CompileVariableDefinitionList();
        CompileCompoundStatement();
    end;

    local procedure Analyze(Code: Text)
    begin
        Clear(Lexer);
        Lexer.Analyze(Code);
    end;

    local procedure CompileVariableDefinitionList()
    begin
        AssertNextLexeme("FS Keyword"::"var");

        while PeekNextLexeme("FS Lexeme Type"::"Symbol") do
            CompileVariableDefinition();
    end;

    local procedure CompileVariableDefinition()
    var
        Lexeme: Record "FS Lexeme";
    begin
        // TODO insert variable definition = new table ?
        Lexer.GetNextLexeme(Lexeme);

        AssertNextLexeme("FS Operator"::":");

        // TODO compile type
        Lexer.GetNextLexeme(Lexeme);

        AssertNextLexeme("FS Operator"::";");
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
            PeekNextLexeme("FS Keyword"::"if"):
                ; // TODO CompileIfStatement = condition + statement/compoundstatement
            PeekNextLexeme("FS Keyword"::"repeat"):
                ; // TODO CompileRepeatStatement
            PeekNextLexeme("FS Keyword"::"while"):
                ; // TODO CompileWhileStatement
            PeekNextLexeme("FS Keyword"::"for"):
                ; // TODO CompileForStatement
            PeekNextLexeme("FS Keyword"::"foreach"):
                ; // TODO CompileForeachStatement
            PeekNextLexeme("FS Lexeme Type"::Symbol):
                CompileAssignmentStatement(CompoundStatement);
            else
                NoOp();
        end;
    end;

    local procedure NoOp()
    begin
    end;

    local procedure CompileAssignmentStatement(CompoundStatement: Integer)
    var
        Lexeme: Record "FS Lexeme";
        Variable: Text[100];
        Assignment: Integer;
    begin
        Lexer.GetNextLexeme(Lexeme);
        Variable := Lexeme.Name;
        // TODO check variable declaration 

        AssertNextLexeme("FS Operator"::":=");

        Assignment := NodeTree.InsertAssignment(CompoundStatement, Variable); // TODO add expression entry no.?
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
                    NodeTree.UpdateParent(Product, Expression);
                    CompileExpression(Expression);
                end;
            PeekNextLexeme("FS Operator"::"-"):
                begin
                    AssertNextLexeme("FS Operator"::"-");
                    // TODO change Factor order/parent
                    Expression := NodeTree.InsertOperation(ParentNode, "FS Operator"::"-");
                    NodeTree.UpdateParent(Product, Expression);
                    CompileExpression(Expression);
                end;
            // TODO add "and" and "or" and "xor" ?
            else
                Expression := Product;
        end;

        // TODO update indentation ?
        NodeTree.UpdateOrderAndIndentation(Expression);
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
                    NodeTree.UpdateParent(Factor, Product);
                    CompileProduct(Product);
                end;
            PeekNextLexeme("FS Operator"::"/"):
                begin
                    AssertNextLexeme("FS Operator"::"/");
                    // TODO change Factor order/parent
                    Product := NodeTree.InsertOperation(ParentNode, "FS Operator"::"/");
                    NodeTree.UpdateParent(Factor, Product);
                    CompileProduct(Product);
                end;
            else
                Product := Factor;
        end;
    end;

    local procedure CompileFactor(ParentNode: Integer) Factor: Integer
    begin
        case true of
            PeekNextLexeme("FS Operator"::"+"),
            PeekNextLexeme("FS Operator"::"-"):
                Factor := CompileUnaryOperator(ParentNode);
            PeekNextLexeme("FS Operator"::"("):
                begin
                    AssertNextLexeme("FS Operator"::"(");
                    Factor := CompileExpression(ParentNode);
                    AssertNextLexeme("FS Operator"::")");
                end;
            PeekNextLexeme("FS Lexeme Type"::Integer),
            PeekNextLexeme("FS Lexeme Type"::Decimal):
                Factor := CompileValue(ParentNode);
            PeekNextLexeme("FS Lexeme Type"::Symbol):
                Factor := CompileSymbol(ParentNode);
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

    local procedure CompileSymbol(ParentNode: Integer) Symbol: Integer
    var
        Lexeme: Record "FS Lexeme";
    begin
        Lexer.GetNextLexeme(Lexeme);
        // TODO checks ?
        // TODO records/codeunits / functions ?

        case true of
            PeekNextLexeme("FS Operator"::"."):
                ; // Record/codeunit ?
            PeekNextLexeme("FS Operator"::"("):
                ; // function call ? // TODO can also be written without parenthesis?
            else
                Symbol := NodeTree.InsertVariable(ParentNode, Lexeme.Name);
        end;
    end;

    local procedure PeekNextLexeme(LexemeType: Enum "FS Lexeme Type"): Boolean
    var
        Lexeme: Record "FS Lexeme";
    begin
        Lexer.PeekNextLexeme(Lexeme);
        exit(Lexeme.Type = LexemeType);
    end;

    local procedure PeekNextLexeme(Operator: Enum "FS Operator"): Boolean
    var
        Lexeme: Record "FS Lexeme";
    begin
        Lexer.PeekNextLexeme(Lexeme);
        exit(Lexeme.Operator = Operator);
    end;

    local procedure PeekNextLexeme(Keyword: Enum "FS Keyword"): Boolean
    var
        Lexeme: Record "FS Lexeme";
    begin
        Lexer.PeekNextLexeme(Lexeme);
        exit(Lexeme.Keyword = Keyword);
    end;

    local procedure AssertNextLexeme(LexemeType: Enum "FS Lexeme Type")
    begin
        AssertNextLexeme(LexemeType, "FS Keyword"::" ", "FS Operator"::" ", '');
    end;

    local procedure AssertNextLexeme(Keyword: Enum "FS Keyword")
    begin
        AssertNextLexeme("FS Lexeme Type"::Keyword, Keyword, "FS Operator"::" ", '');
    end;

    local procedure AssertNextLexeme(Operator: Enum "FS Operator")
    begin
        AssertNextLexeme("FS Lexeme Type"::Operator, "FS Keyword"::" ", Operator, '');
    end;

    local procedure AssertNextLexeme(SymbolName: Text)
    begin
        AssertNextLexeme("FS Lexeme Type"::Symbol, "FS Keyword"::" ", "FS Operator"::" ", SymbolName);
    end;

    local procedure AssertNextLexeme
    (
        LexemeType: Enum "FS Lexeme Type";
        Keyword: Enum "FS Keyword";
        Operator: Enum "FS Operator";
        Name: Text
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

        if Name <> '' then
            if Lexeme.Name <> Name then
                Error('Unexpected lexeme %1, expected %2.', Lexeme.Name, Name);
    end;
}
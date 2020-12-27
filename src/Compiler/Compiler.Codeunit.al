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

    procedure GetNodeTree(var VarNodeTree: Codeunit "FS Node Tree")
    begin
        VarNodeTree := NodeTree;
    end;

    local procedure Analyze(Code: Text)
    begin
        Clear(Lexer);
        Lexer.Analyze(Code);
    end;

    local procedure CompileScript()
    var
        OnRunDefined: Boolean;
        MultipleOnRunDefinitionsErr: Label 'Multiple OnRun definitions are not allowed.';
        OnRunNotDefinedErr: Label 'OnRun is not defined.';
        ProgressDialog: Dialog;
    begin
        ProgressDialog.Open('Compiling...');

        // TODO first scan code for all defined functions?
        OnRunDefined := false;

        while not Lexer.EOF() do
            case true of
                PeekNextLexeme("FS Keyword"::"local"),
                PeekNextLexeme("FS Keyword"::"procedure"):
                    CompileFunction();
                PeekNextLexeme("FS Keyword"::"var"):
                    CompileVariableDefinitionList(0, "FS Variable Scope"::Global);
                PeekNextLexeme("FS Keyword"::"trigger"):
                    begin
                        if OnRunDefined then
                            Error(MultipleOnRunDefinitionsErr);

                        OnRunDefined := true;

                        CompileOnRun();
                    end;
                else
                    Error('TODO'); // TODO
            end;

        if not OnRunDefined then
            Error(OnRunNotDefinedErr);

        ProgressDialog.Close();
    end;

    local procedure CompileOnRun()
    var
        Function: Integer;
        OnRunFunctionTok: Label 'OnRun', Locked = true;
    begin
        NodeTree.ResetIndentation(); // XXX not necessary ?

        AssertNextLexeme("FS Keyword"::"trigger");
        AssertNextLexeme(OnRunFunctionTok);
        AssertNextLexeme("FS Operator"::"(");
        AssertNextLexeme("FS Operator"::")");

        Function := NodeTree.InsertOnRun(OnRunFunctionTok);

        if PeekNextLexeme("FS Keyword"::"var") then
            CompileVariableDefinitionList(Function, "FS Variable Scope"::Local);

        NodeTree.Indent();
        CompileCompoundStatement(Function);
        AssertNextLexeme("FS Operator"::";");
        NodeTree.UnIndent();
    end;

    local procedure CompileFunction()
    var
        Lexeme: Record "FS Lexeme";
        Name: Text[250];
        Function: Integer;
    begin
        NodeTree.ResetIndentation(); // XXX not necessary ?

        if PeekNextLexeme("FS Keyword"::"local") then
            AssertNextLexeme("FS Keyword"::"local");

        AssertNextLexeme("FS Keyword"::"procedure");

        Lexer.GetNextLexeme(Lexeme);
        AssertLexeme(Lexeme, "FS Lexeme Type"::Symbol);
        Name := Lexeme.Name;

        Function := NodeTree.InsertFunction(Name);

        CompileParameterDefinitionList(Function);

        if PeekNextLexeme("FS Keyword"::"var") then
            CompileVariableDefinitionList(Function, "FS Variable Scope"::Local);

        NodeTree.Indent();
        CompileCompoundStatement(Function);
        AssertNextLexeme("FS Operator"::";");
        NodeTree.UnIndent();
    end;

    local procedure CompileParameterDefinitionList(FunctionNo: Integer)
    begin
        AssertNextLexeme("FS Operator"::"(");
        while not PeekNextLexeme("FS Operator"::")") do begin
            CompileVariableDefinition(FunctionNo, "FS Variable Scope"::Parameter);
            if not PeekNextLexeme("FS Operator"::")") then
                AssertNextLexeme("FS Operator"::";");
        end;
        AssertNextLexeme("FS Operator"::")");

        if PeekNextLexeme("FS Lexeme Type"::Symbol) or PeekNextLexeme("FS Operator"::":") then begin
            // TODO return type/variable declaration
            ;
            ;
        end;
    end;

    local procedure CompileVariableDefinitionList(FunctionNo: Integer; Scope: Enum "FS Variable Scope")
    begin
        AssertNextLexeme("FS Keyword"::"var");

        while PeekNextLexeme("FS Lexeme Type"::"Symbol") do begin // FIXME does not work with Code: Code[20];
            CompileVariableDefinition(FunctionNo, Scope);
            AssertNextLexeme("FS Operator"::";");
        end;
    end;

    local procedure CompileVariableDefinition(FunctionNo: Integer; Scope: Enum "FS Variable Scope") VariableNo: Integer
    var
        Lexeme: Record "FS Lexeme";
        Name: Text[250];
        Type: Enum "FS Variable Type";
        Length: Integer;
        i: Integer;
    begin
        Lexer.GetNextLexeme(Lexeme);
        AssertLexeme(Lexeme, "FS Lexeme Type"::Symbol);

        Name := Lexeme.Name;

        AssertNextLexeme("FS Operator"::":");

        Lexer.GetNextLexeme(Lexeme);
        AssertLexeme(Lexeme, "FS Lexeme Type"::Keyword);

        i := "FS Variable Type".Names().IndexOf(Lexeme.Name.ToLower());
        if i = 0 then
            Error('Unexpected value %1, expected variable type %2', Lexeme.Name, "FS Variable Type".Names());

        Type := "FS Variable Type".FromInteger("FS Variable Type".Ordinals().Get(i));

        case true of
            (Type = "FS Variable Type"::text) and PeekNextLexeme("FS Operator"::"["),
            Type = "FS Variable Type"::code:
                begin
                    AssertNextLexeme("FS Operator"::"[");
                    Lexer.GetNextLexeme(Lexeme);
                    AssertLexeme(Lexeme, "FS Lexeme Type"::Integer);

                    Length := Lexeme."Number Value";

                    AssertNextLexeme("FS Operator"::"]");
                end;
        end;

        VariableNo := NodeTree.InsertVariableDefinition(
            Scope,
            Name,
            Type,
            FunctionNo,
            Length);
    end;

    local procedure CompileCompoundStatement(ParentNode: Integer) CompoundStatement: Integer
    begin
        AssertNextLexeme("FS Keyword"::"begin");
        CompoundStatement := NodeTree.InsertCompoundStatement(ParentNode);
        CompileStatement(CompoundStatement);

        while PeekNextLexeme("FS Operator"::";") do begin
            AssertNextLexeme("FS Operator"::";");
            CompileStatement(CompoundStatement);
        end;

        AssertNextLexeme("FS Keyword"::"end");
    end;

    local procedure CompileStatement(CompoundStatement: Integer) Statement: Integer
    begin
        case true of
            PeekNextLexeme("FS Keyword"::"begin"):
                begin
                    NodeTree.Indent();
                    Statement := CompileCompoundStatement(CompoundStatement);
                    AssertNextLexeme("FS Operator"::";");
                    NodeTree.UnIndent();
                end;
            PeekNextLexeme("FS Keyword"::"if"):
                Statement := CompileIfStatement(CompoundStatement);
            PeekNextLexeme("FS Keyword"::"repeat"):
                ; // TODO CompileRepeatStatement
            PeekNextLexeme("FS Keyword"::"while"):
                ; // TODO CompileWhileStatement
            PeekNextLexeme("FS Keyword"::"for"):
                ; // TODO CompileForStatement
            PeekNextLexeme("FS Keyword"::"foreach"):
                ; // TODO CompileForeachStatement
            PeekNextLexeme("FS Lexeme Type"::Symbol):
                Statement := CompileAssignmentStatement(CompoundStatement);
            else
                NoOp();
        end;
    end;

    local procedure NoOp()
    begin
    end;

    local procedure CompileIfStatement(CompoundStatement: Integer) IfStatement: Integer
    var
        ConditionNode, TrueStatementNode, FalseStatementNode : Integer;
    begin
        AssertNextLexeme("FS Keyword"::"if");

        IfStatement := NodeTree.InsertIfStatement(CompoundStatement);
        ConditionNode := CompileBooleanExpression(IfStatement);

        AssertNextLexeme("FS Keyword"::"then");

        NodeTree.Indent();
        TrueStatementNode := CompileStatement(IfStatement);
        NodeTree.UnIndent();

        if PeekNextLexeme("FS Keyword"::"else") then begin
            AssertNextLexeme("FS Keyword"::"else");

            NodeTree.Indent();
            FalseStatementNode := CompileStatement(IfStatement);
            NodeTree.UnIndent();
        end;

        NodeTree.UpdateIfStatement(
            IfStatement,
            ConditionNode,
            TrueStatementNode,
            FalseStatementNode);
    end;

    local procedure CompileForStatement(CompoundStatement: Integer)
    begin
        AssertNextLexeme("FS Keyword"::"for");
        // TODO compile assignment
        // TODO keyword "to / downto"
        // TODO compile expression
        AssertNextLexeme("FS Keyword"::"do");

        CompileStatement(CompoundStatement);
    end;

    local procedure CompileAssignmentStatement(CompoundStatement: Integer) Assignment: Integer;
    var
        Lexeme: Record "FS Lexeme";
        Variable: Text[250];
        VariableType: Enum "FS Variable Type";
    begin
        Lexer.GetNextLexeme(Lexeme);
        Variable := Lexeme.Name;

        VariableType := NodeTree.ValidateVariable(Variable, 0); // FIXME 0 = main

        AssertNextLexeme("FS Operator"::":=");

        Assignment := NodeTree.InsertAssignment(CompoundStatement, Variable); // TODO add expression entry no.?

        case VariableType of
            "FS Variable Type"::boolean:
                CompileBooleanExpression(Assignment);
            "FS Variable Type"::text,
            "FS Variable Type"::code:
                CompileStringExpression(Assignment);
            else
                CompileExpression(Assignment);
        end;
    end;

    local procedure CompileExpression(ParentNode: Integer) Expression: Integer
    var
        Product: Integer;
    begin
        Product := CompileProduct(ParentNode);

        case true of
            PeekNextLexeme("FS Operator"::"+"):
                begin
                    AssertNextLexeme("FS Operator"::"+");
                    Expression := NodeTree.InsertOperation(ParentNode, "FS Operator"::"+");
                    CompileExpression(Expression);
                end;
            PeekNextLexeme("FS Operator"::"-"):
                begin
                    AssertNextLexeme("FS Operator"::"-");
                    Expression := NodeTree.InsertOperation(ParentNode, "FS Operator"::"-");
                    CompileExpression(Expression);
                end;
            else
                Expression := Product;
        end;

        // TODO update indentation ?
        NodeTree.UpdateParent(Product, Expression);
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
                Factor := CompileSymbol(ParentNode, "FS Variable Type"::"decimal");
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

    local procedure CompileSymbol(ParentNode: Integer; ExpectedType: Enum "FS Variable Type") Symbol: Integer
    var
        Lexeme: Record "FS Lexeme";
    begin
        Lexer.GetNextLexeme(Lexeme);
        // TODO type check ! - ExpectedType
        // TODO type check ! - ExpectedType
        // TODO type check ! - ExpectedType
        // TODO records / functions ?

        // TODO check if function !

        case true of
            PeekNextLexeme("FS Operator"::"."):
                ; // Record/codeunit ?
            PeekNextLexeme("FS Operator"::"("):
                ; // function call ? // TODO can also be written without parenthesis?
            else
                Symbol := NodeTree.InsertVariable(ParentNode, Lexeme.Name);
        end;
    end;

    local procedure CompileBooleanExpression(ParentNode: Integer) Expression: Integer
    var
        Comparison: Integer;
    begin
        Comparison := CompileBooleanComparison(ParentNode);

        case true of
            // TODO repeated code
            PeekNextLexeme("FS Operator"::"and"):
                begin
                    AssertNextLexeme("FS Operator"::"and");
                    Expression := NodeTree.InsertOperation(ParentNode, "FS Operator"::"and");
                    CompileBooleanExpression(Expression);
                end;
            PeekNextLexeme("FS Operator"::"or"):
                begin
                    AssertNextLexeme("FS Operator"::"or");
                    Expression := NodeTree.InsertOperation(ParentNode, "FS Operator"::"or");
                    CompileBooleanExpression(Expression);
                end;
            PeekNextLexeme("FS Operator"::"xor"):
                begin
                    AssertNextLexeme("FS Operator"::"xor");
                    Expression := NodeTree.InsertOperation(ParentNode, "FS Operator"::"xor");
                    CompileBooleanExpression(Expression);
                end;
            else
                Expression := Comparison;
        end;

        NodeTree.UpdateParent(Comparison, Expression);
        NodeTree.UpdateOrderAndIndentation(Expression);
    end;

    local procedure CompileBooleanComparison(ParentNode: Integer) Comparison: Integer
    var
        Factor: Integer;
    begin
        Factor := CompileBooleanFactor(ParentNode);

        case true of
            PeekNextLexeme("FS Operator"::"="):
                begin
                    AssertNextLexeme("FS Operator"::"and");
                    Comparison := NodeTree.InsertOperation(ParentNode, "FS Operator"::"and");
                    CompileBooleanFactor(Comparison);
                end;
            PeekNextLexeme("FS Operator"::">"):
                begin
                    AssertNextLexeme("FS Operator"::">");
                    Comparison := NodeTree.InsertOperation(ParentNode, "FS Operator"::">");
                    CompileBooleanFactor(Comparison);
                end;
            PeekNextLexeme("FS Operator"::"<"):
                begin
                    AssertNextLexeme("FS Operator"::"<");
                    Comparison := NodeTree.InsertOperation(ParentNode, "FS Operator"::"<");
                    CompileBooleanFactor(Comparison);
                end;
            PeekNextLexeme("FS Operator"::"<>"):
                begin
                    AssertNextLexeme("FS Operator"::"<>");
                    Comparison := NodeTree.InsertOperation(ParentNode, "FS Operator"::"<>");
                    CompileBooleanFactor(Comparison);
                end;
            PeekNextLexeme("FS Operator"::">="):
                begin
                    AssertNextLexeme("FS Operator"::">=");
                    Comparison := NodeTree.InsertOperation(ParentNode, "FS Operator"::">=");
                    CompileBooleanFactor(Comparison);
                end;
            PeekNextLexeme("FS Operator"::"<="):
                begin
                    AssertNextLexeme("FS Operator"::"<=");
                    Comparison := NodeTree.InsertOperation(ParentNode, "FS Operator"::"<=");
                    CompileBooleanFactor(Comparison);
                end;
            else
                Factor := Comparison;
        end;

        NodeTree.UpdateParent(Factor, Comparison);
        NodeTree.UpdateOrderAndIndentation(Comparison);
    end;

    local procedure CompileBooleanFactor(ParentNode: Integer) Factor: Integer
    begin
        case true of
            PeekNextLexeme("FS Operator"::"not"):
                Factor := CompileBooleanUnaryOperator(ParentNode);
            PeekNextLexeme("FS Operator"::"("):
                begin
                    AssertNextLexeme("FS Operator"::"(");
                    Factor := CompileBooleanExpression(ParentNode);
                    AssertNextLexeme("FS Operator"::")");
                end;
            PeekNextLexeme("FS Lexeme Type"::Boolean):
                Factor := CompileBooleanValue(ParentNode);
            PeekNextLexeme("FS Lexeme Type"::Symbol):
                Factor := CompileSymbol(ParentNode, "FS Variable Type"::"boolean");
            else
                Error('TODO'); // TODO error message
        end;
    end;

    local procedure CompileBooleanUnaryOperator(ParentNode: Integer) UnaryOperator: Integer
    begin
        AssertNextLexeme("FS Operator"::"not");

        UnaryOperator := NodeTree.InsertUnaryOperator(ParentNode, "FS Operator"::"not");
        CompileBooleanExpression(UnaryOperator);
    end;

    local procedure CompileBooleanValue(ParentNode: Integer) Value: Integer
    var
        Lexeme: Record "FS Lexeme";
    begin
        Lexer.GetNextLexeme(Lexeme);
        AssertLexeme(Lexeme, "FS Lexeme Type"::Boolean);

        Value := NodeTree.InsertBooleanValue(ParentNode, Lexeme."Boolean Value");
    end;

    local procedure CompileStringExpression(ParentNode: Integer) Expression: Integer
    var
        Factor: Integer;
    begin
        Factor := CompileStringFactor(ParentNode);

        case true of
            PeekNextLexeme("FS Operator"::"+"):
                begin
                    AssertNextLexeme("FS Operator"::"+");
                    Expression := NodeTree.InsertOperation(ParentNode, "FS Operator"::"+"); // XXX add type ?
                    CompileStringExpression(Expression);
                end;
            else
                Expression := Factor;
        end;

        NodeTree.UpdateParent(Factor, Expression);
        NodeTree.UpdateOrderAndIndentation(Expression);
    end;

    local procedure CompileStringFactor(ParentNode: Integer) Factor: Integer
    begin
        case true of
            PeekNextLexeme("FS Operator"::"("):
                begin
                    AssertNextLexeme("FS Operator"::"(");
                    Factor := CompileStringExpression(ParentNode);
                    AssertNextLexeme("FS Operator"::")");
                end;
            PeekNextLexeme("FS Lexeme Type"::StringLiteral):
                Factor := CompileStringValue(ParentNode);
            PeekNextLexeme("FS Lexeme Type"::Symbol):
                Factor := CompileSymbol(ParentNode, "FS Variable Type"::"text");
            else
                Error('TODO'); // TODO error message
        end;
    end;

    local procedure CompileStringValue(ParentNode: Integer) Value: Integer
    var
        Lexeme: Record "FS Lexeme";
    begin
        Lexer.GetNextLexeme(Lexeme);
        AssertLexeme(Lexeme, "FS Lexeme Type"::StringLiteral);

        Value := NodeTree.InsertTextValue(ParentNode, Lexeme.GetTextValue());
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
        AssertLexeme(Lexeme, LexemeType, Keyword, Operator, Name);
    end;

    local procedure AssertLexeme
    (
        Lexeme: Record "FS Lexeme";
        LexemeType: Enum "FS Lexeme Type"
    )
    begin
        AssertLexeme(Lexeme, LexemeType, "FS Keyword"::" ", "FS Operator"::" ", '');
    end;

    local procedure AssertLexeme
    (
        Lexeme: Record "FS Lexeme";
        LexemeType: Enum "FS Lexeme Type";
                        Keyword: Enum "FS Keyword";
                        Operator: Enum "FS Operator";
                        Name: Text
    )
    var
        UnexpectedLexemeErr: Label 'Unexpected lexeme %1, expected %2.', Comment = '%1 = got, %2 = expected';
    begin
        if Lexeme.Type <> LexemeType then
            Error(UnexpectedLexemeErr, Lexeme.Type, LexemeType);

        if Keyword <> "FS Keyword"::" " then
            if Lexeme.Keyword <> Keyword then
                Error(UnexpectedLexemeErr, Lexeme.Keyword, Keyword);

        if Operator <> "FS Operator"::" " then
            if Lexeme.Operator <> Operator then
                Error(UnexpectedLexemeErr, Lexeme.Operator, Operator);

        if Name <> '' then
            if Lexeme.Name.ToLower() <> Name.ToLower() then
                Error(UnexpectedLexemeErr, Lexeme.Name, Name);
    end;
}
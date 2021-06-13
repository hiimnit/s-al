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
        FunctionNo, FunctionNode : Integer;
        OnRunFunctionTok: Label 'OnRun', Locked = true;
    begin
        NodeTree.ResetIndentation(); // XXX not necessary ?

        AssertNextLexeme("FS Keyword"::"trigger");
        AssertNextLexeme(OnRunFunctionTok);
        AssertNextLexeme("FS Operator"::"(");
        AssertNextLexeme("FS Operator"::")");

        FunctionNode := NodeTree.InsertOnRun(OnRunFunctionTok, FunctionNo);

        if PeekNextLexeme("FS Keyword"::"var") then
            CompileVariableDefinitionList(FunctionNo, "FS Variable Scope"::Local);

        NodeTree.Indent();
        CompileCompoundStatement(FunctionNode);
        AssertNextLexeme("FS Operator"::";");
        NodeTree.UnIndent();
    end;

    local procedure CompileFunction()
    var
        Lexeme: Record "FS Lexeme";
        Name: Text[250];
        FunctionNo, FunctionNode : Integer;
    begin
        NodeTree.ResetIndentation(); // XXX not necessary ?

        if PeekNextLexeme("FS Keyword"::"local") then
            AssertNextLexeme("FS Keyword"::"local");

        AssertNextLexeme("FS Keyword"::"procedure");

        Lexer.GetNextLexeme(Lexeme);
        AssertLexeme(Lexeme, "FS Lexeme Type"::Symbol);
        Name := Lexeme.Name;

        FunctionNode := NodeTree.InsertFunction(Name, FunctionNo);

        CompileParameterDefinitionList(FunctionNo);

        if PeekNextLexeme("FS Keyword"::"var") then
            CompileVariableDefinitionList(FunctionNo, "FS Variable Scope"::Local);

        NodeTree.Indent();
        CompileCompoundStatement(FunctionNode);
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
        i, TableId : Integer;
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
            Type = "FS Variable Type"::record:
                begin
                    Lexer.GetNextLexeme(Lexeme);
                    AssertLexeme(Lexeme, Enum::"FS Lexeme Type"::Symbol);

                    TableId := ValidateTable(Lexeme.Name);
                end;
        end;

        VariableNo := NodeTree.InsertVariableDefinition(
            Scope,
            Name,
            Type,
            FunctionNo,
            Length,
            TableId);
    end;

    local procedure ValidateTable(TableName: Text) TableId: Integer
    var
        AllObj: Record AllObj;
    begin
        AllObj.SetRange("Object Type", AllObj."Object Type"::Table);
        AllObj.SetRange("Object Name", TableName);
        AllObj.FindFirst();
        TableId := AllObj."Object ID";
    end;

    local procedure CompileCompoundStatement(ParentNode: Integer) CompoundStatement: Integer
    begin
        AssertNextLexeme("FS Keyword"::"begin");
        CompoundStatement := NodeTree.InsertCompoundStatement(ParentNode);

        NodeTree.Indent();

        CompileStatement(CompoundStatement);
        while PeekNextLexeme("FS Operator"::";") do begin
            AssertNextLexeme("FS Operator"::";");
            CompileStatement(CompoundStatement);
        end;

        NodeTree.UnIndent();

        AssertNextLexeme("FS Keyword"::"end");
    end;

    local procedure CompileStatement(CompoundStatement: Integer) Statement: Integer
    begin
        case true of
            PeekNextLexeme("FS Keyword"::"begin"):
                begin
                    NodeTree.Indent();
                    Statement := CompileCompoundStatement(CompoundStatement);
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
                Statement := CompileSymbolStatement(CompoundStatement);
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

    local procedure CompileSymbolStatement(CompoundStatement: Integer) Statement: Integer
    var
        Lexeme: Record "FS Lexeme";
    begin
        Lexer.GetNextLexeme(Lexeme);
        Statement := CompileSymbol(CompoundStatement, Enum::"FS Variable Type"::void, Lexeme);

        if PeekNextLexeme(Enum::"FS Operator"::":=") then
            Statement := CompileAssignmentStatement(CompoundStatement, Statement);
    end;

    local procedure CompileAssignmentStatement(CompoundStatement: Integer; Variable: Integer) Assignment: Integer;
    var
        VariableType: Enum "FS Variable Type";
    begin
        VariableType := NodeTree.ValidateVariable(Variable);

        AssertNextLexeme("FS Operator"::":=");

        Assignment := NodeTree.InsertAssignment(CompoundStatement, Variable); // TODO add expression entry no.?

        CompileExpression(Assignment, VariableType);
    end;

    local procedure CompileExpression(ParentNode: Integer; VariableType: Enum "FS Variable Type") Expression: Integer
    begin
        case VariableType of
            "FS Variable Type"::boolean:
                Expression := CompileBooleanExpression(ParentNode);
            "FS Variable Type"::text,
            "FS Variable Type"::code:
                Expression := CompileStringExpression(ParentNode);
            "FS Variable Type"::integer,
            "FS Variable Type"::decimal:
                Expression := CompileNumericExpression(ParentNode);
            else
                // FIXME this needs a rework
                // try to guess the type?
                if PeekNextLexeme(Enum::"FS Lexeme Type"::StringLiteral) then
                    Expression := CompileStringExpression(ParentNode)
                else
                    Expression := CompileNumericExpression(ParentNode);
        end;
    end;

    local procedure CompileNumericExpression(ParentNode: Integer) Expression: Integer
    var
        Product: Integer;
    begin
        Product := CompileProduct(ParentNode);

        while true do
            case true of
                PeekNextLexeme("FS Operator"::"+"):
                    begin
                        AssertNextLexeme("FS Operator"::"+");

                        Expression := NodeTree.InsertOperation(ParentNode, "FS Operator"::"+");
                        NodeTree.UpdateParent(Product, Expression);
                        CompileProduct(Expression);

                        Product := Expression;
                    end;
                PeekNextLexeme("FS Operator"::"-"):
                    begin
                        AssertNextLexeme("FS Operator"::"-");

                        Expression := NodeTree.InsertOperation(ParentNode, "FS Operator"::"-");
                        NodeTree.UpdateParent(Product, Expression);
                        CompileProduct(Expression);

                        Product := Expression;
                    end;
                else
                    Expression := Product;
                    NodeTree.UpdateOrderAndIndentation(Expression); // XXX
                    exit; // break does not work in a case statement?
            end;
    end;

    local procedure CompileProduct(ParentNode: Integer) Product: Integer
    var
        Factor: Integer;
    begin
        Factor := CompileFactor(ParentNode);
        // TODO while ?

        while true do
            case true of
                PeekNextLexeme("FS Operator"::"*"):
                    begin
                        AssertNextLexeme("FS Operator"::"*");

                        Product := NodeTree.InsertOperation(ParentNode, "FS Operator"::"*");
                        NodeTree.UpdateParent(Factor, Product);
                        CompileFactor(Product);

                        Factor := Product;
                    end;
                PeekNextLexeme("FS Operator"::"/"):
                    begin
                        AssertNextLexeme("FS Operator"::"/");

                        Product := NodeTree.InsertOperation(ParentNode, "FS Operator"::"/");
                        NodeTree.UpdateParent(Factor, Product);
                        CompileFactor(Product);

                        Factor := Product;
                    end;
                else
                    Product := Factor;
                    exit; // break does not work in a case statement?
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
                    Factor := CompileNumericExpression(ParentNode);
                    AssertNextLexeme("FS Operator"::")");
                end;
            PeekNextLexeme("FS Lexeme Type"::Integer),
            PeekNextLexeme("FS Lexeme Type"::Decimal):
                Factor := CompileValue(ParentNode);
            PeekNextLexeme("FS Lexeme Type"::Symbol):
                Factor := CompileSymbol(ParentNode, "FS Variable Type"::"decimal");
            // FIXME add non-numerical operations !
            // TODO function call ?
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
        Symbol := CompileSymbol(ParentNode, ExpectedType, Lexeme);
    end;

    local procedure CompileSymbol(ParentNode: Integer; ExpectedType: Enum "FS Variable Type"; Lexeme: Record "FS Lexeme") Symbol: Integer
    begin
        // TODO type check ! - ExpectedType
        // TODO type check ! - ExpectedType
        // FIXME type check ! - ExpectedType
        // TODO records / functions ?

        case true of
            PeekNextLexeme("FS Operator"::"."):
                begin
                    // property/method
                    Symbol := NodeTree.InsertVariable(ParentNode, Lexeme.Name, true);
                    AssertNextLexeme("FS Operator"::".");
                    NodeTree.Indent();
                    CompileSymbol(Symbol, ExpectedType);
                    NodeTree.UnIndent();
                end;
            PeekNextLexeme("FS Operator"::"("):
                Symbol := CompileFunctionCall(ParentNode, Lexeme); // TODO pass in ExpectedType ?
            else
                Symbol := NodeTree.InsertVariable(ParentNode, Lexeme.Name, false);
        end;
    end;

    local procedure CompileFunctionCall(ParentNode: Integer; Lexeme: Record "FS Lexeme") FunctionCall: Integer
    begin
        // FIXME validate function name 
        FunctionCall := NodeTree.InsertFunctionCall(ParentNode, Lexeme.Name);

        AssertNextLexeme(Enum::"FS Operator"::"(");
        while not PeekNextLexeme(Enum::"FS Operator"::")") do begin
            CompileExpression(FunctionCall, Enum::"FS Variable Type"::void); // FIXME type!
            if PeekNextLexeme(Enum::"FS Operator"::"comma") then
                AssertNextLexeme(Enum::"FS Operator"::"comma");
        end;
        AssertNextLexeme(Enum::"FS Operator"::")");
    end;

    local procedure CompileBooleanExpression(ParentNode: Integer) Expression: Integer
    var
        Comparison: Integer;
    begin
        Comparison := CompileBooleanComparison(ParentNode);

        while true do
            case true of
                // TODO repeated code
                PeekNextLexeme("FS Operator"::"and"):
                    begin
                        AssertNextLexeme("FS Operator"::"and");

                        Expression := NodeTree.InsertOperation(ParentNode, Enum::"FS Operator"::"and");
                        NodeTree.UpdateParent(Comparison, Expression);
                        CompileBooleanComparison(Expression);

                        Comparison := Expression;
                    end;
                PeekNextLexeme("FS Operator"::"or"):
                    begin
                        AssertNextLexeme("FS Operator"::"or");

                        Expression := NodeTree.InsertOperation(ParentNode, Enum::"FS Operator"::"or");
                        NodeTree.UpdateParent(Comparison, Expression);
                        CompileBooleanComparison(Expression);

                        Comparison := Expression;
                    end;
                PeekNextLexeme("FS Operator"::"xor"):
                    begin
                        AssertNextLexeme("FS Operator"::"xor");

                        Expression := NodeTree.InsertOperation(ParentNode, Enum::"FS Operator"::"xor");
                        NodeTree.UpdateParent(Comparison, Expression);
                        CompileBooleanComparison(Expression);

                        Comparison := Expression;
                    end;
                else
                    Expression := Comparison;
                    NodeTree.UpdateOrderAndIndentation(Expression);
                    exit;
            end;

    end;

    local procedure CompileBooleanComparison(ParentNode: Integer) Comparison: Integer
    var
        Factor: Integer;
    begin
        Factor := CompileBooleanFactor(ParentNode);

        case true of
            PeekNextLexeme("FS Operator"::"="):
                begin
                    AssertNextLexeme("FS Operator"::"=");
                    Comparison := NodeTree.InsertOperation(ParentNode, "FS Operator"::"=");
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
                Comparison := Factor;
        end;

        NodeTree.UpdateParent(Factor, Comparison);
        NodeTree.UpdateOrderAndIndentation(Comparison); // TODO ?
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
            // TODO non boolean constant values
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

        while true do
            case true of
                PeekNextLexeme("FS Operator"::"+"):
                    begin
                        AssertNextLexeme("FS Operator"::"+");

                        Expression := NodeTree.InsertOperation(ParentNode, "FS Operator"::"+");
                        NodeTree.UpdateParent(Factor, Expression);
                        CompileStringFactor(Expression);

                        Factor := Expression;
                    end;
                // XXX add "*" operator for text? 
                else
                    Expression := Factor;
                    NodeTree.UpdateOrderAndIndentation(Expression);
                    exit;
            end;
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
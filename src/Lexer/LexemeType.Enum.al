enum 81000 "FS Lexeme Type"
{
    Caption = 'Lexeme Type';

    // table names ?

    value(0; " ")
    {
        Caption = ' ';
    }
    value(10; Keyword)
    {
        Caption = 'Keyword';
    }
    value(20; Symbol)
    {
        Caption = 'Symbol';
    }
    value(30; StringLiteral)
    {
        Caption = 'String literal';
    }
    value(40; Integer)
    {
        Caption = 'Integer';
    }
    value(41; Decimal)
    {
        Caption = 'Decimal';
    }
    value(42; Boolean)
    {
        Caption = 'Boolean';
    }
    value(50; Operator)
    {
        Caption = 'Operator';
    }
    // value(60; Method)
    // {
    //     Caption = 'Method';
    // }
    // value(61; "Procedure")
    // {
    //     Caption = 'Procedure';
    // }
}
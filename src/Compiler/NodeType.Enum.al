enum 81003 "FS Node Type"
{
    // XXX 6.0 Caption = 'Node Type';

    value(0; Pass)
    {
        Caption = 'Pass';
    }

    value(100; CompoundStatement)
    {
        Caption = 'Compound Statement';
    }

    value(200; Assignment)
    {
        Caption = 'Assignment';
    }

    value(300; Expression)
    {
        // FIXME replace by expressions
    }
    value(301; NumericValue)
    {
        Caption = 'Numeric Value';
    }
    value(302; Variable)
    {
        Caption = 'Variable';
    }
    value(303; UnaryOperator)
    {
        Caption = 'Unary Operator';
    }
    value(304; Operation)
    {
        Caption = 'Operation';
    }
}
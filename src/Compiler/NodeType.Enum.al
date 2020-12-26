enum 81003 "FS Node Type"
{
    // XXX 6.0 Caption = 'Node Type';

    value(0; Pass)
    {
        Caption = 'Pass';
    }

    value(10; Function)
    {
        Caption = 'Function';
    }

    value(100; IfStatement)
    {
        Caption = 'If Statement';
    }
    value(109; CompoundStatement)
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
    value(302; BooleanValue)
    {
        Caption = 'Boolean Value';
    }
    value(303; TextValue)
    {
        Caption = 'Text Value';
    }
    value(304; Variable)
    {
        Caption = 'Variable';
    }
    value(305; UnaryOperator)
    {
        Caption = 'Unary Operator';
    }
    value(306; Operation)
    {
        Caption = 'Operation';
    }
}
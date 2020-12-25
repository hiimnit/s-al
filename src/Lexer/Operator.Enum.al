enum 81002 "FS Operator"
{
    // XXX 6.0 Caption = 'Operator';

    // two char operator ids are 1000+
    // boolean operator ids are 10000+

    value(0; " ") { }

    value(1; "+") { }
    value(2; "-") { }
    value(3; "*") { }
    value(4; "/") { }

    value(1000; "+=") { }
    value(1001; "-=") { }
    value(1002; "*=") { }
    value(1003; "/=") { }
    value(1004; ":=") { }

    value(10; "(") { }
    value(11; ")") { }
    value(12; ";") { }
    value(13; ":") { }
    value(1005; "::") { }
    value(14; "<") { }
    value(15; ">") { }
    value(1006; "<>") { }
    value(1007; "<=") { }
    value(1008; ">=") { }
    value(17; "=") { }
    value(18; ".") { }
    value(19; ",") { }
    value(20; "[") { }
    value(21; "]") { }

    value(10000; "and") { }
    value(10001; "or") { }
    value(10002; "xor") { }
    value(10003; "not") { }
}

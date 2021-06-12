codeunit 81007 "FS Variable"
{
    // TODO
    var
        Name: Text[250];
        Type: Enum "FS Variable Type";
        Length: Integer;

    var
        Text: Text;
        Decimal: Decimal;
        Integer: Integer;
        Boolean: Boolean;

    procedure Setup(NewName: Text[250]; NewType: Enum "FS Variable Type"; NewLength: Integer)
    begin
        Name := NewName;
        Type := NewType;
        Length := NewLength;
    end;

    procedure GetType(): Enum "FS Variable Type";
    begin
        exit(Type);
    end;

    procedure Copy(var Variable: Codeunit "FS Variable")
    begin
        Clear(Variable);
        Variable.Setup(Name, Type, Length);

        case Type of
            "FS Variable Type"::text:
                Variable.SetValue(Text);
            "FS Variable Type"::code:
                Variable.SetValue(Text);
            "FS Variable Type"::decimal:
                Variable.SetValue(Decimal);
            "FS Variable Type"::integer:
                Variable.SetValue(Integer);
            "FS Variable Type"::boolean:
                Variable.SetValue(Boolean);
        end;
    end;

    procedure GetValue(var Value: Variant)
    begin
        // TODO type check
        // TODO length check

        case Type of
            "FS Variable Type"::text:
                Value := Text;
            "FS Variable Type"::code:
                Value := Text;
            "FS Variable Type"::decimal:
                Value := Decimal;
            "FS Variable Type"::integer:
                Value := Integer;
            "FS Variable Type"::boolean:
                Value := Boolean;
        end;
    end;

    procedure SetValue(Value: Variant)
    begin
        // TODO type check
        // TODO length check
        // TODO if code then uppercase ?

        case Type of
            "FS Variable Type"::text:
                Text := Value;
            "FS Variable Type"::code:
                Text := Value;
            "FS Variable Type"::decimal:
                Decimal := Value;
            "FS Variable Type"::integer:
                Integer := Value;
            "FS Variable Type"::boolean:
                Boolean := Value;
        end;
    end;

    procedure Add
    (
        var Left: Codeunit "FS Variable";
        var Right: Codeunit "FS Variable"
    )
    var
        LeftValue, RightValue : Variant;
        LeftValueDecimal, RightValueDecimal : Decimal;
    begin
        // TODO 

        Left.GetValue(LeftValue);
        Right.GetValue(RightValue);

        Setup('', Left.GetType(), 0);

        LeftValueDecimal := LeftValue;
        RightValueDecimal := RightValue;

        SetValue(LeftValueDecimal + RightValueDecimal);
    end;

    procedure Subtract
    (
        var Left: Codeunit "FS Variable";
        var Right: Codeunit "FS Variable"
    )
    var
        LeftValue, RightValue : Variant;
        LeftValueDecimal, RightValueDecimal : Decimal;
    begin
        // TODO 

        Left.GetValue(LeftValue);
        Right.GetValue(RightValue);

        Setup('', Left.GetType(), 0);

        LeftValueDecimal := LeftValue;
        RightValueDecimal := RightValue;

        SetValue(LeftValueDecimal - RightValueDecimal);
    end;

    procedure Multiply
    (
        var Left: Codeunit "FS Variable";
        var Right: Codeunit "FS Variable"
    )
    var
        LeftValue, RightValue : Variant;
        LeftValueDecimal, RightValueDecimal : Decimal;
    begin
        // TODO 

        Left.GetValue(LeftValue);
        Right.GetValue(RightValue);

        Setup('', Left.GetType(), 0);

        LeftValueDecimal := LeftValue;
        RightValueDecimal := RightValue;

        SetValue(LeftValueDecimal * RightValueDecimal);
    end;

    procedure Divide
    (
        var Left: Codeunit "FS Variable";
        var Right: Codeunit "FS Variable"
    )
    var
        LeftValue, RightValue : Variant;
        LeftValueDecimal, RightValueDecimal : Decimal;
    begin
        // TODO 

        Left.GetValue(LeftValue);
        Right.GetValue(RightValue);

        Setup('', Left.GetType(), 0);

        LeftValueDecimal := LeftValue;
        RightValueDecimal := RightValue;

        SetValue(LeftValueDecimal / RightValueDecimal); // TODO check non-zero
    end;
}
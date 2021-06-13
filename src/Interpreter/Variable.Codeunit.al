codeunit 81007 "FS Variable"
{
    // TODO
    var
        Name: Text[250];
        Type: Enum "FS Variable Type";
        Length: Integer;
        ObjectId: Integer;

    var
        RecordRef: RecordRef;
        Text: Text;
        Decimal: Decimal;
        Integer: Integer;
        Boolean: Boolean;

    procedure Setup(NewType: Enum "FS Variable Type")
    begin
        Setup('', NewType, 0, 0);
    end;

    procedure Setup(NewName: Text[250]; NewType: Enum "FS Variable Type"; NewLength: Integer; ObjectId: Integer)
    begin
        Name := NewName;
        Type := NewType;
        Length := NewLength;
        ObjectId := ObjectId;

        if Type = Enum::"FS Variable Type"::record then
            RecordRef.Open(ObjectId);
    end;

    procedure GetName(): Text[250]
    begin
        exit(Name);
    end;

    procedure SetName(NewName: Text[250])
    begin
        Name := NewName;
    end;

    procedure GetType(): Enum "FS Variable Type";
    begin
        exit(Type);
    end;

    procedure GetLength(): Integer
    begin
        exit(Length);
    end;

    procedure GetObjectId(): Integer
    begin
        exit(ObjectId);
    end;

    procedure Copy(var Variable: Codeunit "FS Variable")
    begin
        Clear(Variable);
        Variable.Setup(Name, Type, Length, ObjectId);

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
            "FS Variable Type"::record:
                Variable.SetValue(RecordRef);
            else
        // TODO
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
            "FS Variable Type"::record:
                Value := RecordRef;
            else
                Clear(Value);
        end;
    end;

    procedure GetValue(): Variant
    var
        Value: Variant;
    begin
        GetValue(Value);
        exit(value);
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
                Text := UpperCase(Value);
            "FS Variable Type"::decimal:
                Decimal := Value;
            "FS Variable Type"::integer:
                Integer := Value;
            "FS Variable Type"::boolean:
                Boolean := Value;
            "FS Variable Type"::record:
                RecordRef := Value;
            else
        // TODO
        end;
    end;

    procedure Add
    (
        var Left: Codeunit "FS Variable";
        var Right: Codeunit "FS Variable"
    )
    var
        LeftValue, RightValue : Variant;
    begin
        Left.GetValue(LeftValue);
        Right.GetValue(RightValue);

        Setup('', Left.GetType(), 0, 0);

        case Type of
            Type::integer,
            Type::decimal:
                AddDecimals(LeftValue, RightValue);
            Type::text,
            Type::code:
                AddTexts(LeftValue, RightValue);
            else
                Error('Can not add %1', Type);
        end
    end;

    local procedure AddDecimals
    (
        Left: Decimal;
        Right: Decimal
    )
    begin
        SetValue(Left + Right);
    end;

    local procedure AddTexts
    (
        Left: Text;
        Right: Text
    )
    begin
        SetValue(Left + Right);
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

        Setup('', Left.GetType(), 0, 0);

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

        Setup('', Left.GetType(), 0, 0);

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

        Setup('', Left.GetType(), 0, 0);

        LeftValueDecimal := LeftValue;
        RightValueDecimal := RightValue;

        SetValue(LeftValueDecimal / RightValueDecimal); // TODO check non-zero
    end;
}
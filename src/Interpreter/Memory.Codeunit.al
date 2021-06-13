codeunit 81005 "FS Memory"
{
    var
        Variables: array[256] of Codeunit "FS Variable";
        Stack: array[256] of Codeunit "FS Memory"; // TODO this could just use "FS Memory"?
        VariableMapping: Dictionary of [Text, Integer];
        VariableCount: Integer;
        StackCount: Integer;

    procedure InitGlobals
    (
        var TempVariable: Record "FS Variable" temporary
    )
    begin
        InitMemory(TempVariable, Enum::"FS Variable Scope"::Global);
    end;

    procedure InitMemory
    (
        var TempVariable: Record "FS Variable" temporary;
        Scope: Enum "FS Variable Scope"
    )
    begin
        TempVariable.SetRange(Scope, Scope);
        if TempVariable.FindSet() then
            repeat
                AddVariable(TempVariable);
            until TempVariable.Next() = 0;
    end;

    procedure AddVariable(Variable: Record "FS Variable")
    var
        i: Integer;
    begin
        VariableCount += 1;
        i := VariableCount;

        VariableMapping.Add(Variable.Name.ToLower(), i);
        Variables[i].Setup(Variable.Name, Variable.Type, Variable.Length, Variable."Object Id");
    end;

    procedure AddVariable(var Variable: Codeunit "FS Variable")
    var
        Value: Variant;
        i: Integer;
    begin
        VariableCount += 1;
        i := VariableCount;

        if Variable.GetName() <> '' then
            VariableMapping.Add(Variable.GetName().ToLower(), i);
        Variables[i].Setup(Variable.GetName(), Variable.GetType(), Variable.GetLength(), Variable.GetObjectId());
        Variable.GetValue(Value);
        Variables[i].SetValue(Value);
    end;

    procedure Push
    (
        Function: Record "FS Function";
        // FIXME var Parameter: Record "FS Variable" temporary;
        // TODO should not be necessary! var ParameterValue: array[256] of Codeunit "FS Variable"; // TODO ? var ?
        var Variable: Record "FS Variable" temporary
    )
    var
        i: Integer;
    begin
        StackCount += 1;
        i := StackCount;

        Stack[i].InitMemory(Variable, Enum::"FS Variable Scope"::Local); // FIXME add parameters
    end;

    procedure Pop(): Codeunit "FS Variable"
    begin
        Clear(Stack[StackCount]);
        StackCount -= 1;

        // FIXME return value !
    end;

    procedure GetVariableCount(): Integer
    begin
        exit(VariableCount);
    end;

    procedure HasVariable(Name: Text): Boolean
    begin
        exit(VariableMapping.ContainsKey(Name.ToLower()));
    end;

    procedure GetVariable(Name: Text): Codeunit "FS Variable"
    begin
        if StackCount <> 0 then // global memory
            if Stack[StackCount].HasVariable(Name) then
                exit(Stack[StackCount].GetVariable(Name));

        exit(Variables[VariableMapping.Get(Name.ToLower())]);
    end;

    procedure SetVariable(Name: Text; var NewValue: Codeunit "FS Variable")
    var
        Value: Variant;
    begin
        NewValue.GetValue(Value);

        SetVariable(Name, Value);
    end;

    procedure SetVariable(Name: Text; var Value: Variant)
    begin
        if StackCount <> 0 then // global memory
            if Stack[StackCount].HasVariable(Name) then begin
                Stack[StackCount].SetVariable(Name, Value);
                exit;
            end;

        Variables[VariableMapping.Get(Name.ToLower())].SetValue(Value);
    end;

    procedure SetParameter(Variable: Record "FS Variable"; var Value: Codeunit "FS Variable")
    var
    begin
        Stack[StackCount + 1].AddVariable(Variable);
        Stack[StackCount + 1].SetVariable(Variable.Name, Value);
    end;
}
codeunit 81006 "FS Call Memory"
{
    var
        Variables: array[256] of Codeunit "FS Variable";
        VariableMapping: Dictionary of [Integer, Integer];
        VariableCount: Integer;

    procedure InitMemory
    (
        var Parameter: Record "FS Variable" temporary;
        var ParameterValue: array[256] of Codeunit "FS Variable"; // TODO ? how to send value?
        var TempVariable: Record "FS Variable" temporary
    )
    begin
        // TODO AddParameter

        TempVariable.SetRange(Scope, TempVariable.Scope::Local);
        if TempVariable.FindSet() then
            repeat
                AddVariable(TempVariable);
            until TempVariable.Next() = 0;
    end;

    local procedure AddVariable(Variable: Record "FS Variable")
    var
        i: Integer;
    begin
        VariableCount += 1;
        i := VariableCount;

        VariableMapping.Add(Variable."Entry No.", i);
        Variables[i].Setup(Variable.Name, Variable.Type, Variable.Length);
    end;

    local procedure AddParameter(var Parameter: Record "FS Variable" temporary)
    var
        i: Integer;
    begin
        VariableCount += 1;
        i := VariableCount;

        VariableMapping.Add(Parameter."Entry No.", i);
        Variables[i] := ''; // TODO ? how to send value?
    end;
}
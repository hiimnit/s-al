codeunit 81005 "FS Memory"
{
    var
        Globals: array[256] of Codeunit "FS Variable";
        Stack: array[256] of Codeunit "FS Call Memory";
        GlobalMapping: Dictionary of [Integer, Integer];
        GlobalCount: Integer;
        StackCount: Integer;

    procedure InitGlobals(var TempVariable: Record "FS Variable" temporary)
    begin
        TempVariable.SetRange(Scope, TempVariable.Scope::Global);
        if TempVariable.FindSet() then
            repeat
                AddGlobal(TempVariable);
            until TempVariable.Next() = 0;
    end;

    local procedure AddGlobal(Variable: Record "FS Variable")
    var
        i: Integer;
    begin
        GlobalCount += 1;
        i := GlobalCount;

        GlobalMapping.Add(Variable."Entry No.", i);
        Globals[i].Setup(Variable.Name, Variable.Type, Variable.Length);
    end;

    procedure Push
    (
        Function: Record "FS Function";
        var Parameter: Record "FS Variable" temporary;
        var ParameterValue: array[256] of Codeunit "FS Variable"; // TODO ? var ?
        var Variable: Record "FS Variable" temporary
    )
    var
        i: Integer;
    begin
        StackCount += 1;
        i := StackCount;

        Stack[i].InitMemory(Variable); // TODO
    end;

    procedure Pop()
    begin
        Clear(Stack[StackCount]);
        StackCount -= 1;
    end;
}
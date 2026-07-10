unit ContractPerformRealVcl;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.ListBox, FMX.Memo, FMX.Types, System.Classes,
  System.SysUtils, System.Variants;
type
  TMemo = class(FMX.Memo.TMemo)
  public
    procedure Clear; reintroduce;
  end;
  TContractPerformRealVcl = class
  private
    Memo1: TMemo;
  public
    procedure Run;
  end;
implementation
{ Generated Windows-message compatibility helpers.
  These replace common VCL Perform/SendMessage patterns with compile-safe FMX code. }
procedure TMemo.Clear;
begin
  Lines.Clear;
end;
function GeneratedFMXMemoLineScroll(const AMemo: TMemo; const ADelta: Integer): NativeInt;
begin
  Result := 0;
  if AMemo = nil then
    Exit;
  if ADelta > 0 then
    AMemo.GoToTextEnd;
end;
function GeneratedFMXMemoLineFromChar(const AMemo: TMemo; const ACharIndex: Integer): Integer;
var
  I: Integer;
  Limit: Integer;
  S: string;
begin
  Result := 0;
  if AMemo = nil then
    Exit;
  S := AMemo.Text;
  Limit := ACharIndex;
  if Limit < 0 then
    Exit;
  if Limit > Length(S) then
    Limit := Length(S);
  for I := 1 to Limit do
    if S[I] = #10 then
      Inc(Result);
end;
function GeneratedFMXMemoVScroll(const AMemo: TMemo; const AScrollCode: string; const APos: NativeInt): NativeInt;
var
  Code: string;
begin
  Result := 0;
  if AMemo = nil then
    Exit;
  Code := UpperCase(AScrollCode);
  if Code = 'SB_TOP' then
    AMemo.SelStart := 0
  else if Code = 'SB_BOTTOM' then
    AMemo.GoToTextEnd
  else if Code = 'SB_LINEDOWN' then
    GeneratedFMXMemoLineScroll(AMemo, 1)
  else if Code = 'SB_LINEUP' then
    GeneratedFMXMemoLineScroll(AMemo, -1);
end;
function GeneratedFMXListBoxSelectString(const AListBox: TListBox; const AText: string): Integer;
var
  I: Integer;
  SearchText: string;
  ItemText: string;
begin
  Result := -1;
  if AListBox = nil then
    Exit;
  SearchText := UpperCase(AText);
  for I := 0 to AListBox.Items.Count - 1 do
  begin
    ItemText := AListBox.Items[I];
    if Copy(UpperCase(ItemText), 1, Length(SearchText)) = SearchText then
    begin
      AListBox.ItemIndex := I;
      Result := I;
      Exit;
    end;
  end;
end;
procedure TContractPerformRealVcl.Run;
begin
  GeneratedFMXMemoLineScroll(Memo1, -3);
end;
end.

unit ContractPenBrushFont;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.StdCtrls, FMX.Types, System.Classes, System.SysUtils,
  System.Types, System.UIConsts, System.UITypes, System.Variants, Winapi.Windows;
type TContractPenBrushFont = class(TForm) procedure Run; end;
implementation
var
  GeneratedCanvasCurrentPointCanvas: TCanvas;
  GeneratedCanvasCurrentPoint: TPointF;
  GeneratedCapturedGradientCanvas: TCanvas;
  GeneratedCapturedGradientRect: TRectF;
  GeneratedCapturedGradientTopY: Single;
  GeneratedCapturedGradientBottomY: Single;
  GeneratedCapturedGradientTopColor: TAlphaColor;
  GeneratedCapturedGradientBottomColor: TAlphaColor;
  GeneratedCapturedGradientValid: Boolean;
  GeneratedLastFillCanvas: TCanvas;
  GeneratedLastFillRect: TRectF;
  GeneratedLastFillColor: TAlphaColor;
  GeneratedLastFillValid: Boolean;
function GeneratedClientRect(const AObject: TObject): TRect;
begin
  if AObject is TControl then
    Result := Rect(0, 0, Round(TControl(AObject).Width), Round(TControl(AObject).Height))
  else if AObject is TCommonCustomForm then
    Result := Rect(0, 0, Round(TCommonCustomForm(AObject).ClientWidth), Round(TCommonCustomForm(AObject).ClientHeight))
  else
    Result := Rect(0, 0, 0, 0);
end;
function GeneratedRectF(const R: TRect): TRectF;
begin
  Result := TRectF.Create(R.Left, R.Top, R.Right, R.Bottom);
end;
procedure GeneratedCanvasFillRect(ACanvas: TCanvas; const R: TRect);
var
  RF: TRectF;
begin
  RF := GeneratedRectF(R);
  GeneratedLastFillCanvas := ACanvas;
  GeneratedLastFillRect := RF;
  GeneratedLastFillColor := ACanvas.Fill.Color;
  GeneratedLastFillValid := True;
  ACanvas.Fill.Kind := TBrushKind.Solid;
  ACanvas.FillRect(RF, 0, 0, AllCorners, 1);
end;
procedure GeneratedCanvasMoveTo(ACanvas: TCanvas; const X, Y: Single);
begin
  GeneratedCanvasCurrentPointCanvas := ACanvas;
  GeneratedCanvasCurrentPoint := PointF(X, Y);
end;
procedure GeneratedCanvasLineTo(ACanvas: TCanvas; const X, Y: Single);
var
  P1: TPointF;
  L: Single;
  R: Single;
begin
  if GeneratedCanvasCurrentPointCanvas = ACanvas then
    P1 := GeneratedCanvasCurrentPoint
  else
    P1 := PointF(X, Y);
  ACanvas.Stroke.Kind := TBrushKind.Solid;
  ACanvas.DrawLine(P1, PointF(X, Y), 1);
  if Abs(P1.Y - Y) <= 0.5 then
  begin
    if P1.X <= X then
    begin
      L := P1.X;
      R := X;
    end
    else
    begin
      L := X;
      R := P1.X;
    end;
    if (not GeneratedCapturedGradientValid) or (GeneratedCapturedGradientCanvas <> ACanvas) then
    begin
      GeneratedCapturedGradientCanvas := ACanvas;
      GeneratedCapturedGradientRect := TRectF.Create(L, Y, R, Y);
      GeneratedCapturedGradientTopY := Y;
      GeneratedCapturedGradientBottomY := Y;
      GeneratedCapturedGradientTopColor := ACanvas.Stroke.Color;
      GeneratedCapturedGradientBottomColor := ACanvas.Stroke.Color;
      GeneratedCapturedGradientValid := True;
    end
    else
    begin
      if L < GeneratedCapturedGradientRect.Left then
        GeneratedCapturedGradientRect.Left := L;
      if R > GeneratedCapturedGradientRect.Right then
        GeneratedCapturedGradientRect.Right := R;
      if Y < GeneratedCapturedGradientTopY then
      begin
        GeneratedCapturedGradientTopY := Y;
        GeneratedCapturedGradientTopColor := ACanvas.Stroke.Color;
      end;
      if Y > GeneratedCapturedGradientBottomY then
      begin
        GeneratedCapturedGradientBottomY := Y;
        GeneratedCapturedGradientBottomColor := ACanvas.Stroke.Color;
      end;
      if Y < GeneratedCapturedGradientRect.Top then
        GeneratedCapturedGradientRect.Top := Y;
      if Y > GeneratedCapturedGradientRect.Bottom then
        GeneratedCapturedGradientRect.Bottom := Y;
    end;
  end;
  GeneratedCanvasCurrentPointCanvas := ACanvas;
  GeneratedCanvasCurrentPoint := PointF(X, Y);
end;
procedure GeneratedCanvasRoundRect(ACanvas: TCanvas; const Left, Top, Right, Bottom, RadiusX, RadiusY: Single);
var
  RoundRectF: TRectF;
  OriginalFillKind: TBrushKind;
  OriginalFillColor: TAlphaColor;
begin
  RoundRectF := TRectF.Create(Left, Top, Right, Bottom);
  OriginalFillKind := ACanvas.Fill.Kind;
  OriginalFillColor := ACanvas.Fill.Color;
  if GeneratedLastFillValid and (GeneratedLastFillCanvas = ACanvas) and
     (Abs(GeneratedLastFillRect.Left - (Left - 1)) <= 2) and
     (Abs(GeneratedLastFillRect.Top - (Top - 1)) <= 2) and
     (Abs(GeneratedLastFillRect.Right - (Right + 1)) <= 2) and
     (Abs(GeneratedLastFillRect.Bottom - (Bottom + 1)) <= 2) then
  begin
    ACanvas.Fill.Kind := TBrushKind.Solid;
    ACanvas.Fill.Color := GeneratedLastFillColor;
    ACanvas.FillRect(GeneratedLastFillRect, 0, 0, AllCorners, 1);
    ACanvas.Fill.Kind := OriginalFillKind;
    ACanvas.Fill.Color := OriginalFillColor;
  end;
  if (OriginalFillKind = TBrushKind.None) and GeneratedCapturedGradientValid and
     (GeneratedCapturedGradientCanvas = ACanvas) and
     (Abs(GeneratedCapturedGradientRect.Left - (Left - 1)) <= 2) and
     (Abs(GeneratedCapturedGradientRect.Top - (Top - 1)) <= 2) and
     (Abs(GeneratedCapturedGradientRect.Right - (Right + 1)) <= 2) and
     (Abs(GeneratedCapturedGradientRect.Bottom - (Bottom + 1)) <= 2) then
  begin
    ACanvas.Fill.Kind := TBrushKind.Gradient;
    ACanvas.Fill.Gradient.Style := TGradientStyle.Linear;
    ACanvas.Fill.Gradient.Points[0].Color := GeneratedCapturedGradientTopColor;
    ACanvas.Fill.Gradient.Points[0].Offset := 0;
    ACanvas.Fill.Gradient.Points[1].Color := GeneratedCapturedGradientBottomColor;
    ACanvas.Fill.Gradient.Points[1].Offset := 1;
    ACanvas.Fill.Gradient.StartPosition.Point := PointF(0, 0);
    ACanvas.Fill.Gradient.StopPosition.Point := PointF(0, 1);
    ACanvas.FillRect(RoundRectF, RadiusX, RadiusY, AllCorners, 1);
    ACanvas.Fill.Kind := OriginalFillKind;
    ACanvas.Fill.Color := OriginalFillColor;
    GeneratedCapturedGradientValid := False;
  end;
  if (OriginalFillKind <> TBrushKind.None) and not GeneratedCapturedGradientValid then
  begin
    ACanvas.Fill.Kind := OriginalFillKind;
    ACanvas.Fill.Color := OriginalFillColor;
    ACanvas.FillRect(RoundRectF, RadiusX, RadiusY, AllCorners, 1);
  end;
  GeneratedLastFillValid := False;
  ACanvas.Stroke.Kind := TBrushKind.Solid;
  ACanvas.DrawRect(RoundRectF, RadiusX, RadiusY, AllCorners, 1);
end;
procedure GeneratedSetVerticalGradientFill(ACanvas: TCanvas; const R: TRect; const TopColor, BottomColor: TAlphaColor);
begin
  ACanvas.Fill.Kind := TBrushKind.Gradient;
  ACanvas.Fill.Gradient.Style := TGradientStyle.Linear;
  ACanvas.Fill.Gradient.Points[0].Color := TopColor;
  ACanvas.Fill.Gradient.Points[0].Offset := 0;
  ACanvas.Fill.Gradient.Points[1].Color := BottomColor;
  ACanvas.Fill.Gradient.Points[1].Offset := 1;
  ACanvas.Fill.Gradient.StartPosition.Point := PointF(0, 0);
  ACanvas.Fill.Gradient.StopPosition.Point := PointF(0, 1);
end;
procedure GeneratedCanvasStretchDraw(ACanvas: TCanvas; const R: TRect; const Bitmap: FMX.Graphics.TBitmap);
begin
  if Assigned(Bitmap) and not Bitmap.IsEmpty then
    ACanvas.DrawBitmap(Bitmap, TRectF.Create(0, 0, Bitmap.Width, Bitmap.Height), GeneratedRectF(R), 1);
end;
function GeneratedRGB(const R, G, B: Integer): TAlphaColor;
begin
  Result := TAlphaColor($FF000000 or ((Cardinal(R) and $FF) shl 16) or
    ((Cardinal(G) and $FF) shl 8) or (Cardinal(B) and $FF));
end;
function GeneratedColorToRGB(const Color: TAlphaColor): Cardinal;
begin
  Result := Cardinal(TAlphaColorRec(Color).R) or (Cardinal(TAlphaColorRec(Color).G) shl 8) or
    (Cardinal(TAlphaColorRec(Color).B) shl 16);
end;
function GeneratedGetRValue(const Color: Cardinal): Byte;
begin
  if (Color and $FF000000) <> 0 then
    Result := TAlphaColorRec(TAlphaColor(Color)).R
  else
    Result := GetRValue(Color);
end;
function GeneratedGetGValue(const Color: Cardinal): Byte;
begin
  if (Color and $FF000000) <> 0 then
    Result := TAlphaColorRec(TAlphaColor(Color)).G
  else
    Result := GetGValue(Color);
end;
function GeneratedGetBValue(const Color: Cardinal): Byte;
begin
  if (Color and $FF000000) <> 0 then
    Result := TAlphaColorRec(TAlphaColor(Color)).B
  else
    Result := GetBValue(Color);
end;
procedure GeneratedSetCanvasTextColor(ATarget: TObject; const AColor: TAlphaColor);
var
  LTextSettings: ITextSettings;
begin
  if ATarget is TCanvas then
  begin
    TCanvas(ATarget).Fill.Kind := TBrushKind.Solid;
    TCanvas(ATarget).Fill.Color := AColor;
  end
  else if Supports(ATarget, ITextSettings, LTextSettings) then
  begin
    LTextSettings.StyledSettings := LTextSettings.StyledSettings - [TStyledSetting.FontColor];
    LTextSettings.TextSettings.FontColor := AColor;
  end;
end;
procedure GeneratedSyncAutoSizeTextHeight(ATarget: TObject; const ASize: Single);
var
  LLabel: TLabel;
  LDesiredHeight: Single;
begin
  if (ASize <= 0) or not (ATarget is TLabel) then
    Exit;
  LLabel := TLabel(ATarget);
  if not LLabel.AutoSize then
    Exit;
  if LLabel.WordWrap then
    Exit;
  LDesiredHeight := ASize * 1.38;
  if LLabel.Height < LDesiredHeight then
    LLabel.Height := LDesiredHeight;
end;
procedure GeneratedSetCanvasFontPixelHeight(ATarget: TObject; const APixels: Integer);
var
  LTextSettings: ITextSettings;
  LFontSize: Single;
begin
  if APixels <= 0 then
    Exit;
  LFontSize := APixels * 72 / 96;
  if ATarget is TCanvas then
    TCanvas(ATarget).Font.Size := LFontSize
  else if Supports(ATarget, ITextSettings, LTextSettings) then
  begin
    LTextSettings.StyledSettings := LTextSettings.StyledSettings - [TStyledSetting.Size];
    LTextSettings.TextSettings.Font.Size := LFontSize;
  end;
  GeneratedSyncAutoSizeTextHeight(ATarget, LFontSize);
end;
procedure GeneratedSetCanvasFontSize(ATarget: TObject; const ASize: Single);
var
  LTextSettings: ITextSettings;
begin
  if ASize <= 0 then
    Exit;
  if ATarget is TCanvas then
    TCanvas(ATarget).Font.Size := ASize
  else if Supports(ATarget, ITextSettings, LTextSettings) then
  begin
    LTextSettings.StyledSettings := LTextSettings.StyledSettings - [TStyledSetting.Size];
    LTextSettings.TextSettings.Font.Size := ASize;
  end;
  GeneratedSyncAutoSizeTextHeight(ATarget, ASize);
end;
procedure GeneratedDrawText(ACanvas: TCanvas; const AText: string; var ARect: TRect; const AFlags: Cardinal);
var
  RF: TRectF;
  WordWrap: Boolean;
  CalcRect: Boolean;
  HAlign: TTextAlign;
  VAlign: TTextAlign;
begin
  RF := GeneratedRectF(ARect);
  WordWrap := (AFlags and DT_WORDBREAK) <> 0;
  CalcRect := (AFlags and DT_CALCRECT) <> 0;
  if (AFlags and DT_CENTER) <> 0 then
    HAlign := TTextAlign.Center
  else if (AFlags and DT_RIGHT) <> 0 then
    HAlign := TTextAlign.Trailing
  else
    HAlign := TTextAlign.Leading;
  if (AFlags and DT_VCENTER) <> 0 then
    VAlign := TTextAlign.Center
  else if (AFlags and DT_BOTTOM) <> 0 then
    VAlign := TTextAlign.Trailing
  else
    VAlign := TTextAlign.Leading;
  if CalcRect then
  begin
    ACanvas.MeasureText(RF, AText, WordWrap, [], HAlign, VAlign);
    ARect := Rect(Trunc(RF.Left), Trunc(RF.Top), Round(RF.Right), Round(RF.Bottom));
  end
  else
    ACanvas.FillText(RF, AText, WordWrap, 1, [], HAlign, VAlign);
end;
procedure TContractPenBrushFont.Run;
begin
  Canvas.Stroke.Color := claRed;
  Canvas.Fill.Kind := TBrushKind.None;
  GeneratedSetCanvasTextColor(Canvas, claBlue);
end;
end.

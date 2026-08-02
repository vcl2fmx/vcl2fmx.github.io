{VCL2FMX © 2026 echurchsites.wixsite.com
 Delphi VCL to FMX Converter and assistant
 Version v6.0 Navigator
 Written and built in the USA}

unit Converter.Mapper.Catalog;

interface

uses
  System.Generics.Collections,
  Converter.Core.Types,
  Converter.Mapper.Component;

procedure PopulateBuiltInMappings(
  AMappingDatabase: TObjectList<TComponentMapping>);
procedure PopulateFMXComponentCatalog(
  AFMXComponents: TObjectList<TFMXComponentInfo>);

implementation

procedure PopulateBuiltInMappings(AMappingDatabase: TObjectList<TComponentMapping>);
var
  Mapping: TComponentMapping;
  PropMap: TPropertyMapping;
  EventMap: TEventMapping;
begin
  // Direct mappings
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TForm';
  Mapping.FMXClassName := 'TForm';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 100;
  Mapping.Notes := 'Root forms are converted through dedicated parser rules; this row keeps form properties and events explicit in the mapping matrix.';

  PropMap.VCLProp := 'Caption';
  PropMap.FMXProp := 'Caption';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'ClientWidth';
  PropMap.FMXProp := 'ClientWidth';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'ClientHeight';
  PropMap.FMXProp := 'ClientHeight';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  EventMap.VCLEvent := 'OnCreate';
  EventMap.FMXEvent := 'OnCreate';
  EventMap.SignatureMatch := True;
  Mapping.EventMaps.Add(EventMap);

  EventMap.VCLEvent := 'OnShow';
  EventMap.FMXEvent := 'OnShow';
  EventMap.SignatureMatch := True;
  Mapping.EventMaps.Add(EventMap);

  EventMap.VCLEvent := 'OnMouseMove';
  EventMap.FMXEvent := 'OnMouseMove';
  EventMap.SignatureMatch := False;
  Mapping.EventMaps.Add(EventMap);

  AMappingDatabase.Add(Mapping);

  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TFrame';
  Mapping.FMXClassName := 'TFrame';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 95;
  Mapping.Notes := 'FMX frames are available and should be treated as first-class matrix entries.';
  AMappingDatabase.Add(Mapping);

  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TButton';
  Mapping.FMXClassName := 'TButton';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 100;

  PropMap.VCLProp := 'Caption';
  PropMap.FMXProp := 'Text';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'Enabled';
  PropMap.FMXProp := 'Enabled';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  EventMap.VCLEvent := 'OnClick';
  EventMap.FMXEvent := 'OnClick';
  EventMap.SignatureMatch := True;
  Mapping.EventMaps.Add(EventMap);

  AMappingDatabase.Add(Mapping);

  // TEdit mapping
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TEdit';
  Mapping.FMXClassName := 'TEdit';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 100;

  PropMap.VCLProp := 'Text';
  PropMap.FMXProp := 'Text';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'ReadOnly';
  PropMap.FMXProp := 'ReadOnly';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'MaxLength';
  PropMap.FMXProp := 'MaxLength';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  EventMap.VCLEvent := 'OnChange';
  EventMap.FMXEvent := 'OnChange';
  EventMap.SignatureMatch := True;
  Mapping.EventMaps.Add(EventMap);

  EventMap.VCLEvent := 'OnEnter';
  EventMap.FMXEvent := 'OnEnter';
  EventMap.SignatureMatch := True;
  Mapping.EventMaps.Add(EventMap);

  EventMap.VCLEvent := 'OnExit';
  EventMap.FMXEvent := 'OnExit';
  EventMap.SignatureMatch := True;
  Mapping.EventMaps.Add(EventMap);

  EventMap.VCLEvent := 'OnKeyDown';
  EventMap.FMXEvent := 'OnKeyDown';
  EventMap.SignatureMatch := False;
  Mapping.EventMaps.Add(EventMap);

  EventMap.VCLEvent := 'OnKeyUp';
  EventMap.FMXEvent := 'OnKeyUp';
  EventMap.SignatureMatch := False;
  Mapping.EventMaps.Add(EventMap);

  AMappingDatabase.Add(Mapping);

  // TMaskEdit -> TEdit
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TMaskEdit';
  Mapping.FMXClassName := 'TEdit';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 80;
  Mapping.Notes := 'Use FMX TEdit and review EditMask behavior manually.';

  PropMap.VCLProp := 'Text';
  PropMap.FMXProp := 'Text';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'ReadOnly';
  PropMap.FMXProp := 'ReadOnly';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'MaxLength';
  PropMap.FMXProp := 'MaxLength';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'EditMask';
  PropMap.FMXProp := '';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  EventMap.VCLEvent := 'OnChange';
  EventMap.FMXEvent := 'OnChange';
  EventMap.SignatureMatch := True;
  Mapping.EventMaps.Add(EventMap);

  AMappingDatabase.Add(Mapping);

  // TLabel mapping
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TLabel';
  Mapping.FMXClassName := 'TLabel';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 100;

  PropMap.VCLProp := 'Caption';
  PropMap.FMXProp := 'Text';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'Layout';
  PropMap.FMXProp := 'TextSettings.VertAlign';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  AMappingDatabase.Add(Mapping);

  // TStaticText -> TLabel
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TStaticText';
  Mapping.FMXClassName := 'TLabel';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 90;
  Mapping.Notes := 'Static text converts cleanly to an FMX label.';

  PropMap.VCLProp := 'Caption';
  PropMap.FMXProp := 'Text';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  AMappingDatabase.Add(Mapping);

  // TPanel -> TPanel
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TPanel';
  Mapping.FMXClassName := 'TPanel';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 95;
  Mapping.Notes := 'Preserve visual FMX panel semantics for container controls';
  AMappingDatabase.Add(Mapping);

  // TGroupBox -> TGroupBox
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TGroupBox';
  Mapping.FMXClassName := 'TGroupBox';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 95;
  Mapping.Notes := 'Preserve visual FMX group box semantics and caption handling';

  PropMap.VCLProp := 'Caption';
  PropMap.FMXProp := 'Text';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  AMappingDatabase.Add(Mapping);

  // TFlowPanel -> TFlowLayout
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TFlowPanel';
  Mapping.FMXClassName := 'TFlowLayout';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 85;
  Mapping.Notes := 'Use FMX TFlowLayout as the closest standard flow container.';
  AMappingDatabase.Add(Mapping);

  // TGridPanel -> TGridPanelLayout
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TGridPanel';
  Mapping.FMXClassName := 'TGridPanelLayout';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 85;
  Mapping.Notes := 'Use FMX TGridPanelLayout as the closest standard grid layout container.';
  AMappingDatabase.Add(Mapping);

  // TCheckBox mapping
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TCheckBox';
  Mapping.FMXClassName := 'TCheckBox';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 100;

  PropMap.VCLProp := 'Caption';
  PropMap.FMXProp := 'Text';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'Checked';
  PropMap.FMXProp := 'IsChecked';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  EventMap.VCLEvent := 'OnClick';
  EventMap.FMXEvent := 'OnClick';
  EventMap.SignatureMatch := True;
  Mapping.EventMaps.Add(EventMap);

  AMappingDatabase.Add(Mapping);

  // TRadioButton mapping
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TRadioButton';
  Mapping.FMXClassName := 'TRadioButton';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 100;

  PropMap.VCLProp := 'Caption';
  PropMap.FMXProp := 'Text';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'Checked';
  PropMap.FMXProp := 'IsChecked';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  EventMap.VCLEvent := 'OnClick';
  EventMap.FMXEvent := 'OnClick';
  EventMap.SignatureMatch := True;
  Mapping.EventMaps.Add(EventMap);

  AMappingDatabase.Add(Mapping);

  // TListBox mapping
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TListBox';
  Mapping.FMXClassName := 'TListBox';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 90;
  Mapping.Notes := 'Item objects need conversion';

  PropMap.VCLProp := 'Items';
  PropMap.FMXProp := 'Items';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'ItemIndex';
  PropMap.FMXProp := 'ItemIndex';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  EventMap.VCLEvent := 'OnChange';
  EventMap.FMXEvent := 'OnChange';
  EventMap.SignatureMatch := True;
  Mapping.EventMaps.Add(EventMap);

  EventMap.VCLEvent := 'OnClick';
  EventMap.FMXEvent := 'OnClick';
  EventMap.SignatureMatch := True;
  Mapping.EventMaps.Add(EventMap);

  AMappingDatabase.Add(Mapping);

  // TCheckListBox -> TListBox
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TCheckListBox';
  Mapping.FMXClassName := 'TListBox';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 70;
  Mapping.Notes := 'Use FMX TListBox and review checked-item behavior manually.';

  PropMap.VCLProp := 'Items';
  PropMap.FMXProp := 'Items';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'ItemIndex';
  PropMap.FMXProp := 'ItemIndex';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  AMappingDatabase.Add(Mapping);

  // TDBListBox -> TListBox
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TDBListBox';
  Mapping.FMXClassName := 'TListBox';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 60;
  Mapping.Notes := 'Use LiveBindings with FMX TListBox and review lookup/list-source behavior manually.';
  AMappingDatabase.Add(Mapping);

  // TComboBox mapping
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TComboBox';
  Mapping.FMXClassName := 'TComboBox';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 90;

  PropMap.VCLProp := 'Text';
  PropMap.FMXProp := 'Text';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'Items';
  PropMap.FMXProp := 'Items';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'ItemIndex';
  PropMap.FMXProp := 'ItemIndex';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'Style';
  PropMap.FMXProp := '';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  EventMap.VCLEvent := 'OnChange';
  EventMap.FMXEvent := 'OnChange';
  EventMap.SignatureMatch := True;
  Mapping.EventMaps.Add(EventMap);

  EventMap.VCLEvent := 'OnDropDown';
  EventMap.FMXEvent := 'OnPopup';
  EventMap.SignatureMatch := True;
  Mapping.EventMaps.Add(EventMap);

  EventMap.VCLEvent := 'OnCloseUp';
  EventMap.FMXEvent := 'OnClosePopup';
  EventMap.SignatureMatch := True;
  Mapping.EventMaps.Add(EventMap);

  EventMap.VCLEvent := 'OnSelect';
  EventMap.FMXEvent := 'OnChange';
  EventMap.SignatureMatch := True;
  Mapping.EventMaps.Add(EventMap);

  EventMap.VCLEvent := 'OnKeyDown';
  EventMap.FMXEvent := 'OnKeyDown';
  EventMap.SignatureMatch := False;
  Mapping.EventMaps.Add(EventMap);

  EventMap.VCLEvent := 'OnKeyUp';
  EventMap.FMXEvent := 'OnKeyUp';
  EventMap.SignatureMatch := False;
  Mapping.EventMaps.Add(EventMap);

  AMappingDatabase.Add(Mapping);

  // TNumberBox mapping
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TNumberBox';
  Mapping.FMXClassName := 'TNumberBox';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 95;
  Mapping.Notes := 'FMX TNumberBox is available in FMX.NumberBox';

  PropMap.VCLProp := 'MinValue';
  PropMap.FMXProp := 'Min';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'MaxValue';
  PropMap.FMXProp := 'Max';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'Decimal';
  PropMap.FMXProp := 'DecimalDigits';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  AMappingDatabase.Add(Mapping);

  // TSpinEdit -> TSpinBox
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TSpinEdit';
  Mapping.FMXClassName := 'TSpinBox';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 90;
  Mapping.Notes := 'FMX TSpinBox is available in FMX.SpinBox';

  PropMap.VCLProp := 'MinValue';
  PropMap.FMXProp := 'Min';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'MaxValue';
  PropMap.FMXProp := 'Max';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'Increment';
  PropMap.FMXProp := 'Increment';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  AMappingDatabase.Add(Mapping);

  // TColorBox -> TColorComboBox
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TColorBox';
  Mapping.FMXClassName := 'TColorComboBox';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 85;
  Mapping.Notes := 'FMX color-selection equivalent is TColorComboBox in FMX.Colors';
  AMappingDatabase.Add(Mapping);

  // TMemo mapping
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TMemo';
  Mapping.FMXClassName := 'TMemo';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 90;

  PropMap.VCLProp := 'Lines';
  PropMap.FMXProp := 'Lines';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'ReadOnly';
  PropMap.FMXProp := 'ReadOnly';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'WordWrap';
  PropMap.FMXProp := 'WordWrap';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  EventMap.VCLEvent := 'OnChange';
  EventMap.FMXEvent := 'OnChange';
  EventMap.SignatureMatch := True;
  Mapping.EventMaps.Add(EventMap);

  EventMap.VCLEvent := 'OnKeyDown';
  EventMap.FMXEvent := 'OnKeyDown';
  EventMap.SignatureMatch := False;
  Mapping.EventMaps.Add(EventMap);

  EventMap.VCLEvent := 'OnKeyUp';
  EventMap.FMXEvent := 'OnKeyUp';
  EventMap.SignatureMatch := False;
  Mapping.EventMaps.Add(EventMap);

  AMappingDatabase.Add(Mapping);

  // TRichEdit -> TMemo
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TRichEdit';
  Mapping.FMXClassName := 'TMemo';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 75;
  Mapping.Notes := 'Use FMX TMemo and review rich-text formatting behavior manually.';

  PropMap.VCLProp := 'Lines';
  PropMap.FMXProp := 'Lines';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'ReadOnly';
  PropMap.FMXProp := 'ReadOnly';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'WordWrap';
  PropMap.FMXProp := 'WordWrap';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  AMappingDatabase.Add(Mapping);

  // TPaintBox mapping
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TPaintBox';
  Mapping.FMXClassName := 'TPaintBox';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 90;
  Mapping.Notes := 'FMX TPaintBox is available in FMX.Objects';
  AMappingDatabase.Add(Mapping);

  // TImage mapping
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TImage';
  Mapping.FMXClassName := 'TImage';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 80;

  PropMap.VCLProp := 'Picture';
  PropMap.FMXProp := 'Bitmap';
  PropMap.NeedsTransformation := True;
  PropMap.TransformerFunc := 'TransformPicture';
  Mapping.PropertyMaps.Add(PropMap);

  AMappingDatabase.Add(Mapping);

  // TPageControl -> TTabControl
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TPageControl';
  Mapping.FMXClassName := 'TTabControl';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 85;
  AMappingDatabase.Add(Mapping);

  // TTabSheet -> TTabItem
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TTabSheet';
  Mapping.FMXClassName := 'TTabItem';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 90;
  AMappingDatabase.Add(Mapping);

  // TScrollBox -> TScrollBox
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TScrollBox';
  Mapping.FMXClassName := 'TScrollBox';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 90;
  AMappingDatabase.Add(Mapping);

  // TStringGrid -> TStringGrid
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TStringGrid';
  Mapping.FMXClassName := 'TStringGrid';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 70;
  Mapping.Notes := 'Data model completely different - requires LiveBindings';
  AMappingDatabase.Add(Mapping);

  // TDBEdit -> TEdit (with LiveBindings)
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TDBEdit';
  Mapping.FMXClassName := 'TEdit';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 60;
  Mapping.Notes := 'Use LiveBindings to connect to data source';
  AMappingDatabase.Add(Mapping);

  // TDBCheckBox -> TCheckBox (with LiveBindings)
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TDBCheckBox';
  Mapping.FMXClassName := 'TCheckBox';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 55;
  Mapping.Notes := 'Use LiveBindings to connect to data source';
  AMappingDatabase.Add(Mapping);

  // TDBComboBox -> TComboEdit (with LiveBindings)
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TDBComboBox';
  Mapping.FMXClassName := 'TComboEdit';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 50;
  Mapping.Notes := 'Use LiveBindings to connect to data source';
  AMappingDatabase.Add(Mapping);

  // TDBGrid -> TStringGrid
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TDBGrid';
  Mapping.FMXClassName := 'TStringGrid';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 50;
  Mapping.Notes := 'Major architectural difference - requires LiveBindings completely';
  AMappingDatabase.Add(Mapping);

  // TDrawGrid -> TStringGrid
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TDrawGrid';
  Mapping.FMXClassName := 'TStringGrid';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 55;
  Mapping.Notes := 'Use FMX TStringGrid and review custom drawing/cell rendering manually.';
  AMappingDatabase.Add(Mapping);

  // TDBCtrlGrid -> TStringGrid
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TDBCtrlGrid';
  Mapping.FMXClassName := 'TStringGrid';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 45;
  Mapping.Notes := 'Major structural difference - requires LiveBindings and manual layout review.';
  AMappingDatabase.Add(Mapping);

  // TDBNavigator -> TBindNavigator
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TDBNavigator';
  Mapping.FMXClassName := 'TBindNavigator';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 85;
  Mapping.Notes := 'Use FMX LiveBindings navigator with generated TBindSourceDB hookup';
  AMappingDatabase.Add(Mapping);

  // TMainMenu -> TMenuBar
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TMainMenu';
  Mapping.FMXClassName := 'TMenuBar';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 85;
  AMappingDatabase.Add(Mapping);

  // TMenuItem -> TMenuItem
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TMenuItem';
  Mapping.FMXClassName := 'TMenuItem';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 95;
  AMappingDatabase.Add(Mapping);

  // TPopupMenu -> TPopupMenu
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TPopupMenu';
  Mapping.FMXClassName := 'TPopupMenu';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 90;
  AMappingDatabase.Add(Mapping);

  // TTimer -> TTimer
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TTimer';
  Mapping.FMXClassName := 'TTimer';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 100;

  EventMap.VCLEvent := 'OnTimer';
  EventMap.FMXEvent := 'OnTimer';
  EventMap.SignatureMatch := True;
  Mapping.EventMaps.Add(EventMap);

  AMappingDatabase.Add(Mapping);

  // TOpenDialog -> TOpenDialog
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TOpenDialog';
  Mapping.FMXClassName := 'TOpenDialog';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 90;

  PropMap.VCLProp := 'FileName';
  PropMap.FMXProp := 'FileName';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'Filter';
  PropMap.FMXProp := 'Filter';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'DefaultExt';
  PropMap.FMXProp := 'DefaultExt';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'InitialDir';
  PropMap.FMXProp := 'InitialDir';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'Title';
  PropMap.FMXProp := 'Title';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  AMappingDatabase.Add(Mapping);

  // TFileOpenDialog -> TOpenDialog
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TFileOpenDialog';
  Mapping.FMXClassName := 'TOpenDialog';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 60;
  Mapping.Notes := 'Use FMX TOpenDialog as the closest standard substitute';
  AMappingDatabase.Add(Mapping);

  // TSaveDialog -> TSaveDialog
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TSaveDialog';
  Mapping.FMXClassName := 'TSaveDialog';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 90;

  PropMap.VCLProp := 'FileName';
  PropMap.FMXProp := 'FileName';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'Filter';
  PropMap.FMXProp := 'Filter';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'DefaultExt';
  PropMap.FMXProp := 'DefaultExt';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'InitialDir';
  PropMap.FMXProp := 'InitialDir';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'Title';
  PropMap.FMXProp := 'Title';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  AMappingDatabase.Add(Mapping);

  // TFileSaveDialog -> TSaveDialog
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TFileSaveDialog';
  Mapping.FMXClassName := 'TSaveDialog';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 65;
  Mapping.Notes := 'Use FMX TSaveDialog as the closest standard substitute.';

  PropMap.VCLProp := 'FileName';
  PropMap.FMXProp := 'FileName';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'DefaultExtension';
  PropMap.FMXProp := 'DefaultExt';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'DefaultFolder';
  PropMap.FMXProp := 'InitialDir';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'Title';
  PropMap.FMXProp := 'Title';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  AMappingDatabase.Add(Mapping);

  // TFontDialog -> generated compatibility class
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TFontDialog';
  Mapping.FMXClassName := 'TFontDialog';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 70;
  Mapping.Notes := 'Generated compatibility dialog with a streamed Font property and Execute support';
  AMappingDatabase.Add(Mapping);

  // TRadioGroup -> generated compatibility class
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TRadioGroup';
  Mapping.FMXClassName := 'TRadioGroup';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 75;
  Mapping.Notes := 'Generated compatibility group that rebuilds internal FMX radio buttons from Items';

  PropMap.VCLProp := 'Items';
  PropMap.FMXProp := 'Items';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'ItemIndex';
  PropMap.FMXProp := 'ItemIndex';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  AMappingDatabase.Add(Mapping);

  // TLinkLabel -> TLabel
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TLinkLabel';
  Mapping.FMXClassName := 'TLabel';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 65;
  Mapping.Notes := 'Hyperlink behavior requires manual review, but the visual text target is an FMX label.';

  PropMap.VCLProp := 'Caption';
  PropMap.FMXProp := 'Text';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  AMappingDatabase.Add(Mapping);

  // TTrayIcon -> no generic FMX equivalent
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TTrayIcon';
  Mapping.FMXClassName := '';
  Mapping.MappingType := 'Unmapped';
  Mapping.Confidence := 0;
  Mapping.Notes := 'No standard FMX tray icon component - requires platform-specific code';
  AMappingDatabase.Add(Mapping);

  // TApdComPort -> third-party serial component with no generic FMX equivalent
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TApdComPort';
  Mapping.FMXClassName := '';
  Mapping.MappingType := 'Unmapped';
  Mapping.Confidence := 0;
  Mapping.Notes := 'Third-party serial communications component - requires a custom FMX/WinAPI replacement';
  AMappingDatabase.Add(Mapping);

  // TColorDialog -> generated compatibility class
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TColorDialog';
  Mapping.FMXClassName := 'TColorDialog';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 70;
  Mapping.Notes := 'Generated compatibility dialog with a Color property and Execute support';
  AMappingDatabase.Add(Mapping);

  // TActionList -> TActionList
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TActionList';
  Mapping.FMXClassName := 'TActionList';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 95;
  AMappingDatabase.Add(Mapping);

  // TAction -> TAction
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TAction';
  Mapping.FMXClassName := 'TAction';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 95;
  AMappingDatabase.Add(Mapping);

  // TImageList -> TImageList
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TImageList';
  Mapping.FMXClassName := 'TImageList';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 80;
  AMappingDatabase.Add(Mapping);

  // TSplitter -> TSplitter
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TSplitter';
  Mapping.FMXClassName := 'TSplitter';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 90;
  AMappingDatabase.Add(Mapping);

  // TStatusBar -> TStatusBar
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TStatusBar';
  Mapping.FMXClassName := 'TStatusBar';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 80;
  AMappingDatabase.Add(Mapping);

  // TToolBar -> TToolBar
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TToolBar';
  Mapping.FMXClassName := 'TToolBar';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 85;
  AMappingDatabase.Add(Mapping);

  // TProgressBar -> TProgressBar
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TProgressBar';
  Mapping.FMXClassName := 'TProgressBar';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 95;

  PropMap.VCLProp := 'Position';
  PropMap.FMXProp := 'Value';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  AMappingDatabase.Add(Mapping);

  // TTrackBar -> TTrackBar
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TTrackBar';
  Mapping.FMXClassName := 'TTrackBar';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 95;

  PropMap.VCLProp := 'Position';
  PropMap.FMXProp := 'Value';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  AMappingDatabase.Add(Mapping);

  // TUpDown -> TSpinBox
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TUpDown';
  Mapping.FMXClassName := 'TSpinBox';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 70;

  PropMap.VCLProp := 'Position';
  PropMap.FMXProp := 'Value';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'Min';
  PropMap.FMXProp := 'Min';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'Max';
  PropMap.FMXProp := 'Max';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  AMappingDatabase.Add(Mapping);

  // TDateTimePicker -> TDateEdit
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TDateTimePicker';
  Mapping.FMXClassName := 'TDateEdit';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 75;

  PropMap.VCLProp := 'Date';
  PropMap.FMXProp := 'Date';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'Time';
  PropMap.FMXProp := 'Time';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'Checked';
  PropMap.FMXProp := 'IsChecked';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'ShowCheckBox';
  PropMap.FMXProp := 'ShowCheckBox';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'Format';
  PropMap.FMXProp := 'Format';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  EventMap.VCLEvent := 'OnChange';
  EventMap.FMXEvent := 'OnChange';
  EventMap.SignatureMatch := True;
  Mapping.EventMaps.Add(EventMap);

  EventMap.VCLEvent := 'OnDropDown';
  EventMap.FMXEvent := 'OnOpenPicker';
  EventMap.SignatureMatch := True;
  Mapping.EventMaps.Add(EventMap);

  EventMap.VCLEvent := 'OnCloseUp';
  EventMap.FMXEvent := 'OnClosePicker';
  EventMap.SignatureMatch := True;
  Mapping.EventMaps.Add(EventMap);

  AMappingDatabase.Add(Mapping);

  // TMonthCalendar -> TCalendar
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TMonthCalendar';
  Mapping.FMXClassName := 'TCalendar';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 80;

  PropMap.VCLProp := 'Date';
  PropMap.FMXProp := 'Date';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  AMappingDatabase.Add(Mapping);

  // TTreeView -> TTreeView
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TTreeView';
  Mapping.FMXClassName := 'TTreeView';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 85;
  AMappingDatabase.Add(Mapping);

  // TListView -> TListView
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TListView';
  Mapping.FMXClassName := 'TListView';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 80;
  AMappingDatabase.Add(Mapping);

  // TWebBrowser -> TWebBrowser
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TWebBrowser';
  Mapping.FMXClassName := 'TWebBrowser';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 80;
  AMappingDatabase.Add(Mapping);

  // TShape -> TShape (but different properties)
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TShape';
  Mapping.FMXClassName := 'TShape';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 70;

  PropMap.VCLProp := 'Brush';
  PropMap.FMXProp := 'Fill';
  PropMap.NeedsTransformation := True;
  PropMap.TransformerFunc := 'TransformBrush';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'Pen';
  PropMap.FMXProp := 'Stroke';
  PropMap.NeedsTransformation := True;
  PropMap.TransformerFunc := 'TransformPen';
  Mapping.PropertyMaps.Add(PropMap);

  AMappingDatabase.Add(Mapping);

  // TBevel -> TRectangle (approximation)
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TBevel';
  Mapping.FMXClassName := 'TRectangle';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 60;
  Mapping.Notes := 'Use TRectangle with appropriate Fill and Stroke';
  AMappingDatabase.Add(Mapping);

  // TScrollBar -> TScrollBar
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TScrollBar';
  Mapping.FMXClassName := 'TScrollBar';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 85;
  AMappingDatabase.Add(Mapping);

  // TSpeedButton -> TSpeedButton
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TSpeedButton';
  Mapping.FMXClassName := 'TSpeedButton';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 85;
  AMappingDatabase.Add(Mapping);

  // TBitBtn -> TButton (with Image)
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TBitBtn';
  Mapping.FMXClassName := 'TButton';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 75;
  Mapping.Notes := 'Use TButton with Images property';
  AMappingDatabase.Add(Mapping);

  // TLabeledEdit -> TLayout + TEdit
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TLabeledEdit';
  Mapping.FMXClassName := '';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 65;
  Mapping.Notes := 'Create TLayout with TLabel and TEdit';
  AMappingDatabase.Add(Mapping);

  // TValueListEditor -> TGrid
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TValueListEditor';
  Mapping.FMXClassName := 'TGrid';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 50;
  Mapping.Notes := 'Complex - requires custom grid implementation';
  AMappingDatabase.Add(Mapping);

  // TChart -> Not available in standard FMX
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TChart';
  Mapping.FMXClassName := '';
  Mapping.MappingType := 'Unmapped';
  Mapping.Confidence := 0;
  Mapping.Notes := 'Requires TMS FMX Chart or similar third-party component';
  AMappingDatabase.Add(Mapping);

  // TTaskDialog -> no standard FMX equivalent
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TTaskDialog';
  Mapping.FMXClassName := '';
  Mapping.MappingType := 'Unmapped';
  Mapping.Confidence := 0;
  Mapping.Notes := 'No standard FMX task dialog component - requires a custom dialog implementation.';
  AMappingDatabase.Add(Mapping);

  // Explicit dataset rows for matrix completeness
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TClientDataSet';
  Mapping.FMXClassName := '';
  Mapping.MappingType := 'Unmapped';
  Mapping.Confidence := 0;
  Mapping.Notes := 'Dataset component requires manual review; preserve only if the target platform and supporting units are appropriate.';
  AMappingDatabase.Add(Mapping);

  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TQuery';
  Mapping.FMXClassName := '';
  Mapping.MappingType := 'Unmapped';
  Mapping.Confidence := 0;
  Mapping.Notes := 'Legacy query component requires manual review or replacement.';
  AMappingDatabase.Add(Mapping);

  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TADODataSet';
  Mapping.FMXClassName := '';
  Mapping.MappingType := 'Unmapped';
  Mapping.Confidence := 0;
  Mapping.Notes := 'Windows-specific ADO dataset requires manual review for FMX targets.';
  AMappingDatabase.Add(Mapping);

  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TSQLDataSet';
  Mapping.FMXClassName := '';
  Mapping.MappingType := 'Unmapped';
  Mapping.Confidence := 0;
  Mapping.Notes := 'dbExpress dataset requires manual review for FMX targets.';
  AMappingDatabase.Add(Mapping);

  // TMediaPlayer -> TMediaPlayer
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TMediaPlayer';
  Mapping.FMXClassName := 'TMediaPlayer';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 80;
  AMappingDatabase.Add(Mapping);
end;

procedure PopulateFMXComponentCatalog(AFMXComponents: TObjectList<TFMXComponentInfo>);
var
  FMXComp: TFMXComponentInfo;
begin
  // Standard FMX components catalog
  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TControl';
  FMXComp.ParentClass := '';
  FMXComp.Category := 'Base';
  FMXComp.Properties.Add('Align');
  FMXComp.Properties.Add('Anchors');
  FMXComp.Properties.Add('Enabled');
  FMXComp.Properties.Add('Visible');
  FMXComp.Properties.Add('Position');
  FMXComp.Properties.Add('Size');
  FMXComp.Properties.Add('Width');
  FMXComp.Properties.Add('Height');
  FMXComp.Properties.Add('Hint');
  FMXComp.Properties.Add('ShowHint');
  FMXComp.Properties.Add('TabOrder');
  FMXComp.Properties.Add('TabStop');
  FMXComp.Properties.Add('Opacity');
  FMXComp.Properties.Add('Margins');
  FMXComp.Properties.Add('Padding');
  FMXComp.Properties.Add('HitTest');
  FMXComp.Events.Add('OnClick');
  FMXComp.Events.Add('OnDblClick');
  FMXComp.Events.Add('OnEnter');
  FMXComp.Events.Add('OnExit');
  FMXComp.Events.Add('OnMouseDown');
  FMXComp.Events.Add('OnMouseMove');
  FMXComp.Events.Add('OnMouseUp');
  FMXComp.Events.Add('OnMouseWheel');
  FMXComp.Events.Add('OnKeyDown');
  FMXComp.Events.Add('OnKeyUp');
  AFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TForm';
  FMXComp.ParentClass := 'TCommonCustomForm';
  FMXComp.Category := 'Forms';
  FMXComp.Properties.Add('Caption');
  FMXComp.Properties.Add('ClientWidth');
  FMXComp.Properties.Add('ClientHeight');
  FMXComp.Properties.Add('Width');
  FMXComp.Properties.Add('Height');
  FMXComp.Properties.Add('Left');
  FMXComp.Properties.Add('Top');
  FMXComp.Properties.Add('Position');
  FMXComp.Properties.Add('FormStyle');
  FMXComp.Properties.Add('BorderStyle');
  FMXComp.Properties.Add('Transparency');
  FMXComp.Events.Add('OnClick');
  FMXComp.Events.Add('OnCreate');
  FMXComp.Events.Add('OnShow');
  FMXComp.Events.Add('OnClose');
  FMXComp.Events.Add('OnMouseDown');
  FMXComp.Events.Add('OnMouseMove');
  FMXComp.Events.Add('OnMouseUp');
  FMXComp.Events.Add('OnMouseWheel');
  FMXComp.Events.Add('OnResize');
  AFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TButton';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('Text');
  FMXComp.Properties.Add('Enabled');
  FMXComp.Properties.Add('Visible');
  FMXComp.Properties.Add('Width');
  FMXComp.Properties.Add('Height');
  FMXComp.Properties.Add('Position');
  FMXComp.Properties.Add('TabOrder');
  FMXComp.Properties.Add('TabStop');
  FMXComp.Properties.Add('StyledSettings');
  FMXComp.Properties.Add('Font');
  FMXComp.Properties.Add('TextSettings');
  FMXComp.Properties.Add('WordWrap');
  FMXComp.Properties.Add('Anchors');
  FMXComp.Events.Add('OnClick');
  FMXComp.Events.Add('OnDblClick');
  FMXComp.Events.Add('OnMouseDown');
  FMXComp.Events.Add('OnMouseUp');
  FMXComp.Events.Add('OnMouseMove');
  FMXComp.Events.Add('OnKeyDown');
  FMXComp.Events.Add('OnKeyUp');
  AFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TEdit';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('Text');
  FMXComp.Properties.Add('Enabled');
  FMXComp.Properties.Add('ReadOnly');
  FMXComp.Properties.Add('Password');
  FMXComp.Properties.Add('MaxLength');
  FMXComp.Properties.Add('Anchors');
  FMXComp.Events.Add('OnChange');
  FMXComp.Events.Add('OnDblClick');
  FMXComp.Events.Add('OnEnter');
  FMXComp.Events.Add('OnExit');
  FMXComp.Events.Add('OnKeyDown');
  FMXComp.Events.Add('OnKeyUp');
  AFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TLabel';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('Text');
  FMXComp.Properties.Add('AutoSize');
  FMXComp.Properties.Add('WordWrap');
  FMXComp.Properties.Add('Trimming');
  FMXComp.Properties.Add('Anchors');
  FMXComp.Properties.Add('Font');
  FMXComp.Properties.Add('TextSettings');
  FMXComp.Events.Add('OnClick');
  FMXComp.Events.Add('OnDblClick');
  AFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TCheckBox';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('Text');
  FMXComp.Properties.Add('IsChecked');
  FMXComp.Properties.Add('Enabled');
  FMXComp.Properties.Add('StyledSettings');
  FMXComp.Properties.Add('TextSettings');
  FMXComp.Properties.Add('WordWrap');
  FMXComp.Events.Add('OnChange');
  FMXComp.Events.Add('OnDblClick');
  AFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TRadioButton';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('Text');
  FMXComp.Properties.Add('IsChecked');
  FMXComp.Properties.Add('GroupName');
  FMXComp.Properties.Add('StyledSettings');
  FMXComp.Properties.Add('TextSettings');
  FMXComp.Properties.Add('WordWrap');
  FMXComp.Events.Add('OnChange');
  FMXComp.Events.Add('OnDblClick');
  AFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TListBox';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('Items');
  FMXComp.Properties.Add('ItemHeight');
  FMXComp.Properties.Add('MultiSelect');
  FMXComp.Events.Add('OnChange');
  FMXComp.Events.Add('OnItemClick');
  AFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TComboBox';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('Items');
  FMXComp.Properties.Add('ItemHeight');
  FMXComp.Properties.Add('DropDownCount');
  FMXComp.Events.Add('OnChange');
  FMXComp.Events.Add('OnClosePopup');
  FMXComp.Events.Add('OnPopup');
  AFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TComboEdit';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('Items');
  FMXComp.Properties.Add('ItemHeight');
  FMXComp.Properties.Add('DropDownCount');
  FMXComp.Properties.Add('Text');
  FMXComp.Properties.Add('Hint');
  FMXComp.Properties.Add('ShowHint');
  FMXComp.Properties.Add('TabOrder');
  FMXComp.Properties.Add('Position');
  FMXComp.Properties.Add('Size');
  FMXComp.Properties.Add('Width');
  FMXComp.Properties.Add('Height');
  FMXComp.Events.Add('OnChange');
  FMXComp.Events.Add('OnClosePopup');
  FMXComp.Events.Add('OnPopup');
  AFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TMemo';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('Lines');
  FMXComp.Properties.Add('ReadOnly');
  FMXComp.Properties.Add('WordWrap');
  FMXComp.Properties.Add('MaxLength');
  FMXComp.Events.Add('OnChange');
  AFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TImage';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Additional';
  FMXComp.Properties.Add('Bitmap');
  FMXComp.Properties.Add('WrapMode');
  FMXComp.Properties.Add('DisableInterpolation');
  AFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TTabControl';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('Tabs');
  FMXComp.Properties.Add('TabIndex');
  FMXComp.Properties.Add('TabPosition');
  FMXComp.Events.Add('OnChange');
  AFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TTabItem';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('Text');
  FMXComp.Properties.Add('IsSelected');
  AFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TGrid';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('RowCount');
  FMXComp.Properties.Add('ColumnCount');
  FMXComp.Properties.Add('DefaultRowHeight');
  FMXComp.Properties.Add('ShowScrollBars');
  FMXComp.Events.Add('OnCellClick');
  FMXComp.Events.Add('OnCellDblClick');
  AFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TStringGrid';
  FMXComp.ParentClass := 'TCustomGrid';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('RowCount');
  FMXComp.Properties.Add('ColumnCount');
  FMXComp.Properties.Add('DefaultRowHeight');
  FMXComp.Properties.Add('ShowScrollBars');
  FMXComp.Events.Add('OnCellClick');
  FMXComp.Events.Add('OnCellDblClick');
  AFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TLayout';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('EnableDrag');
  FMXComp.Properties.Add('HitTest');
  AFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TPanel';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('Align');
  FMXComp.Properties.Add('Anchors');
  FMXComp.Properties.Add('ClipChildren');
  FMXComp.Properties.Add('Height');
  FMXComp.Properties.Add('Hint');
  FMXComp.Properties.Add('Margins');
  FMXComp.Properties.Add('Opacity');
  FMXComp.Properties.Add('Padding');
  FMXComp.Properties.Add('Position');
  FMXComp.Properties.Add('ShowHint');
  FMXComp.Properties.Add('TabOrder');
  FMXComp.Properties.Add('Visible');
  FMXComp.Properties.Add('Width');
  AFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TGroupBox';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('Align');
  FMXComp.Properties.Add('Anchors');
  FMXComp.Properties.Add('ClipChildren');
  FMXComp.Properties.Add('Height');
  FMXComp.Properties.Add('Hint');
  FMXComp.Properties.Add('Margins');
  FMXComp.Properties.Add('Opacity');
  FMXComp.Properties.Add('Padding');
  FMXComp.Properties.Add('Position');
  FMXComp.Properties.Add('ShowHint');
  FMXComp.Properties.Add('StyledSettings');
  FMXComp.Properties.Add('TabOrder');
  FMXComp.Properties.Add('Text');
  FMXComp.Properties.Add('TextSettings');
  FMXComp.Properties.Add('WordWrap');
  FMXComp.Properties.Add('Visible');
  FMXComp.Properties.Add('Width');
  AFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TRectangle';
  FMXComp.ParentClass := 'TShape';
  FMXComp.Category := 'Shapes';
  FMXComp.Properties.Add('Fill');
  FMXComp.Properties.Add('Fill.Color');
  FMXComp.Properties.Add('Stroke');
  FMXComp.Properties.Add('Stroke.Color');
  FMXComp.Properties.Add('Corners');
  FMXComp.Properties.Add('Sides');
  FMXComp.Properties.Add('XRadius');
  FMXComp.Properties.Add('YRadius');
  AFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TCircle';
  FMXComp.ParentClass := 'TShape';
  FMXComp.Category := 'Shapes';
  FMXComp.Properties.Add('Fill');
  FMXComp.Properties.Add('Fill.Color');
  FMXComp.Properties.Add('Stroke');
  FMXComp.Properties.Add('Stroke.Color');
  AFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TScrollBox';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('ShowScrollBars');
  FMXComp.Properties.Add('AniCalculations');
  AFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TMenuBar';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('Items');
  AFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TMenuItem';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('Text');
  FMXComp.Properties.Add('Items');
  FMXComp.Events.Add('OnClick');
  AFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TPopupMenu';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('Items');
  FMXComp.Properties.Add('PopupComponent');
  AFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TTimer';
  FMXComp.ParentClass := 'TComponent';
  FMXComp.Category := 'System';
  FMXComp.Properties.Add('Interval');
  FMXComp.Properties.Add('Enabled');
  FMXComp.Events.Add('OnTimer');
  AFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TOpenDialog';
  FMXComp.ParentClass := 'TComponent';
  FMXComp.Category := 'Dialogs';
  FMXComp.Properties.Add('FileName');
  FMXComp.Properties.Add('Filter');
  FMXComp.Properties.Add('DefaultExt');
  FMXComp.Properties.Add('Title');
  FMXComp.Events.Add('OnClose');
  AFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TSaveDialog';
  FMXComp.ParentClass := 'TComponent';
  FMXComp.Category := 'Dialogs';
  FMXComp.Properties.Add('FileName');
  FMXComp.Properties.Add('Filter');
  FMXComp.Properties.Add('DefaultExt');
  FMXComp.Properties.Add('Title');
  FMXComp.Events.Add('OnClose');
  AFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TColorDialog';
  FMXComp.ParentClass := 'TComponent';
  FMXComp.Category := 'Dialogs';
  FMXComp.Properties.Add('Color');
  FMXComp.Events.Add('OnClose');
  AFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TActionList';
  FMXComp.ParentClass := 'TComponent';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('Actions');
  AFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TAction';
  FMXComp.ParentClass := 'TComponent';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('AutoCheck');
  FMXComp.Properties.Add('Text');
  FMXComp.Properties.Add('ShortCut');
  FMXComp.Properties.Add('SecondaryShortCuts');
  FMXComp.Properties.Add('Enabled');
  FMXComp.Properties.Add('Checked');
  FMXComp.Properties.Add('GroupIndex');
  FMXComp.Properties.Add('HelpContext');
  FMXComp.Properties.Add('HelpKeyword');
  FMXComp.Properties.Add('HelpType');
  FMXComp.Properties.Add('Hint');
  FMXComp.Properties.Add('ImageIndex');
  FMXComp.Properties.Add('Visible');
  FMXComp.Events.Add('OnExecute');
  FMXComp.Events.Add('OnUpdate');
  FMXComp.Events.Add('OnHint');
  AFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TImageList';
  FMXComp.ParentClass := 'TComponent';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('Source');
  FMXComp.Properties.Add('Size');
  FMXComp.Properties.Add('Bitmap');
  AFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TSplitter';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('ResizeControl');
  FMXComp.Properties.Add('ResizeStyle');
  AFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TStatusBar';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('Panels');
  AFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TToolBar';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('Items');
  AFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TBindNavigator';
  FMXComp.ParentClass := 'TLayout';
  FMXComp.Category := 'DataBinding';
  FMXComp.Properties.Add('DataSource');
  FMXComp.Properties.Add('VisibleButtons');
  FMXComp.Properties.Add('BeforeAction');
  FMXComp.Properties.Add('Hint');
  FMXComp.Properties.Add('ShowHint');
  FMXComp.Properties.Add('TabOrder');
  FMXComp.Properties.Add('Position');
  FMXComp.Properties.Add('Size');
  FMXComp.Properties.Add('Width');
  FMXComp.Properties.Add('Height');
  FMXComp.Events.Add('BeforeAction');
  FMXComp.Events.Add('OnClick');
  AFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TProgressBar';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('Value');
  FMXComp.Properties.Add('Min');
  FMXComp.Properties.Add('Max');
  AFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TTrackBar';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('Value');
  FMXComp.Properties.Add('Min');
  FMXComp.Properties.Add('Max');
  FMXComp.Properties.Add('Orientation');
  FMXComp.Properties.Add('Anchors');
  FMXComp.Events.Add('OnChange');
  FMXComp.Events.Add('OnDblClick');
  AFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TSpinBox';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('Value');
  FMXComp.Properties.Add('Min');
  FMXComp.Properties.Add('Max');
  FMXComp.Properties.Add('Frequency');
  FMXComp.Events.Add('OnChange');
  AFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TDateEdit';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('Date');
  FMXComp.Properties.Add('ShowClearButton');
  FMXComp.Properties.Add('ShowToday');
  FMXComp.Events.Add('OnChange');
  AFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TCalendar';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('Date');
  FMXComp.Properties.Add('FirstDayOfWeek');
  FMXComp.Properties.Add('ShowToday');
  FMXComp.Events.Add('OnChange');
  AFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TTreeView';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('Items');
  FMXComp.Events.Add('OnChange');
  FMXComp.Events.Add('OnItemClick');
  AFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TListView';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('Items');
  FMXComp.Properties.Add('ItemAppearance');
  FMXComp.Properties.Add('EditMode');
  FMXComp.Events.Add('OnChange');
  FMXComp.Events.Add('OnItemClick');
  AFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TWebBrowser';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('URL');
  FMXComp.Events.Add('OnDidFinishLoad');
  FMXComp.Events.Add('OnDidStartLoad');
  FMXComp.Events.Add('OnDidFailLoad');
  AFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TShape';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Shapes';
  FMXComp.Properties.Add('Fill');
  FMXComp.Properties.Add('Fill.Color');
  FMXComp.Properties.Add('Stroke');
  FMXComp.Properties.Add('Stroke.Color');
  FMXComp.Properties.Add('ShapeType');
  AFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TLine';
  FMXComp.ParentClass := 'TShape';
  FMXComp.Category := 'Shapes';
  FMXComp.Properties.Add('LineType');
  FMXComp.Properties.Add('Stroke');
  FMXComp.Properties.Add('Stroke.Color');
  AFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TScrollBar';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('Value');
  FMXComp.Properties.Add('Min');
  FMXComp.Properties.Add('Max');
  FMXComp.Properties.Add('Orientation');
  FMXComp.Events.Add('OnChange');
  AFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TSpeedButton';
  FMXComp.ParentClass := 'TButton';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('Images');
  FMXComp.Properties.Add('ImageIndex');
  FMXComp.Properties.Add('GroupName');
  FMXComp.Properties.Add('Down');
  FMXComp.Properties.Add('TextSettings');
  FMXComp.Properties.Add('WordWrap');
  AFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TMediaPlayer';
  FMXComp.ParentClass := 'TFmxObject';
  FMXComp.Category := 'Media';
  FMXComp.Properties.Add('FileName');
  FMXComp.Properties.Add('Duration');
  FMXComp.Properties.Add('CurrentTime');
  FMXComp.Properties.Add('Volume');
  FMXComp.Properties.Add('State');
  AFMXComponents.Add(FMXComp);
end;

end.

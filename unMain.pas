unit unMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, VclTee.TeeGDIPlus, VCLTee.TeEngine,
  VCLTee.Series, Vcl.ExtCtrls, VCLTee.TeeProcs, VCLTee.Chart, VCLTee.TeeFunci,
  Vcl.StdCtrls, unApiContour, Vcl.FileCtrl, System.Generics.Collections, System.StrUtils, System.IOUtils;

type
    TFuncMakeTitle = reference to function (a: IContourBit): string;

    TFormMain = class(TForm)
      chtMain: TChart;
      btnSelectDirectory: TButton;
      btnCutContours: TButton;
      grpRect: TGroupBox;
      pnlControl: TPanel;
      splMain: TSplitter;
      btnSaveContours: TButton;
      lblX1: TLabel;
      lblX2: TLabel;
      lblY1: TLabel;
      lblY2: TLabel;
      edtX1: TEdit;
      edtX2: TEdit;
      edtY1: TEdit;
      edtY2: TEdit;
      flsvdlgMain: TFileSaveDialog;
      chkExcludeReplay: TCheckBox;
      procedure FormCreate(Sender: TObject);
      procedure btnSelectDirectoryClick(Sender: TObject);
      procedure btnSaveContoursClick(Sender: TObject);
      procedure FormDestroy(Sender: TObject);
      procedure btnCutContoursClick(Sender: TObject);
    private
      { Private declarations }
      FLineSeries: TLineSeries;
      contours: IContours;
      fCounterBit: Integer;
      /// <summary>
      /// Список уже отрисованных
      /// </summary>
      fDrawingContourBit: TList<IContourBit>;

      FContourSave: IContour;

      /// <summary>
      /// Прямоугольник
      /// </summary>
      function getWindowRect: TRect_Float;

      /// <summary>
      /// Определяет заголовок ломаной по контур-биту для основых графиков
      /// </summary>
      function makeTitleMain(aContourBit: IContourBit): string;

      /// <summary>
      /// Определяет заголовок ломаной по контур-биту для обрезанных графиков
      /// </summary>
      function makeTitleCut(aContourBit: IContourBit): string;

      procedure loadOnChart;
      procedure drawContour(aContour: IContour; aWidthLine: Integer = 1; aRandomColor: Boolean = False; aColorLine: TColor = clRed; aRefMakeTitle: TFuncMakeTitle = nil);
      procedure drawContourBit(aContourBit: IContourBit; aWidthLine: Integer = 1; aRandomColor: Boolean = False; aColorLine: TColor = clRed; aRefMakeTitle: TFuncMakeTitle = nil);
    public
      { Public declarations }
    end;

var
  FormMain: TFormMain;

implementation

{$R *.dfm}

procedure TFormMain.btnCutContoursClick(Sender: TObject);
var
    cutSeries: TLineSeries;
    r: TRect_Float;
    contour: IContour;
    contourBitIterOuter: IContourBit;
    idxContourBit: Integer;
begin
    cutSeries := TLineSeries.Create(chtMain);
    cutSeries.XValues.Order := loNone;
    cutSeries.LinePen.Width := 2;

    r := getWindowRect;

    cutSeries.AddXY(r.x1, r.y1, '', clRed);
    cutSeries.AddXY(r.x2, r.y1, '', clRed);
    cutSeries.AddXY(r.x2, r.y2, '', clRed);
    cutSeries.AddXY(r.x1, r.y2, '', clRed);
    cutSeries.AddXY(r.x1, r.y1, '', clRed);
    cutSeries.Title := 'Граница';
    chtMain.AddSeries(cutSeries);

    FContourSave := CutContoursByWindow(contours, r);

    drawContour(FContourSave, 4, False, clRed, makeTitleCut);

    btnSaveContours.Enabled := True;
end;

procedure TFormMain.btnSaveContoursClick(Sender: TObject);
var
    contourBit: IContourBit;
    idxContourBit, idxPoint: Integer;
    point: IContourPoint;
begin
    if flsvdlgMain.Execute then begin
        flsvdlgMain.FileName;

        idxContourBit := 0;
        while idxContourBit < FContourSave.getContourBitCount do begin
            contourBit := FContourSave.getContourBit(idxContourBit);
            idxPoint := 0;
            while idxPoint < contourBit.getPointCount do begin
                point := contourBit.getPoint(idxPoint);
                point.getX;
                point.getY;
                TFIle.AppendAllText(flsvdlgMain.FileName, Format('%g %g'#13#10, [point.getX, point.getY]));

                Inc(idxPoint);
            end;
            Inc(idxContourBit);
        end;

    end;
end;

procedure TFormMain.btnSelectDirectoryClick(Sender: TObject);
var
    directory: string;
begin
    if SelectDirectory(directory, [sdAllowCreate, sdPerformCreate, sdPrompt], 1000) then begin
        contours := nil;
        contours := contoursFromDir(directory);

        loadOnChart;

//        contours := nil;

        btnCutContours.Enabled := True;
    end;
end;

procedure TFormMain.drawContour(aContour: IContour; aWidthLine: Integer; aRandomColor: Boolean; aColorLine: TColor; aRefMakeTitle: TFuncMakeTitle);
var
    idxPoint, idxBitContours: Integer;
    point: IContourPoint;
    se: TLineSeries;
    clr: TColor;
    contourBit: IContourBit;
begin
    Randomize;
    if aRandomColor then
        clr := RGB(Random(255), Random(255), Random(255))
    else
        clr := aColorLine;

    idxBitContours := 0;

    while idxBitContours < aContour.getContourBitCount do begin
        contourBit := aContour.getContourBit(idxBitContours);

        idxPoint := 0;
        se := TLineSeries.Create(chtMain);
        se.XValues.Order := loNone;
        se.LinePen.Width := aWidthLine;

        if Assigned(aRefMakeTitle) then
            se.Title := aRefMakeTitle(contourBit);

        chtMain.AddSeries(se);

        while idxPoint < contourBit.getPointCount do begin
            point := contourBit.getPoint(idxPoint);
            se.AddXY(point.getX, point.getY, '', clr);
            Inc(idxPoint);
        end;

        Inc(idxBitContours);
    end;
end;

procedure TFormMain.drawContourBit(aContourBit: IContourBit;
  aWidthLine: Integer; aRandomColor: Boolean; aColorLine: TColor;
  aRefMakeTitle: TFuncMakeTitle);
var
    idxPoint: Integer;
    point: IContourPoint;
    se: TLineSeries;
    clr: TColor;
begin
    Randomize;
    if aRandomColor then
        clr := RGB(Random(255), Random(255), Random(255))
    else
        clr := aColorLine;

    idxPoint := 0;
    se := TLineSeries.Create(chtMain);
    se.XValues.Order := loNone;
    se.LinePen.Width := aWidthLine;

    if Assigned(aRefMakeTitle) then
        se.Title := aRefMakeTitle(aContourBit);

    chtMain.AddSeries(se);

    while idxPoint < aContourBit.getPointCount do begin
        point := aContourBit.getPoint(idxPoint);
        se.AddXY(point.getX, point.getY, '', clr);
        Inc(idxPoint);
    end;
end;

procedure TFormMain.FormCreate(Sender: TObject);
begin
    Caption := 'Главная форма';
    dictExt := TDictionary<IContourBit, TRecExt>.Create();
    flsvdlgMain.DefaultFolder := ExtractFileDir(Application.ExeName);
end;

procedure TFormMain.FormDestroy(Sender: TObject);
begin
    dictExt.free;
end;

function TFormMain.getWindowRect: TRect_Float;
begin
    Result.x1 := Double.Parse(edtX1.Text);
    Result.x2 := Double.Parse(edtX2.Text);
    Result.y1 := Double.Parse(edtY1.Text);
    Result.y2 := Double.Parse(edtY2.Text);
end;

procedure TFormMain.loadOnChart;
var
    idxContours: Integer;
    listContourBit: TList<IContourBit>;
    contour: IContour;
    contourBit: IContourBit;
    idxContour, idxContourBit: Integer;

    procedure add(aContourBit: IContourBit);
    begin
        if Assigned(listContourBit) then begin
            listContourBit.Add(aContourBit);
        end;
    end;

    function containInList(aContourBit: IContourBit): Boolean;
    var
        point1, point2: IContourPoint;
        idxPoint: Integer;
        contourBitIter: IContourBit;
        flag: Boolean;
    begin
        if not Assigned(listContourBit) then
            Exit(False);

        for contourBitIter in listContourBit do begin
            if contourBitIter.getPointCount <> aContourBit.getPointCount then
                Continue;

            idxPoint := 0;

            flag := True;

            while idxPoint < aContourBit.getPointCount do begin
                point1 := aContourBit.getPoint(idxPoint);
                point2 := contourBitIter.getPoint(idxPoint);
                if (point1.getX <> point2.getX) or (point1.getY <> point2.getY) then begin
                    flag := False;
                    break;
                end;

                Inc(idxPoint);
            end;

            if flag then
                Exit(True);
        end;

        Result := False;
    end;
begin
    chtMain.RemoveAllSeries;

    idxContours := 0;
    fCounterBit := 1;

    if chkExcludeReplay.Checked then
        listContourBit := TList<IContourBit>.Create
    else
        listContourBit := nil;

    while idxContours < contours.getContourCount do begin
        contour := contours.getContour(idxContours);

        idxContourBit := 0;
        while idxContourBit < contour.getContourBitCount do begin
            contourBit := contour.getContourBit(idxContourBit);
            if not containInList(contourBit) then begin
                drawContourBit(contourBit, 1, True, clRed, makeTitleMain);
                add(contourBit);
            end;
            Inc(idxContourBit);
        end;

        Inc(idxContours);
    end;

    if Assigned(listContourBit) then begin
        listContourBit.Clear;
        listContourBit.Free;
    end;
end;

function TFormMain.makeTitleCut(aContourBit: IContourBit): string;
begin
    Result := Format('cBit_%d', [fCounterBit]);
    Inc(fCounterBit);
end;

function TFormMain.makeTitleMain(aContourBit: IContourBit): string;
var
    recExt: TRecExt;
begin
    if dictExt.TryGetValue(aContourBit, recExt) then
        Result := recExt.name.Replace('Горные отводы_1#', '').Replace('.ktr', '') + IfThen(aContourBit.isClosed, '(закр)', '')
    else
        Result := '';
end;

end.

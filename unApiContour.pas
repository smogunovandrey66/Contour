unit unApiContour;

interface

uses
    System.Classes, System.SysUtils, System.IOUtils, System.Types,
    System.Generics.Collections;

type
    TRect_Float = record // Прямоугольник. Стороны параллельны осям координат.
        x1, y1, x2, y2: double; // Для простоты гарантируется что X1<X2, Y1<Y2
    end;

    /// <summary>
    /// Тип точки по отношению к ограничиваемому прямоугольнику:
    ///  -внутри
    ///  -на границе
    ///  -вне границы
    /// </summary>
    TTypePoint = (tpInRect, tpOnBorder, tpOutRect);

    IContourPoint = interface // точка
        function getX: double;
        function getY: double;
    end;

    IContourBit = interface // фрагмент контура
        function getPointCount: integer; // количество точек в фрагменте
        function isClosed: Boolean; //флажок замкнутости контура. True – последняя точка соединена с первой.
        function getPoint(const idx: integer): IContourPoint; // nil если (idx < 0) or (idx >= GetPointCount)
    end;

    IContour = interface // контур. состоит из нескольких фрагментов
        function getContourBitCount: integer; // количество фрагментов
        function getContourBit(const idx: integer): IContourBit;
    end;

    IContours = interface // коллекция контуров
        function getContourCount: integer;
        function getContour(const idx: integer): IContour;
    end;

    IContourEdit = interface(IContour)
        procedure AddContourBit(const bit: IContourBit); //Добавляет контурбит в контур
    end;

    IContourBitEdit = interface(IContourBit)
        procedure AddPoint(const x, y, value: double); //Value всегда должно быть = 0
        procedure SetClosed(const closed: boolean);
    end;

    TContourPoint = class(TInterfacedObject, IContourPoint)
    public
        constructor Create(x, y: double);
        destructor Destroy; override;
    private
        Fx, Fy: double; //координаты точки
    protected
        function getX: double;
        function getY: double;
    end;

    TContours = class(TInterfacedObject, IContours)
    public
        constructor Create;
        destructor Destroy; override;
    private
        FItems: IInterfaceList; //список указателей на контуры
    public
        function getContourCount: integer;
        function getContour(const idx: integer): IContour;
        procedure addContour(const contour: IContour);
    end;

    TContourBitEdit = class(TInterfacedObject, IContourBit, IContourBitEdit)
    public
        constructor Create;
        destructor Destroy; override;
    private
        FItems: IInterfaceList;
        FClosed: boolean;
    public //IContourBit
        function getPointCount: integer; // количество точек в фрагменте
        function isClosed: boolean; //флажок замкнутости контура. True – последняя точка соединена с первой.
        function getPoint(const idx: integer): IContourPoint; // nil если (idx < 0) or (idx >= getPointCount)
    public //IContourBitEdit
        procedure addPoint(const x, y, value: double); //Value всегда должно быть = 0
        procedure setClosed(const closed: boolean);
    end;

    TContourEdit = class(TInterfacedObject, IContour, IContourEdit)
    public
        constructor Create();
        destructor Destroy; override;
    private
        FItems: TInterfaceList;
    private //IContour
        function getContourBitCount: integer; // количество фрагментов
        function getContourBit(const idx: integer): IContourBit;
    private//IContourEdit
        procedure addContourBit(const bit: IContourBit); //Добавляет контурбит в контур
    end;

    TRecExt = record
      name: string;
    end;

    THelperTRec_Float = record helper for TRect_Float
        public
            /// <summary>
            /// Входит ли точка в прямоугольник
            /// </summary>
            function containStrict(aPoint: IContourPoint): Boolean;
            /// <summary>
            /// Пересекается ли отрезок, заданный двумя точками, с одной из сторон прямоугольника
            /// </summary>
            function crossCount(aPoint1: IContourPoint; aPoint2: IContourPoint): Integer; overload;

            /// <summary>
            /// Количество пересечений с
            /// </summary>
//            function crossCount(aPoint1: IContourPoint; aPoint2: IContourPoint): Integer;

            /// <summary>
            /// Определение типа точки по отношению к прямоугольнику
            /// </summary>
            function typePoint(aPoint: IContourPoint): TTypePoint;
    end;

    /// <summary>
    /// Точка вещественных координат
    /// </summary>
    TPointD = record
            x: Double;
            y: Double;
        public
            constructor Create(x, y: Double);
    end;

    /// <summary>
    /// Хелпер для списка вещественных точек
    /// </summary>
    THelperListPoint = class helper for TList<TPointD>
        function toContourBit: IContourBit;
        function contains(x, y: Double): Boolean; overload;
        procedure add(aPoint: IContourPoint); overload;
    end;

var
    //Дополнительная информация о контур-бите. Например, имя соответствующего файла.
    dictExt: TDictionary<IContourBit, TRecExt>;

    /// <summary>
    /// Загрузка данных из папки
    /// </summary>
    function contoursFromDir(aPath: string): IContours;

    /// <summary>
    /// Функция должна вернуть IContour, состоящий из отрезков входящих контуров, которые (отрезки)
    /// попадают внутрь заданного окна, либо пересекают/касаются его границ.
    /// </summary>
    function CutContoursByWindow(const cntrs: IContours; const window: TRect_Float): IContour;

    /// <summary>
    /// Вспомогательная функция, определения пересечения двух отрезков,
    /// заданных каждый двумя точками.
    /// https://ru.wikipedia.org/wiki/Пересечение_(евклидова_геометрия)#Два_отрезка
    /// </summary>
    function cross2(x1, y1, x2, y2, x3, y3, x4, y4: Double): Boolean;

implementation

function contoursFromDir(aPath: string): IContours;
var
    files, lines: TStringDynArray;
    oneFile, line: string;
    i: Integer;
    splitter: TStrings;
    contourBit: TContourBitEdit;
    contourEdit: TContourEdit;
    contours: TContours;
    recExt: TRecExt;
begin
    contours := TContours.Create;
    splitter := TStringList.Create;
    splitter.Delimiter := ' ';
    dictExt.Clear;

    files := TDirectory.GetFiles(aPath, '*.ktr');
    for oneFile in files do begin
        lines := TFile.ReadAllLines(oneFile);
        i := 1;
        contourBit := TContourBitEdit.Create;
        while i < Length(lines) do begin
            line := lines[i];
            splitter.Clear;
            splitter.DelimitedText := line;
            contourBit.addPoint(splitter[0].ToDouble, splitter[1].ToDouble, 0);
            Inc(i);
        end;
        contourEdit := TContourEdit.Create;
        recExt.name := TPath.GetFileName(oneFile);
        dictExt.Add(contourBit, recExt);
        contourEdit.addContourBit(contourBit);
        contours.addContour(contourEdit);
    end;
    Result := contours;
    splitter.Free;
end;

function CutContoursByWindow(const cntrs: IContours; const window: TRect_Float): IContour;
var
    contourRes: TContourEdit;
    idxContour, idxContourBit, idxPoint: Integer;
    contourIter: IContour;
    contourBitIter: IContourBit;
    pointIter, pointNext: IContourPoint;
    contourBitRes: TContourBitEdit;
    curListBit: TList<TPointD>;
    tp: TTypePoint;

    //flush contourBit
    procedure freeCurList;
    begin
      if Assigned(curListBit) then begin
        contourRes.addContourBit(curListBit.toContourBit);
        FreeAndNil(curListBit);
      end;

    end;

    procedure addPoint(aPoint: IContourPoint); overload;
    begin
      if not Assigned(curListBit) then
        curListBit := TList<TPointD>.Create;
      curListBit.add(aPoint);
    end;

    procedure addPoint(aPoints: array of IContourPoint); overload;
    var
        pnt: IContourPoint;
    begin
      if not Assigned(curListBit) then
        curListBit := TList<TPointD>.Create;
      for pnt in aPoints do begin
        curListBit.add(pnt);
      end;
      Inc(idxPoint, Length(aPoints));
    end;
begin
    contourRes := TContourEdit.Create;

    idxContour := 0;
    while idxContour < cntrs.getContourCount do begin
        contourIter := cntrs.getContour(idxContour);
        idxContourBit := 0;
        contourBitRes := nil;
        curListBit := nil;

        while idxContourBit < contourIter.getContourBitCount do begin
            contourBitIter := contourIter.getContourBit(idxContourBit);
            idxPoint := 0;

            while  idxPoint < contourBitIter.getPointCount do begin
                pointIter := contourBitIter.getPoint(idxPoint);

                case window.typePoint(pointIter) of
                    tpInRect: begin
                        addPoint(pointIter);
                    end;
                    tpOnBorder: begin
                        pointNext := contourBitIter.getPoint(idxPoint + 1);
                        tp := window.typePoint(pointNext);

                        case tp of
                            tpInRect, tpOnBorder: begin
                                addPoint([pointIter, pointNext]);
                                Continue;
                            end;
                            tpOutRect: begin
                                if window.crossCount(pointIter, pointNext) > 1 then begin
                                    addPoint([pointIter, pointNext]);
                                    Continue;
                                end
                                    else begin
                                      freeCurList;
                                    end;

                            end;
                        end;

                    end;
                    tpOutRect: begin
                        //Вариант через следующую точку
                        pointNext := contourBitIter.getPoint(idxPoint + 1);
                        tp := window.typePoint(pointNext);
                        case tp of
                          tpInRect: begin
                            addPoint([pointIter, pointNext]);
                            Continue;
                          end;
                          tpOnBorder: begin
                            freeCurList;
                          end;
                          tpOutRect: begin
                            if window.crossCount(pointIter, pointNext) > 1 {хотя можно и 0} then begin
                                addPoint([pointIter, pointNext]);
                                Continue;
                            end
                                else
                                    freeCurList;

                          end;
                        end;

                        //Вариант через предыдущую точку
//                        pointPrev := contourBitIter.getPoint(idxPoint - 1);
//                        //Смотрим на предыдущую точку
//                        case window.typePoint(pointPrev) of
//                            ptInRect: begin
//                                curListBit.add(pointIter)
//                            end;
//                            ptOutRect: begin
//                                //Два случая: пересекает или нет прямоугольник
//
//                                //Пересекает прямоугольник
//                                if window.cross(pointIter, pointPrev) then begin
//                                    addPoint(pointIter);
//                                end
//                                    else begin // Предыдущая точка вне прямоугольника - значит обрыв
//                                        freeCurList;
//                                    end;
//                            end;
//                            ptOnBorder: begin
//                                //Обрыв
//                                freeCurList;
//                            end;
//                        end;
                    end;
                end;

                Inc(idxPoint);
            end;

            Inc(idxContourBit);
        end;

        freeCurList;

        Inc(idxContour);
    end;

    Result := contourRes;
end;


{ TContourPoint }

constructor TContourPoint.Create(x, y: double);//конструктор класса точки
begin
    Fx := x;
    Fy := y;
end;

destructor TContourPoint.Destroy;
begin

  inherited;
end;

function TContourPoint.getX: double; // получить x данной точки
begin
    result := Fx;
end;

function TContourPoint.getY: double; // получить x данной точки
begin
    result := Fy;
end;

{ TContours }

procedure TContours.addContour(const contour: IContour);
begin
    if contour = nil then
        exit;

    FItems.Add(contour);
end;

constructor TContours.Create;
begin
    inherited Create;

    FItems := TInterfaceList.Create;
end;

destructor TContours.Destroy;
var
    i: Integer;
begin
    for i := 0 to FItems.Count - 1 do begin
        FItems[i] := nil;
    end;

    FItems := nil;

    inherited;
end;

function TContours.getContour(const idx: integer): IContour;
begin
    if (idx >= 0) and (idx < getContourCount) then
        result := IContour(FItems[idx])
    else
        result := nil
end;

function TContours.getContourCount: integer;
begin
    result := FItems.Count;
end;

{ TContourEdit }

procedure TContourEdit.addContourBit(const bit: IContourBit);
begin
    FItems.Add(bit);
end;

constructor TContourEdit.Create;
begin
    inherited Create;

    FItems := TInterfaceList.Create;
end;

destructor TContourEdit.Destroy;
begin
    FreeAndNil(FItems);

    inherited;
end;

function TContourEdit.getContourBit(const idx: integer): IContourBit;
begin
    if (idx < 0) or (idx >= FItems.Count) then
        Exit(nil);
    result := IContourBit(FItems[idx]);
end;

function TContourEdit.getContourBitCount: integer;
begin
    result := FItems.Count;
end;

{ TContourBitEdit }

procedure TContourBitEdit.addPoint(const x, y, value: double);
var
    pt: IContourPoint;
begin
    pt := TContourPoint.Create(x, y);
    FItems.Add(pt);
end;

constructor TContourBitEdit.Create();
begin
    inherited Create;
    FItems := TInterfaceList.Create;
end;

destructor TContourBitEdit.Destroy;
var
    i: Integer;
begin
    for i := 0 to FItems.Count - 1 do begin
        FItems[i] := nil;
    end;

    FItems := nil;

    inherited;
end;

function TContourBitEdit.getPoint(const idx: integer): IContourPoint;
begin
    if (idx < 0) or (idx >= FItems.Count) then
        Exit(nil);

    result := IContourPoint(FItems[idx]);
end;

function TContourBitEdit.getPointCount: integer;
begin
    result := FItems.Count;
end;

function TContourBitEdit.isClosed: boolean;
var
    pointFirst, pointLast: IContourPoint;
begin
    if FItems.Count > 1 then begin
        pointFirst := getPoint(0);
        pointLast := getPoint(FItems.Count - 1);
        Result := (pointFirst.getX = pointLast.getX) and (pointFirst.getY = pointLast.getY);
    end
        else
            Result := False;
end;

procedure TContourBitEdit.setClosed(const closed: boolean);
begin
    FClosed := closed;
end;

{ THelperTRec_Float }

function THelperTRec_Float.containStrict(aPoint: IContourPoint): Boolean;
var
    x, y: Double;
begin
  x := aPoint.getX;
  y := aPoint.getY;

  Result := (x > x1) and (x < x2) and
            (y > y1) and (y < y2);
end;

/// <summary>
/// Вспомогательная функция, определения пересечения двух отрезков,
/// заданных каждый двумя точками.
/// </summary>
function cross2(x1, y1, x2, y2, x3, y3, x4, y4: Double): Boolean;
var
    den{denominator}, s, t, upT, upS: Double;
begin
    den := (x4 - x3) * (y2 - y1) - (y4 - y3) * (x2 - x1);
    upT := (x2 - x1) * (y3 - y1) - (x3 - x1) * (y2 - y1);
    upS := (y3 - y1) * (x4 - x3) + (x1 - x3) * (y4 - y3);

    //Пока считаем, что параллельность и включение(наложение, по сути параллельные отрезки),
    //не является пересечением. Закоментировать при такой необходимости.
     if den = 0 then
        Exit(False);

    if den = 0 then begin
        if (upT <> 0) or (upT <> 0) then // Отрезки параллельны и лежать не на одной линии
            Exit(False);

        //Проверяем являются ли продолжением друг друга отрезки
        Exit(
            //Х
            (((x1 >= x3) and (x1 <= x4)) or ((x2 >= x3) and (x2 <= x4)))
            //и Y
            and
            (((y1 >= y3) and (y1 <= y4)) or ((y2 >= y3) and (y2 <= y4)))
        );
    end;

    //Далее как в https://ru.wikipedia.org/wiki/Пересечение_(евклидова_геометрия)#Два_отрезка

    t := upT / den;
    s := upS / den;

    Result := (t >= 0) and (t <= 1) and (s >= 0) and (s <= 1);
end;

function THelperTRec_Float.crossCount(aPoint1, aPoint2: IContourPoint): Integer;
var
    x3, y3, x4, y4: Double;
begin
    Result := 0;
    if (aPoint1 = nil) or (aPoint2 = nil) then
        Exit;

    x3 := aPoint1.getX;
    y3 := aPoint1.getY;
    x4 := aPoint2.getX;
    y4 := aPoint2.getY;

    if cross2(x3, y3, x4, y4, x1, y1, x2, y1) then
        Inc(Result);

    if cross2(x3, y3, x4, y4, x2, y1, x2, y2) then
        Inc(Result);

    if cross2(x3, y3, x4, y4, x1, y2, x2, y2) then
        Inc(Result);

    if cross2(x3, y3, x4, y4, x1, y1, x1, y2) then
        Inc(result);
end;

function THelperTRec_Float.typePoint(aPoint: IContourPoint): TTypePoint;
var
    x, y: Double;
begin
    if aPoint = nil then
        Exit(tpOutRect);

    x := aPoint.getX;
    y := aPoint.getY;

    if containStrict(aPoint) then
        Result := tpInRect
    else if ((x < x1) or (x > x2)) or ((y > y2) or (y < y1)) then
        Result := tpOutRect
            else
                Result := tpOnBorder;

end;

{ TPointD }

constructor TPointD.Create(x, y: Double);
begin
  Self.x := x;
  Self.y := y;
end;


{ THelperListPoint }

function THelperListPoint.toContourBit: IContourBit;
var
    res: TContourBitEdit;
    point: TPointD;
begin
    Result := nil;
    if Count = 0 then
        Exit;

    res := TContourBitEdit.Create;

    for point in Self do begin
        res.addPoint(point.X, point.Y, 0);
    end;

    Result := res;
end;

function THelperListPoint.contains(x, y: Double): Boolean;
begin
    Result := Contains(TPointD.Create(x, y));
end;

procedure THelperListPoint.add(aPoint: IContourPoint);
begin
    add(TPointD.Create(aPoint.getX, aPoint.getY));
end;

var
    list: TList<TPointD>;
    p: tpointD;
    b: boolean;
    x1, y1, x2, y2, x3, y3, x4, y4: Double;

initialization
    x1 := 1;
    y1 := -1;
    x2 := 1;
    y2 := 1;

    x3 := 1;
    y3 := 1;
    x4 := 1;
    y4 := 4;

    b := cross2(x1, y1, x2, y2, x3, y3, x4, y4);

    list := Tlist<TPointD>.Create;
    list.Add(TPointD.Create(1, 1));
    p.X := 1;
    p.Y := 1.3;
    b := list.Contains(1, 1.00001);

    b := false;


end.

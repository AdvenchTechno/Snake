uses GraphABC, Timers;

type
  PNode = ^TNode;
  TNode = record
    x, y: integer;
    color: Color;
    Next: PNode;
  end;

var
  Head, Food: PNode;
  Direction: (Up, Down, Left, Right);
  GameOver: boolean;
  Score: integer;
  Speed: integer;
  GameTimer: Timer;
  ExitRequested: boolean;

procedure InitializeGame;
begin
  // Создаем голову змейки
  New(Head);
  Head^.x := Window.Width div 2;
  Head^.y := Window.Height div 2;
  Head^.color := RGB(255, 0, 0); // Красная голова
  Head^.Next := nil;
  

  // Создаем первый сегмент тела
  New(Head^.Next);
  Head^.Next^.x := Head^.x - 20;
  Head^.Next^.y := Head^.y;
  Head^.Next^.color := RGB(255, 0, 0); 
  Head^.Next^.Next := nil;

  // Создаем еду на поле 
  New(Food);
  Food^.x := Random(Window.Width - 20) + 10;
  Food^.y := Random(Window.Height - 20) + 10;
  Food^.color := clYellow;
  Food^.Next := nil;

  // Начальные настройки
  Direction := Right;
  GameOver := False;
  ExitRequested := False; //для Esc корректный выброс
  Score := 0;
  Speed := 150;

  // Настройка окна
  Window.Title := 'Разноцветная змейка';
  Window.SetSize(800, 600);
  Window.IsFixedSize := True;
  Window.Clear(clYellow); // Темно-зеленый 
end;

//еда 
procedure GenerateFood;
var
  Current: PNode;
  Collision: boolean;
begin
  repeat
    Collision := False;                                          //флаг который сбрасывается перед каждой попыткой
    Food^.x := Random(Window.Width - 20) + 10;
    Food^.y := Random(Window.Height - 20) + 10;

                                     //проверка пересечения еды и змейки
    Current := Head;
    while Current <> nil do
    begin
      if (Abs(Current^.x - Food^.x) < 20) and (Abs(Current^.y - Food^.y) < 20) then
        Collision := True;
      Current := Current^.Next;
    end;
  until not Collision;
end;

//премещение змейки на один шаг
procedure MoveSnake;
var
  NewHead, Current: PNode;
begin
  // память под головуновоую
  New(NewHead);
  NewHead^.Next := Head;
  NewHead^.x := Head^.x;
  NewHead^.y := Head^.y;

  // Движение
  case Direction of //зависит от изначального положения
    Up: Dec(NewHead^.y, 20);
    Down: Inc(NewHead^.y, 20);
    Left: Dec(NewHead^.x, 20);
    Right: Inc(NewHead^.x, 20);
  end;

  // Границы
  if (NewHead^.x < 0) or (NewHead^.x > Window.Width) or
     (NewHead^.y < 0) or (NewHead^.y > Window.Height) then
  begin
    LockDrawing;
    //Window.Close;
    GameOver := True;
    // SetFontColor(clWhite);
    SetFontSize(24);
    //   Window.Title := 'Разноцветная змейка';
  Window.SetSize(800, 600);
  Window.IsFixedSize := True;
  Window.Clear(clForestGreen);
    //  TextOut(Window.Width div 2 - 100, Window.Height div 2 - 15, 'Игра окончена!');
    //  TextOut(Window.Width div 2 - 50, Window.Height div 2 + 15, 'Счет: ' + IntToStr(Score));
      Sleep(3000);
    Exit;
  end;

                                      // Проверка столкновения с собой (начинаем со второго сегмента)
  Current := Head^.Next;
  while Current <> nil do
  begin
    if (NewHead^.x = Current^.x) and (NewHead^.y = Current^.y) then
    begin
      GameOver := True;
       SetFontColor(clWhite);
      SetFontSize(24);
      TextOut(Window.Width div 2 - 100, Window.Height div 2 - 15, 'Игра окончена!');
      TextOut(Window.Width div 2 - 50, Window.Height div 2 + 15, 'Счет: ' + IntToStr(Score));
      Sleep(3000);
      Exit;
    end;
    Current := Current^.Next;
  end;

  // Проверка съедения еды
  if (Abs(NewHead^.x - Food^.x) < 15) and (Abs(NewHead^.y - Food^.y) < 15) then
  begin
    Inc(Score);
    if Speed > 50 then Dec(Speed, 5);

    // Добавляем новый кусочек 
    New(Current);
    Current^.Next := Head;
    Current^.color := RGB(Random(256), Random(256), Random(256));
    Head := Current;

    GenerateFood;
  end
  else
  begin
    // Удаляем хвост если не съела еду
    Current := Head;
    while Current^.Next^.Next <> nil do
      Current := Current^.Next;
    Dispose(Current^.Next);
    Current^.Next := nil;
  end;

  // новая голова
  NewHead^.color := RGB(255, 0, 0);
  Head := NewHead;
end;

procedure DrawGame;
var
  Current: PNode;
begin
  LockDrawing;
  Window.Clear(clForestGreen);

                           // отрисовка змеи 
  Current := Head;
  while Current <> nil do
  begin
    SetBrushColor(Current^.color);
    FillCircle(Current^.x, Current^.y, 10); //тело
    SetPenColor(clBlack); //контур
    Circle(Current^.x, Current^.y, 10);
    Current := Current^.Next;
  end;

  // Рисуем еду
  SetBrushColor(Food^.color);
  FillCircle(Food^.x, Food^.y, 10);
  SetPenColor(clBlack);
  Circle(Food^.x, Food^.y, 10);

  // Выводим счет
  SetFontColor(clBlack);
  SetFontSize(14);
  TextOut(10, 10, 'Счет: ' + IntToStr(Score));
  TextOut(10, 30, 'Скорость: ' + IntToStr(150 - Speed));

  Redraw;
end;

procedure KeyDown(Key: integer);
begin
  case Key of
    VK_Up: if Direction <> Down then Direction := Up;
    VK_Down: if Direction <> Up then Direction := Down;
    VK_Left: if Direction <> Right then Direction := Left;
    VK_Right: if Direction <> Left then Direction := Right;
    VK_Escape: ExitRequested := True;
  end;
end;
//управление игрой
procedure OnTimer;
begin
  if not GameOver and not ExitRequested then
  begin
    MoveSnake;
    DrawGame;
  end
  else
  begin
    GameTimer.Stop;
    Window.Close;
  end;
end;

begin
  InitializeGame;
  OnKeyDown := KeyDown;
  
  // Запускаем игровой таймер
  GameTimer := Timer.Create(Speed, OnTimer);
  GameTimer.Start;

end.
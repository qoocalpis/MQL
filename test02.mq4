//+------------------------------------------------------------------+
//|                                                       test02.mq4 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//メンバ初期値
datetime today = iTime(Symbol(), PERIOD_D1, 0);
datetime previousDay = iTime(Symbol(), PERIOD_D1, 1);
double previousHigh = 0;
double previousFiboHigh = 0;
double previousHurf = 0;
double previousFiboLow = 0;
double previousLow = 0;
 

//固定値
const long Chart_ID = ChartID();
const string previousDayName = "前日Opened時間";
const string todayName = "前日Closed時間";
const string HighLineName = "高値";
const string LowLineName = "安値";
const string HurfLineName = "半値";
const string FiboHighLineName = "61.8%";
const string FiboLowLineName = "38.2%";
const int FiboThreeWick = 2;


struct CandlestickInfo
  {
   double            open, close, high, low;
  };


//+------------------------------------------------------------------+
//| ラインを作成する                                                     |
//+------------------------------------------------------------------+
bool LineCreate
(
   const long            chart_ID,           // チャート識別子
   const string          name,               // 線の名称
   const double          price=0,            // 線の価格
   const datetime        time=0,             // 線の時間
   const int             sub_window=0,       // サブウィンドウ番号
   const color           clr=clrBlue,        // 線の色
   const ENUM_LINE_STYLE style=STYLE_SOLID,  // 線のスタイル
   const int             width=1,            // 線の幅
   const bool            back=false,         // 背景で表示する
   const bool            selection=false,    // 強調表示して移動
   const bool            hidden=true         // オブジェクトリストに隠す
)
  {
//--- エラー値をリセットする
   ResetLastError();

//--- 既に作成済みの場合falseを返す
   if(ObjectFind(chart_ID,name) > -1)
      return (false);

//--- 水平線を作成する
   if(price && !time && !ObjectCreate(chart_ID,name,OBJ_HLINE,sub_window,0,price))
     {
      Print(__FUNCTION__,
            ": failed to create a horizontal line! Error code = ",GetLastError());
      return(false);
     }

//--- 垂直線を作成する
   if(!price && time && !ObjectCreate(chart_ID,name,OBJ_VLINE,sub_window,time,0))
     {
      Print(__FUNCTION__,
            ": failed to create a vertical line! Error code = ",GetLastError());
      return(false);
     }
//--- 線の色を設定する
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- 線の表示スタイルを設定する
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style);
//--- 線の幅を設定する
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width);
//--- 前景（false）または背景（true）に表示
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- マウスで線を移動させるモードを有効（true）か無効（false）にする
//--- ObjectCreate 関数を使用してグラフィックオブジェクトを作成する際、オブジェクトは
//--- デフォルトではハイライトされたり動かされたり出来ない。このメソッド内では、選択パラメータは
//--- デフォルトでは true でハイライトと移動を可能にする。
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
//--- オブジェクトリストのグラフィックオブジェクトを非表示（true）か表示（false）にする
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- 実行成功
//   Print(name + "を引きました!");
   return(true);
  }


//+------------------------------------------------------------------+
//| 線を移動する                                                     |
//+------------------------------------------------------------------+
bool LineMove
(
   const long   chart_ID,   // チャート識別子
   const string name,       // 線の名称
   const double price=0,    // 線の価格
   datetime     time=0      // 線の時間
)
  {
//--- エラー値をリセットする
   ResetLastError();
//--- 水平線を移動する
   if(price && !time && !ObjectMove(chart_ID,name,0,0,price))
     {
      Print(__FUNCTION__,
            ": failed to move the horizontal line! Error code = ",GetLastError());
      return(false);
     }

//--- 水平線を移動する
   if(!price && time && !ObjectMove(chart_ID,name,0,time,0))
     {
      Print(__FUNCTION__,
            ": failed to move the horizontal line! Error code = ",GetLastError());
      return(false);
     }
//--- 実行成功
   return(true);
  }

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
   EventSetTimer(60);

   GetPreviousFibo();
   DrawAllLine();

//---
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
   EventKillTimer();
  }


//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---

   int res = checkFirstTrigger(previousHigh, previousLow, previousHurf, previousFiboHigh, previousFiboLow, today); 
   if(res != 0)
      OrderSendOperation(res);

   if(previousDay == iTime(Symbol(), PERIOD_D1, 1))
      return;

   GetPreviousFibo();
   DrawAllLine();


  }

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---

  }


//+------------------------------------------------------------------+
//|GetPreviousHighLow　定義
//+------------------------------------------------------------------+
void GetPreviousFibo()
  {

// 前日のOpenClose時間
   today = iTime(Symbol(), PERIOD_D1, 0);
   previousDay = iTime(Symbol(), PERIOD_D1, 1);

// 前日の高値を取得
   previousHigh = iHigh(Symbol(), PERIOD_D1, 1);

// 前日の安値を取得
   previousLow = iLow(Symbol(), PERIOD_D1, 1);

//　前日のFiboを計算
   previousHurf = (previousHigh - previousLow) * 0.5 + previousLow;
   previousFiboHigh = (previousHigh - previousLow) * 0.618 + previousLow;
   previousFiboLow = (previousHigh - previousLow) * 0.382 + previousLow;

// 取得した前日の高値と安値を表示
   Print("高値: ", previousHigh, " / 安値: ", previousLow, " / 半値: ", previousHurf, " / Fibo 61.8%: ", previousFiboHigh, " / Fibo 38.2%: ", previousFiboLow);

  }


//+------------------------------------------------------------------+
//|DrawAllLine　定義
//+------------------------------------------------------------------+
void DrawAllLine()
  {

// 前日の市場Opened時間とclosed時間に垂直線を作成
// 存在する場合は垂直線移動
   if(!LineCreate(Chart_ID,todayName,0,today,0,clrBrown) && ObjectFind(Chart_ID,todayName) > -1)
      if(!LineMove(Chart_ID,todayName,0,today))
         Print("error" + todayName);

   if(!LineCreate(Chart_ID,previousDayName,0,previousDay,0,clrBrown) && ObjectFind(Chart_ID,previousDayName) > -1)
      if(!LineMove(Chart_ID,previousDayName,0,previousDay))
         Print("error" + previousDayName);

// 前日高値にFiboの水平線を作成
// 存在する場合は水平線移動
   if(!LineCreate(Chart_ID,HighLineName,previousHigh) && ObjectFind(Chart_ID,HighLineName) > -1)
      if(!LineMove(Chart_ID,HighLineName,previousHigh))
         Print("error" + HighLineName);

   if(!LineCreate(Chart_ID,FiboHighLineName,previousFiboHigh) && ObjectFind(Chart_ID,FiboHighLineName) > -1)
      if(!LineMove(Chart_ID,FiboHighLineName,previousFiboHigh))
         Print("eror" + FiboHighLineName);

   if(!LineCreate(Chart_ID,HurfLineName,previousHurf) && ObjectFind(Chart_ID,HurfLineName) > -1)
      if(!LineMove(Chart_ID,HurfLineName,previousHurf))
         Print("eror" + HurfLineName);

   if(!LineCreate(Chart_ID,FiboLowLineName,previousFiboLow) && ObjectFind(Chart_ID,FiboLowLineName) > -1)
      if(!LineMove(Chart_ID,FiboLowLineName,previousFiboLow))
         Print("eror" + FiboLowLineName);

   if(!LineCreate(Chart_ID,LowLineName,previousLow) && ObjectFind(Chart_ID,LowLineName) > -1)
      if(!LineMove(Chart_ID,LowLineName,previousLow))
         Print("eror" + LowLineName);
  }


//+------------------------------------------------------------------+
//|checkTrigger　定義
//+------------------------------------------------------------------+



int checkFirstTrigger
(
   const double Hp,
   const double Lp,
   const double Hu,
   const double Fh,
   const double Fl,
   const datetime OpendToday
)
  {

   int trigger = 0;

   CandlestickInfo cs01;
   CandlestickInfo cs02;
   CandlestickInfo cs03;

   cs01.open = iOpen(Symbol(),PERIOD_M15,1);
   cs01.close = iClose(Symbol(),PERIOD_M15,1);
   cs01.high = iHigh(Symbol(),PERIOD_M15,1);
   cs01.low = iLow(Symbol(),PERIOD_M15,1);

   cs02.open = iOpen(Symbol(),PERIOD_M15,2);
   cs02.close = iClose(Symbol(),PERIOD_M15,2);
   cs02.high = iHigh(Symbol(),PERIOD_M15,2);
   cs02.low = iLow(Symbol(),PERIOD_M15,2);

   cs03.open = iOpen(Symbol(),PERIOD_M15,3);
   cs03.close = iClose(Symbol(),PERIOD_M15,3);
   cs03.high = iHigh(Symbol(),PERIOD_M15,3);
   cs03.low = iLow(Symbol(),PERIOD_M15,3);

   if
   (
      (cs03.open > Fh && cs03.close > Fh && cs03.high > Fh && cs03.low < Fh
       && cs02.open > Fh &&cs02.close > Fh &&cs02.high > Fh &&cs02.low < Fh
       && cs01.open > Fh && cs01.close > Fh && cs01.high > Fh && cs01.low < Fh)
      ||
      (cs03.open > Fl && cs03.close > Fl && cs03.high > Fl && cs03.low < Fl
       && cs02.open > Fl &&cs02.close > Fl &&cs02.high > Fl &&cs02.low < Fl
       && cs01.open > Fl && cs01.close > Fl && cs01.high > Fl && cs01.low < Fl)
   )
     {
      trigger = 1;
     }

   if
   (
      (cs03.open < Fh && cs03.close < Fh && cs03.high > Fh && cs03.low < Fh
       && cs02.open < Fh &&cs02.close < Fh && cs02.high > Fh &&cs02.low < Fh
       && cs01.open < Fh && cs01.close < Fh && cs01.high > Fh && cs01.low < Fh)
      ||
      (cs03.open < Fl && cs03.close < Fl && cs03.high > Fl && cs03.low < Fl
       && cs02.open < Fl &&cs02.close < Fl && cs02.high > Fl &&cs02.low < Fl
       && cs01.open < Fl && cs01.close < Fl && cs01.high > Fl && cs01.low < Fl)
   )
     {
      trigger = -1;
     }

   return trigger;
  }

//+------------------------------------------------------------------+

void OrderSendOperation(int res)
{
   int resultIndex = 0;
   double targetPrice = 0;

   if(res < 0)
   {
      resultIndex = iLowest(NULL,PERIOD_M15,MODE_LOW,3,1);
      if(resultIndex!=-1)
         targetPrice=iLow(Symbol(),PERIOD_M15,resultIndex);
      else
         PrintFormat("iLowest() call error. Error code=%d",GetLastError());
      
   }
   if(res > 0)
   {
      resultIndex = iHighest(NULL,PERIOD_M15,MODE_HIGH,3,1);
      if(resultIndex!=-1)
         targetPrice=iHigh(Symbol(),PERIOD_M15,resultIndex);
      else
         PrintFormat("iLowest() call error. Error code=%d",GetLastError());
   }
   
   int sL = 0;
   int tP = int(sL * 1.5);
   double lot = 0;
   
   int ticket = OrderSend(   // 新規エントリー注文
                Symbol(),                // 通貨ペア
                OP_BUY,                  // オーダータイプ[OP_BUY / OP_SELL]
                lot,                     // ロット[0.01単位]
                Ask,                      // オーダープライスレート
                20,                       // スリップ上限    (int)[分解能 0.1pips]
                sL,                        // ストップレート
                tP,                        // リミットレート
                "テストオーダー",            // オーダーコメント
                999,                      // マジックナンバー(識別用)
                0,                        // オーダーリミット時間
                clrRed                   // オーダーアイコンカラー
                );
   if(ticket == -1)
      Print("OrderSend request error. Error code=%d",GetLastError());
}

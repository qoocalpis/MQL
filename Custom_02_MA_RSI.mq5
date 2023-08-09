//+------------------------------------------------------------------+
//|                                             Custom_02_MA_RSI.mq5 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#define EXPERT_MAGIC 2   // エキスパートアドバイザのMagicNumber

#include <Trade\Trade.mqh>
#include <Trade\Custom_Price_Action.mqh>

CTrade ExtTrade;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
input int percent = 5;
input int Reward = 3;
input int input_MA_M5_1 = 20;
input int input_MA_M5_2 = 288;
input int input_MA_H1 = 24;

int   handle_MA_M5_1 = 0;
int   handle_MA_M5_2 = 0;
int   handle_MA_H1_1 = 0;
double   buff_MA_M5_1[];
double   buff_MA_M5_2[];
double   buff_MA_H1_1[];
datetime previousbarTime = iTime(Symbol(), PERIOD_M5, 1);
MqlRates cs[];


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   handle_MA_M5_1 = iMA(_Symbol,PERIOD_M5,input_MA_M5_1,0,MODE_SMA,PRICE_CLOSE);
   handle_MA_M5_2 = iMA(_Symbol,PERIOD_M5,input_MA_M5_2,0,MODE_SMA,PRICE_CLOSE);
   handle_MA_H1_1 = iMA(_Symbol,PERIOD_H1,input_MA_H1,0,MODE_SMA,PRICE_CLOSE);

   ArraySetAsSeries(buff_MA_M5_1, true);
   ArraySetAsSeries(buff_MA_M5_2, true);
   ArraySetAsSeries(buff_MA_H1_1, true);
   ArraySetAsSeries(cs,true);

   CopyToArrays();

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(handle_MA_M5_1!=INVALID_HANDLE)
      IndicatorRelease(handle_MA_M5_1);
   if(handle_MA_M5_2!=INVALID_HANDLE)
      IndicatorRelease(handle_MA_M5_2);
   if(handle_MA_H1_1!=INVALID_HANDLE)
      IndicatorRelease(handle_MA_H1_1);
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   if(previousbarTime == iTime(Symbol(), PERIOD_M5, 1))
      return;

   CopyToArrays();

   int count = PositionsTotal();
   if(count>0)
   {}
   int resFirst = stastusTwoMAandBar(buff_MA_M5_1, buff_MA_M5_2, cs);
   int resPA = PriceActionTrigger(PERIOD_M5, cs);

   if(resFirst == resPA && count == 0)
      OrderSendOperation(resPA);

   previousbarTime = iTime(Symbol(), PERIOD_M5, 1);
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|stastusMA function
//+------------------------------------------------------------------+
int stastusTwoMAandBar(double &ma1[], double &ma2[], MqlRates &bar[])
  {
   
   //短期MAが長期MAより上かつ短期MAよりローソク足が下
   if(ma1[0] > ma2[0] && ma1[0] > bar[0].low)
      return 1;
   //短期MAが長期MAより下かつ短期MAよりローソク足が上
   if(ma1[0] < ma2[0] && ma1[0] < bar[0].high)
      return -1;

   return 0;
  }


//+------------------------------------------------------------------+
//|StatusInRSI function
//+------------------------------------------------------------------+
// int StatusInRSI(double &rsi[], int intFirstStatus)
//   {

//    int index_max=ArrayMaximum(rsi); // 最高
//    int index_min=ArrayMinimum(rsi); // 最低

//    if(intFirstStatus>0 && rsi[index_max]<70.0)
//       return 1;
//    if(intFirstStatus<0 && rsi[index_min]<30.0)
//       return -1;

//    return 0;
//   }

//+------------------------------------------------------------------+
//|OrderSendOperation function
//+------------------------------------------------------------------+
void OrderSendOperation(int res)
  {
   if(res == 0)
      return;

   bool signal = res > 0 ? true : false;

   ENUM_ORDER_TYPE orderType = signal ? ORDER_TYPE_BUY:ORDER_TYPE_SELL;
   double ask=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
   double bid=SymbolInfoDouble(Symbol(),SYMBOL_BID);
   double spread=ask-bid;
   double price = 0;
   double pips = 0;
   double lot = 0;
//double acceptLossMoney = AccountInfoDouble(ACCOUNT_BALANCE) * double(percent / 100);
   double acceptLossMoney = MathRound(10000 * double(percent) / 100);
   double sL = 0;
   double tP = 0;

   if(signal)
     {
      price = ask;
      sL = iLow(_Symbol,PERIOD_CURRENT,1)+spread*2;
      tP = ask+spread+(ask-sL)*Reward;
     }
   else
     {
      price = bid;
      sL = iHigh(_Symbol,PERIOD_CURRENT,1)-spread*2;
      tP = bid-spread-(sL-bid)*Reward;
     }


   if(!ExtTrade.PositionOpen(_Symbol,orderType,0.1,price,sL,tP))
      PrintFormat("OrderSend error %d",GetLastError());     // リクエストの送信が失敗した場合、エラーコードを出力する
   else
      Print(signal ? "ロング!!! ":"ショート!!! ","res: ", res, " sL: ",sL, " tP: ",tP, " spread: ",spread, " ask: ",ask, " bid: ",bid," type: ",orderType);
  }

  void CopyToArrays()
  {
   if(CopyBuffer(handle_MA_M5_1,0,1,1,buff_MA_M5_1)<=0)
      Print("CopyBuffer from iMA_1 failed, no data");
   if(CopyBuffer(handle_MA_M5_2,0,1,1,buff_MA_M5_2)<=0)
      Print("CopyBuffer from iMA_2 failed, no data");
   if(CopyBuffer(handle_MA_H1_1,0,1,1,buff_MA_H1_1)<=0)
      Print("CopyBuffer from iMA_2 failed, no data");
   if(CopyRates(Symbol(),PERIOD_M5,1,3,cs)<=0)
      Print("CopyRates from bars failed, no data");
  }
//+------------------------------------------------------------------+

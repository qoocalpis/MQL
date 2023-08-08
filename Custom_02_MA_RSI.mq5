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
input int input_RSI = 14;
input int input_MA_1 = 288;
input int input_MA_2 = 24;
input int percent = 5;
input int Reward = 3;

int   handleRSI = 0;
int   handleMA_1 = 0;
int   handleMA_2 = 0;
datetime previousbarTime = iTime(Symbol(), PERIOD_M5, 1);
double   bufferRSI[];
double   bufferMA_1[];
double   bufferMA_2[];
MqlRates cs[];


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   handleRSI = iRSI(_Symbol,PERIOD_M5,input_RSI,PRICE_CLOSE);
   handleMA_1 = iMA(_Symbol,PERIOD_M5,input_MA_1,0,MODE_SMA,PRICE_CLOSE);
   handleMA_2 = iMA(_Symbol,PERIOD_H1,input_MA_2,0,MODE_SMA,PRICE_CLOSE);

   ArraySetAsSeries(bufferRSI, true);
   ArraySetAsSeries(bufferMA_1, true);
   ArraySetAsSeries(bufferMA_2, true);
   ArraySetAsSeries(cs,true);


   if(CopyBuffer(handleRSI,0,0,2,bufferRSI)<=0)
      Print("CopyBuffer from iRSI failed, no data");
   if(CopyBuffer(handleMA_1,0,1,1,bufferMA_1)<=0)
      Print("CopyBuffer from iMA_1 failed, no data");
   if(CopyBuffer(handleMA_2,0,1,1,bufferMA_2)<=0)
      Print("CopyBuffer from iMA_2 failed, no data");
   if(CopyRates(Symbol(),PERIOD_M5,1,3,cs)<=0)
      Print("CopyRates from bars failed, no data");

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(handleRSI!=INVALID_HANDLE)
      IndicatorRelease(handleRSI);
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   if(previousbarTime == iTime(Symbol(), PERIOD_M5, 1))
      return;

   if(CopyBuffer(handleRSI,0,1,3,bufferRSI)<=0)
      Print("CopyBuffer from iRSI failed, no data");
   if(CopyBuffer(handleMA_1,0,1,2,bufferMA_1)<=0)
      Print("CopyBuffer from iMA_1 failed, no data");
   if(CopyBuffer(handleMA_2,0,1,2,bufferMA_2)<=0)
      Print("CopyBuffer from iMA_2 failed, no data");
   if(CopyRates(Symbol(),PERIOD_M5,1,3,cs)<=0)
      Print("CopyRates from bars failed, no data");

   int resPA = 0;
   int target = 0;

   int intFirstStatus = StatusOutSideMA(bufferMA_2);
   int boolSecondStatus = StatusInRSI(bufferRSI, intFirstStatus);



   resPA = PriceActionTrigger(PERIOD_M5, cs);


   OrderSendOperation(resPA);

   previousbarTime = iTime(Symbol(), PERIOD_M5, 1);
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|StatusOutSideMA function
//+------------------------------------------------------------------+
int StatusOutSideMA(double &ma[])
  {
  
   double max1 = MathMax(iOpen(Symbol(), PERIOD_H1, 1), iClose(Symbol(), PERIOD_H1, 1));
   double min1 = MathMin(iOpen(Symbol(), PERIOD_H1, 1), iClose(Symbol(), PERIOD_H1, 1));
   double max2 = MathMax(iOpen(Symbol(), PERIOD_H1, 2), iClose(Symbol(), PERIOD_H1, 2));
   double min2 = MathMin(iOpen(Symbol(), PERIOD_H1, 2), iClose(Symbol(), PERIOD_H1, 2));

   if(min1 > ma[0] && min2 > ma[1])
      return 1;

   if(max1 < ma[0] && max2 < ma[1])
      return -1;

   return 0;
  }


//+------------------------------------------------------------------+
//|StatusInRSI function
//+------------------------------------------------------------------+
int StatusInRSI(double &rsi[], int intFirstStatus)
  {

   int index_max=ArrayMaximum(rsi); // 最高
   int index_min=ArrayMinimum(rsi); // 最低

   if(intFirstStatus>0 && rsi[index_max]<70.0)
      return 1;
   if(intFirstStatus<0 && rsi[index_min]<30.0)
      return -1;

   return 0;
  }

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
//+------------------------------------------------------------------+

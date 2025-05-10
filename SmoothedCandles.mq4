//+------------------------------------------------------------------+
//|                                          Smoothed Candles Indicator |
//|                                      Copyright 2025                 |
//+------------------------------------------------------------------+
#property strict
#property indicator_chart_window
#property version "1.1"
#property copyright "2025"

#property indicator_buffers 4
#property indicator_color1 Red
#property indicator_color2 Blue
#property indicator_color3 Red
#property indicator_color4 Blue
#property indicator_width1 1
#property indicator_width2 1
#property indicator_width3 3
#property indicator_width4 3

#include "libs/time-handler.mqh"

//--- Input Parameters
input ENUM_MA_METHOD MA_Method = MODE_EMA;
input int EMALength = 10;
input int DaysLimit = 2;
input color ExtColor1 = Red;
input color ExtColor2 = Blue;
input color ExtColor3 = Red;
input color ExtColor4 = Blue;

//--- Indicator Buffers
double ExtLowHighBuffer[];
double ExtHighLowBuffer[];
double ExtOpenBuffer[];
double ExtCloseBuffer[];

//--- Global Variables
NewCandleObserver g_currentCandle(PERIOD_CURRENT);
datetime g_limitDate;

//+------------------------------------------------------------------+
//| Calculate limit date based on days limit                          |
//+------------------------------------------------------------------+
datetime calculateLimitDate(int daysLimit)
   {
//  const int SECONDS_IN_DAY = 86400;
//  return Time[0] - daysLimit * SECONDS_IN_DAY;
    return iTime(NULL, PERIOD_D1, daysLimit);
   }

//+------------------------------------------------------------------+
//| Set indicator buffers and styles                                  |
//+------------------------------------------------------------------+
void setupIndicatorBuffers(int emaLength)
   {
// Configure buffer 0 - Low/High
    SetIndexBuffer(0, ExtLowHighBuffer);
    SetIndexStyle(0, DRAW_HISTOGRAM, 0, 1, ExtColor1);
    SetIndexLabel(0, "Low/High");
    SetIndexDrawBegin(0, emaLength);
// Configure buffer 1 - High/Low
    SetIndexBuffer(1, ExtHighLowBuffer);
    SetIndexStyle(1, DRAW_HISTOGRAM, 0, 1, ExtColor2);
    SetIndexLabel(1, "High/Low");
    SetIndexDrawBegin(1, emaLength);
// Configure buffer 2 - Open
    SetIndexBuffer(2, ExtOpenBuffer);
    SetIndexStyle(2, DRAW_HISTOGRAM, 0, 3, ExtColor3);
    SetIndexLabel(2, "Open");
    SetIndexDrawBegin(2, emaLength);
// Configure buffer 3 - Close
    SetIndexBuffer(3, ExtCloseBuffer);
    SetIndexStyle(3, DRAW_HISTOGRAM, 0, 3, ExtColor4);
    SetIndexLabel(3, "Close");
    SetIndexDrawBegin(3, emaLength);
   }

//+------------------------------------------------------------------+
//| Calculate smoothed price values and assign to buffers             |
//+------------------------------------------------------------------+
void calculateSmoothedPrices(int limit, int emaLength, ENUM_MA_METHOD maMethod)
   {
    for(int i = limit; i >= 0; i--)
       {
        if(Time[i] < g_limitDate)
            continue;
        double smoothedOpen = iMA(NULL, 0, emaLength, 0, maMethod, PRICE_OPEN, i);
        double smoothedHigh = iMA(NULL, 0, emaLength, 0, maMethod, PRICE_HIGH, i);
        double smoothedLow = iMA(NULL, 0, emaLength, 0, maMethod, PRICE_LOW, i);
        double smoothedClose = iMA(NULL, 0, emaLength, 0, maMethod, PRICE_CLOSE, i);
        if(smoothedClose > smoothedOpen)
           {
            ExtLowHighBuffer[i] = smoothedLow;
            ExtHighLowBuffer[i] = smoothedHigh;
           }
        else
           {
            ExtLowHighBuffer[i] = smoothedHigh;
            ExtHighLowBuffer[i] = smoothedLow;
           }
        ExtOpenBuffer[i] = smoothedOpen;
        ExtCloseBuffer[i] = smoothedClose;
       }
   }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
   {
    IndicatorShortName("Smoothed Candles (EMA: " + IntegerToString(EMALength) + ", Days: " + IntegerToString(DaysLimit) + ")");
    IndicatorDigits(Digits);
    setupIndicatorBuffers(EMALength);
    g_limitDate = calculateLimitDate(DaysLimit);
    return INIT_SUCCEEDED;
   }

//+------------------------------------------------------------------+
//| OnCalculate - Main calculation function                           |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
   {
    int pos;
    if(rates_total < EMALength + 1)
        return 0;
    if(g_currentCandle.IsNewCandle())
       {
        pos = prev_calculated == 0 ? rates_total - EMALength - 1 : rates_total - prev_calculated;
       }
    else
       {
        pos = 0;
       }
    calculateSmoothedPrices(pos, EMALength, MA_Method);
    return rates_total;
   }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
   {
   }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                           CJ.mq5 |
//|                                         Copyright 2020, Lowcash. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Lowcash."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "../Core/Include/MQL4Helper.mqh"
#include "../Core/Include/Common.mqh"
#include "../Core/Include/Draw.mqh"

#include "../Core/Signal/_Indicators/_IndicatorParser.mqh"
#include "../Core/Signal/Trend/TrendManager.mqh"
#include "../Core/Signal/Crossover/CrossoverManager.mqh"
#include "../Core/Signal/_Indicators/MovingAverage.mqh"
#include "../Core/Signal/_Indicators/Ichimoku.mqh"

MovingAverageSettings		_FastTrendMASettings(_Symbol, PERIOD_H1, MODE_EMA, PRICE_CLOSE, 8, 0);
MovingAverageSettings		_SlowTrendMASettings(_Symbol, PERIOD_H1, MODE_EMA, PRICE_CLOSE, 21, 0);

IchimokuSettings           _IchimokuSettings(_Symbol, PERIOD_H1, 9, 26, 52, 0);

ObjectBuffer               _MarkersBuffer("Marker", 9999);

TrendManager               _TrendManager(9999);
CrossoverManager           _CrossoverManager(9999);

bool                       _IsPrevCrossoverSenkouSpanA = false;
bool                       _IsPrevCrossoverSenkouSpanB = false;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
   return(INIT_SUCCEEDED);
}

void OnTick() {
   // Do the necessary things first
   UpdatePredefinedVars();
   //+------------------------------------------------------------------+
   
   const bool _IsNewHour = IsNewBar(PERIOD_H1);
   
   // Crossover analysis
   if(_IsNewHour) {
      Ichimoku _Ichimoku[]; IndicatorParser::GetIchimokuValues(_Ichimoku, _IchimokuSettings, 1, 2);

      double _IchimokuTenkanSen[]; GetTenkanSen(_Ichimoku, _IchimokuTenkanSen);
      double _IchimokuKijunSen[]; GetKijunSen(_Ichimoku, _IchimokuKijunSen);
      double _IchimokuChikouSpan[]; GetChikouSpan(_Ichimoku, _IchimokuChikouSpan);
      double _IchimokuSenkouSpanA[], _IchimokuSenkouSpanB[]; GetSenkouSpan(_Ichimoku, _IchimokuSenkouSpanA, _IchimokuSenkouSpanB);
      
      double _ClosePrices[2]; _ClosePrices[0] = Close[1]; _ClosePrices[1] = Close[2];
      
      // Analysis Price/Cloud Crossover
      const bool _IsCrossoverSenkouSpanA = _CrossoverManager.AnalyzeByValueComparer(_ClosePrices, _IchimokuSenkouSpanA) != Crossover::State::INVALID_CROSSOVER;
      const bool _IsCrossoverSenkouSpanB = _CrossoverManager.AnalyzeByValueComparer(_ClosePrices, _IchimokuSenkouSpanB) != Crossover::State::INVALID_CROSSOVER;
      
      if(_IsCrossoverSenkouSpanA && _IsCrossoverSenkouSpanB) {
         DrawArrowMarker(_MarkersBuffer.GetNewObjectId(), Time[1], Close[1], true, clrGoldenrod);
      } else {
         if((_IsPrevCrossoverSenkouSpanA && _IsCrossoverSenkouSpanB) ||
            (_IsPrevCrossoverSenkouSpanB && _IsCrossoverSenkouSpanA)) {
            _IsPrevCrossoverSenkouSpanA = false;
            _IsPrevCrossoverSenkouSpanB = false;
            
            DrawArrowMarker(_MarkersBuffer.GetNewObjectId(), Time[1], Close[1], true, clrGoldenrod);
         } else {
            if(_IsCrossoverSenkouSpanA) {
               _IsPrevCrossoverSenkouSpanA = !_IsPrevCrossoverSenkouSpanA;
            }
            if(_IsCrossoverSenkouSpanB) {
               _IsPrevCrossoverSenkouSpanB = !_IsPrevCrossoverSenkouSpanB;
            }
         }
      }
      
      // Analysis Price/KijunSen Crossover
      if(_CrossoverManager.AnalyzeByValueComparer(_ClosePrices, _IchimokuKijunSen) != Crossover::State::INVALID_CROSSOVER) {
         DrawArrowMarker(_MarkersBuffer.GetNewObjectId(), Time[1], Low[1], true, clrDarkOrchid);
      }
      
      // Analysis TenkanSen/KijunSen Crossover
      if(_CrossoverManager.AnalyzeByValueComparer(_IchimokuTenkanSen, _IchimokuKijunSen) != Crossover::State::INVALID_CROSSOVER) {
         Crossover *_SelectedCrossover = _CrossoverManager.GetSelectedCrossover();
         
         DrawRectangeMarker(_SelectedCrossover.GetSignalID(), _SelectedCrossover.GetBeginDateTime(), _SelectedCrossover.GetBeginValue(), _SelectedCrossover.GetEndDateTime(), _SelectedCrossover.GetEndValue(), clrDeepPink);
         //DrawArrowMarker(_MarkersBuffer.GetNewObjectId(), Time[1], Close[1], true, clrDeepPink);
      }
      
      Comment(StringFormat("Cloud color is %s", EnumToString(_IchimokuSenkouSpanA[0] > _IchimokuSenkouSpanB[1] ? CloudColor::BULL : CloudColor::BEAR)));
   }
}
//+------------------------------------------------------------------+

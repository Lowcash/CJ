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
#include "../Core/Signal/_Indicators/MovingAverage.mqh"

MovingAverageSettings		_FastTrendMASettings(_Symbol, PERIOD_H1, MODE_EMA, PRICE_CLOSE, 8, 0);
MovingAverageSettings		_SlowTrendMASettings(_Symbol, PERIOD_H1, MODE_EMA, PRICE_CLOSE, 21, 0);

IchimokuSettings           _IchimokuSettings(_Symbol, PERIOD_H1, 9, 26, 52, 0);

ObjectBuffer               _MarkersBuffer("Marker", 9999);

TrendManager               _TrendManager(9999);

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
   return(INIT_SUCCEEDED);
}

void OnTick() {
   UpdatePredefinedVars();
   
   // Trend analysis
   if(IsNewBar(PERIOD_H1)) {
      MovingAverage _MAFast[]; IndicatorParser::GetMovingAverageValues(_MAFast, _FastTrendMASettings, 1, 1);
      MovingAverage _MASlow[]; IndicatorParser::GetMovingAverageValues(_MASlow, _SlowTrendMASettings, 1, 1);
      
      double _MAFastValues[]; GetMovingAverage(_MAFast, _MAFastValues);
      double _MASlowValues[]; GetMovingAverage(_MASlow, _MASlowValues);
      double _MAValues[];
      
      ArrayInsert(_MAValues, _MAFastValues, ArraySize(_MAValues));
      ArrayInsert(_MAValues, _MASlowValues, ArraySize(_MAValues));
      
   	const Trend::State _TrendState = _TrendManager.AnalyzeByTrendByCandlePosition(Close[1], _MAValues, ArraySize(_MAValues) - 1, true, true);
   	//const Trend::State _TrendState = _TrendManager.AnalyzeByIchimokuTracing(_IchimokuSettings, KIJUNSEN_LINE, false);
   	
      if(_TrendState == Trend::State::VALID_UPTREND || _TrendState == Trend::State::VALID_DOWNTREND) {
         _MarkersBuffer.GetNewObjectId();
      }
   }
   
   // Draw objects into the chart
   if(_Period == PERIOD_H1) {
   	Trend* _SelectedTrend = _TrendManager.GetSelectedTrend();

      if(_TrendManager.GetCurrentState() == Trend::State::VALID_UPTREND) {
         DrawTrendMarker(_MarkersBuffer.GetSelecterObjectId(), iTimeMQL4(_Symbol, PERIOD_H1, 0), Low[0], true, clrForestGreen);
         DrawTrendMarker(_SelectedTrend.GetSignalID(), _SelectedTrend.GetBeginDateTime(), _SelectedTrend.GetHighestValue(), _SelectedTrend.GetEndDateTime(), _SelectedTrend.GetLowestValue(), clrForestGreen);
      }
      if(_TrendManager.GetCurrentState() == Trend::State::VALID_DOWNTREND) {
         DrawTrendMarker(_MarkersBuffer.GetSelecterObjectId(), iTimeMQL4(_Symbol, PERIOD_H1, 0), Low[0], false, clrCrimson);
         DrawTrendMarker(_SelectedTrend.GetSignalID(), _SelectedTrend.GetBeginDateTime(), _SelectedTrend.GetLowestValue(), _SelectedTrend.GetEndDateTime(), _SelectedTrend.GetHighestValue(), clrCrimson);
      }
   }
}
//+------------------------------------------------------------------+

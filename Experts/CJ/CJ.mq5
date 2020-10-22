//+------------------------------------------------------------------+
//|                                                           CJ.mq5 |
//|                                         Copyright 2020, Lowcash. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Lowcash."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "../../Core/Include/MQL4Helper.mqh"
#include "../../Core/Include/Common.mqh"
#include "../../Core/Include/Draw.mqh"

#include "../../Core/Signal/_Indicators/_IndicatorParser.mqh"
#include "../../Core/Signal/_Indicators/Ichimoku.mqh"
#include "../../Core/Signal/Trend/TrendManager.mqh"
#include "../../Core/Signal/Crossover/CrossoverManager.mqh"
#include "../../Core/Signal/Relation/RelationManager.mqh"

MovingAverageSettings		_FastTrendMASettings(_Symbol, PERIOD_H1, MODE_EMA, PRICE_CLOSE, 8, 0);
MovingAverageSettings		_SlowTrendMASettings(_Symbol, PERIOD_H1, MODE_EMA, PRICE_CLOSE, 21, 0);

IchimokuSettings           _IchimokuSettings(_Symbol, PERIOD_H1, 9, 26, 52, 0);

ObjectBuffer               _MarkersBuffer("Marker", 9999);

CrossoverManager           _PriceCloudCrossover(9999);
TrendManager               _KijunSenTrend(9999);
RelationManager            _PriceKijunSenRelation(9999);
RelationManager            _TenkanSenKijunSenRelation(9999);
RelationManager            _ChikouSpanPriceRelation(9999);

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
      // Analysis Price/Cloud Crossover
      Ichimoku _IchimokuCros[]; IndicatorParser::GetIchimokuValues(_IchimokuCros, _IchimokuSettings, 1, 2, 0, 0);
      double _CrosClosePrices[2]; _CrosClosePrices[0] = Close[1]; _CrosClosePrices[1] = Close[2];
      double _IchimokuCrosSenkouSpanA[], _IchimokuCrosSenkouSpanB[]; GetSenkouSpan(_IchimokuCros, _IchimokuCrosSenkouSpanA, _IchimokuCrosSenkouSpanB);
      
      const bool _IsCrossoverSenkouSpanA = _PriceCloudCrossover.AnalyzeByValueComparer(_CrosClosePrices, _IchimokuCrosSenkouSpanA) != Crossover::State::INVALID_CROSSOVER;
      const bool _IsCrossoverSenkouSpanB = _PriceCloudCrossover.AnalyzeByValueComparer(_CrosClosePrices, _IchimokuCrosSenkouSpanB) != Crossover::State::INVALID_CROSSOVER;
      
      if(_IsCrossoverSenkouSpanA && _IsCrossoverSenkouSpanB) {
         Crossover *_SelectedCrossover = _PriceCloudCrossover.GetSelectedCrossover();
         
         DrawArrowMarker(_MarkersBuffer.GetNewObjectId(), _SelectedCrossover.GetEndDateTime(), _SelectedCrossover.GetBeginValue(), true, clrGoldenrod);
      } else {
         if((_IsPrevCrossoverSenkouSpanA && _IsCrossoverSenkouSpanB) ||
            (_IsPrevCrossoverSenkouSpanB && _IsCrossoverSenkouSpanA)) {
            _IsPrevCrossoverSenkouSpanA = false;
            _IsPrevCrossoverSenkouSpanB = false;
            
            Crossover *_SelectedCrossover = _PriceCloudCrossover.GetSelectedCrossover();
            
            DrawArrowMarker(_MarkersBuffer.GetNewObjectId(), _SelectedCrossover.GetEndDateTime(), _SelectedCrossover.GetBeginValue(), true, clrGoldenrod);
         } else {
            if(_IsCrossoverSenkouSpanA) {
               _IsPrevCrossoverSenkouSpanA = !_IsPrevCrossoverSenkouSpanA;
            }
            if(_IsCrossoverSenkouSpanB) {
               _IsPrevCrossoverSenkouSpanB = !_IsPrevCrossoverSenkouSpanB;
            }
         }
      }
      
      double _IchimokuCrosKijunSen[]; GetKijunSen(_IchimokuCros, _IchimokuCrosKijunSen);
      _KijunSenTrend.AnalyzeByLineDirection(_IchimokuCrosKijunSen[1], _IchimokuCrosKijunSen[0]);
      
      Ichimoku _IchimokuCurr[]; IndicatorParser::GetIchimokuValues(_IchimokuCurr, _IchimokuSettings, 1, 1, 0, 0);
      double _IchimokuCurrTenkanSen[]; GetTenkanSen(_IchimokuCurr, _IchimokuCurrTenkanSen);
      double _IchimokuCurrKijunSen[]; GetKijunSen(_IchimokuCurr, _IchimokuCurrKijunSen);
      double _CurrClosePrices[1]; _CurrClosePrices[0] = Close[1];
      
      // Analysis Price is lower then KijunSen
      if(_PriceKijunSenRelation.AnalyzeByValueComparer(Time[1], _CurrClosePrices, _IchimokuCurrKijunSen, Relation::Type::IS_LOWER) != Relation::State::INVALID_RELATION) {
         DrawArrowMarker(_MarkersBuffer.GetNewObjectId(), _PriceKijunSenRelation.GetSelectedRelation().GetBeginDateTime(), _CurrClosePrices[0], true, clrBlue);
      }
      
      // Analysis TenkanSen is lower then KijunSen
      if(_TenkanSenKijunSenRelation.AnalyzeByValueComparer(Time[1], _IchimokuCurrTenkanSen, _IchimokuCurrKijunSen, Relation::Type::IS_LOWER) != Relation::State::INVALID_RELATION) {
         DrawArrowMarker(_MarkersBuffer.GetNewObjectId(), _TenkanSenKijunSenRelation.GetSelectedRelation().GetBeginDateTime(), _IchimokuCurrTenkanSen[0], true, clrRed);
      }
      
      Ichimoku _IchimokuShif[]; IndicatorParser::GetIchimokuValues(_IchimokuShif, _IchimokuSettings, 1, 1, 26, -26);
      double _IchimokuShifChikouSpan[]; GetChikouSpan(_IchimokuShif, _IchimokuShifChikouSpan);
      double _IchimokuShifSenkouSpanA[], _IchimokuSenkouSpanB[]; GetSenkouSpan(_IchimokuShif, _IchimokuShifSenkouSpanA, _IchimokuSenkouSpanB);
      double _ShifClosePrices[1]; _ShifClosePrices[0] = Close[27];

      // Analysis ChikouSen is lower then Price
      if(_ChikouSpanPriceRelation.AnalyzeByValueComparer(Time[27], _IchimokuShifChikouSpan, _ShifClosePrices, Relation::Type::IS_LOWER) != Relation::State::INVALID_RELATION) {
         DrawArrowMarker(_MarkersBuffer.GetNewObjectId(), _ChikouSpanPriceRelation.GetSelectedRelation().GetBeginDateTime(), _IchimokuShifChikouSpan[0], true, clrLawnGreen);
      }
      
      Comment(StringFormat("Trend direction: %s\nCloud color is %s", 
         EnumToString(_KijunSenTrend.GetSelectedTrend().GetState()), 
         EnumToString(_IchimokuShifSenkouSpanA[0] > _IchimokuSenkouSpanB[0] ? CloudColor::BULL : CloudColor::BEAR))
      );
   }
}
//+------------------------------------------------------------------+

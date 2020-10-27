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

#include "CJTradeManager.mqh"

input group                "Base settings"
input double               LotSize = 0.01;
input ENUM_TIMEFRAMES      TimeFrame = PERIOD_H1;

input group                "Additional condtions"
input double               RewardRatio = 1.5;
input uint                 PipTradeOffset = 5;
input uint                 MinSignalPointsToTrade = 10;

IchimokuSettings           _IchimokuSettings(_Symbol, TimeFrame, 9, 26, 52, 0);

ObjectBuffer               _MarkersBuffer("Marker", 9999);

CrossoverManager           _PriceCloudCrossover(9999);
TrendManager               _KijunSenTrend(9999);
RelationManager            _PriceKijunSenRelation(9999);
RelationManager            _TenkanSenKijunSenRelation(9999);
RelationManager            _ChikouSpanPriceRelation(9999);

CJTradeManager             _CJTradeManager();

bool                       _IsPrevCrosSenkouSpanA = false;
bool                       _IsPrevCrosSenkouSpanB = false;

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
   
   const bool _IsNewHour = IsNewBar(TimeFrame);
   
   // Crossover analysis
   if(_IsNewHour) {
      Ichimoku _IchimokuTwoPrev[]; IndicatorParser::GetIchimokuValues(_IchimokuTwoPrev, _IchimokuSettings, 2, 3,  0,   0);
      Ichimoku _IchimokuTwoCurr[]; IndicatorParser::GetIchimokuValues(_IchimokuTwoCurr, _IchimokuSettings, 1, 2,  0,   0);
      Ichimoku _IchimokuOnePrev[]; IndicatorParser::GetIchimokuValues(_IchimokuOnePrev, _IchimokuSettings, 2, 2,  0,   0);
      Ichimoku _IchimokuOneShif[]; IndicatorParser::GetIchimokuValues(_IchimokuOneShif, _IchimokuSettings, 2, 2, 27, -25);
      
      double _ClosePricesTwoCurr[2]; _ClosePricesTwoCurr[0] = Close[1]; _ClosePricesTwoCurr[1] = Close[2];
      double _IchimokuSenkouSpanATwoCurr[], _IchimokuSenkouSpanBTwoCurr[]; GetSenkouSpan(_IchimokuTwoCurr, _IchimokuSenkouSpanATwoCurr, _IchimokuSenkouSpanBTwoCurr);
      
      _CJTradeManager.AnalyzeTrades(_IchimokuSenkouSpanATwoCurr[0], _IchimokuSenkouSpanBTwoCurr[0], PipTradeOffset);
      
      // Analysis KijunSen Trend
      double _IchimokuTwoKijunSen[]; GetKijunSen(_IchimokuTwoPrev, _IchimokuTwoKijunSen);
      _KijunSenTrend.AnalyzeByLineDirection(_IchimokuTwoKijunSen[1], _IchimokuTwoKijunSen[0]);
      
      Trend::State _TrendState = _KijunSenTrend.GetSelectedTrend().GetState();
      
      Comment(StringFormat("Trend direction: %s", EnumToString(_TrendState)));

      // Analysis Price/Cloud Crossover
      double _ClosePricesTwoPrev[2]; _ClosePricesTwoPrev[0] = Close[2]; _ClosePricesTwoPrev[1] = Close[3];
      double _IchimokuSenkouSpanATwoPrev[], _IchimokuSenkouSpanBTwoPrev[]; GetSenkouSpan(_IchimokuTwoPrev, _IchimokuSenkouSpanATwoPrev, _IchimokuSenkouSpanBTwoPrev);
      
      const bool _IsCrosSenkouSpanA = _PriceCloudCrossover.AnalyzeByValueComparer(Time[2], _ClosePricesTwoPrev, _IchimokuSenkouSpanATwoPrev) != Crossover::State::INVALID_CROSSOVER;
      const bool _IsCrosSenkouSpanB = _PriceCloudCrossover.AnalyzeByValueComparer(Time[2], _ClosePricesTwoPrev, _IchimokuSenkouSpanBTwoPrev) != Crossover::State::INVALID_CROSSOVER;
      
      if(_IsCrosSenkouSpanA) { 
         _IsPrevCrosSenkouSpanA = !_IsPrevCrosSenkouSpanA; 
      }
      if(_IsCrosSenkouSpanB) { 
         _IsPrevCrosSenkouSpanB = !_IsPrevCrosSenkouSpanB; 
      }
      
      if(_IsPrevCrosSenkouSpanA && _IsPrevCrosSenkouSpanB) {
         Crossover *_SelectedCrossover = _PriceCloudCrossover.GetSelectedCrossover();
         
         const bool _IsCrossoverSenkouSpanA = _PriceCloudCrossover.AnalyzeByValueComparer(Time[1], _ClosePricesTwoCurr, _IchimokuSenkouSpanATwoCurr) != Crossover::State::INVALID_CROSSOVER;
         const bool _IsCrossoverSenkouSpanB = _PriceCloudCrossover.AnalyzeByValueComparer(Time[1], _ClosePricesTwoCurr, _IchimokuSenkouSpanBTwoCurr) != Crossover::State::INVALID_CROSSOVER;
         
         DrawArrowMarker(_MarkersBuffer.GetNewObjectId(), _SelectedCrossover.GetEndDateTime(), _SelectedCrossover.GetBeginValue(), _TrendState == Trend::State::VALID_UPTREND, clrBlack);
         
         if(!(_IsCrossoverSenkouSpanA || _IsCrossoverSenkouSpanB)) {
            DrawArrowMarker(_MarkersBuffer.GetNewObjectId(), _SelectedCrossover.GetEndDateTime(), _SelectedCrossover.GetBeginValue(), _TrendState == Trend::State::VALID_UPTREND, clrGoldenrod);
            
            _IsPrevCrosSenkouSpanA = false;
            _IsPrevCrosSenkouSpanB = false;

            double _IchimokuSenkouSpanAOneShif[], _IchimokuSenkouSpanBOneShif[]; GetSenkouSpan(_IchimokuOneShif, _IchimokuSenkouSpanAOneShif, _IchimokuSenkouSpanBOneShif);
            double _IchimokuChikouSpanShif[]; GetChikouSpan(_IchimokuOneShif, _IchimokuChikouSpanShif);
            
            bool _IsColorCloud = false;
            bool _IsPriceKijunSen = false;
            bool _IsTenkanSenKijun = false;
            bool _IsChikouSpanPrice = false;
            
            uint _Points = 0;
            
            if(_IsColorCloud = (_TrendState == Trend::State::VALID_UPTREND && _IchimokuSenkouSpanAOneShif[0] > _IchimokuSenkouSpanBOneShif[0]) ||
                               (_TrendState == Trend::State::VALID_DOWNTREND && _IchimokuSenkouSpanAOneShif[0] < _IchimokuSenkouSpanBOneShif[0])) {
               _Points += 5;
            }
            
            double _IchimokuTenkanSenOnePrev[]; GetTenkanSen(_IchimokuOnePrev, _IchimokuTenkanSenOnePrev);
            double _IchimokuKijunSenOnePrev[]; GetKijunSen(_IchimokuOnePrev, _IchimokuKijunSenOnePrev);
            double _ClosePricesOnePrev[1]; _ClosePricesOnePrev[0] = Close[ 2];
            double _ClosePricesOneShif[1]; _ClosePricesOneShif[0] = Close[27];

            // Analysis Price/KijunSen
            if(_IsPriceKijunSen = (_PriceKijunSenRelation.AnalyzeByValueComparer(Time[2], _ClosePricesOnePrev, _IchimokuKijunSenOnePrev, _TrendState == Trend::State::VALID_UPTREND ? Relation::Type::IS_HIGHER : Relation::Type::IS_LOWER) != Relation::State::INVALID_RELATION)) {
               _Points += 5;
            }
            
            // Analysis TenkanSen/KijunSen
            if(_IsTenkanSenKijun = (_TenkanSenKijunSenRelation.AnalyzeByValueComparer(Time[2], _IchimokuTenkanSenOnePrev, _IchimokuKijunSenOnePrev, _TrendState == Trend::State::VALID_UPTREND ? Relation::Type::IS_HIGHER : Relation::Type::IS_LOWER) != Relation::State::INVALID_RELATION)) {
               _Points += 4;
            }
            
            // Analysis ChikouSpan/Price
            if(_IsChikouSpanPrice = (_ChikouSpanPriceRelation.AnalyzeByValueComparer(Time[27], _IchimokuChikouSpanShif, _ClosePricesOneShif, _TrendState == Trend::State::VALID_UPTREND ? Relation::Type::IS_HIGHER : Relation::Type::IS_LOWER) != Relation::State::INVALID_RELATION)) {
               _Points += 4;
            }
            
            if(_Points >= MinSignalPointsToTrade) {
               if(_TrendState == Trend::State::VALID_UPTREND) {
                  _CJTradeManager.TryOpenOrder(ORDER_TYPE_BUY, LotSize, _IchimokuSenkouSpanATwoPrev[0], _IchimokuSenkouSpanBTwoPrev[0], _ClosePricesTwoPrev[0], RewardRatio, PipTradeOffset);
               }
               if(_TrendState == Trend::State::VALID_DOWNTREND) {
                  _CJTradeManager.TryOpenOrder(ORDER_TYPE_SELL, LotSize, _IchimokuSenkouSpanATwoPrev[0], _IchimokuSenkouSpanBTwoPrev[0], _ClosePricesTwoPrev[0], RewardRatio, PipTradeOffset);
               }
               
               //if(_IsPriceKijunSen) {
               //   DrawArrowMarker(_MarkersBuffer.GetNewObjectId(), _PriceKijunSenRelation.GetSelectedRelation().GetBeginDateTime(), _ClosePricesOnePrev[0], _TrendState == Trend::State::VALID_UPTREND, clrBlue);
               //}
               //if(_IsTenkanSenKijun) {
               //   DrawArrowMarker(_MarkersBuffer.GetNewObjectId(), _TenkanSenKijunSenRelation.GetSelectedRelation().GetBeginDateTime(), _ClosePricesOnePrev[0], _TrendState == Trend::State::VALID_UPTREND, clrRed);
               //}
               //if(_IsChikouSpanPrice) {
               //   DrawArrowMarker(_MarkersBuffer.GetNewObjectId(), _ChikouSpanPriceRelation.GetSelectedRelation().GetBeginDateTime(), _ClosePricesOnePrev[0], _TrendState == Trend::State::VALID_UPTREND, clrLawnGreen);
               //}
            }
         }
      }
   }
}

void OnTradeTransaction(const MqlTradeTransaction &p_Trans, const MqlTradeRequest &p_Request, const MqlTradeResult &p_Result) {
   //PrintFormat("Orders: %d, Positions: %d", OrdersTotal(), PositionsTotal());
   
   if(HistoryDealSelect(p_Trans.deal)) {
      ulong _PositionID;
      
      if(HistoryDealGetInteger(p_Trans.deal, DEAL_POSITION_ID, _PositionID)) {
         //PrintFormat("Order: %lu; Position: %lu", p_Trans.order, _PositionID);
         
         switch(p_Trans.type) {
            case TRADE_TRANSACTION_DEAL_ADD: {
               _CJTradeManager.HandleMakeDeal(_PositionID);
            
               break;
            }
         }
      } else {
         Print("Cannot transform deal ID to ticket ID!");
      }
   } else {
      switch(p_Trans.type) {
         case TRADE_TRANSACTION_ORDER_ADD: {
            //_ReggieTradeManager.HandleOrderSend(p_Trans.order);
   
            break;
         }
         case TRADE_TRANSACTION_ORDER_DELETE: {
            /*if(p_Trans.order_state == ORDER_STATE_FILLED) {
               _CJTradeManager.HandleMakeDeal(p_Trans.order);
            }*/
            
            break;
         }
      }
   }
}
//+------------------------------------------------------------------+

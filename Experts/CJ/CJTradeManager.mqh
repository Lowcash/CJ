//+------------------------------------------------------------------+
//|                                               CJTradeManager.mqh |
//|                                         Copyright 2020, Lowcash. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Lowcash."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Arrays/List.mqh>

#include "CJTrade.mqh"
#include "../../Core/Include/Common.mqh"
#include "../../Core/Trade/_TradeManager.mqh"

class CJTradeManager : public _TradeManager {
 private:
   const double m_PipValue;
 
   CList m_CJTrades;
 public:
   CJTradeManager();
   
   void HandleOrderSend(const ulong p_Ticket);
 	void HandleOrderDelete(const ulong p_Ticket);
 	void HandleMakeDeal(const ulong p_Ticket);
 	
   bool TryOpenOrder(const ENUM_ORDER_TYPE p_OrderType, const double p_LotSize, const double p_IchimokuSenkouSpanA, const double p_IchimokuSenkouSpanB, const double p_CloseCandlePrice, const uint p_PipOffset);
};

CJTradeManager::CJTradeManager()
   : m_PipValue(GetForexPipValue()) {}

bool CJTradeManager::TryOpenOrder(const ENUM_ORDER_TYPE p_OrderType, const double p_LotSize, const double p_IchimokuSenkouSpanA, const double p_IchimokuSenkouSpanB, const double p_CloseCandlePrice, const uint p_PipOffset) {
   double _StopLoss = DBL_EPSILON, _Distance = DBL_EPSILON, _TakeProf = DBL_EPSILON;
   ulong _ResultTicket = -1;
   
   switch(p_OrderType) {
      case ORDER_TYPE_BUY: {
         _StopLoss = MathMin(p_IchimokuSenkouSpanA, p_IchimokuSenkouSpanB) - p_PipOffset * m_PipValue;
         _Distance = GetNumPipsBetweenPrices(p_CloseCandlePrice, _StopLoss, m_PipValue);
         _TakeProf = p_CloseCandlePrice + (_Distance * 1.5) * m_PipValue;
         
         if(_TradeFunc.Buy(p_LotSize, _Symbol, 0.0, NormalizeDouble(_StopLoss, _Digits), NormalizeDouble(_TakeProf, _Digits))) {
            if(_TradeFunc.ResultRetcode() == TRADE_RETCODE_DONE) {
               _ResultTicket = _TradeFunc.ResultOrder();
            }
         } else {
            Print("Order failed with error #", GetLastError());
         }
                  
         break;
      }
      case ORDER_TYPE_SELL: {
         _StopLoss = MathMax(p_IchimokuSenkouSpanA, p_IchimokuSenkouSpanB) + p_PipOffset * m_PipValue;
         _Distance = GetNumPipsBetweenPrices(p_CloseCandlePrice, _StopLoss, m_PipValue);
         _TakeProf = p_CloseCandlePrice - (_Distance * 1.5) * m_PipValue;
         
         if(_TradeFunc.Sell(p_LotSize, _Symbol, 0.0, NormalizeDouble(_StopLoss, _Digits), NormalizeDouble(_TakeProf, _Digits))) {
            if(_TradeFunc.ResultRetcode() == TRADE_RETCODE_DONE) {
               _ResultTicket = _TradeFunc.ResultOrder();
            }
         } else {
            Print("Order failed with error #", GetLastError());
         }
         
         break;
      }
      default:
         PrintFormat("%s is invalid order type!", EnumToString(p_OrderType));
         
         return(false);
   }
   
   if(_ResultTicket != -1) {
      m_CJTrades.Add(new CJTrade(_StopLoss));
   }

   return(_ResultTicket != -1);
}
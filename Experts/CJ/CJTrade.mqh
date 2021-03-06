//+------------------------------------------------------------------+
//|                                                      CJTrade.mqh |
//|                                         Copyright 2020, Lowcash. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Lowcash."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "../../Core/Trade/_Trade.mqh"

class CJTrade : public Trade {
 private:
   const ENUM_ORDER_TYPE m_OrderType;
 
   double m_StopLoss;
 public:
   CJTrade(const ulong p_Ticket, const ENUM_ORDER_TYPE p_OrderType, const double p_StopLoss)
      : Trade(p_Ticket), m_OrderType(p_OrderType), m_StopLoss(p_StopLoss) {}
   
   void SetStopLoss(const double p_StopLoss) { m_StopLoss = p_StopLoss; }
   
   double GetStopLoss() const { return(m_StopLoss); }
   ENUM_ORDER_TYPE GetOrderType() const { return(m_OrderType); }
};

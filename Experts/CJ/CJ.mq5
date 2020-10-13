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

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
   return(INIT_SUCCEEDED);
}

void OnTradeTransaction(const MqlTradeTransaction &p_Trans, const MqlTradeRequest &p_Request, const MqlTradeResult &p_Result) {
   if(HistoryDealSelect(p_Trans.deal)) {
      ulong _PositionID;
      
      if(HistoryDealGetInteger(p_Trans.deal, DEAL_POSITION_ID, _PositionID)) {
         switch(p_Trans.type) {
            case TRADE_TRANSACTION_DEAL_ADD: {
               _ReggieTradeManager.HandleMakeDeal(_PositionID);
            
               break;
            }
         }
      } else {
         Print("Cannot transform deal ID to ticket ID!");
      }
   } else {
      switch(p_Trans.type) {
         case TRADE_TRANSACTION_ORDER_ADD: {
            _ReggieTradeManager.HandleOrderSend(p_Trans.order);
   
            break;
         }
         case TRADE_TRANSACTION_ORDER_DELETE: {
            if(p_Trans.order_state == ORDER_STATE_CANCELED) {
               _ReggieTradeManager.HandleOrderDelete(p_Trans.order);
            }
            
            break;
         }
      }
   }
}

void OnTick() {

}
//+------------------------------------------------------------------+

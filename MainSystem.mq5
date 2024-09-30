//+------------------------------------------------------------------+
//|                                            MainTradingSystem.mq5 |
//|                                                            duyng |
//|                                      https://github.com/duyng219 |
//+------------------------------------------------------------------+
#property copyright "duyng"
#property link      "https://github.com/duyng219"
#property version   "1.00"
#include "MainSystemManager.mqh"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

MainManager system;

int OnInit()
  {
    system.OnInit();
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
    
  }

void OnTick()
  {
    system.OnTick();
  }


//+------------------------------------------------------------------+
//|                                                  MainManager.mqh |
//|                                                            duyng |
//|                                      https://github.com/duyng219 |
//+------------------------------------------------------------------+
#property copyright "duyng"
#property link      "https://github.com/duyng219"
#property version   "1.00"

class MainManager {
   private:
      // CAccountManager accountManager;
      // CRiskManager riskManager;
      // CStrategy1Manager strategy1;

   public:
      void OnInit() {
        //  accountManager.Init();
        //  riskManager.Init(accountManager);
        //  strategy1.Init();
         Print("Chay OnInit");
      }

      void OnTick() {
        //  strategy1.Execute();
        Print("Chay Ontick");
      }
};
//+------------------------------------------------------------------+
//|                                              PositionManager.mqh |
//|                                                            duyng |
//|                                      https://github.com/duyng219 |
//+------------------------------------------------------------------+
#property copyright "duyng"
#property link      "https://github.com/duyng219"
#property version   "1.00"

//+------------------------------------------------------------------+
//| CPM Class - Stop Loss, Take Profit, TSL & BE                     |
//+------------------------------------------------------------------+
class CPM
{
    public:
        MqlTradeRequest     request;
        MqlTradeResult      result;

                            CPM(void);

        double              CalculatorStopLoss(string pSymbol, string pEntrySignal, int pSLFixedPoints);
};

//+------------------------------------------------------------------+
//| CPM Class Methods                                                |
//+------------------------------------------------------------------+
CPM::CPM()
{
    ZeroMemory(request);
    ZeroMemory(result);
}

double CPM::CalculatorStopLoss(string pSymbol, string pEntrySignal, int pSLFixedPoints)
{
    double stopLoss = 0.0;
    double askPrice = SymbolInfoDouble(pSymbol,SYMBOL_ASK);
    double bidPrice = SymbolInfoDouble(pSymbol,SYMBOL_BID);
    double tickSize = SymbolInfoDouble(pSymbol,SYMBOL_TRADE_TICK_SIZE);
    double point    = SymbolInfoDouble(pSymbol,SYMBOL_POINT);

    if(pEntrySignal == "BUY")
    {
        if(pSLFixedPoints > 0){ 
            stopLoss = askPrice - (pSLFixedPoints * point); }
    }
    else if(pEntrySignal == "SELL")
    {
        if(pSLFixedPoints > 0){ 
            stopLoss = bidPrice + (pSLFixedPoints * point); }
    }

    stopLoss = round(stopLoss/tickSize) * tickSize;
    return stopLoss;
}
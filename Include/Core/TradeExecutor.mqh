//+------------------------------------------------------------------+
//|                                                TradeExecutor.mqh |
//|                                                            duyng |
//|                                      https://github.com/duyng219 |
//+------------------------------------------------------------------+
#property copyright "duyng"
#property link      "https://github.com/duyng219"

//+------------------------------------------------------------------+
//| CTradeExecutor Class - Gửi lệnh mở, đóng và sửa đổi vị thế       |
//+------------------------------------------------------------------+

class CTradeExecutor
{
    protected:
        ulong                       OpenPosition(string pSymbol,ENUM_ORDER_TYPE pType, double pVolume, double pPrice, double pStopLoss=0, double pTakeProfit=0, string pComment=NULL);

        ulong                       magicNumber;
        ulong                       deviation;
        ENUM_ORDER_TYPE_FILLING     fillingType;
        ENUM_ACCOUNT_MARGIN_MODE    marginMode;

    public:
        MqlTradeRequest             request;
        MqlTradeResult              result;

                                    CTradeExecutor(void);
        
        //Trade methods
        ulong                       Buy(string pSymbol, double pVolume, double pStopLoss=0, double pTakeProfit=0, string pComment=NULL);
        ulong                       Sell(string pSymbol, double pVolume, double pStopLoss=0, double pTakeProfit=0, string pComment=NULL);

        void                        CloseTrades(string pSymbol, string pExitSignal);
        void                        Delete(ulong pTicket);

        //Các phương thức hỗ trợ kiểm tra đầu vào
        void                        SetMarginMode(void) {marginMode = (ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE);}
        bool                        IsHedging(void) {return (marginMode == ACCOUNT_MARGIN_MODE_RETAIL_HEDGING);}
        void                        SetMagicNumber(ulong pMagic) {magicNumber = pMagic;}
        void                        SetDeviation(ulong pDeviation) {deviation = pDeviation;}
        void                        SetFillingType(ENUM_ORDER_TYPE_FILLING pFillingType) {fillingType = pFillingType;}
        bool                        SelectPosition(string pSymbol);
};

//+------------------------------------------------------------------+
//| CTradeExecutor Class Methods                                     |
//+------------------------------------------------------------------+

CTradeExecutor::CTradeExecutor(void)
{
    SetMarginMode();

    ZeroMemory(request);
    ZeroMemory(result);
}

ulong CTradeExecutor::OpenPosition(string pSymbol,ENUM_ORDER_TYPE pType, double pVolume, double pPrice, double pStopLoss=0, double pTakeProfit=0, string pComment=NULL)
{
    ZeroMemory(request);
    ZeroMemory(result);

    //Request Parameters
    request.action       = TRADE_ACTION_DEAL;
    request.magic        = magicNumber;
    request.symbol       = pSymbol;
    request.type         = pType;
    request.volume       = pVolume;
    request.price        = pPrice; //Lệnh thị trường không cần giá nhưng một số brokers yêu cầu giá phải được truyền vào các tham số lệnh
    request.sl           = pStopLoss;
    request.tp           = pTakeProfit;
    request.deviation    = deviation;
    request.type_filling = fillingType;
    request.comment      = pComment;

    //Request Send
    if(!OrderSend(request,result))
        Print("OrderSend lỗi đặt lệnh giao dịch: ", GetLastError()); //Nếu yêu cầu không được gửi, in mã lỗi

    //Trade Information - result.price không được sử dụng cho lệnh thị trường
    Print("Order #",result.order," sent: ",result.retcode,", Volume: ",result.volume," Price: ",result.price,", Bid: ",result.bid,", Ask: ",result.ask);

    if(result.retcode==TRADE_RETCODE_DONE || result.retcode==TRADE_RETCODE_DONE_PARTIAL || result.retcode==TRADE_RETCODE_PLACED || result.retcode==TRADE_RETCODE_NO_CHANGES)
    {
        return result.order;
    }
    else return 0;
}

ulong CTradeExecutor::Buy(string pSymbol, double pVolume, double pStopLoss=0, double pTakeProfit=0, string pComment=NULL)
{
    return 0;
}

ulong CTradeExecutor::Sell(string pSymbol, double pVolume, double pStopLoss=0, double pTakeProfit=0, string pComment=NULL)
{
    return 0;
}
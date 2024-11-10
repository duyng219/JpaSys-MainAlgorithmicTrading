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

        void                        ModifyPosition(string pSymbol, ulong pTicket, double pStopLoss=0, double pTakeProfit=0);

        void                        CloseTrades(string pSymbol, string pExitSignal);

        //Các phương thức hỗ trợ kiểm tra đầu vào
        void                        SetMarginMode(void) {marginMode = (ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE);}
        bool                        IsHedging(void) {return (marginMode == ACCOUNT_MARGIN_MODE_RETAIL_HEDGING);}
        void                        SetMagicNumber(ulong pMagic) {magicNumber = pMagic;}
        void                        SetDeviation(ulong pDeviation) {deviation = pDeviation;}
        void                        SetFillingType(ENUM_ORDER_TYPE_FILLING pFillingType) {fillingType = pFillingType;}
        bool                        IsFillingTypeAllowed(int pFillType);
        string                      GetFillingTypeName(int pFillType);

        bool                        CheckPlacedPosition(ulong pMagic);
        bool                        CheckPositionProfitOrStopReached(ulong pMagic);
        
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
    Print("Order(Đặt hàng) #",result.order," sent(đã gửi): ",result.retcode,", Volume: ",result.volume," Price: ",result.price,", Bid: ",result.bid,", Ask: ",result.ask);

    if( result.retcode==TRADE_RETCODE_DONE         || 
        result.retcode==TRADE_RETCODE_DONE_PARTIAL || 
        result.retcode==TRADE_RETCODE_PLACED       || 
        result.retcode==TRADE_RETCODE_NO_CHANGES    )
    {
        return result.order;
    }
    else return 0;
}

ulong CTradeExecutor::Buy(string pSymbol, double pVolume, double pStopLoss=0, double pTakeProfit=0, string pComment=NULL)
{
    pComment = "BUY(MUA)" + " | " + pSymbol + " | " + string(magicNumber);
    double price = SymbolInfoDouble(pSymbol,SYMBOL_ASK);

    ulong ticket = OpenPosition(pSymbol,ORDER_TYPE_BUY,pVolume,price,pStopLoss,pTakeProfit,pComment);
    return(ticket);
}

ulong CTradeExecutor::Sell(string pSymbol, double pVolume, double pStopLoss=0, double pTakeProfit=0, string pComment=NULL)
{
    pComment = "SELL(BÁN)" + " | " + pSymbol + " | " + string(magicNumber);
    double price = SymbolInfoDouble(pSymbol,SYMBOL_BID);
		
	ulong ticket = OpenPosition(pSymbol,ORDER_TYPE_SELL,pVolume,price,pStopLoss,pTakeProfit,pComment);
	return(ticket);
}

void CTradeExecutor::ModifyPosition(string pSymbol, ulong pTicket, double pStopLoss=0, double pTakeProfit=0)
{
    if(!CheckPlacedPosition(magicNumber)) return;

    ZeroMemory(request);
    ZeroMemory(result);

    double tickSize = SymbolInfoDouble(pSymbol,SYMBOL_TRADE_TICK_SIZE);
    int digits      = (int)SymbolInfoInteger(pSymbol,SYMBOL_DIGITS);

    if(pStopLoss>0)   pStopLoss   = round(pStopLoss/tickSize) * tickSize;
    if(pTakeProfit>0) pTakeProfit = round(pTakeProfit/tickSize) * tickSize;

    request.action      = TRADE_ACTION_SLTP;
    request.position    = pTicket;
	request.sl          = pStopLoss;
	request.tp          = pTakeProfit;
	request.symbol      = pSymbol;
	request.comment     = "MOD(SỬA ĐỔI SLTP)." + " | " + pSymbol + " | " + string(magicNumber) + ", SL: " + DoubleToString(request.sl,digits) + ", TP: "+ DoubleToString(request.tp,digits);

    if(request.sl > 0 || request.tp > 0) 
	{
		Sleep(1000);
		bool sent = OrderSend(request,result);
		Print(result.comment);
		
		if(!sent) 
		{
		   Print("OrderSend Modification error: ", GetLastError());
		   Sleep(3000);
   		
            sent = OrderSend(request,result);
            Print(result.comment);
            if(!sent) Print("OrderSend 2nd Try Modification error: ", GetLastError());
		}
      
        if(result.retcode == TRADE_RETCODE_DONE || result.retcode == TRADE_RETCODE_DONE_PARTIAL || result.retcode == TRADE_RETCODE_PLACED || result.retcode == TRADE_RETCODE_NO_CHANGES)
        {
            Print(pSymbol, " #",pTicket, " modified(đã sửa đổi SL)");
        }				
	}
}

void CTradeExecutor::CloseTrades(string pSymbol, string pExitSignal)
{
    if(!CheckPlacedPosition(magicNumber)) return;

    ZeroMemory(request);
    ZeroMemory(result);

    ulong posMagic      = PositionGetInteger(POSITION_MAGIC);
    ulong posType       = PositionGetInteger(POSITION_TYPE);
    ulong posTicket     = PositionGetInteger(POSITION_TICKET);
    string posSymbol    = PositionGetString(POSITION_SYMBOL);

    if(posSymbol == pSymbol && posMagic == magicNumber && posType == POSITION_TYPE_BUY && (pExitSignal == "EXIT_BUY" || pExitSignal == "EXIT"))
    {
        request.action          = TRADE_ACTION_DEAL;
        request.type            = ORDER_TYPE_SELL;
        request.symbol          = pSymbol;
        request.volume          = PositionGetDouble(POSITION_VOLUME);
        request.price           = SymbolInfoDouble(pSymbol, SYMBOL_BID);
        request.deviation       = deviation;
        request.type_filling    = fillingType;
        request.position        = posTicket;

    }
    else if(posSymbol == pSymbol && posMagic == magicNumber && posType == POSITION_TYPE_SELL && (pExitSignal == "EXIT_SELL" || pExitSignal == "EXIT"))
    {
        request.action          = TRADE_ACTION_DEAL;
        request.type            = ORDER_TYPE_BUY;
        request.symbol          = pSymbol;
        request.volume          = PositionGetDouble(POSITION_VOLUME);
        request.price           = SymbolInfoDouble(pSymbol, SYMBOL_ASK);
        request.deviation       = deviation;
        request.type_filling    = fillingType;
        request.position        = posTicket;
    }
    if(request.action == TRADE_ACTION_DEAL)   //Added to prevent sending the order when there is no exit signal
        if(!OrderSend(request,result))
            Print("OrderSend trade close error: ", GetLastError());     //if request was not send, print error code
	   		
   if(result.retcode == TRADE_RETCODE_DONE || result.retcode == TRADE_RETCODE_DONE_PARTIAL || result.retcode == TRADE_RETCODE_PLACED || result.retcode == TRADE_RETCODE_NO_CHANGES) 
	{
      Print(pSymbol, " #",posTicket, " closed(đã đóng)");
   }
}

bool CTradeExecutor::CheckPlacedPosition(ulong pMagic)
{
    bool placedPosition = false;
    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        ulong positionTicket = PositionGetTicket(i);
        PositionSelectByTicket(positionTicket);

        ulong posMagic = PositionGetInteger(POSITION_MAGIC);

        if(posMagic == pMagic)
        {
            placedPosition = true;
            break;
        }
    }
    return placedPosition;   
}

bool CTradeExecutor::CheckPositionProfitOrStopReached(ulong pMagic)
{
    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        ulong positionTicket = PositionGetTicket(i);
        PositionSelectByTicket(positionTicket);

        ulong posMagic = PositionGetInteger(POSITION_MAGIC);
        double posStopLoss = PositionGetDouble(POSITION_SL);
        double posPriceOpen = PositionGetDouble(POSITION_PRICE_OPEN);
        double posProfit = PositionGetDouble(POSITION_PROFIT);

        // Kiểm tra nếu vị thế có magic number tương ứng
        if(posMagic == pMagic)
        {
            // Kiểm tra nếu StopLoss đạt đến Entry hoặc vị thế đang có lợi nhuận
            //if(posStopLoss >= posPriceOpen || posProfit > 0)
            // Kiểm tra nếu StopLoss đạt đến Entry  (Trailing Stop)
            if(posStopLoss >= posPriceOpen)
            {
                return true;
            }
        }
    }
    return false;
}

//+------------------------------------------------------------------+
//| NON-CLASS TRADE FUNCTIONS                                        |
//+------------------------------------------------------------------+

bool CTradeExecutor::IsFillingTypeAllowed(int pFillType)
{
    //Lấy giá trị của thuộc tính Filling of Symbol hiện tại
    int symbolFillingMode = (int)SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE);
    //Trả về "true" nếu chế độ fill_type được phép
    return ((symbolFillingMode & pFillType) == pFillType);
}

string CTradeExecutor::GetFillingTypeName(int pFillType)
{
    switch(pFillType)
    {
        case ORDER_FILLING_FOK:
            return "ORDER_FILLING_FOK.";
        case ORDER_FILLING_IOC:
            return "ORDER_FILLING_IOC.";
        case ORDER_FILLING_RETURN:
            return "ORDER_FILLING_RETURN.";
        default:
            return "UNKNOWN_FILLING_TYPE.";
    }
}
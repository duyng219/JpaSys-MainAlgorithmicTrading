//+------------------------------------------------------------------+
//|                                                  Strategy101.mq5 |
//|                                                            duyng |
//|                                      https://github.com/duyng219 |
//+------------------------------------------------------------------+
#property copyright "duyng"
#property link "https://github.com/duyng219"
#property version "2.00"

//+------------------------------------------------------------------+
//| Mô tả chiến lược                                                 |
//+------------------------------------------------------------------+
// EA mã hóa chiến lược Trung bình động - Giao dịch theo xu hướng
// Điều kiện vào lệnh (Entry Conditions): Xác định các tín hiệu vào lệnh dựa trên chỉ báo đường trung bình động MA Quy tắc vào lệnh theo xu hướng (breakout khỏi đường EMA). Mô tả cụ thể: Đặt các vị thế mua khi thanh cuối cùng đóng trên đường trung bình động và các vị thế bán khống khi thanh cuối cùng đóng dưới đường trung bình động
// Điều kiện thoát lệnh (Exit Conditions): Kết hợp các thiết lập lệnh hòa vốn và lệnh dừng lỗ theo sau (Trailing Stop ATR 14 * 2)
// Quản lý rủi ro (Risk Management): 1% vốn. Mô tả chi tiết: Lệnh dừng lỗ đối với các giao dịch mua dưới giá mở cửa hoặc đường trung bình động, đối với các giao dịch bán trên giá mở cửa hoặc đường trung bình động

//Version Log
//v2.0   Changed framework to OOP

//+------------------------------------------------------------------+
//| Objects & Include Files                                          |
//+------------------------------------------------------------------+
#include "../../Include/Framework.mqh"
#include "../../Include/Core/TradeExecutor.mqh"

CTradeExecutor  Trade;
CDate           Date;
CBar            Bar;
CiMA            MA;
CRM             RM;
CPM             PM;

//+------------------------------------------------------------------+
//| EA Enumerations                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Input & Global Variables                                         |
//+------------------------------------------------------------------+
sinput group                    "EA GENERAL SETTINGS"
input ulong                     MagicNumber         = 101;
input int                       Deviation           = 30;
// input ENUM_ORDER_TYPE_FILLING   FillingPolicy       = ORDER_FILLING_FOK;

sinput group                    "MOVING AVERAGE SETTINGS"
input int                       MAPeriod            = 21;
input ENUM_MA_METHOD            MAMethod            = MODE_EMA;
input int                       MAShift             = 0;
input ENUM_APPLIED_PRICE        MAPrice             = PRICE_CLOSE;

sinput group                    "ATR SETTINGS"
input int                       ATRPeriod           = 14;
input double                    ATRFactor           = 2.0;

sinput group                    "RISK MANAGEMENT"
sinput string                   strMM;              // --- Money Management ---
input ENUM_MONEY_MANAGEMENT     MoneyManagement     = MM_EQUITY_RISK_PERCENT;
input double                    RiskPercent         = 1;
input double                    MinLotPerEquityStep = 0;
input double                    FixedVolume         = 0.01;

sinput string                   strMaxLoss;         // --- Max Loss(Rủi ro giới hạn) ---
input double                    MaxLossPercent      = 0;
input ENUM_TIMEFRAMES           ProfitPeriod        = PERIOD_D1;
input uchar                     NumberOfPeriods     = 0;
input bool                      IncludeFloating     = false;

sinput group                    "POSITION MANAGEMENT"
input int                       SLFixedPoints       = 200;
// input int                       SLFixedPointsMA     = 0;
// input int                       TPFixedPoints       = 0;
// input int                       TSLFixedPoints      = 0;
// input int                       BEFixedPoints       = 0;

sinput group                    "DAY OF WEEK FILTER"
input bool                      Sunday              = false;
input bool                      Monday              = true;
input bool                      Tuesday             = true;
input bool                      Wednesday           = true;
input bool                      Thursday             = true;
input bool                      Friday              = true;
input bool                      Saturday            = false;

datetime                        glTimeBarOpen;
ENUM_ORDER_TYPE_FILLING         glFillingPolicy;

//+------------------------------------------------------------------+
//| Event Handlers                                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    Print("STRATEGY HAS BEEN INITIALIZED.");

    //KIỂM TRA INPUT
    //Kiểm tra phương thức khớp lệnh
    if(Trade.IsFillingTypeAllowed(SYMBOL_FILLING_FOK)) { 
        //ORDER_FILLING_FOK (Fill or Kill): Lệnh phải được khớp toàn bộ tại giá mong muốn. Nếu không thể khớp đủ khối lượng ngay lập tức, lệnh sẽ bị hủy.
        glFillingPolicy = ORDER_FILLING_FOK; Print("PHƯƠNG THỨC KHỚP LỆNH: ",Trade.GetFillingTypeName(glFillingPolicy)); 
    }
    else if(Trade.IsFillingTypeAllowed(SYMBOL_FILLING_IOC)) { 
        //ORDER_FILLING_IOC (Immediate or Cancel): Lệnh sẽ được khớp tối đa khối lượng có thể tại giá mong muốn ngay lập tức, và phần còn lại, nếu không khớp được, sẽ bị hủy.
        glFillingPolicy = ORDER_FILLING_IOC; Print("PHƯƠNG THỨC KHỚP LỆNH: ",Trade.GetFillingTypeName(glFillingPolicy)); 
    } else { 
        //ORDER_FILLING_RETURN (Return): Lệnh sẽ được khớp một phần và phần còn lại sẽ tiếp tục chờ để khớp ở các giá mong muốn sau đó.
        glFillingPolicy = ORDER_FILLING_RETURN; Print("PHƯƠNG THỨC KHỚP LỆNH: ",Trade.GetFillingTypeName(glFillingPolicy)); 
    }

    //SET VARIABLES
    Trade.SetDeviation(Deviation);
    Trade.SetMagicNumber(MagicNumber);
    Trade.SetFillingType(glFillingPolicy);
    glTimeBarOpen = D'1971.01.01 00.00';
    
    //Kiểm tra Account Hedging or Netting
    if (Trade.IsHedging()) { Print("ACCOUNT ĐANG Ở CHẾ ĐỘ HEDGING."); }
    else { Print("ACCOUNT ĐANG Ở CHẾ ĐỘ NETTING.");  return(INIT_FAILED); }
    
    //INITIALIZE METHODS
    int MAHandle = MA.Init(_Symbol,PERIOD_CURRENT,MAPeriod,MAShift,MAMethod,MAPrice);
    if(MAHandle == -1) { return(INIT_FAILED);}

    //DateTime
    Date.Init(Sunday,Monday,Tuesday,Wednesday,Thursday,Friday,Saturday);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    Print("STRATEGY HAS BEEN REMOVED.");
}

void OnTick()
{
    //--------------------------------------//
    //  STAGE 1: KIỂM TRA ĐẦU VÀO TỔNG THỂ 
    //--------------------------------------//
    string report = "";
    // Kiểm tra điều kiện giao dịch theo ngày và giờ
    if (!Date.IsTradingDay(report)) {Comment(report); return;}
         // // Dừng EA nếu là thứ Bảy hoặc Chủ nhật

    // Các logic giao dịch khác sẽ nằm ở đây...

    //Check for new bar & Date Filter
    bool newBar = false;
    bool dateFilter = Date.DayOfWeekFilter();

    if(glTimeBarOpen != iTime(Symbol(),PERIOD_CURRENT,0)) 
    { 
        newBar = true; 
        glTimeBarOpen = iTime(Symbol(),PERIOD_CURRENT,0); 
    }
    if(newBar && dateFilter)
    {
        //Khởi tạo Price & Indicators (Lấy giá trị để thiết lập điều kiện)
        Bar.Refresh(_Symbol,PERIOD_CURRENT,3);
        double close1 = Bar.Close(1); // Lấy nến đóng cửa đầu tiên - 0 là nến đang giao dịch
        double close2 = Bar.Close(2);
        //Normalization of close price to tick size
        double tickSize = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE); 
        close1 = round(close1/tickSize) * tickSize;
        close2 = round(close2/tickSize) * tickSize;
        //--Moving Average
        MA.RefreshMain();
        double ma1 = MA.main[1];
        double ma2 = MA.main[2];
        //--ATR

        //--------------------------------------------------//
        // STAGE 2: KIỂM TRA ĐIỀU KIỆN & TÍN HIỆU KÍCH HOẠT
        //--------------------------------------------------//

        //Tín hiệu kích hoạt chính
        string entrySignal = MA_EntrySignal(close1,close2,ma1,ma2);
        Comment("HELLO WORLD! "," | Magic Numer: ",MagicNumber, "\n");
        //--Kiểm tra điều kiện kích hoạt vị thế 
        if((!Trade.CheckPlacedPosition(MagicNumber) || Trade.CheckPositionProfitOrStopReached(MagicNumber)) && (entrySignal == "BUY" || entrySignal == "SELL"))
        {   
            //----------------------------------------//
            //   STAGE 3: MỞ VỊ THẾ (TRADE PLACEMENT)
            //----------------------------------------//
            
            ulong ticket = 0;
            //SL & TP Calculation
            double stopLoss = PM.CalculatorStopLoss(_Symbol,entrySignal,SLFixedPoints);

            if(entrySignal == "BUY")
            {
                //Tính toán Volume & Mở vị thế
                double volume = RM.MoneyManagement(_Symbol,MoneyManagement,MinLotPerEquityStep,RiskPercent,MathAbs(stopLoss-close1),FixedVolume,ORDER_TYPE_BUY);
                
                if(volume > 0) ticket = Trade.Buy(_Symbol,volume);
            }
            else if(entrySignal == "SELL")
            {
                //Tính toán Volume & Mở vị thế
                double volume = RM.MoneyManagement(_Symbol,MoneyManagement,MinLotPerEquityStep,RiskPercent,MathAbs(stopLoss-close1),FixedVolume,ORDER_TYPE_SELL);
                
                if(volume > 0) ticket = Trade.Sell(_Symbol,volume);
            }
            //SL & TP Trade Modification
            if(ticket > 0) { Trade.ModifyPosition(_Symbol,ticket,stopLoss); }
        }
        //----------------------------------------------//
        // STAGE 4: QUẢN LÝ VỊ THẾ (POSITION MANAGEMENT)
        //----------------------------------------------//
        
        //Sử dụng TrailingStopLoss để làm TP

        //--------------------------------------------//
        // STAGE 5: ĐÓNG VỊ THẾ (SIGNALS & TRADE EXIT)
        //--------------------------------------------//

        //Tín hiệu thoát & Đóng giao dịch thực hiện
        string exitSignal = MA_ExitSignal(close1,close2,ma1,ma2);
        if(exitSignal == "EXIT_BUY" || exitSignal == "EXIT_SELL")
            {
                Trade.CloseTrades(_Symbol,exitSignal);
            }
        Sleep(1000);
    }
}
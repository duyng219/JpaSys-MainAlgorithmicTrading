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
input double                    MinLotPerEquityStep = 500;
input double                    FixedVolume         = 0.05;

sinput string                   strMaxLoss;         // --- Max Loss(Rủi ro giới hạn) ---
input double                    MaxLossPercent      = 0;
input ENUM_TIMEFRAMES           ProfitPeriod        = PERIOD_D1;
input uchar                     NumberOfPeriods     = 0;
input bool                      IncludeFloating     = false;

sinput group                    "DAY OF WEEK FILTER"
input bool                      Sunday              = false;
input bool                      Monday              = true;
input bool                      Tuesday             = true;
input bool                      Wednesday           = true;
input bool                      Thursday             = true;
input bool                      Friday              = true;
input bool                      Saturday            = false;

// sinput group                    "POSITION MANAGEMENT"
// input int                       SLFixedPoints       = 0;
// input int                       SLFixedPointsMA     = 200;
// input int                       TPFixedPoints       = 0;
// input int                       TSLFixedPoints      = 0;
// input int                       BEFixedPoints       = 0;

datetime                        glTimeBarOpen;
ENUM_ORDER_TYPE_FILLING         glFillingPolicy;

//+------------------------------------------------------------------+
//| Event Handlers                                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    //SET VARIABLES
    glTimeBarOpen = D'1971.01.01 00.00';

    //KIỂM TRA INPUT
    //--Kiểm tra phương thức khớp lệnh
    if(Trade.IsFillingTypeAllowed(SYMBOL_FILLING_FOK)) { 
        //ORDER_FILLING_FOK (Fill or Kill): Lệnh phải được khớp toàn bộ tại giá mong muốn. Nếu không thể khớp đủ khối lượng ngay lập tức, lệnh sẽ bị hủy.
        glFillingPolicy = ORDER_FILLING_FOK; 
        Print("PHƯƠNG THỨC KHỚP LỆNH: ",Trade.GetFillingTypeName(glFillingPolicy)); 
    }
    else if(Trade.IsFillingTypeAllowed(SYMBOL_FILLING_IOC)) { 
        //ORDER_FILLING_IOC (Immediate or Cancel): Lệnh sẽ được khớp tối đa khối lượng có thể tại giá mong muốn ngay lập tức, và phần còn lại, nếu không khớp được, sẽ bị hủy.
        glFillingPolicy = ORDER_FILLING_IOC; 
        Print("PHƯƠNG THỨC KHỚP LỆNH: ",Trade.GetFillingTypeName(glFillingPolicy)); 
    }
    else { 
        //ORDER_FILLING_RETURN (Return): Lệnh sẽ được khớp một phần và phần còn lại sẽ tiếp tục chờ để khớp ở các giá mong muốn sau đó.
        glFillingPolicy = ORDER_FILLING_RETURN; 
        Print("PHƯƠNG THỨC KHỚP LỆNH: ",Trade.GetFillingTypeName(glFillingPolicy)); 
    }

    //--Kiểm tra Account Hedging or Netting
    if (Trade.IsHedging()) { Print("ACCOUNT ĐANG Ở CHẾ ĐỘ HEDGING."); }
    else { Print("ACCOUNT ĐANG Ở CHẾ ĐỘ NETTING.");  return(INIT_FAILED); }
    

    //INITIALIZE METHODS

    //DateTime
    Date.Init(Sunday,Monday,Tuesday,Wednesday,Thursday,Friday,Saturday);

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    Print("Expert removed");
}

void OnTick()
{
    //--------------------------------------//
    //  STAGE 1: KIỂM TRA ĐẦU VÀO TỔNG THỂ 
    //--------------------------------------//

    //--Check for new bar
    bool newBar = false;
    if(glTimeBarOpen != iTime(Symbol(),PERIOD_CURRENT,0)) 
    { 
        newBar = true; 
        glTimeBarOpen = iTime(Symbol(),PERIOD_CURRENT,0); 
    }
    if(newBar == true)
    {
        //--Khởi tạo Price & Indicators
        //--Price
        //--Normalization of close price to tick size(Chuẩn hóa giá đóng cửa theo kích thước tick)
        //--Moving Average
        //--ATR

        //--------------------------------------------//
        // STAGE 2: ĐÓNG VỊ THẾ (SIGNALS & TRADE EXIT)
        //--------------------------------------------//

        //Tín hiệu thoát & Đóng giao dịch thực hiện
        string exitSignal = "";
        if(exitSignal == "EXIT_BUY" || exitSignal == "EXIT_SELL")
            {
                
            }
        Sleep(1000);

        //--------------------------------------------//
        // STAGE 3: TÍN HIỆU KÍCH HOẠT (ENTRY SIGNALS)
        //--------------------------------------------//

        //--Tín hiệu kích hoạt chính
        string entrySignal = "";
        
        //--Lọc các ngày giao dịch trong tuần
        bool dateFilter = Date.DayOfWeekFilter();

        //--Kiểm tra Trend hiện tại BUY(UPTREND) & SELL(DOWNTREND)
        string isTrend = "";

        //--Kiểm tra điều kiện kích hoạt vị thế & mở vị thế
        //--Phần kiểm tra isTrend sử dụng class để tính toán và trả về entrySignal và isTrend
        // if((dateFilter == true)  && 
        //     ((entrySignal=="BUY" && isTrend=="UP_TREND") || 
        //     (entrySignal=="SELL" && isTrend=="DOWN_TREND")))
        // {
        if((!Trade.CheckPlacedPosition(MagicNumber) || Trade.CheckPositionProfitOrStopReached(MagicNumber)) && dateFilter && (entrySignal == "BUY" || entrySignal == "SELL"))
        {   
            //----------------------------------------//
            //   STAGE 4: MỞ VỊ THẾ (TRADE PLACEMENT)
            //----------------------------------------//

            //SL & TP Calculation
            if(entrySignal == "BUY")
            {
                //Calculate volume
            }
            else if(entrySignal == "SEll")
            {
                //Calculate volume
            }
            //SL & TP Trade Modification
        }
        //----------------------------------------------//
        // STAGE 5: QUẢN LÝ VỊ THẾ (POSITION MANAGEMENT)
        //----------------------------------------------//
        
    }
}
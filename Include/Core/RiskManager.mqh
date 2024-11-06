//+------------------------------------------------------------------+
//|                                                  RiskManager.mqh |
//|                                                            duyng |
//|                                      https://github.com/duyng219 |
//+------------------------------------------------------------------+
#property copyright "duyng"
#property link      "https://github.com/duyng219"

enum ENUM_MONEY_MANAGEMENT
{
    //MM_MIN_LOT_SIZE: Kích thước Volume tối thiểu của Symbol(VD: EURUSD Volume nhỏ nhất là 0.01)
    //MM_MIN_LOT_PER_EQUITY: Kích thước Volume tối thiểu / Vốn (VD: Account 1500(500(x3)) -> 3(Vốn chia đều) * 0.01(Volume Min Symbol) = 0.03)
    //MM_FIXED_LOT_SIZE: Kích thước Volume cố định(VD: Default 0.05 -> 0.05)
    //MM_FIXED_LOT_PER_EQUITY: Kích thước Volume tối thiểu / Vốn (VD: Account 1500(500(x3)) -> 3(Vốn chia đều) * 0.05(Volume cố định) = 0.15) (Khác với cách trên là thay vì dùng khối lượng nhỏ nhất thì ta truyền vào khối lượng cố định mà ta đưa vào)
    //MM_EQUITY_RISK_PERCENT: Phần trăm rủi ro trên Vốn(VD: 1%/10000$ = 100$)

    MM_MIN_LOT_SIZE,
    MM_MIN_LOT_PER_EQUITY,
    MM_FIXED_LOT_SIZE,
    MM_FIXED_LOT_PER_EQUITY,
    MM_EQUITY_RISK_PERCENT
};

class CRM
{
    private:


    public:

        
};

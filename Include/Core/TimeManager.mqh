//+------------------------------------------------------------------+
//|                                                  TimeManager.mqh |
//|                                                            duyng |
//|                                      https://github.com/duyng219 |
//+------------------------------------------------------------------+
#property copyright "duyng"
#property link      "https://github.com/duyng219"
#property version   "1.00"
//+------------------------------------------------------------------+
//|  Enumerations                                                    |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|  DateTime Base Class                                             |
//+------------------------------------------------------------------+
class CDateTime
{
    protected:
        //Variables
        MqlDateTime         currentDateTime;
    
    public:
        //Current Date & Time Methods
        int Year()          { TimeCurrent(currentDateTime); return currentDateTime.year;}
        int Month()         { TimeCurrent(currentDateTime); return currentDateTime.mon;}
        int Day()           { TimeCurrent(currentDateTime); return currentDateTime.day;}    //Day of month, 1 to 30/31, 28-29 feb
        int DayOfWeek()     { TimeCurrent(currentDateTime); return currentDateTime.day_of_week;}
        int Hour()          { TimeCurrent(currentDateTime); return currentDateTime.hour;}
        int Minute()        { TimeCurrent(currentDateTime); return currentDateTime.min;}
        int Seconds()       { TimeCurrent(currentDateTime); return currentDateTime.sec;}
};

class CDate : public CDateTime
{
    private:
        bool                daysOfWeek[7];
    
    public:
        //Date Signal Methods
        void                Init(bool pSunday,bool pMonday, bool pTuesday, bool pWednesday, bool pThursday, bool pFriday, bool pSaturday);

        //Day of Week Filter Method
        bool                DayOfWeekFilter();
};

void CDate::Init(bool pSunday,bool pMonday, bool pTuesday, bool pWednesday, bool pThursday, bool pFriday, bool pSaturday)
{
    daysOfWeek[0] = pSunday;
    daysOfWeek[1] = pMonday;
    daysOfWeek[2] = pTuesday;
    daysOfWeek[3] = pWednesday;
    daysOfWeek[4] = pThursday;
    daysOfWeek[5] = pFriday;
    daysOfWeek[6] = pSaturday;
}

bool CDate::DayOfWeekFilter()
{
    TimeCurrent(currentDateTime);
    // return (daysOfWeek[currentDateTime.day_of_week]);
    if(daysOfWeek[currentDateTime.day_of_week]) 
        return true;
    else
        Print("Error - Check lại DayOfWeekFilter", GetLastError());
        return false;
}



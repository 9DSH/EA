//+------------------------------------------------------------------+
//|                                                  The Hunter1.mq4 |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict




int gTkLineBearish, gKjLineBearish, gChLineBearish , gTkLineBullish , gKjLineBullish , gChLineBullish, gBullishKomu ,
    gBearishKomu,gTkExitTime,gKjExitTime, gClosedOrder,gModifiedOrder, gNewStart,gPAZoneCheck, gPARemove = 0;
int  gBullSpanA, gBullSpanB, gBearSpanA, gBearSpanB, gBullCrossStrong, gBearCrossStrong, gBullCandleBreak, 
     gBearCandleBreak , gBearHunter, gBullHunter, gEntry,gStopLoss,gRR,gPro, gAllHistoryOrders, gOverTrade;
double gPeakKomu, gDepthKomu, gPADepthLine , gPAPeakLine,gOpen ,gSumEntry, gSumStopLoss, gSumRR, gSumPro, gSumFear, gSumGreed,
       gPAExit_Peak, gPAExit_Depth,gMonitorOpen, gActivePA = 0;
datetime gBarTime , gBreakTime, gTime;
bool  gDeleteTicket;
string gSignal[3],gStop[3],gEmotion[3], gTake[3], gPoint[6],gHistory_PA[1];
string gSymbol,gMonitorTime;
string gUserpointCSV,gEmotionalCSV, gStopLossCSV, gTakeProfitCSV, gSignalsCSV,gPAZoneCSV, gPriceActionCSV , gAdditionalPACSV, gStrongPACSV;


//+-------------------------------------------------------------------------------------------------------------+
///// INPUSTS
//+-------------------------------------------------------------------------------------------------------------+ 

input int PriceAction_History = 1;
input int Add_PriceAction_in_Minute = 1440;
input double RISK = 3;
input int Timeframe = 30;
input int Trade_Number = 1;
input string LicenceKey = "AEojavDvRHY6SFk2U0ZrMlUwWnJNbFV3V25KTmJGVjNW";


//+-------------------------------------------------------------------------------------------------------------+
///// Initial Functions
//+-------------------------------------------------------------------------------------------------------------+

void FileCreation(string symbol)
   {
      gUserpointCSV = ""; gEmotionalCSV = ""; gStopLossCSV = ""; gTakeProfitCSV = "";
      gSignalsCSV = ""; gPriceActionCSV = ""; gPAZoneCSV = "";
      
      gUserpointCSV += "Userpoint-"; gUserpointCSV += symbol; gUserpointCSV += ".csv";
      gEmotionalCSV += "Emotional-"; gEmotionalCSV += symbol; gEmotionalCSV += ".csv";
      gStopLossCSV += "Stoploss-"; gStopLossCSV += symbol; gStopLossCSV += ".csv";
      gTakeProfitCSV += "Takeprofit-"; gTakeProfitCSV += symbol; gTakeProfitCSV += ".csv";
      gSignalsCSV += "Signals-"; gSignalsCSV += symbol; gSignalsCSV += ".csv";
      gPriceActionCSV += IntegerToString(Timeframe); gPriceActionCSV += "-Priceactions-"; gPriceActionCSV += symbol; gPriceActionCSV += ".csv";
      gPAZoneCSV += IntegerToString(Timeframe); gPAZoneCSV += "-PAZone-"; gPAZoneCSV += symbol; gPAZoneCSV += ".csv";
      
      if(Add_PriceAction_in_Minute != 0)
        {
           string Add_Timeframe = IntegerToString(Add_PriceAction_in_Minute);
           gAdditionalPACSV = ""; gAdditionalPACSV += Add_Timeframe; gAdditionalPACSV += "-Priceactions-"; 
           gAdditionalPACSV += symbol; gAdditionalPACSV += ".csv";
           
           gStrongPACSV = "";  gStrongPACSV += "Strong";  gStrongPACSV += "-Priceactions-"; 
           gStrongPACSV += symbol; gStrongPACSV += ".csv";
        }
   }
//+------------------------------------------------------------------+
bool LicenceCheck(string licence)
   {
       int LIC_EXPIRES_DAYS = 30;
       datetime LIC_START = D'2022.10.28';
       string LIC_PRIVATE_KEY = "HAMED";
       
       datetime ExpiredDate = LIC_START + (LIC_EXPIRES_DAYS*86400);
       //PrintFormat("Time Limited Copy, Licence to use expires at %s" , TimeToString(ExpiredDate)) ;
       if(TimeCurrent() > ExpiredDate)
         {
             MessageBox("Licence To Use Has Expired" + "\n" + "\n" + "Please Check Your Licence" , "LICENCE STATUS", MB_OK);
             return(false);
         }
 
       long account = AccountInfoInteger(ACCOUNT_LOGIN);
       account = 123456789;
       string result = KeyGen(IntegerToString(account),LIC_PRIVATE_KEY);
       
       if(result != licence)
            {
                  MessageBox("INVALID LICENCE" + "\n" + "Please Check Your Licence" , "LICENCE STATUS", MB_OK);
                  return(false);
            }
       
       
       return(true);
   }
//-------------------------------------------------------------------------------------
string KeyGen( string Account, string PrivateKey)
   {
       
       uchar accountChar[];
       StringToCharArray(Account,accountChar);
       
       uchar keyChar[];
       StringToCharArray(PrivateKey, keyChar);
       
       uchar resultChar[];
       CryptEncode(CRYPT_HASH_SHA256,accountChar, keyChar, resultChar);
       CryptEncode(CRYPT_BASE64, resultChar , resultChar, resultChar);
       
       string result = CharArrayToString(resultChar);
       return result;
   }
//+------------------------------------------------------------------+
void Monitoring_TimeSpread()
   {
        
        if(ObjectFind("SpreadBar") != True)
          {
               ObjectCreate("SpreadBar", OBJ_LABEL,0, 0, 0);
               ObjectSet("SpreadBar", OBJPROP_CORNER, 3);
               ObjectSet("SpreadBar", OBJPROP_XDISTANCE, 10);
               ObjectSet("SpreadBar", OBJPROP_YDISTANCE, 2); 
          }
        
        
        int Min,Sec;

        datetime date1=TimeCurrent(); 
        datetime date2=(Time[0] + Period()*60); 
        
        Min = date2 - date1;
        Sec = Min%60;
        Min = (Min - Sec)/60;
        
        double spread = MarketInfo(Symbol(), MODE_SPREAD);
       
        string _sp="",_m="",_s="";
        if (spread<10) _sp="..";
        else if (spread<100) _sp=".";
        if (Min<10) _m="0";
        if (Sec<10) _s="0";
  
       ObjectSetText("SpreadBar","Spread: " +DoubleToStr(spread,0)+_sp + " | "+" Next Bar Open in "
                     +_m+DoubleToStr(Min,0)+":"+_s+DoubleToStr(Sec,0), 10, "Courier", LightGray);
       
   }
//+------------------------------------------------------------------+   
void Start_ICHIGO()
   {
            datetime RightBarTime = iTime(_Symbol,Timeframe,0);
            gSymbol = Symbol();
            
            FileCreation(gSymbol);
            
            //if(!LicenceCheck(LicenceKey)) ExpertRemove();
            if(ThreeLines_DelayCheck() == False) 
              {
                  string Message = "\n"+ " > THREELINES DELAY CHECK COMPLETED -- There is no komu exit";
                  Comment(RightBarTime,Message);
              }
            CrossOver_DelayCheck(6);  
            Read_UserPoint(1);
            First_Run(gUserpointCSV);
            if(Is_TodayNewDay() == True)  Monitoring_Report(-1);
            gNewStart = 1;
            
            gOverTrade = Trade_Number;
            
         
   }


//+------------------------------------------------------------------+
void First_Run(string Filename)  
   {
       int FileHandle = FileOpen(Filename,FILE_READ|FILE_CSV);
       if(FileHandle == -1)
         {
            MessageBox("Everything is Prepared to Become a Pro Trader!!" + "\n" + "\n" + 
                       "ICHIGO microbot is able to record your activities and emotional reactions while you are trading." + "\n" + 
                       "Every day you will be reported by recorded points based on your interactions."  , "ICHIGO Microbot",MB_OK);
            FileClose(FileHandle);
           
         }
       else FileClose(FileHandle);
   }
//+------------------------------------------------------------------+
double PIP_Calculator( double Lot)
   {
       double PIP;
       if(Digits() == 3)  // XXX/JPY
         {
            double PairPrice = iClose("USDJPY",_Period,0);
            PIP = (0.001/PairPrice)*(Lot*100000);
            return PIP; 
         }
       if(Digits() == 5)
         {
            double PairPrice = 1;
            PIP = (0.00001/PairPrice)*(Lot*100000);
            return PIP;
         }
      return NULL;
       
   }
//+------------------------------------------------------------------+
bool Is_TodayNewDay()
   {
       if(StringToInteger(gPoint[0]) == 0) return false;
       
       datetime RightBarTime = iTime(_Symbol,Timeframe,0);
       int RightDay = TimeDay(RightBarTime);  // ex: 2 for 11/2
       int LastPointDay = TimeDay(StringToTime(gPoint[0]));
       if(RightDay > LastPointDay) return true;
       else return false;
       
   }
  
//------------------------------------------------------------------------------------------------------
//// Main Events
//------------------------------------------------------------------------------------------------------

void OnTick()
  {
     if(gNewStart == 0 )    Start_ICHIGO();
     if(PriceAction_History == 1) 
         {
           Historical_PriceAction(gPriceActionCSV);
           if(Add_PriceAction_in_Minute != 0) 
             {
                 Historical_PriceAction(gAdditionalPACSV);
                 Historical_PriceAction(gStrongPACSV);
             }
         }
          
     else if(gPARemove == 0)
         {
               Remove_Historical_PA(gPriceActionCSV);
               if(Add_PriceAction_in_Minute != 0)
                 {
                     Remove_Historical_PA(gAdditionalPACSV);
                     Remove_Historical_PA(gStrongPACSV);
                 }
         }
         
     Monitoring_TimeSpread();
     
     
     if(OrdersTotal() > 0)
       {
            gAllHistoryOrders = OrdersHistoryTotal();
            Initialize_Reports();
            StopLoss_Check();     // Fear
            TakeProfit_Check();   // Greed
            OverTrade_Check();    // Greed
       }
     else User_Activity();
     
     datetime RightBarTime = iTime(_Symbol,Timeframe,0);
     if(RightBarTime != gBarTime)
       {
           gBarTime = RightBarTime;
           
           CrossOverSignal(1);
           CrossOver(1);
           Komu_Signals();
           ThreeLinesSignal(27);
           if(gBreakTime != gBarTime) KomuOrder();
           if(Add_PriceAction_in_Minute != 0)
             {
                 Price_Action(gAdditionalPACSV,Add_PriceAction_in_Minute);
                 Nearby_PriceAction(gAdditionalPACSV,Add_PriceAction_in_Minute);
             }
           Price_Action(gPriceActionCSV,Timeframe);
           Nearby_PriceAction(gPriceActionCSV,Timeframe);
           Price_Action_Optimizer(200);
           Price_Action_Exit();
           if((gBullCandleBreak != 0) || (gBearCandleBreak != 0))
               {
                  if((gBreakTime != RightBarTime))
                    {
                        Price_Action_Check();
                    }
                }
                  
            
          
       }     
  }
//+------------------------------------------------------------------+ 
int deinit()
  {
      
        ObjectDelete("SpreadBar");
      
        //----
        return(0);
  } 

//+------------------------------------------------------------------------------------------------------------+
//// Compile and Initialize Reports
//+------------------------------------------------------------------------------------------------------------+

void PointValueCompiler(string Filename,int BytesWritten, int Shift)
   {
       int NumRecorded;
       double SumEntry = 0;
       double SumStopLoss = 0;
       double SumRR = 0;
       double SumPro = 0;
       string MonitorOpen;
       string MonitorTime;
       string Entry;
       string StopLoss;
       string RR;
       string Pro;
       
       if(Shift == -1)
         {
             NumRecorded = Number_Of_EventRecorded(Filename,BytesWritten);
             PrintFormat(IntegerToString(NumRecorded));
         }
       else NumRecorded = Shift;
       
      
       
       
       int FileHandle = FileOpen(Filename,FILE_READ|FILE_CSV);
       for(int i=1;i<=NumRecorded;i++)
         {
               string Recorded_Value;
               int Pointer = -BytesWritten*i;  // 34 = bytes written in every line
               
               if(FileSeek(FileHandle,Pointer,SEEK_END) == True) Recorded_Value = FileReadString(FileHandle,0);  
               
               
               Recorded_Value = StringSubstr(Recorded_Value,0,BytesWritten);
               MonitorTime =  StringSubstr(Recorded_Value,0,16);   // Time
               MonitorOpen = StringSubstr(Recorded_Value,17,7); 
               Entry = StringSubstr(Recorded_Value,25,1);   // Entry
               StopLoss = StringSubstr(Recorded_Value,27,1);   // Stoploss 
               RR = StringSubstr(Recorded_Value,29,1);   // RR
               Pro = StringSubstr(Recorded_Value,31,1);   // Pro 
               
               SumEntry += StringToDouble(Entry);
               SumStopLoss += StringToDouble(StopLoss);
               SumRR += StringToDouble(RR);
               SumPro += StringToDouble(Pro);
               
              
         } 
        gMonitorTime = MonitorTime;
        gMonitorOpen = StringToDouble(MonitorOpen); 
        gSumEntry = (SumEntry/NumRecorded)*100;
        gSumStopLoss = (SumStopLoss/NumRecorded)*100;
        gSumRR = (SumRR/NumRecorded)*100;
        gSumPro = (SumPro/NumRecorded)*100;
       
        FileClose(FileHandle);
       
   }
//+------------------------------------------------------------------+
void EmotionValueCompiler(string Filename,int BytesWritten, int Shift)
   {
       int NumRecorded;
       double SumFear = 0;
       double SumGreed = 0;
       string Fear;
       string Greed;
       
       if(Shift == -1)
         {
             NumRecorded = Number_Of_EventRecorded(Filename,BytesWritten);
         }
       else NumRecorded = Shift;
      
       
       
       int FileHandle = FileOpen(Filename,FILE_READ|FILE_CSV);
       for(int i=1;i<=NumRecorded;i++)
         {
               string Recorded_Value;
               int Pointer = -BytesWritten*i;  // 13 = bytes written in every line
               
               if(FileSeek(FileHandle,Pointer,SEEK_END) == True) Recorded_Value = FileReadString(FileHandle,0);  
               
               
               Recorded_Value = StringSubstr(Recorded_Value,0,BytesWritten);
                
               Fear = StringSubstr(Recorded_Value,8,1);   // Fear
               Greed = StringSubstr(Recorded_Value,10,1);   // Greed 
               
               SumFear += StringToDouble(Fear);
               SumGreed += StringToDouble(Greed);
               
              
         } 
         
        gSumFear = (SumFear/NumRecorded)*100;
        gSumGreed = (SumGreed/NumRecorded)*100;
       
        FileClose(FileHandle);
       
   }
//+------------------------------------------------------------------+
int Number_Of_EventRecorded(string Filename, int BytesWritten)
   {
      string First_Data;
      string Current_Data;
      int NumData;
      int Pointer  = 0 ;
      
      
      int FileHandle = FileOpen(Filename,FILE_READ|FILE_CSV);
     
      if(FileSeek(FileHandle,0,SEEK_SET) == True) First_Data = FileReadString(FileHandle,0);
      else return NULL;
      
      for(int i=0;i>=0;i++)
          {
            
            Pointer += BytesWritten;
            if(FileSeek(FileHandle,-Pointer,SEEK_END) == True) Current_Data = FileReadString(FileHandle,0);  
      
            if(Current_Data == First_Data)
              {
                 NumData = i+1;
                 FileClose(FileHandle);
                 return NumData;
              }
            else continue;
             
         } 
      return NULL;
   }

//+------------------------------------------------------------------+
void Initialize_Reports() 
   {
       int Emo_Index;
       int Take_Index;
       int Stop_Index;
       
       for(int i=OrdersTotal()-1;i>=0;i--)
         {
            if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
              {
                  if(OrderSymbol() == Symbol())
                    {
                        if((OrderType() == OP_BUY) || (OrdersTotal() == OP_SELL))
                          {
                              Emo_Index = Get_OrderIndex(gEmotionalCSV,"Data",13,OrderOpenPrice());
                              Take_Index = Get_OrderIndex(gTakeProfitCSV,"Data",17,OrderOpenPrice());
                              Stop_Index = Get_OrderIndex(gStopLossCSV,"Data",17,OrderOpenPrice());
                              
                              
                              if(Emo_Index == 0)   // means there is no emotional report for this position
                                {
                                     Record_UserEmotional("Append",0,OrderOpenPrice(),"0","0");
                                     Read_Emotional_Report(Emo_Index);
                                }
                              if(Stop_Index == 0)
                                {
                                     Record_Data("Append",gStopLossCSV,0,OrderOpenPrice(),OrderStopLoss());
                                     
                                }
                              if(Take_Index == 0)
                                {
                                     Record_Data("Append",gTakeProfitCSV,0,OrderOpenPrice(),OrderTakeProfit());
                                     
                                 
                                }
                          }
                        
                    }
              }
         }
   }
//+------------------------------------------------------------------+
void Monitoring_Report( int Shift)  // -1 for All record--- Shift must be more than 1
{
      
      PointValueCompiler(gUserpointCSV,34,Shift);
      EmotionValueCompiler(gEmotionalCSV,13,Shift);
      
      
      
      string MonitorTime = gMonitorTime;
      string MonitorOpen = DoubleToString(gMonitorOpen,Digits);
      string Entry = DoubleToString(gSumEntry,0);
      string StopLoss = DoubleToString(gSumStopLoss,0);
      string RR = DoubleToString(gSumRR,0);
      string Pro = DoubleToString(gSumPro,0);
      string Fear = DoubleToString(gSumFear,0);
      string Greed = DoubleToString(gSumGreed,0);
      
      string ReportTime;
      
      if(Shift == -1)
       {
           ReportTime = "OVERALL SCORES";
           
           MessageBox(  gSymbol  + "\n" + "\n" +
                       "> Your Entry: " + Entry  + "\n" +
                       "> Your Edge: " + StopLoss + "\n" +
                       "> Your Risk/Reward: " + RR + "\n" +
                       "> Your Pro: " + Pro + "\n" +
                       "> Your Fear: " + Fear + "\n" +
                       "> Your Greed: " + Greed , ReportTime,MB_OK);
       } 
      else 
      {
           ReportTime = "LAST SCORES";
           
           MessageBox( "Order Date: " + MonitorTime + "\n" +
                       "Order Symbol: " + gSymbol + "\n" +
                       "Open Price: " + MonitorOpen + "\n" + "\n" +
                       "> Your Entry: " + Entry  + "\n" +
                       "> Your Edge: " + StopLoss + "\n" +
                       "> Your Risk/Reward: " + RR + "\n" +
                       "> Your Pro: " + Pro + "\n" +
                       "> Your Fear: " + Fear + "\n" +
                       "> Your Greed: " + Greed , ReportTime,MB_OK);
      }
        
       
      
} 
//+------------------------------------------------------------------+

uint AppendToFile(string filename,int FilePointer,string text)
   {
      uint bytes_written = -1;
      int  filehandle    = FileOpen(filename,FILE_READ|FILE_WRITE);
      if(filehandle == INVALID_HANDLE)
         {
            // Something went wrong here.
            return(-1);
         }
      bool seek = FileSeek(filehandle,FilePointer,SEEK_END);
      if(seek == false)
         {
            // Something went wrong here.
            return(-1);
         }
      if(seek == true)
         {
            bytes_written = FileWriteString(filehandle, text, StringLen(text));
         }
      FileClose(filehandle);
      return(bytes_written);
   }
   
//+-----------------------------------------------------------------------------------------------------------+
//// Record Data 
//+-----------------------------------------------------------------------------------------------------------+

void Record_Signal(string Filename,datetime DataTime ,double DataPrice, int DataType)
   {
      string Data = "";
      Data += TimeToStr(DataTime) + ",";
      Data += DoubleToString(DataPrice,_Digits) + ",";
      Data += IntegerToString(DataType);
      Data += "\n"; 
      uint res = AppendToFile(Filename,0,Data);
      
   }
//+-----------------------------------------------------------------------+ 
void Record_Data(string Mode, string Filename,int Index, double OpenPrice ,double DataPrice)
   {
      string Data = "";
      Data += DoubleToString(OpenPrice,_Digits) + ",";
      Data += DoubleToString(DataPrice,_Digits);
      Data += "\n";
      
      
      if(Mode == "Append")      {uint res = AppendToFile(Filename,0,Data);}
      else if(Mode == "Modify") {uint res = AppendToFile(Filename,-17*Index,Data);}
      
   }
//+-----------------------------------------------------------------------+
void Record_UserEmotional(string Mode, int Index,double OpenPrice , string Fear, string Greed)
   {
      string Data = "";
      Data += DoubleToString(OpenPrice,_Digits) + ",";
      Data += Fear + ",";
      Data += Greed;
      Data += "\n";
      
      if(Mode == "Append")      {uint res = AppendToFile(gEmotionalCSV,0,Data);}
      else if(Mode == "Modify") {uint res = AppendToFile(gEmotionalCSV,-13*Index,Data);}
      
   }
//+-----------------------------------------------------------------------+ 
void Record_UserPoints(datetime DataTime , double OpenPrice, int Entry, int StopLoss, int RR, int Pro)
   {
      string Data = "";
      Data += TimeToStr(DataTime) + ",";
      Data += DoubleToString(OpenPrice,_Digits) + ",";
      Data += IntegerToString(Entry) + ",";
      Data += IntegerToString(StopLoss) + ",";
      Data += IntegerToString(RR) + ",";
      Data += IntegerToString(Pro);
      Data += "\n";
      
      
      uint res = AppendToFile(gUserpointCSV,0,Data);
      
   }
//+-----------------------------------------------------------------------+ 
void Record_PriceAction(string Filename, double PriceAction)
   {
      string Data = "";   
      Data += DoubleToString(PriceAction,_Digits);
      Data += "\n";
            
      uint res = AppendToFile(Filename,0,Data);
   
      
   }   
   
//+---------------------------------------------------------------------------------------------------------+ 
//// READ FILES
//+---------------------------------------------------------------------------------------------------------+ 


void Read_Emotional_Report(int Shift)
   {
      string Recorded_Value;
      int Pointer = -13*Shift;  // 13 = bytes written in every line
      
      int FileHandle = FileOpen(gEmotionalCSV,FILE_READ|FILE_CSV);
       // Accese to the point
      if(FileSeek(FileHandle,Pointer,SEEK_END) == True) Recorded_Value = FileReadString(FileHandle,0);  
      
      Recorded_Value = StringSubstr(Recorded_Value,0,13); 
      gEmotion[0] = StringSubstr(Recorded_Value,0,7);   // Price
      gEmotion[1] = StringSubstr(Recorded_Value,8,1);   // Fear
      gEmotion[2] = StringSubstr(Recorded_Value,10,1);   // Greed
      FileClose(FileHandle);
   }

//+------------------------------------------------------------------+
void Read_TakeProfit(int Shift)
   {
      string Recorded_Value;
      int Pointer = -17*Shift;  // 17 = bytes written in every line
      
      int FileHandle = FileOpen(gTakeProfitCSV,FILE_READ|FILE_CSV);
       // Accese to the point
      if(FileSeek(FileHandle,Pointer,SEEK_END) == True) Recorded_Value = FileReadString(FileHandle,0);  
      
      Recorded_Value = StringSubstr(Recorded_Value,0,17);  
      gTake[0] = StringSubstr(Recorded_Value,0,7);   // Open
      gTake[1] = StringSubstr(Recorded_Value,8,7);   // Price
      FileClose(FileHandle);
   }

//+------------------------------------------------------------------+
int Get_OrderIndex(string FileName,string Mode, int Bytes, double OpenPrice)
   {
      string OpenCompiled[1];
      int Num_Of_Order = Number_Of_EventRecorded(FileName,Bytes);
      if(Num_Of_Order != 0)
        {
            for(int i=Num_Of_Order;i>0;i--)
              {
                  string Recorded_Value;
                  int Pointer = -Bytes*i;  // bytes written in every line
                  
                  int FileHandle = FileOpen(FileName,FILE_READ|FILE_CSV);
                   // Accese to the point
                  if(FileSeek(FileHandle,Pointer,SEEK_END) == True) Recorded_Value = FileReadString(FileHandle,0);  
                  
                  Recorded_Value = StringSubstr(Recorded_Value,0,Bytes); 
                  if(Mode == "Data")
                    {
                        OpenCompiled[0] = StringSubstr(Recorded_Value,0,7);   // Open
                    }
                  if(Mode == "Point")
                    {
                        OpenCompiled[0] = StringSubstr(Recorded_Value,17,7);   // Open
                    } 
                  
                  
                  if((StringToDouble(OpenCompiled[0]) == OpenPrice))  // Means OpenPrice was recorded
                    {
                        FileClose(FileHandle);
                        return i;
                    }
                  else
                    {
                        FileClose(FileHandle);
                        continue;
                    }
                  
              }
           return 0;
            
        }
     else if(Num_Of_Order == 0)
            {
               return 0;
            }
     return 0;
      
   }

//+------------------------------------------------------------------+
void Read_StopLoss(int Shift)
   {
      string Recorded_Value;
      int Pointer = -17*Shift;  // 17 = bytes written in every line
      
      int FileHandle = FileOpen(gStopLossCSV,FILE_READ|FILE_CSV);
       // Accese to the point
      if(FileSeek(FileHandle,Pointer,SEEK_END) == True) Recorded_Value = FileReadString(FileHandle,0);  
      
      Recorded_Value = StringSubstr(Recorded_Value,0,17); 
      gStop[0] = StringSubstr(Recorded_Value,0,7);   // Open
      gStop[1] = StringSubstr(Recorded_Value,8,7);   // Price
      FileClose(FileHandle);
   }

//+------------------------------------------------------------------+
void Read_Signal(int Shift)
   {
      string Recorded_Value;
      int Pointer = -28*Shift;  // 28 = bytes written in every line
      
      int FileHandle = FileOpen(gSignalsCSV,FILE_READ|FILE_CSV);
       // Accese to the point
      if(FileSeek(FileHandle,Pointer,SEEK_END) == True) Recorded_Value = FileReadString(FileHandle,0);  
      
      Recorded_Value = StringSubstr(Recorded_Value,0,28);  
      gSignal[0] = StringSubstr(Recorded_Value,0,16);   // Time
      gSignal[1] = StringSubstr(Recorded_Value,17,7);   // Price
      gSignal[2] = StringSubstr(Recorded_Value,25,1);   // Type 
      FileClose(FileHandle);
   }

//+------------------------------------------------------------------+
void Read_UserPoint(int Shift)
   {
      string Recorded_Value;
      int Pointer = -34*Shift;  // 34 = bytes written in every line
      
      int FileHandle = FileOpen(gUserpointCSV,FILE_READ|FILE_CSV);
       // Accese to the point
      if(FileSeek(FileHandle,Pointer,SEEK_END) == True) Recorded_Value = FileReadString(FileHandle,0);  
      
      Recorded_Value = StringSubstr(Recorded_Value,0,34); 
      gPoint[0] = StringSubstr(Recorded_Value,0,16);   // Time
      gPoint[1] = StringSubstr(Recorded_Value,17,7);   // Open
      gPoint[2] = StringSubstr(Recorded_Value,25,1);   // Entry
      gPoint[3] = StringSubstr(Recorded_Value,27,1);   // Stoploss 
      gPoint[4] = StringSubstr(Recorded_Value,29,1);   // RR
      gPoint[5] = StringSubstr(Recorded_Value,31,1);   // Pro 
      FileClose(FileHandle);
   }

//+------------------------------------------------------------------+
void Read_PriceAction(string Filename, int Shift)
   {
      string Recorded_Value;
      int Pointer = -9*Shift;
      int FileHandle = FileOpen(Filename,FILE_READ|FILE_CSV);
       // Accese to the point
      if(FileSeek(FileHandle,Pointer,SEEK_END) == True) Recorded_Value = FileReadString(FileHandle,0);  
      
      Recorded_Value = StringSubstr(Recorded_Value,0,9);
      gHistory_PA[0] = StringSubstr(Recorded_Value,0,7);   // Priceaction
      FileClose(FileHandle);
   }
   
//+-------------------------------------------------------------------------------------------------------+
//// User Interactions Check
//+-------------------------------------------------------------------------------------------------------+

void TakeProfit_Check()
   {
       datetime RightBarTime = iTime(_Symbol,Timeframe,0);
       int Take_Index;
       int Emo_Index;
       for(int i=OrdersTotal()-1;i>=0;i--)
         {
            if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
              {
                  if(OrderSymbol() == Symbol())
                    {
                        if(OrderType() == OP_BUY)
                          {
                              if(OrderTakeProfit() != 0)
                                {
                                    Take_Index = Get_OrderIndex(gTakeProfitCSV,"Data",17,OrderOpenPrice());
                                    Read_TakeProfit(Take_Index);
                                    if(OrderTakeProfit() != StringToDouble(gTake[1]))  // if tp dosen't record
                                      {
                                            Record_Data("Modify",gTakeProfitCSV,Take_Index,OrderOpenPrice(),OrderTakeProfit());
                                      }
                                    if((StringToDouble(gTake[1]) != 0) 
                                    && (OrderTakeProfit() > StringToDouble(gTake[1])) 
                                    && (((StringToDouble(gTake[1]) - Bid)/_Point) <= 100))
                                       {
                                            int MB = MessageBox("HEY YOU!!"+ "\n" +
                                                                "Don't Be So Greedy, Let Your TP Hit, After That You Can Open Another Position" + "\n" +
                                                                "If You Are Agree, Close The Order Right Now !?","TAKE PROFIT",MB_YESNO);
                                            if(MB == 6)  // Yes
                                               {
                                                  gClosedOrder = OrderClose(OrderTicket(),OrderLots(),Bid,100,0);
                                               }
                                            if(MB == 7)
                                               {
                                                  Emo_Index = Get_OrderIndex(gEmotionalCSV,"Data",13,OrderOpenPrice());
                                                  Read_Emotional_Report(Emo_Index);
                                                  
                                                  double Greed = StringToDouble(gEmotion[2]) + 1;
                                                  Record_UserEmotional("Modify",Emo_Index,OrderOpenPrice(),gEmotion[1],DoubleToString(Greed,0));
                                                  
                                               }
                                       }
                                }
                          }
                       if(OrderType() == OP_SELL)
                         {
                             if(OrderTakeProfit() != 0)
                                {
                                    Take_Index = Get_OrderIndex(gTakeProfitCSV,"Data",17,OrderOpenPrice());
                                    Read_TakeProfit(Take_Index);
                                    if(OrderTakeProfit() != StringToDouble(gTake[1]))  // if tp dosen't record
                                      {
                                            Record_Data("Modify",gTakeProfitCSV,Take_Index,OrderOpenPrice(),OrderTakeProfit());
                                      }
                                    if((StringToDouble(gTake[1]) != 0) 
                                    && (OrderTakeProfit() < StringToDouble(gTake[1])) 
                                    && (((Ask - StringToDouble(gTake[1]))/_Point) <= 100))
                                       {
                                            int MB = MessageBox("HEY YOU!!"+ "\n" +
                                                                "Don't Be So Greedy, Let Your TP Hit, After That You Can Open Another Position" + "\n" +
                                                                "If You Are Agree, Close The Order Right Now !?","TAKE PROFIT",MB_YESNO);
                                            if(MB == 6)  // Yes
                                               {
                                                  gClosedOrder = OrderClose(OrderTicket(),OrderLots(),Ask,100,0);
                                               }
                                            if(MB == 7)
                                               {
                                                  Emo_Index = Get_OrderIndex(gEmotionalCSV,"Data",13,OrderOpenPrice());
                                                  Read_Emotional_Report(Emo_Index);
                                                  
                                                  double Greed = StringToDouble(gEmotion[2]) + 1;
                                                  Record_UserEmotional("Modify",Emo_Index,OrderOpenPrice(),gEmotion[1],DoubleToString(Greed,0));
                                               }
                                       }
                                }
                         }
                    }
              }
         }
   }
//+------------------------------------------------------------------+
void StopLoss_Check()   
   {
      datetime RightBarTime = iTime(_Symbol,Timeframe,0);
      int Stop_Index;
      int Emo_Index;
      for(int i=OrdersTotal()-1;i>=0;i--)
        {
            if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
              {
                 if(OrderSymbol() == Symbol())
                   {
                        if(OrderType() == OP_BUY)
                          {
                               if(OrderStopLoss() == 0)
                                  {
                                   
                                   Stop_Index = Get_OrderIndex(gStopLossCSV,"Data",17,OrderOpenPrice());
                                   Read_StopLoss(Stop_Index);
                                   if((Stop_Index != 0) && (StringToDouble(gStop[1]) != 0))
                                     {
                                         
                                         int MBS = MessageBox(" You Just Removed Your Stoploss!! " + "\n" +
                                                              " You Are Risking Your Whole Margin," + "\n" +
                                                              " If You Are Agree, Change It Back ?", "STOP LOSS", MB_YESNO);
                                         if(MBS == 6)  // Yes
                                               {
                                                  gModifiedOrder = OrderModify(OrderTicket(), OrderOpenPrice(), StringToDouble(gStop[1]),OrderTakeProfit(),0,0);
                                               }
                                         if(MBS == 7)
                                               {
                                                  Emo_Index = Get_OrderIndex(gEmotionalCSV,"Data",13,OrderOpenPrice());
                                                  Read_Emotional_Report(Emo_Index);
                                                  
                                                  double Fear = StringToDouble(gEmotion[1]) + 1;
                                                  Record_UserEmotional("Modify",Emo_Index,OrderOpenPrice(),DoubleToString(Fear,0),gEmotion[2]);
                                                  Record_Data("Modify",gStopLossCSV,Stop_Index,OrderOpenPrice(),OrderStopLoss());
                                               }
                                     }
                                   else
                                     {
                                        double PIP_Value = PIP_Calculator(OrderLots());
                                        double Risk = (AccountBalance()*RISK/100);
                                        int MB = MessageBox("Don't Forget STOPLOSS!!" + "\n" + "\n" +
                                                            "Pip Value (Based on Your Lot): " + DoubleToString(PIP_Value,4) + "\n" +
                                                            "Best Stoploss (PIP): " + DoubleToString((Risk/PIP_Value),0),"STOP LOSS",MB_OK);
                                     }
                                   
                                   
                                   }
                               else
                                 {
                                       Stop_Index = Get_OrderIndex(gStopLossCSV,"Data",17,OrderOpenPrice());
                                       Read_StopLoss(Stop_Index);
                                       if(OrderStopLoss() != StringToDouble(gStop[1]))  // if sl doesn't record
                                            {
                                                Record_Data("Modify",gStopLossCSV,Stop_Index,OrderOpenPrice(),OrderStopLoss());
                                               
                                            }
                                       if((StringToDouble(gStop[1]) != 0) 
                                       && (OrderStopLoss() < StringToDouble(gStop[1]))
                                       && (Bid <= OrderOpenPrice())  && (((Bid - OrderStopLoss())/_Point) <= 100))                   // User Change StopLoss To more
                                         {
                                             int MB = MessageBox("You Just Let Your Loss Run!!"+ "\n" +
                                                                 "Don't Be Afraid, Let Your SL Hit and Embarace New Apportunity" + "\n" +
                                                                 "If You Are Agree, Change It Back ?","STOP LOSS",MB_YESNO);
                                             if(MB == 6)  // Yes
                                               {
                                                  gModifiedOrder = OrderModify(OrderTicket(), OrderOpenPrice(), StringToDouble(gStop[1]),OrderTakeProfit(),0,0);
                                               }
                                             if(MB == 7)
                                               {
                                                  Emo_Index = Get_OrderIndex(gEmotionalCSV,"Data",13,OrderOpenPrice());
                                                  Read_Emotional_Report(Emo_Index);
                                                  
                                                  double Fear = StringToDouble(gEmotion[1]) + 1;
                                                  Record_UserEmotional("Modify",Emo_Index,OrderOpenPrice(),DoubleToString(Fear,0),gEmotion[2]);
                                               }
                                         }
                                 }                          
                          }
                       if(OrderType() == OP_SELL)
                         {
                              if(OrderStopLoss() == 0)
                                  {
                                      Stop_Index = Get_OrderIndex(gStopLossCSV,"Data",17,OrderOpenPrice());
                                      Read_StopLoss(Stop_Index);
                                      if((Stop_Index != 0) && (StringToDouble(gStop[1]) != 0))
                                        {
                                            
                                            
                                            int MBS = MessageBox(" You Just Removed Your Stoploss!! " + "\n" +
                                                                 " You Are Risking Your Whole Margin," + "\n" +
                                                                 " If You Are Agree, Change It Back ?", "STOP LOSS", MB_YESNO);
                                            if(MBS == 6)  // Yes
                                                  {
                                                     gModifiedOrder = OrderModify(OrderTicket(), OrderOpenPrice(), StringToDouble(gStop[1]),OrderTakeProfit(),0,0);
                                                  }
                                            if(MBS == 7)
                                                  {
                                                     Emo_Index = Get_OrderIndex(gEmotionalCSV,"Data",13,OrderOpenPrice());
                                                     Read_Emotional_Report(Emo_Index);
                                                     
                                                     double Fear = StringToDouble(gEmotion[1]) + 1;
                                                     Record_UserEmotional("Modify",Emo_Index,OrderOpenPrice(),DoubleToString(Fear,0),gEmotion[2]);
                                                     Record_Data("Modify",gStopLossCSV,Stop_Index,OrderOpenPrice(),OrderStopLoss());
                                                  }
                                        }
                                      else
                                        {
                                            double PIP_Value = PIP_Calculator(OrderLots());
                                            double Risk = (AccountBalance()*RISK/100);
                                            int MB = MessageBox("Don't Forget STOPLOSS!!" + "\n" + "\n" +
                                                                "Pip Value (Based on Your Lot): " + DoubleToString(PIP_Value,4) + "\n" +
                                                                "Best Stoploss (PIP): " + DoubleToString((Risk/PIP_Value),0),"STOP LOSS",MB_OK);
                                        }
                                                                     
                                   }
                               else
                                 {
                                       Stop_Index = Get_OrderIndex(gStopLossCSV,"Data",17,OrderOpenPrice());
                                       Read_StopLoss(Stop_Index);
                                       if(OrderStopLoss() != StringToDouble(gStop[1]))  // if sl doesn't record
                                            {
                                                Record_Data("Modify",gStopLossCSV,Stop_Index,OrderOpenPrice(),OrderStopLoss());
                                            }
                                       if((StringToDouble(gStop[1]) != 0) 
                                       && (OrderStopLoss() > StringToDouble(gStop[1])) 
                                       && (Ask >= OrderOpenPrice()) && (((OrderStopLoss()-Ask)/_Point) <= 100))                     // User Change StopLoss To more
                                         {
                                             int MB = MessageBox("You Just Let Your Loss Run!!"+ "\n" +
                                                                 "Don't Be Afraid, Let Your SL Hit and Embarace New Apportunity" + "\n" +
                                                                 "If You Are Agree, Change It Back ?","STOP LOSS",MB_YESNO);
                                             if(MB == 6)  // Yes
                                               {
                                                  gModifiedOrder = OrderModify(OrderTicket(),OrderOpenPrice(),StringToDouble(gStop[1]),OrderTakeProfit(),0,0);
                                               }
                                             if(MB == 7)
                                               {
                                                  Emo_Index = Get_OrderIndex(gEmotionalCSV,"Data",13,OrderOpenPrice());
                                                  Read_Emotional_Report(Emo_Index);
                                                  
                                                  double Fear = StringToDouble(gEmotion[1]) + 1;
                                                  Record_UserEmotional("Modify",Emo_Index,OrderOpenPrice(),DoubleToString(Fear,0),gEmotion[2]);
                                                   
                                               }
                                         }
                                 } 
                         }
                    }
                        
                            
                 } 
        }
   }
//+------------------------------------------------------------------+ 
void OverTrade_Check()
   {
      
      
      datetime RightBarTime = iTime(_Symbol,Timeframe,0);
      int RightMonth = TimeMonth(RightBarTime);
      int RightDay = TimeDay(RightBarTime);
      int NumberOfPositions = 0;
      int HSTTotal=OrdersHistoryTotal();
      
      for(int i=0;i<HSTTotal;i++)
          {
               if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY))
                 { 
                    int PosMonth = TimeMonth(OrderOpenTime());
                    int PosDay = TimeDay(OrderOpenTime());
                    if((OrderSymbol() == Symbol()) && (RightMonth == PosMonth)  && (RightDay == PosDay)) NumberOfPositions++;
                 }
          }    
                     
      for(int i=OrdersTotal()-1;i>=0;i--)
        {
           if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
             {
               if((OrderType() == OP_BUY) && (OrderType() == OP_SELL))
                 {
                     int PosMonth = TimeMonth(OrderOpenTime());
                     int PosDay = TimeDay(OrderOpenTime());
                     if((OrderSymbol() == gSymbol) && (RightMonth == PosMonth)  && (RightDay == PosDay)) NumberOfPositions++;
                 }
                 
             } 
        }
        
      
      if(NumberOfPositions > gOverTrade)
        {
          
          MessageBox("OverTrade Warning","OVERTRADE",MB_OK);
          gOverTrade = NumberOfPositions;
          double Greed = StringToDouble(gEmotion[2]) + 1;
          Record_UserEmotional("Modify",1,OrderOpenPrice(),gEmotion[1],DoubleToString(Greed,0));
        }
   }
//+------------------------------------------------------------------+
bool GoodEntry(double SignalPrice , double OpenPositionPrice)   
   {
      double MaxValidZone = SignalPrice + 100*_Point;
      double MinValidZone = SignalPrice - 100*_Point;
      if((OpenPositionPrice >= MinValidZone) && (OpenPositionPrice <= MaxValidZone)) return true;
      return false;
   }
//+------------------------------------------------------------------+ 
double Risk_to_Reward(int ordertype,double Profit ,double OpenPrice, double StopLoss, double ClosePrice)
   {
        double RR;
        double Win_Zone;
        double Loss_Zone;
        if(ordertype == 0) // Buy
           {
               if(Profit > 0) 
                 {
                    Win_Zone = ClosePrice - OpenPrice;
                // if user change sl to positive value or use trailing step
                    if(StopLoss >= OpenPrice) Loss_Zone = Win_Zone;   // will get RR = 1
                    else Loss_Zone = OpenPrice - StopLoss;
               
                    RR = Win_Zone/Loss_Zone;  
                    
                 }
               else RR = 0;
               
               return RR;
               
           } 
        if(ordertype == 1)  // Sell
           {
               if(Profit > 0)
                 {
                    Win_Zone = OpenPrice - ClosePrice;
                    if(StopLoss <= OpenPrice) Loss_Zone = Win_Zone;   // will get RR = 1
                    else Loss_Zone = StopLoss - OpenPrice;
                    
                    RR = Win_Zone/Loss_Zone;
                 }
               else RR = 0;
               
               return RR;
           }
        
        return NULL;
         
   }

//+------------------------------------------------------------------+
void User_Activity()  // When Orders Closed
   {
       if((OrdersHistoryTotal() > gAllHistoryOrders))
             {
                  int HSTTotal=OrdersHistoryTotal();
      
                  for(int i=0;i<HSTTotal;i++)
                      {
                           if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY))
                             { 
                                 if(OrderSymbol() == gSymbol)
                                   {
                                      Check_History_Orders();
                                      gAllHistoryOrders = OrdersHistoryTotal();
                                      gOverTrade = Trade_Number;
                                      Monitoring_Report(1);
                                      break;
                                   }
                             }
                      }  
                 
             }
             
   }
//+------------------------------------------------------------------+
void Check_History_Orders() 
   {
      int Point_Index;
      int Emo_Index;
      int Entry = 0;
      int StopLoss = 0;
      int Pro = 0;
      int RR = 0;
                      
      int NumHistoryOrders = OrdersHistoryTotal();
      for(int i=0;i<NumHistoryOrders;i++)
        {
            
            if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY))
              {
                  if(OrderSymbol() == gSymbol)
                    {
                       if((OrderType() == OP_BUY) || (OrderType() == OP_SELL))
                         {
                               
                               Point_Index = Get_OrderIndex(gUserpointCSV,"Point",34,OrderOpenPrice());
                               Emo_Index = Get_OrderIndex(gEmotionalCSV,"Data",13,OrderOpenPrice());
                               
                               Read_UserPoint(Point_Index);
                               Read_Emotional_Report(Emo_Index);
                               
                               if(OrderOpenPrice() != StringToDouble(gPoint[1]))
                                    {
                                         if(GoodEntry(StringToDouble(gSignal[1]),OrderOpenPrice()) == True) Entry = 1;
                                         else Entry = 0;
                                         
                                                                                  
                                         if((OrderStopLoss() != 0) && (StringToInteger(gEmotion[1]) == 0)) // && There were no fear in changing Sl
                                           {
                                                 StopLoss =1;
                                                 
                                                 if(Risk_to_Reward(OrderType(),OrderProfit(),OrderOpenPrice(),
                                                                   OrderStopLoss(),OrderClosePrice()) >= 1)
                                                    {
                                                        RR = 1;
                                                    }
                                                 else RR = 0;
                                           }
                                        else StopLoss = 0;   // Dosent attention to MB , Gambler point
                                        
                                        
                                        if((Entry == 1) && (StopLoss == 1) && (RR == 1) && (StringToInteger(gEmotion[1]) == 0) 
                                        && (StringToInteger(gEmotion[2]) == 0)) Pro = 1;
                                        else Pro = 0;
                                        
                                        Record_UserPoints(OrderOpenTime(),OrderOpenPrice(),Entry,StopLoss,RR,Pro);
                                               
                                    }
                               else continue;
                         }
                       else continue;
                           
                   }
                 else continue;    
            }
        }
   }  
//+-----------------------------------------------------------------------------------------------------------+
//+--------------------------------------- Technical Section -------------------------------------------------+
//+-----------------------------------------------------------------------------------------------------------+

//+-----------------------------------------------------------------------------------------------------------+
//// Delay Signals Check
//+-----------------------------------------------------------------------------------------------------------+

bool ThreeLines_DelayCheck() 
   {
      for(int i=4;i>0;i--)
        {
           if((TenkenSenLine_BearishExit(i) == True) || (TenkenSenLine_BullishExit(i) == True) ||
               (KijunSenLine_BearishExit(i) == True) || (KijunSenLine_BullishExit(i) == True))
                   {
                      for(int j=27+i;j>i;j--)
                           {
                               ThreeLinesSignal(j);
                           }
                      return true;
                   }
                    
        }
      return false;
   }
//+------------------------------------------------------------------+
void CrossOver_DelayCheck(int Shift)
   {
       for(int i=Shift;i>=0;i--)
           {
               CrossOverSignal(i);
               CrossOver(i);
               
           }  
   }

//+-----------------------------------------------------------------------------------------------------------+
//// Cross Over Signals 
//+-----------------------------------------------------------------------------------------------------------+

void CrossOverSignal(int Shift) // 1
  {
   double TenkenSen_current = iIchimoku(_Symbol,Timeframe,9,26,52,1,Shift); // Crossed Candle = 1
   double KijunSen_current = iIchimoku(_Symbol,Timeframe,9,26,52,2,Shift);
   double TenkenSen_previous = iIchimoku(_Symbol,Timeframe,9,26,52,1,Shift+2);
   double KijunSen_previous = iIchimoku(_Symbol,Timeframe,9,26,52,2,Shift+2);
   double ChikouSpan = iIchimoku(_Symbol,Timeframe,9,26,52,5,Shift+26);
   double HighPrice= High[Shift+26];
   double LowPrice = Low[Shift+26];
   datetime RightBarTime = iTime(_Symbol,Timeframe,Shift);
   
   
   if(TenkenSen_previous < KijunSen_previous && TenkenSen_current > KijunSen_current ) // is going to be Uptrend
     {
       if(ChikouSpan > HighPrice)
         {
            gBullCrossStrong++;
            if(gBearCrossStrong == 1)
              {
                  gBearCrossStrong = 0;
                  string Message ="\n" + " >  Status: Bearish Cross Failed -- Bullish CROSSOVER";
                  Alert(gSymbol + " | Bearish Cross Failed -- Bullish CrossOver | You Can Wait for Kijunsen to Hit Greater Value");
                  Comment(RightBarTime,Message);
              }
            else
              {
                  gBearCrossStrong = 0; 
                  string Message ="\n" + " >  Status: Strong Bullish CROSSOVER";
                  Alert(gSymbol + " | Strong Bullish CrossOver | You Can Wait for Kijunsen to Hit Greater Value");
                  Comment(RightBarTime,Message);
              }
            
         }
       else
         {
            string Message ="\n" + " >  Status: Weak Bullish CROSSOVER" ;
            Comment(RightBarTime,Message);
         
         }
            
     } 
   else if(TenkenSen_previous > KijunSen_previous && TenkenSen_current < KijunSen_current) // is going to be Downtrend
     {
       if(ChikouSpan < LowPrice)
         {
            gBearCrossStrong++;
            if(gBullCrossStrong == 1 )
              {
                  gBullCrossStrong = 0;
                  string Message ="\n" + " >  Status: Bullish Cross Failed -- Bearish CROSSOVER"; 
                  Alert(gSymbol + " | Bullish Cross Failed -- Bearish CrossOver | You Can Wait for Kijunsen to Hit Lower Value");
                  Comment(RightBarTime,Message);
              }
            else
              {
                  gBullCrossStrong = 0;
                  string Message ="\n" + " >  Status: Strong Bearish CROSSOVER"; 
                  Alert(gSymbol + " | Strong Bearish CrossOver | You Can Wait for Kijunsen to Hit Lower Value");
                  Comment(RightBarTime,Message);
              }
            
         }
       else
         {
            string Message ="\n" + " >  Status: Weak Bearish CROSSOVER" ;
            Comment(RightBarTime,Message);
         }
       
     } 
   else if(TenkenSen_current == KijunSen_current && TenkenSen_previous < KijunSen_previous) 
     { 
       if(ChikouSpan > HighPrice)
         {
            gBullCrossStrong++;
            if(gBearCrossStrong == 1)
              {
                  gBearCrossStrong = 0;
                  string Message ="\n" + " >  Status: Bearish Cross Failed -- Bullish Road CROSSOVER";
                  Alert(gSymbol + " | Bearish Cross Failed -- Bullish Road CrossOver | You Can Wait for Kijunsen to Hit Greater Value");
                  Comment(RightBarTime,Message);
              }
            else
              {
                  gBearCrossStrong = 0;
                  string Message ="\n" + " >  Status: Strong Bullish Road CROSSOVER";
                  Alert(gSymbol + " | Strong Bullish Road CrossOver | You Can Wait for Kijunsen to Hit Greater Value");
                  Comment(RightBarTime,Message);
              }
            
         }
       else
         {
            string Message ="\n" + " >  Status: Weak Bullish Road CROSSOVER" ;
            Comment(RightBarTime,Message);
         
         }
       
     }
   else if(TenkenSen_current == KijunSen_current && TenkenSen_previous > KijunSen_previous)
     {
       if(ChikouSpan < LowPrice)
         {
            gBearCrossStrong++;
            if(gBullCrossStrong == 1)
              {
                  gBullCrossStrong = 0;
                  string Message ="\n" + " >  Status: Bullish Cross Failed -- Bearish Road CROSSOVER"; 
                  Alert(gSymbol + " | Bullish Cross Failed -- Bearish Road CrossOver | You Can Wait for Kijunsen to Hit Lower value");
                  Comment(RightBarTime,Message);
              }
            else
              {
                  gBullCrossStrong = 0;
                  string Message ="\n" + " >  Status: Strong Bearish Road CROSSOVER"; 
                  Alert(gSymbol + " | Strong Bearish Road CrossOver | You Can Wait for Kijunsen to Hit Lower value");
                  Comment(RightBarTime,Message);
              }
            
         }
       else
         {
            string Message ="\n" + " >  Status: Weak Bearish Road CROSSOVER" ;
            Comment(RightBarTime,Message);
         }
     }
       
  } 

//+------------------------------------------------------------------+
void CrossOver(int Shift) // 1
   {
      
      datetime RightBarTime = iTime(_Symbol,Timeframe,Shift-1);
      if((gBullCrossStrong != 0)) 
        {   
            if(ICHI(Shift-1) == "UP"  || ICHI(Shift-1) == "ROAD")
              {
                   Bull_Hunter(Shift);
                   if(gBullHunter == 1)
                     {
                          
                           if(Komu_Situation(Shift) == "KomuZone")
                             {
                                 gBullHunter = 0;
                                 string Message ="\n" + " >  Status: KOMU Limitation -- Have Patience!";
                                 Comment(RightBarTime,Message); 
                                 Alert(gSymbol + " | KOMU Situation -- Candles Are Inside The Komu, Recommendations: "  ,"\r\n" , " > Waiting for candels to validly break from komu. "
                                   ,"\r\n" , " > Waiting for ThreeLines Signal. "  ,"\r\n" , " > You can trade between the resistances of komu, with caution. ");
                                 
                             }
                           else CrossOrder(Shift,"BULL");
                          
                     }
                   
              }
        }
      else if((gBearCrossStrong != 0))
             {
               if(ICHI(0) == "DOWN" || ICHI(0) == "ROAD")
                 {
                     Bear_Hunter(Shift);
                     if(gBearHunter == 1)
                       {
                           if(Komu_Situation(Shift) == "KomuZone")
                             {
                                 gBearHunter = 0;
                                 string Message ="\n" + " >  Status: KOMU Limitation -- Have Patience!";
                                 Alert(gSymbol + " | KOMU Situation -- Candles Are Inside The Komu, Recommendations: "  ,"\r\n" , " > Waiting for candels to validly break from komu. "
                                   ,"\r\n" , " > Waiting for ThreeLines Signal. "  ,"\r\n" , " > You can trade between the resistances of komu, with caution. ");
                                 Comment(RightBarTime,Message); 
                             }
                           else CrossOrder(Shift,"BEAR");
                       }
                 }
             }
   }
//+------------------------------------------------------------------+
string ICHI(int Shift)
   {
     double TenkenSen_current = iIchimoku(_Symbol,Timeframe,9,26,52,1,Shift);
     double KijunSen_current = iIchimoku(_Symbol,Timeframe,9,26,52,2,Shift); 
     if(TenkenSen_current > KijunSen_current)
       {
         string trend = "UP";
         return trend;
       }
     else if(TenkenSen_current < KijunSen_current)
            {
               string trend = "DOWN";
               return trend;
            }
     else
       {
         string trend = "ROAD";
         return trend;
       }
   }
//+------------------------------------------------------------------+  
double  Divergence(int Shift) // 0
   {
      double DivergValue;
      
      double KijunSen_new = iIchimoku(_Symbol,Timeframe,9,26,52,2,Shift);
      double TenkenSen_new = iIchimoku(_Symbol,Timeframe,9,26,52,1,Shift);
      
      if(KijunSen_new > TenkenSen_new)
        {
            DivergValue = (KijunSen_new - TenkenSen_new)/_Point;
            return DivergValue;
        }
      else
        {
             DivergValue = (TenkenSen_new - KijunSen_new)/_Point;
             return DivergValue;
        }

      
   }
//+------------------------------------------------------------------+  

double Candle_Shadow_Length(int Shift, string Type)
   {
      double ClosePrice = Close[Shift];
      double OpenPrice = Open[Shift];
      double HighPrice = High[Shift];
      double LowPrice = Low[Shift];
      double UpperShadow;
      double LowerShadow;
      
      if(ClosePrice > OpenPrice) // Bull
        {
            UpperShadow = HighPrice - ClosePrice;
            LowerShadow = OpenPrice - LowPrice;
            
        }
      else // Bear
        {
            UpperShadow = HighPrice - OpenPrice;
            LowerShadow = ClosePrice - LowPrice; 
        }
      if(Type == "UP") return UpperShadow/_Point;
      if(Type == "DOWN") return LowerShadow/_Point;
      
      return NULL;
      
   }
//+------------------------------------------------------------------+ 

void CrossOrder(int Shift,string Type) // 1
   {
         gBullHunter = 0;
         gBearHunter = 0;
         datetime RightBarTime = iTime(_Symbol,Timeframe,Shift);
         if(Type == "BULL")
           {
               if(Candle_Shadow_Length(Shift,"UP") <= 500)
                    {
                        if((BuyConfirmation(Shift) == True))
                          {
                                               
                              Read_Signal(1);
                              if(StringToDouble(gSignal[1]) != Ask) Record_Signal(gSignalsCSV,RightBarTime,Ask,0);
                                 
                              string Message ="\n" + " >  Status: CROSSOVER -- BULLISH CROSSOVER"; 
                              Alert(gSymbol + " | BULLISH CROSSOVER -- Bulls In Control"); 
                              Comment(RightBarTime,Message);
                          }    
                        else
                          {
                              
                              string Mess = "\n" + " >  Status: KOMU Limitation -- Candles Are Trying to Break Komu Resistances ";
                              Alert(gSymbol + " | KOMU LIMITATION -- Opening Position is not Recommended, Wait for Candles to Break Komu Resistance Validly");
                              Comment(RightBarTime,Mess);
                              
                          }
                    }
              else
                     {
                           
                           string HunterMessage ="\n" + " >  Status: CROSS FAILED | Volatility is Too High...";
                           Comment(RightBarTime,HunterMessage);
                     } 
           }
        else if(Type == "BEAR")
               {
                     if(Candle_Shadow_Length(Shift,"DOWN") <= 500)
                       {
                          if((SellConfirmation(Shift) == True))
                             {
                                 
                                 Read_Signal(1);
                                 if(StringToDouble(gSignal[1]) != Bid) Record_Signal(gSignalsCSV,RightBarTime,Bid,1);
                                 
                                 string Message ="\n" + " >  Status: CROSSOVER -- BEARISH CROSSOVER";
                                 Alert(gSymbol + " | BEARISH CROSSOVER -- Bears In Control");
                                 Comment(RightBarTime,Message);
                             }
                           else
                             {
                                 string Mess = "\n" + " >  Status: KOMU Limitation -- Candles Are Trying to Break Komu Resistances ";
                                 Alert(gSymbol + " | KOMU LIMITATION -- Opening Position is Not Recommended, Wait for Candles to Break Komu Resistance Validly");
                                 Comment(RightBarTime,Mess);
                             }
                       }
                     else
                        {
                              string HunterMessage ="\n" + " >  Status: CROSS FAILED | Volatility is Too High...";
                              Comment(RightBarTime,HunterMessage);
                        }
               }
   } 
//+------------------------------------------------------------------+
void Bull_Hunter( int Shift) // 1
   {  
      double KijunSen_previous = iIchimoku(_Symbol,Timeframe,9,26,52,2,Shift+1);
      double KijunSen_new = iIchimoku(_Symbol,Timeframe,9,26,52,2,Shift);
      double LastClosePrice = Close[Shift];
      datetime RightBarTime = iTime(_Symbol,Timeframe,Shift);
      
      if(KijunSen_new > KijunSen_previous)
        {
            gBullCrossStrong = 0;
            
            if((Divergence(Shift-1) <= 100))
               { 
                     gBullHunter = 1;
               }
            
            else
               {    
                     
                     string Message ="\n" + " >  Status: INVALID CROSSOVER -- Divergence Between Tenkensen and Kijunsen is too High"; 
                     Alert(gSymbol + " | Opening Position is not Recommended, There Are Divergences Between the Lines."); 
                     Comment(RightBarTime,Message);
               }
              
        }
      else
        {
            
            string HunterMessage ="\n" + " >  Status: BULLISH CROSSOVER | Waiting For Kijunsen To Hit Greater Value..."; 
            Comment(RightBarTime,HunterMessage);
             
        }
    } 

//+------------------------------------------------------------------+
void Bear_Hunter(int Shift)
   {  
      double KijunSen_previous = iIchimoku(_Symbol,Timeframe,9,26,52,2,Shift+1);
      double KijunSen_new = iIchimoku(_Symbol,Timeframe,9,26,52,2,Shift);
      double LastClosePrice = Close[Shift];
      datetime RightBarTime = iTime(_Symbol,Timeframe,Shift);
      
      if(KijunSen_new < KijunSen_previous)
        {
            gBearCrossStrong = 0;
            if((Divergence(Shift-1) <= 100))
               { 
                     gBearHunter = 1;
               }
            else
               {    
                     
                     string Message ="\n" + " >  Status: INVALID CROSSOVER -- Divergence Between Tenkensen and Kijunsen is too High"; 
                     Alert(gSymbol + " | Opening Position is not Recommended, There Are Divergences Between the Lines."); 
                     Comment(RightBarTime,Message);
               }
        }
      else
        {
            
            string HunterMessage ="\n" + " >  Status: BEARISH CROSSOVER | Waiting For Kijunsen To Hit Lower Value...";  
            Comment(RightBarTime,HunterMessage);
            
        }     

    } 

//+------------------------------------------------------------------+
bool SellConfirmation(int Shift) //1
   {
      double Upper_Open = Open[Shift+1];
      double Current_Open = Open[Shift-1];
      double Span_A = iIchimoku(_Symbol,Timeframe,9,26,52,3,Shift-1);
      double Span_B = iIchimoku(_Symbol,Timeframe,9,26,52,4,Shift-1);
      
      
      if((Span_B > Span_A) && (Upper_Open > Span_B) && (Current_Open < Span_A) ) return false; // Komu Struggle
      else return true;                       
     
   }
//+------------------------------------------------------------------+
bool BuyConfirmation(int Shift)
   {  
      double Lower_Open = Open[Shift+1];
      double Current_Open = Open[Shift-1];
      double Span_A = iIchimoku(_Symbol,Timeframe,9,26,52,3,Shift-1);
      double Span_B = iIchimoku(_Symbol,Timeframe,9,26,52,4,Shift-1);
      
      
      if((Span_B < Span_A) && (Lower_Open < Span_B) && (Current_Open > Span_A)) return false; // Komu Struggle
      else return true;
                             
     
   }
   
//+-----------------------------------------------------------------------------------------------------------+
//// Komu Interactions
//+-----------------------------------------------------------------------------------------------------------+

void Komu_Signals()
   {
      datetime RightBarTime = iTime(_Symbol,Timeframe,0);
      if(Komu_Situation(1) == "Bull_B_Break")
        {
            gBullSpanB = 1;
            gBreakTime = iTime(_Symbol,Timeframe,0);
            string Message ="\n" + " >  Status: BREAKEVEN -- SenkouSpan B Breakeven, Wait For Confirmation";
            Comment(RightBarTime,Message);
        }
      if(Komu_Situation(1) == "Bull_A_Break")
        {
            gBullSpanA = 1;
            gBreakTime = iTime(_Symbol,Timeframe,0);
            string Message = "\n" + " >  Status: BREAKEVEN -- SenkouSpan A Breakeven, Wait For Confirmation";
            Comment(RightBarTime,Message);
        }
      if(Komu_Situation(1) == "Bear_B_Break")
        {
            gBearSpanB = 1;
            gBreakTime = iTime(_Symbol,Timeframe,0);
            string Message ="\n" + " >  Status: BREAKEVEN -- SenkouSpan B Breakeven, Wait For Confirmation";
            Comment(RightBarTime,Message);
        }
      if(Komu_Situation(1) == "Bear_A_Break")
        {
            gBearSpanA = 1;
            gBreakTime = iTime(_Symbol,Timeframe,0);
            string Message ="\n" + " >  Status: BREAKEVEN -- SenkouSpan A Breakeven, Wait For Confirmation";
            Comment(RightBarTime,Message);
        }   
   }
//+------------------------------------------------------------------+
string Komu_Situation(int Shift) // 1
   {
      double Komu_Resistance;
      double Last_Open = Open[Shift];
      double Last_Close = Close[Shift];
      double Prev_Low = Low[Shift+1];
      double Prev_High = High[Shift+1];
      double Span_A = iIchimoku(_Symbol,Timeframe,9,26,52,3,Shift);
      double Span_B = iIchimoku(_Symbol,Timeframe,9,26,52,4,Shift);
      
      if(Span_B < Span_A)  // Bullish komu
         {
            if((Last_Close < Span_A) && (Last_Close > Span_B))  // candels inside the komu 
              {
                  string Message ="KomuZone";
                  return Message;
              }
            if((Last_Open < Span_A) && (Last_Open > Span_B) && (Last_Close < Span_B) && (Prev_Low >= Span_B) ) // Span B breakeven
              {
                  Komu_Resistance = Span_B;
                  if(Candle_Breakeven(Shift,Komu_Resistance) == True)
                    {
                        string Message = "Bull_B_Break";
                        return Message;
                    }
              }
            if((Last_Open < Span_A) && (Last_Open > Span_B) && (Last_Close > Span_A) && (Prev_High <= Span_A)) // Span A Bearkeven
              {
                  Komu_Resistance = Span_A;
                  if(Candle_Breakeven(Shift,Komu_Resistance) == True)
                    {
                        string Message = "Bull_A_Break ";
                        return Message;
                    }
              }
         }      
        
      if(Span_B > Span_A)  // Bearish komu 
         {
            
            if((Last_Close > Span_A) && (Last_Close < Span_B))  // candels inside the komu 
              {
                  string Message ="KomuZone";
                  return Message;
              }
            if((Last_Open > Span_A) && (Last_Open < Span_B) && (Last_Close > Span_B) && (Prev_High <= Span_B)) // Span B breakeven
              {
                  Komu_Resistance = Span_B;
                  if(Candle_Breakeven(Shift,Komu_Resistance) == True)
                    {
                        string Message = "Bear_B_Break";
                        return Message;
                    }
              }
            if((Last_Open > Span_A) && (Last_Open < Span_B) && (Last_Close < Span_A) && (Prev_Low >= Span_A)) // Span A Bearkeven
              {
                  Komu_Resistance = Span_A;
                  if(Candle_Breakeven(Shift,Komu_Resistance) == True)
                    {
                        string Message = "Bear_A_Break";
                        return Message;
                    }
              }
            
         }
      return NULL; 
     }
//+------------------------------------------------------------------+
void KomuOrder()  
   {
      double Resistance_A;
      double Resistance_B;
      double Span_A = iIchimoku(_Symbol,Timeframe,9,26,52,3,1);
      double Span_B = iIchimoku(_Symbol,Timeframe,9,26,52,4,1);
      datetime RightBarTime = iTime(_Symbol,Timeframe,0);
             
      if(gBullSpanB != 0)
        {
            Resistance_B = Span_B;
            gBullSpanB = 0;
            if(Break_Validation("BEARISH",Resistance_B) == True)
              {
                  if(is_PrevCandle_Touch_Resistance(3,"BEARISH",Resistance_B) == False)
                     {
                          
                           string Message ="\n" + ">  Status: BREAKEVEN -- BULLISH KOMU BREAK.";
                           Alert(gSymbol + " | BULLISH Komu Resistance (SenkouSpan B) Broken by Valid Candle, And Next Candle Didn't Pull Back to Komu.");
                           Comment(RightBarTime,Message);
                     }
                  else
                    {
                           string Message ="\n" + ">  Status: UNCURTAIN BREAKEVEN -- BULLISH KOMU BREAK.";
                           Alert(gSymbol + " | BULLISH Komu Resistance (SenkouSpan B) Broken by Valid Candle, And Next Candle Didn't Pull Back to Komu. But Former Candle Touched The SenkouSpan B. ");
                           Comment(RightBarTime,Message);
                    }
                  
              }
            else
              {
                  string Message = "\n" + ">  Status: INVALID BREAKEVEN -- BULLISH KOMU BREAK.";
                  Alert(gSymbol + " | BULLISH Komu Resistance (SenkouSpan B) Broken by Valid Candle, BUT Next Candle Pulled Back to Komu." ,"\r\n" , "You Should Wait For Valid Break.." );
                  Comment(RightBarTime,Message);
              }
        }
      if(gBearSpanA != 0)
        {
            Resistance_A = Span_A;
            gBearSpanA = 0;
            if(Break_Validation("BEARISH",Resistance_A) == True)
              {
                  if(is_PrevCandle_Touch_Resistance(3,"BEARISH",Resistance_A) == False)
                    {
                        string Message ="\n" + ">  Status: BREAKEVEN -- BEARISH KOMU BREAK.";
                        Alert(gSymbol + " | BEARISH Komu Resistance (SenkouSpan A) Broken by Valid Candle, And Next Candle Didn't Pull Back to Komu.");
                        Comment(RightBarTime,Message);
                    }
                  else
                    {
                        string Message ="\n" + ">  Status: UNCURTAIN BREAKEVEN -- BEARISH KOMU BREAK.";
                        Alert(gSymbol + " | BEARISH Komu Resistance (SenkouSpan A) Broken by Valid Candle, And Next Candle Didn't Pull Back to Komu.  But Former Candle Touched The SenkouSpan A.");
                        Comment(RightBarTime,Message);
                    }
                  
                  
              }
            else
              {
                  string Message = "\n" + ">  Status: INVALID BREAKEVEN -- BEARISH KOMU BREAK.";
                  Alert(gSymbol + " | BEARISH Komu Resistance (SenkouSpan A) Broken by Valid Candle, BUT Next Candle Pulled Back to Komu." ,"\r\n" , "You Should Wait For Valid Break.." );
                  Comment(RightBarTime,Message);
              }
        }
        
      if(gBearSpanB != 0)
        {
            Resistance_B = Span_B;
            gBearSpanB = 0;
            if(Break_Validation("BULLISH",Resistance_B) == True)
              {
                   if(is_PrevCandle_Touch_Resistance(3,"BULLISH",Resistance_B) == False)
                     {
                            string Message ="\n" + ">  Status: BREAKEVEN -- BEARISH KOMU BREAK.";
                            Alert(gSymbol + " | BEARISH Komu Resistance (SenkouSpan B) Broken by Valid Candle, And Next Candle Didn't Pull Back to Komu.");
                            Comment(RightBarTime,Message);
                     }
                   else
                     {
                            string Message ="\n" + ">  Status: UNCURTAIN BREAKEVEN -- BEARISH KOMU BREAK.";
                            Alert(gSymbol + " | BEARISH Komu Resistance (SenkouSpan B) Broken by Valid Candle, And Next Candle Didn't Pull Back to Komu. But Former Candle Touched The SenkouSpan A.");
                            Comment(RightBarTime,Message);
                     }
                   
              }
            else
              {
                   string Message ="\n" +  ">  Status: INVALID BREAKEVEN -- BEARISH KOMU BREAK.";
                   Alert(gSymbol + " | BEARISH Komu Resistance (SenkouSpan B) Broken by Valid Candle, BUT Next Candle Pulled Back to Komu." ,"\r\n" , "You Should Wait For Valid Break.." );
                   Comment(RightBarTime,Message);
              }
        }
        
      if(gBullSpanA != 0)
        {
            Resistance_A = Span_A;
            gBullSpanA = 0;
            if(Break_Validation("BULLISH",Resistance_A) == True)
              {
                   if(is_PrevCandle_Touch_Resistance(3,"BULLISH",Resistance_A) == False)
                     {
                            
                            string Message ="\n" + ">  Status: BREAKEVEN -- BULLISH KOMU BREAK.";
                            Alert(gSymbol + " | BULLISH Komu Resistance (SenkouSpan A) Broken by Valid Candle, And Next Candle Didn't Pull Back to Komu.");
                            Comment(RightBarTime,Message);
                     }
                   else
                     {
                            string Message ="\n" + ">  Status: UNCURTAIN BREAKEVEN -- BULLISH KOMU BREAK.";
                            Alert(gSymbol + " | BULLISH Komu Resistance (SenkouSpan A) Broken by Valid Candle, And Next Candle Didn't Pull Back to Komu. But Former Candle Touched The SenkouSpan A.");
                            Comment(RightBarTime,Message);
                     }
                   
              }
            else
              {
                   string Message ="\n" +  ">  Status: INVALID BREAKEVEN -- BULLISH KOMU BREAK.";
                   Alert(gSymbol + " | BULLISH Komu Resistance (SenkouSpan A) Broken by Valid Candle, BUT Next Candle Pulled Back to Komu." ,"\r\n" , "You Should Wait For Valid Break.." );
                   Comment(RightBarTime,Message);
              }
        }
   }
//+------------------------------------------------------------------+

void KomuSwitch(int Shift)
   {
      double SenkouSpan_B_For_Chikou_p = iIchimoku(_Symbol,Timeframe,9,26,52,4,Shift);
      double SenkouSpan_A_For_Chikou_p = iIchimoku(_Symbol,Timeframe,9,26,52,3,Shift);
      
      if(SenkouSpan_A_For_Chikou_p > SenkouSpan_B_For_Chikou_p)
        {
            
                  double SenkouSpan_B_Current = iIchimoku(_Symbol,Timeframe,9,26,52,4,Shift-1);
                  double SenkouSpan_A_Current = iIchimoku(_Symbol,Timeframe,9,26,52,3,Shift-1);
                  if(SenkouSpan_A_Current < SenkouSpan_B_Current)
                    {
                        gTkLineBullish = 0;
                        gKjLineBullish = 0;
                        gChLineBullish = 0;
                        gTkLineBearish = 0;
                        gKjLineBearish = 0;
                        gChLineBearish = 0;
                    }

        }
      if(SenkouSpan_A_For_Chikou_p < SenkouSpan_B_For_Chikou_p)
        {
            
                  double SenkouSpan_B_Current1 = iIchimoku(_Symbol,Timeframe,9,26,52,4,Shift-1);
                  double SenkouSpan_A_Current1 = iIchimoku(_Symbol,Timeframe,9,26,52,3,Shift-1);
                  if(SenkouSpan_A_Current1 > SenkouSpan_B_Current1)
                    {
                        gTkLineBullish = 0;
                        gKjLineBullish = 0;
                        gChLineBullish = 0;
                        gTkLineBearish = 0;
                        gKjLineBearish = 0;
                        gChLineBearish = 0;
                    }
               
        }
        
        }

//+------------------------------------------------------------------+
int ExitTime(int Shift)
   {
      datetime ExitTime = iTime(_Symbol,Timeframe,Shift);
      int TimeToHour = TimeHour(ExitTime);
      int TimeToMin = TimeMinute(ExitTime);
      if((TimeToHour == 0) && (TimeToMin == 0))
        {
            TimeToHour = 24;
        }
      int TimeHourToMin = TimeToHour*60;
      int ExitTimeToMin = TimeHourToMin + TimeToMin;
      return ExitTimeToMin;
   }
//+------------------------------------------------------------------+
int TimeExitDifference(int Exit1 , int Exit2)
   {
      int TimeDifference;
      if(Exit2 > Exit1)
        {
            Exit2 = 1440 - Exit2;
            TimeDifference = Exit2 + Exit1;
        }
      else TimeDifference = Exit1 - Exit2;
      return TimeDifference;
   }
   
//+-----------------------------------------------------------------------------------------------------------+
//// Three Lines Signals 
//+-----------------------------------------------------------------------------------------------------------+

void ThreeLinesExits(int Shift) // 27
   {
      double Span_A = iIchimoku(_Symbol,Timeframe,9,26,52,3,Shift-27);
      double Span_B = iIchimoku(_Symbol,Timeframe,9,26,52,4,Shift-27);
      if(Span_A > Span_B)
        {
           if(TenkenSenLine_BullishExit(Shift-26) == True)
             {
                 string Message ="\n" + " > Status: KOMU -- Tenkensen Exits From Bullish Komu" + "\n" +
                  " > ThreeLines Status : ";
                 datetime RightBarTime = iTime(_Symbol,Timeframe,Shift-27); 
                 Comment(RightBarTime,Message,gTkLineBearish,gKjLineBearish,gChLineBearish);
             }
           if(KijunSenLine_BullishExit(Shift-26) == True)
             {
                string Message ="\n" + " > Status: KOMU -- Kijunsen Exits From Bullish Komu"+ "\n" +
                        " > ThreeLines Status : " ;
                datetime RightBarTime = iTime(_Symbol,Timeframe,Shift-27);
                Comment(RightBarTime,Message,gTkLineBearish,gKjLineBearish,gChLineBearish);                
             }
           if(ChikouSpanLine_BullishExit(Shift) == True)
             {
                string Message ="\n" + " > Status: KOMU -- Chikouspan Exits From Bullish Komu" + "\n" +
                        " > ThreeLines Status : ";
                datetime RightBarTime = iTime(_Symbol,Timeframe,Shift-1);  
                Comment(RightBarTime,Message,gTkLineBearish,gKjLineBearish,gChLineBearish);
             }
        }
      else if(Span_A <= Span_B)
             {
                  if(TenkenSenLine_BearishExit(Shift-26) == True)
                    {
                        string Message1 ="\n" + " > Status: KOMU -- Tenkensen Exits From Bearish Komu" + "\n" +
                        " > ThreeLines Status : ";
                        datetime RightBarTime = iTime(_Symbol,Timeframe,Shift-27);
                        Comment(RightBarTime,Message1,gTkLineBullish,gKjLineBullish,gChLineBullish);
                    }
                  if(KijunSenLine_BearishExit(Shift-26) == True)
                    {
                        string Message1 ="\n" + " > Status: KOMU -- Kijunsen Exits From Bearish Komu"+ "\n" +
                        " > ThreeLines Status : ";
                        datetime RightBarTime = iTime(_Symbol,Timeframe,Shift-27);
                        Comment(RightBarTime,Message1,gTkLineBullish,gKjLineBullish,gChLineBullish);
                    }
                  if(ChikouSpanLine_BearishExit(Shift) == True)
                    {
                        string Message1 ="\n" + " > Status: KOMU -- Chikouspan Exits From Bearish Komu"+ "\n" +
                        " > ThreeLines Status : " ;
                        datetime RightBarTime = iTime(_Symbol,Timeframe,Shift-1); 
                        Comment(RightBarTime,Message1,gTkLineBullish,gKjLineBullish,gChLineBullish);
                    }
             }
    }
//+------------------------------------------------------------------+
void ThreeLinesSignal(int Shift) // 27
   {
      
      ThreeLinesExits(Shift);      
      KomuSwitch(Shift+1);
      Pullback_To_Komu(Shift-26);
      ThreeLinesOrder(Shift);
   }
//+------------------------------------------------------------------+
void Pullback_To_Komu(int Shift)
   {
      double SenkouSpan_B = iIchimoku(_Symbol,_Period,9,26,52,4,Shift);
      double SenkouSpan_B_For_Chikou = iIchimoku(_Symbol,_Period,9,26,52,4,Shift+26);
      double TenkenSen = iIchimoku(_Symbol,_Period,9,26,52,1,Shift);
      double KijunSen = iIchimoku(_Symbol,_Period,9,26,52,2,Shift);
      double ChikouSpan = iIchimoku(_Symbol,_Period,9,26,52,5,Shift+26);
      datetime RightBarTime = iTime(_Symbol,_Period,Shift);
      datetime RightBarTimeCh = iTime(_Symbol,_Period,Shift+26);
      if((gTkLineBullish != 0))
        {
            if(TenkenSen <= SenkouSpan_B)
              {
                  gTkLineBullish = 0;
                  
                  string Message ="\n" + ">  Status: PULLBACK -- TenkenSen Pulled Back to Bearish Komu." + "\n" +
                  " > ThreeLines Status : ";
                  Comment(RightBarTime,Message,gTkLineBullish,gKjLineBullish,gChLineBullish);
              }
        }
      if((gTkLineBearish != 0))
        {
            if(TenkenSen >= SenkouSpan_B)
              {
                  gTkLineBearish = 0;
                  string Message ="\n" + ">  Status: PULLBACK -- TenkenSen Pulled Back to Bullish Komu." + "\n" +
                  " > ThreeLines Status : " ;
                  Comment(RightBarTime,Message,gTkLineBearish,gKjLineBearish,gChLineBearish);
              }
        }
      if((gKjLineBullish != 0))
        {
            if(KijunSen <= SenkouSpan_B)
              {
                  gKjLineBullish = 0;
                  string Message ="\n" + ">  Status: PULLBACK -- KijunSen Pulled Back to Bearish Komu" + "\n" +
                  " > ThreeLines Status : " ;
                  Comment(RightBarTime,Message,gTkLineBullish,gKjLineBullish,gChLineBullish);
              }
        }
      if((gKjLineBearish != 0) )
        {
            if(KijunSen >= SenkouSpan_B)
              {
                  gKjLineBearish =0;
                  string Message ="\n" + ">  Status: PULLBACK -- KijunSen Pulled Back to BulLish Komu" + "\n" +
                  " > ThreeLines Status : " ;
                  Comment(RightBarTime,Message,gTkLineBearish,gKjLineBearish,gChLineBearish);
              }
        }
      if(gChLineBullish != 0)
        {
            if(ChikouSpan <= SenkouSpan_B_For_Chikou)
              {
                  gChLineBullish =0;
                  string Message ="\n" + ">  Status: PULLBACK -- ChikouSpan Pulled Back to Bearish Komu" + "\n" +
                  " > ThreeLines Status : " ;
                  Comment(RightBarTimeCh,Message,gTkLineBearish,gKjLineBearish,gChLineBearish);
              }
        }
      if(gChLineBearish != 0)
        {
            if(ChikouSpan >= SenkouSpan_B_For_Chikou)
              {
                  gChLineBearish = 0;
                  string Message ="\n" + ">  Status: PULLBACK -- ChikouSpan Pulled Back to BulLish Komu" + "\n" +
                  " > ThreeLines Status : " ;
                  Comment(RightBarTimeCh,Message,gTkLineBearish,gKjLineBearish,gChLineBearish);
                  
              }
        }
      
      
   }
//+------------------------------------------------------------------+
void ThreeLinesOrder(int Shift)  // 27
   {
      double SenkouSpan_B_For_Chikou = iIchimoku(_Symbol,Timeframe,9,26,52,4,Shift);
      double ChikouSpan = iIchimoku(_Symbol,Timeframe,9,26,52,5,Shift);
      double HighPrice=High[Shift];
      double LowPrice = Low[Shift];
      datetime RightBarTime = iTime(_Symbol,Timeframe,0);
      if((gTkLineBearish != 0) && (gKjLineBearish != 0) && (gChLineBearish != 0) && (SellConfirmation(Shift-26) == True))
                    {
                       if(is_there_switch_Forward(Shift-27) == True)
                         {
                              gTkLineBullish = 0;
                              gKjLineBullish = 0;
                              gChLineBullish = 0;
                              gTkLineBearish = 0;
                              gKjLineBearish = 0;
                              gChLineBearish = 0;
                              
                              string Message ="\n" + " > Status: Invalid ThreeLines Exit -- There is a Switch Komu in Between.";
                              Comment(RightBarTime,Message); 
                         }
                       else
                         {
                              if((ICHI(Shift-27) != "UP") && (TimeExitDifference(gKjExitTime , gTkExitTime) <= (4*_Period)))
                                  {
                                       if((ChikouSpan < LowPrice) && (ChikouSpan < SenkouSpan_B_For_Chikou))
                                        {
                                            gTkLineBearish = 0;
                                            gKjLineBearish = 0;
                                            gChLineBearish = 0;
                                            Read_Signal(1);
                                            if(StringToDouble(gSignal[1]) != Bid) Record_Signal(gSignalsCSV,RightBarTime,Bid,1);
                                            
                                            string Message ="\n" + " > Status: THREELINES -- Bearish";
                                            Alert("Three Lines (Tk-Kj-Ch) Exit from Komu -- Bears In Control" );
                                            Comment(RightBarTime,Message);
                                        }
                                  }
                                else
                                  {
                                       gTkLineBearish = 0;
                                       gKjLineBearish = 0;
                                       gChLineBearish = 0;
                                       string Message ="\n" + " > Status: INVALID THREELINES -- Dou to Opposite trend cross, or High distance between Tk/Kj.";
                                        Comment(RightBarTime,Message);
                                  }
                         }
                       
                       
                       
                    }
                    
      if((gTkLineBullish != 0) && (gKjLineBullish != 0) && (gChLineBullish != 0) && (BuyConfirmation(Shift-26) == True))
                    {
                      if(is_there_switch_Forward(Shift-27) == True)
                         {
                              gTkLineBullish = 0;
                              gKjLineBullish = 0;
                              gChLineBullish = 0;
                              gTkLineBearish = 0;
                              gKjLineBearish = 0;
                              gChLineBearish = 0;
                              string Message ="\n" + " > Status: Invalid ThreeLines Exit | There is a Switch Komu in Between...";
                              Comment(RightBarTime,Message); 
                         }
                      else
                        {
                             if((ICHI(Shift-27) != "DOWN") && (TimeExitDifference(gKjExitTime , gTkExitTime) <= (4*_Period)))
                                 {
                                       if((ChikouSpan > HighPrice) && (ChikouSpan > SenkouSpan_B_For_Chikou))
                                          {
                                              gTkLineBullish = 0;
                                              gKjLineBullish = 0;
                                              gChLineBullish = 0;
                                              Read_Signal(1);
                                              if(StringToDouble(gSignal[1]) != Ask) Record_Signal(gSignalsCSV,RightBarTime,Ask,0);
                                              
                                              string Message1 ="\n" + " > Status: THREELINES -- Bullish";
                                              Alert("Three Lines (Tk-Kj-Ch) Exit from Komu -- Bulls In Control" );
                                              Comment(RightBarTime,Message1);
                                          }
                                 }
                               else
                                 {
                                       gTkLineBullish = 0;
                                       gKjLineBullish = 0;
                                       gChLineBullish = 0; 
                                       string Message ="\n" + " > Status: INVALID THREELINES -- Dou to Opposite trend cross, or High distance between Tk/Kj.";
                                       Comment(RightBarTime,Message); 
                                 }  
                        }
                      
                      
                    }
   }
//+------------------------------------------------------------------+
bool is_there_switch_Forward(int Shift)
   {
      double Span_A = iIchimoku(_Symbol,_Period,9,26,52,3,Shift);
      double Span_B = iIchimoku(_Symbol,_Period,9,26,52,4,Shift);
      if(Span_A > Span_B)
        {
            for(int i=Shift+1;i<=26+Shift;i++)
              {
                  double SenkouSpan_A = iIchimoku(_Symbol,_Period,9,26,52,3,i); 
                  double SenkouSpan_B = iIchimoku(_Symbol,_Period,9,26,52,4,i);
                  if(SenkouSpan_A > SenkouSpan_B)
                    {
                        double SenkouSpan_A_Previous = iIchimoku(_Symbol,_Period,9,26,52,3,(i+1));
                        double SenkouSpan_B_Previous = iIchimoku(_Symbol,_Period,9,26,52,4,(i+1));
                        if((i==26+Shift) && (SenkouSpan_A_Previous == SenkouSpan_B_Previous)) return false;
                        if(SenkouSpan_A_Previous <= SenkouSpan_B_Previous)
                          {
                              // Switch Komu
                              return true;
                                
                          }
                        
                    }
                  else return true;
                 
              }
             
        }
     else if(Span_A < Span_B)
       {
            for(int i=Shift+1;i<=26+Shift;i++)
              {
                  double SenkouSpan_A = iIchimoku(_Symbol,_Period,9,26,52,3,i);
                  double SenkouSpan_B = iIchimoku(_Symbol,_Period,9,26,52,4,i);
                  if(SenkouSpan_A < SenkouSpan_B)
                    {
                        double SenkouSpan_A_Previous = iIchimoku(_Symbol,_Period,9,26,52,3,(i+1));
                        double SenkouSpan_B_Previous = iIchimoku(_Symbol,_Period,9,26,52,4,(i+1));
                        if((i==26+Shift) && (SenkouSpan_A_Previous == SenkouSpan_B_Previous)) return false;
                        if(SenkouSpan_A_Previous >= SenkouSpan_B_Previous)
                          {
                              // Switch Komu
                              return true;
                          }
                    }
                  else return true;
                 
              }
        }
     else if(Span_A == Span_B)
             {
                  for(int i=Shift+1;i<3+(Shift+1);i++)
                    {
                         double SenkouSpan_A_p = iIchimoku(_Symbol,_Period,9,26,52,3,i);
                         double SenkouSpan_B_p = iIchimoku(_Symbol,_Period,9,26,52,4,i);
                         if(SenkouSpan_A_p > SenkouSpan_B_p)
                           {
                               for(int j=i+1;j<=26+(i+1);j++)
                                 {
                                    double SenkouSpan_A = iIchimoku(_Symbol,_Period,9,26,52,3,j);
                                    double SenkouSpan_B = iIchimoku(_Symbol,_Period,9,26,52,4,j);
                                    if((j==26+i+1) && (SenkouSpan_A == SenkouSpan_B)) return false;
                                    if(SenkouSpan_A <= SenkouSpan_B)
                                       {
                                           return true;
                                       }
                                 }
                                
                            }
                        
                         if(SenkouSpan_A_p < SenkouSpan_B_p)
                           {
                               for(int j=i+1;j<=26+(i+1);j++)
                                 {
                                    double SenkouSpan_A = iIchimoku(_Symbol,_Period,9,26,52,3,j);
                                    double SenkouSpan_B = iIchimoku(_Symbol,_Period,9,26,52,4,j); 
                                    if((j==26+i+1) && (SenkouSpan_A == SenkouSpan_B)) return false;
                                    if(SenkouSpan_A >= SenkouSpan_B)
                                       {
                                           return true;
                                       }
                                 } 
                                           
                        
                           }
                    }
             }
      return false;
   }
//+------------------------------------------------------------------+
bool TenkenSenLine_BullishExit(int Shift)
   {
      double SenkouSpan_B = iIchimoku(_Symbol,Timeframe,9,26,52,4,Shift);
      double SenkouSpan_A = iIchimoku(_Symbol,Timeframe,9,26,52,3,Shift);
      double TenkenSen_current = iIchimoku(_Symbol,Timeframe,9,26,52,1,Shift);
      datetime RightBarTime = iTime(_Symbol,Timeframe,Shift);
     
      if((TenkenSen_current <= SenkouSpan_B) && (TenkenSen_current < SenkouSpan_A) && (SenkouSpan_A > SenkouSpan_B))
        {
           for(int i=Shift+1;i<=Shift+2;i++)
             {
                  double SenkouSpan_B_previous = iIchimoku(_Symbol,Timeframe,9,26,52,4,i);
                  double TenkenSen_previous = iIchimoku(_Symbol,Timeframe,9,26,52,1,i);
                  if((TenkenSen_previous > SenkouSpan_B_previous) && (TenkenSen_previous != TenkenSen_current))
                    {
                        if(is_there_switch_Forward(Shift) == False)
                          {
                                 gTkExitTime = ExitTime(Shift);
                                 gTkLineBearish = 1;
                                 gTkLineBullish = 0;
                                 return true;
                          } 
                        else
                          {
                                 gTkLineBullish = 0;
                                 gKjLineBullish = 0;
                                 gChLineBullish = 0;
                                 gTkLineBearish = 0;
                                 gKjLineBearish = 0;
                                 gChLineBearish = 0;
                                 string Message ="\n" + " > Status: POSSIBLE SIDEWAY TREND" + "\n" +
                                 " > ThreeLines Status : "; 
                                 Comment(RightBarTime,Message,gTkLineBearish,gKjLineBearish,gChLineBearish);
                                 
                          }                      
                        
                        
                    }
                  else if((TenkenSen_previous > SenkouSpan_B_previous) && (TenkenSen_previous == TenkenSen_current))
                         {
                              
                              string Message ="\n" + " > Status: KOMU -- Tenkensen Flat Exits From Bullish Komu" + "\n" +
                              " > ThreeLines Status : "; 
                              Comment(RightBarTime,Message,gTkLineBearish,gKjLineBearish,gChLineBearish);
                         }
             }
           
        }
      return false;
    }
//+------------------------------------------------------------------+
bool TenkenSenLine_BearishExit(int Shift)
   {     
      double SenkouSpan_B = iIchimoku(_Symbol,Timeframe,9,26,52,4,Shift);
      double SenkouSpan_A = iIchimoku(_Symbol,Timeframe,9,26,52,3,Shift);
      double TenkenSen_current = iIchimoku(_Symbol,Timeframe,9,26,52,1,Shift);
      datetime RightBarTime = iTime(_Symbol,Timeframe,Shift);
         
      if((TenkenSen_current >= SenkouSpan_B) && (TenkenSen_current > SenkouSpan_A) && (SenkouSpan_A < SenkouSpan_B))  
        {
           for(int j=Shift+1;j<=Shift+2;j++)
             {
                  double SenkouSpan_B_previous1 = iIchimoku(_Symbol,Timeframe,9,26,52,4,j);
                  double TenkenSen_previous1 = iIchimoku(_Symbol,Timeframe,9,26,52,1,j);
                  if((TenkenSen_previous1 < SenkouSpan_B_previous1) && (TenkenSen_previous1 != TenkenSen_current))
                    {
                        if(is_there_switch_Forward(Shift) == False)
                          {
                              gTkExitTime = ExitTime(Shift);
                              gTkLineBullish = 1;
                              gTkLineBearish = 0;
                              return true;
                          }
                       else
                          {
                                 gTkLineBullish = 0;
                                 gKjLineBullish = 0;
                                 gChLineBullish = 0;
                                 gTkLineBearish = 0;
                                 gKjLineBearish = 0;
                                 gChLineBearish = 0;
                                 string Message ="\n" + " > Status: POSSIBLE SIDEWAY TREND" + "\n" +
                                 " > ThreeLines Status : "; 
                                 Comment(RightBarTime,Message,gTkLineBearish,gKjLineBearish,gChLineBearish);
                                 
                          }
                          
                        
                    }
                  else if((TenkenSen_previous1 < SenkouSpan_B_previous1) && (TenkenSen_previous1 == TenkenSen_current))
                         {
                              string Message ="\n" + " > Status: KOMU -- Tenkensen Flat Exits From Beraish Komu" + "\n" +
                              " > ThreeLines Status : "; 
                              Comment(RightBarTime,Message,gTkLineBearish,gKjLineBearish,gChLineBearish);
                         }
              
             }
           
        }
      
     return false;
       
    }
//+------------------------------------------------------------------+       
bool KijunSenLine_BullishExit(int Shift)
   { 
      double SenkouSpan_B = iIchimoku(_Symbol,Timeframe,9,26,52,4,Shift);
      double SenkouSpan_A = iIchimoku(_Symbol,Timeframe,9,26,52,3,Shift);
      double KijunSen_current = iIchimoku(_Symbol,Timeframe,9,26,52,2,Shift);
      datetime RightBarTime = iTime(_Symbol,Timeframe,Shift);
      
      if((KijunSen_current <= SenkouSpan_B) && (KijunSen_current < SenkouSpan_A) && (SenkouSpan_A > SenkouSpan_B))
        {
            for(int i=Shift+1;i<=Shift+2;i++)
              {
                  double SenkouSpan_B_previous = iIchimoku(_Symbol,Timeframe,9,26,52,4,i);
                  double KijunSen_previous = iIchimoku(_Symbol,Timeframe,9,26,52,2,i);
                  if((KijunSen_previous > SenkouSpan_B_previous) && (KijunSen_previous != KijunSen_current))
                    {
                        if(is_there_switch_Forward(Shift) == False)
                          {
                              
                              gKjExitTime = ExitTime(Shift);
                              gKjLineBearish = 1;
                              gKjLineBullish =0;
                              return true;
                          }
                       else
                          {
                                 gTkLineBullish = 0;
                                 gKjLineBullish = 0;
                                 gChLineBullish = 0;
                                 gTkLineBearish = 0;
                                 gKjLineBearish = 0;
                                 gChLineBearish = 0;
                                 string Message ="\n" + " > Status: POSSIBLE SIDEWAY TREND" + "\n" +
                                 " > ThreeLines Status : "; 
                                 Comment(RightBarTime,Message,gTkLineBearish,gKjLineBearish,gChLineBearish);
                                 
                          }
                        
                       
                    }
                  else if((KijunSen_previous > SenkouSpan_B_previous) && (KijunSen_previous == KijunSen_current))
                         {
                              string Message ="\n" + " > Status: KOMU -- Kijunsen Flat Exits From Bullish Komu"+ "\n" +
                              " > ThreeLines Status : " ;
                              Comment(RightBarTime,Message,gTkLineBearish,gKjLineBearish,gChLineBearish);
                         }
              }
            
        }
      
      return false;
   }
//+------------------------------------------------------------------+       
bool KijunSenLine_BearishExit(int Shift)
   {   
      double SenkouSpan_B = iIchimoku(_Symbol,Timeframe,9,26,52,4,Shift);
      double SenkouSpan_A = iIchimoku(_Symbol,Timeframe,9,26,52,3,Shift);
      double KijunSen_current = iIchimoku(_Symbol,Timeframe,9,26,52,2,Shift);
      datetime RightBarTime = iTime(_Symbol,Timeframe,Shift);
         
      if((KijunSen_current >= SenkouSpan_B) && (KijunSen_current > SenkouSpan_A) && (SenkouSpan_A < SenkouSpan_B))
        {
            for(int j=Shift+1;j<=Shift+2;j++)
              {
                  double SenkouSpan_B_previous1 = iIchimoku(_Symbol,Timeframe,9,26,52,4,j);
                  double KijunSen_previous1 = iIchimoku(_Symbol,Timeframe,9,26,52,2,j);
                  if((KijunSen_previous1 < SenkouSpan_B_previous1)&& (KijunSen_previous1 != KijunSen_current))
                    {
                        if(is_there_switch_Forward(Shift) == False)
                          {
                              gKjExitTime = ExitTime(Shift);
                              gKjLineBullish = 1;
                              gKjLineBearish =0;
                              return true;
                          } 
                       else
                          {
                                 gTkLineBullish = 0;
                                 gKjLineBullish = 0;
                                 gChLineBullish = 0;
                                 gTkLineBearish = 0;
                                 gKjLineBearish = 0;
                                 gChLineBearish = 0;
                                 string Message ="\n" + " > Status: POSSIBLE SIDEWAY TREND" + "\n" +
                                 " > ThreeLines Status : "; 
                                 Comment(RightBarTime,Message,gTkLineBearish,gKjLineBearish,gChLineBearish);
                                 
                          }
                        
                        
                        
                      
                    }
                  else if((KijunSen_previous1 < SenkouSpan_B_previous1)&& (KijunSen_previous1 == KijunSen_current))
                         {
                              string Message ="\n" + " > Status: KOMU -- Kijunsen Flat Exits From Bearish Komu"+ "\n" +
                              " > ThreeLines Status : " ;
                              Comment(RightBarTime,Message,gTkLineBearish,gKjLineBearish,gChLineBearish);
                         } 
              }
            
        }
      
      return false;
      
  
   } 
//+------------------------------------------------------------------+    
bool ChikouSpanLine_BullishExit(int Shift)
   {
      double Span_B_For_Chikou = iIchimoku(_Symbol,_Period,9,26,52,4,Shift);
      double Span_A_For_Chikou = iIchimoku(_Symbol,_Period,9,26,52,3,Shift);
      double ChikouSpan_current = iIchimoku(_Symbol,_Period,9,26,52,5,Shift);
      if((Span_A_For_Chikou > Span_B_For_Chikou) && (ChikouSpan_current <= Span_B_For_Chikou) && (ChikouSpan_current < Span_A_For_Chikou))
        {
                   if(ChikouConfirmSell(Shift) == true)
                      {
                         if(Prev_Chikou_inKomu("BEAR",Shift+2) == True) 
                          { 
                              gChLineBearish = 1;
                              gChLineBullish = 0;
                              return true;
                              
                          }
                     }
        }
      return false;
   }
//+------------------------------------------------------------------+    
bool ChikouSpanLine_BearishExit(int Shift) // 27
   {
      double Span_B_For_Chikou = iIchimoku(_Symbol,_Period,9,26,52,4,Shift);
      double Span_A_For_Chikou = iIchimoku(_Symbol,_Period,9,26,52,3,Shift);
      double ChikouSpan_current = iIchimoku(_Symbol,_Period,9,26,52,5,Shift);
      if((Span_A_For_Chikou < Span_B_For_Chikou) && (ChikouSpan_current >= Span_B_For_Chikou) && (ChikouSpan_current > Span_A_For_Chikou))
         {        
                  if(ChikouConfirmBuy(Shift) == True)
                     {
                         if(Prev_Chikou_inKomu("BULL",Shift+2) == True)
                             {
                                 gChLineBullish = 1;
                                 gChLineBearish =0;
                                 return true;
                                 
                             }
                   }
        }
      
      
      return false;
    
     
   } 
//+------------------------------------------------------------------+ 
bool Prev_Chikou_inKomu(string Type, int Shift) // 27
   {
      
      if(Type == "BULL")
        {
            for(int i=0;i<=4;i++)
              {
                  double Span_B_For_Chikou = iIchimoku(_Symbol,_Period,9,26,52,4,Shift+i);
                  double ChikouSpan = iIchimoku(_Symbol,_Period,9,26,52,5,Shift+i);
                  if(ChikouSpan <= Span_B_For_Chikou) return true;   
              }
        }
      if(Type == "BEAR")
        {
             for(int i=0;i<=4;i++)
              {
                  double Span_B_For_Chikou = iIchimoku(_Symbol,_Period,9,26,52,4,Shift+i);
                  double ChikouSpan = iIchimoku(_Symbol,_Period,9,26,52,5,Shift+i);
                  if(ChikouSpan >= Span_B_For_Chikou) return true;   
              }
        }
      
      return false;
   } 
//+------------------------------------------------------------------+ 
bool ChikouConfirmSell(int Shift)
   {
      double SpanB_for_Chikou = iIchimoku(_Symbol,_Period,9,26,52,4,Shift);
      double ChikouSpan_current = iIchimoku(_Symbol,_Period,9,26,52,5,Shift);
      double ChikouSpan_previous = iIchimoku(_Symbol,_Period,9,26,52,5,Shift+1);
      
      if((ChikouSpan_previous > ChikouSpan_current))   return true;
      else return false;
    }
//+------------------------------------------------------------------+         
bool ChikouConfirmBuy(int Shift)
   {
      double SpanB_for_Chikou = iIchimoku(_Symbol,_Period,9,26,52,4,Shift);
      double ChikouSpan_current = iIchimoku(_Symbol,_Period,9,26,52,5,Shift);
      double ChikouSpan_previous = iIchimoku(_Symbol,_Period,9,26,52,5,Shift+1);
      
      if((ChikouSpan_previous < ChikouSpan_current))     return true;
      else return false;
    
   }  
      
//+-----------------------------------------------------------------------------------------------------------+
//// Price Action Detections and Signals 
//+-----------------------------------------------------------------------------------------------------------+

void Price_Action(string Filename, int TF)
   {
      double Span_A = iIchimoku(_Symbol,TF,9,26,52,3,-26);
      double Span_B = iIchimoku(_Symbol,TF,9,26,52,4,-26);
      
      if(Span_A > Span_B)
        {
             for(int i=0;i<52;i++)
              {
                  double Bull_SenkouSpan_A = iIchimoku(_Symbol,TF,9,26,52,3,i-26);
                  double Bull_SenkouSpan_B = iIchimoku(_Symbol,TF,9,26,52,4,i-26);
                  if(Bull_SenkouSpan_A > Bull_SenkouSpan_B)
                    {
                        double SenkouSpan_A_Previous = iIchimoku(_Symbol,TF,9,26,52,3,(i+1)-26);
                        double SenkouSpan_B_Previous = iIchimoku(_Symbol,TF,9,26,52,4,(i+1)-26);
                        if(SenkouSpan_A_Previous < SenkouSpan_B_Previous)
                          {
                              // Switch Komu
                              int Depth_Period = (i+1);
                              Get_Price_Action(TF,"Depth" ,Depth_Period);
                              Price_Action_Zone(Filename,TF);
                              for(int j=(Depth_Period+1);j<52;j++)
                                   {
                                       double SenkouSpan_A = iIchimoku(_Symbol,TF,9,26,52,3,j-26);
                                       double SenkouSpan_B = iIchimoku(_Symbol,TF,9,26,52,4,j-26);
                                       if(SenkouSpan_A < SenkouSpan_B)
                                         {
                                             double Bull_SenkouSpan_A_Previous = iIchimoku(_Symbol,TF,9,26,52,3,(j+1)-26);
                                             double Bull_SenkouSpan_B_Previous = iIchimoku(_Symbol,TF,9,26,52,4,(j+1)-26);
                                             if(Bull_SenkouSpan_A_Previous > Bull_SenkouSpan_B_Previous)
                                               {
                                                   // Switch Komu
                                                   int Peak_Period = (j+1);
                                                   Get_Price_Action(TF,"Peak" , Peak_Period);
                                                   Price_Action_Zone(Filename,TF);
                                                   break;
                                               }
                                         }
                                   }      
                                                     
                          }
                    }
                 
              }
        }
      if(Span_A < Span_B)
        {
         
            for(int i=0;i<52;i++)
              {
                  double Bear_SenkouSpan_A = iIchimoku(_Symbol,TF,9,26,52,3,i-26);
                  double Bear_SenkouSpan_B = iIchimoku(_Symbol,TF,9,26,52,4,i-26);
                  if(Bear_SenkouSpan_A < Bear_SenkouSpan_B)
                    {
                        double SenkouSpan_A_Previous = iIchimoku(_Symbol,TF,9,26,52,3,(i+1)-26);
                        double SenkouSpan_B_Previous = iIchimoku(_Symbol,TF,9,26,52,4,(i+1)-26);
                        if(SenkouSpan_A_Previous > SenkouSpan_B_Previous)
                          {
                              // Switch Komu
                              int Peak_Period = (i+1);
                              Get_Price_Action(TF,"Peak" , Peak_Period);
                              Price_Action_Zone(Filename,TF);
                              for(int j=(Peak_Period+1);i<52;j++)
                                   {
                                       double SenkouSpan_A = iIchimoku(_Symbol,TF,9,26,52,3,j-26);
                                       double SenkouSpan_B = iIchimoku(_Symbol,TF,9,26,52,4,j-26);
                                       if(SenkouSpan_A > SenkouSpan_B)
                                         {
                                             double Bear_SenkouSpan_A_Previous = iIchimoku(_Symbol,TF,9,26,52,3,(j+1)-26);
                                             double Bear_SenkouSpan_B_Previous = iIchimoku(_Symbol,TF,9,26,52,4,(j+1)-26);
                                             if(Bear_SenkouSpan_A_Previous < Bear_SenkouSpan_B_Previous)
                                               {
                                                   // Switch Komu
                                                   int Depth_Period = (j+1);
                                                   Get_Price_Action(TF,"Depth" ,Depth_Period);
                                                   Price_Action_Zone(Filename,TF);
                                                   break;
                                               }
                                         }
                                   }
                           }
                    }
                 
              }
         }
        else if(Span_A == Span_B)
             {
                  for(int i=1;i<3;i++)
                    {
                         double SenkouSpan_A = iIchimoku(_Symbol,TF,9,26,52,3,i-26);
                         double SenkouSpan_B = iIchimoku(_Symbol,TF,9,26,52,4,i-26);
                         if(SenkouSpan_A > SenkouSpan_B)
                           {
                              int Peak_Period = (i+1);
                              Get_Price_Action(TF,"Peak" , Peak_Period);
                              Price_Action_Zone(Filename,TF); 
                           }
                         if(SenkouSpan_A < SenkouSpan_B)
                           {
                               int Depth_Period = (i+1);
                               Get_Price_Action(TF,"Depth" ,Depth_Period);
                               Price_Action_Zone(Filename,TF);
                           }
                    }
             }
}
      

//+------------------------------------------------------------------+
void Get_Price_Action(int TF, string SwitchType, int SwitchPeriod)
   {
      double Senkou_A_Depth[];
      double Senkou_A_Peaks[];
      double Senkou_B_Depth[];
      double Senkou_B_Peaks[];
      
      if(SwitchType == "Depth")
        {
             ArrayResize(Senkou_A_Depth,26);
             ArrayResize(Senkou_B_Depth,26);
             for(int i=SwitchPeriod;i<(SwitchPeriod+26);i++)
                 {
                     double SenkouSpan_A = iIchimoku(_Symbol,TF,9,26,52,3,i-26);
                     double SenkouSpan_B = iIchimoku(_Symbol,TF,9,26,52,4,i-26);
                     Senkou_A_Depth[i-SwitchPeriod] = SenkouSpan_A;
                     Senkou_B_Depth[i-SwitchPeriod] = SenkouSpan_B;
                 }
             int DepthKomuIndex_A = ArrayMinimum(Senkou_A_Depth,WHOLE_ARRAY,0);
             int DepthKomuIndex_B = ArrayMinimum(Senkou_B_Depth,WHOLE_ARRAY,0);
             double Depth_A = Senkou_A_Depth[DepthKomuIndex_A];
             double Depth_B = Senkou_B_Depth[DepthKomuIndex_B];
             if(Depth_A <= Depth_B)  gDepthKomu = Depth_A;
             else  gDepthKomu = Depth_B;
                       
        }
      else if(SwitchType == "Peak")
             {
                  ArrayResize(Senkou_A_Peaks,26);
                  ArrayResize(Senkou_B_Peaks,26);
                  for(int i=SwitchPeriod;i<(SwitchPeriod+26);i++)
                     {
                          double SenkouSpan_A = iIchimoku(_Symbol,TF,9,26,52,3,i-26);
                          double SenkouSpan_B = iIchimoku(_Symbol,TF,9,26,52,4,i-26);
                          Senkou_A_Peaks[i-SwitchPeriod] = SenkouSpan_A;
                          Senkou_B_Peaks[i-SwitchPeriod] = SenkouSpan_B;
                     }
                  int PeakKomuIndex_A = ArrayMaximum(Senkou_A_Peaks,WHOLE_ARRAY,0);
                  int PeakKomuIndex_B = ArrayMaximum(Senkou_B_Peaks,WHOLE_ARRAY,0);
                  double Peak_A = Senkou_A_Peaks[PeakKomuIndex_A];
                  double Peak_B = Senkou_B_Peaks[PeakKomuIndex_B];
                  if(Peak_A >= Peak_B) gPeakKomu = Peak_A;
                  else  gPeakKomu = Peak_B;
                  
                  
             }
   }

//+------------------------------------------------------------------+
void Price_Action_Optimizer(int Zone)
   {
       int PAZone_Num;
       double Differ;
       double ZoneVaue[];
       string Rec_Name = "";
       datetime BarTime_Backward = (iTime(_Symbol,_Period,0) - 4000*4000);
       datetime BarTime_Forward = (iTime(_Symbol,_Period,0) + 4000*4000);
       
       PA_Zone_Recorder(Zone);
       PAZone_Num = Number_Of_EventRecorded(gPAZoneCSV,9);
       
       if((PAZone_Num > 1) && (gPAZoneCheck != PAZone_Num))
         {
             ArrayResize(ZoneVaue,PAZone_Num);
       
             for(int i=1;i<=PAZone_Num;i++)
               {
                   Read_PriceAction(gPAZoneCSV,i);
                   double Selected_Value = StringToDouble(gHistory_PA[0]);
                   ZoneVaue[i-1] = Selected_Value;
               }
             ArraySort(ZoneVaue,WHOLE_ARRAY,0,MODE_DESCEND);  
                 
             for(int j=0;j<PAZone_Num;j++)
                 {
                     
                   double Price_Backward = ZoneVaue[j];
                   
                   for(int k=1;k<PAZone_Num;k++)
                     {
                            double Price_Forward = ZoneVaue[k];
                            Differ = (Price_Backward - Price_Forward)/_Point;
                            Rec_Name += DoubleToString(Price_Backward,Digits);
                            Rec_Name += "-Zone-";
                            Rec_Name += DoubleToString(Price_Forward,Digits);
                                                         
                            if((Differ <= Zone) && (Differ > 0) && (ObjectFind(ChartID(),Rec_Name) == -1))
                                {
                                   ObjectCreate(ChartID(),Rec_Name,OBJ_RECTANGLE,0,BarTime_Backward,Price_Backward,BarTime_Forward,Price_Forward);
                                   ObjectSetInteger(ChartID(),Rec_Name,OBJPROP_COLOR,clrMaroon);     
                                                              
                               }
                            else Rec_Name = "";
                     }
                   
                }
                
             gPAZoneCheck = PAZone_Num;
         }
       
             
  }
//+------------------------------------------------------------------+
void PA_Zone_Recorder(int Zone)
   {
       int PATotal;
       int PAZoneNum = 0;
       int ZoneCount = 0;
       double Selected_Values[];
       double Zone_Values[];
       datetime BarTime_Backward = (iTime(_Symbol,_Period,0) - 4000*4000);
       datetime BarTime_Forward = (iTime(_Symbol,_Period,0) + 4000*4000);
       
       Read_PriceAction(gPriceActionCSV,1);
       if(gHistory_PA[0] != NULL)
         {
            PATotal = Number_Of_EventRecorded(gPriceActionCSV,9);
            ArrayResize(Selected_Values,PATotal);
            
            for(int i=1;i<=PATotal;i++)
               {
                   Read_PriceAction(gPriceActionCSV,i);
                   double Selected_PA = StringToDouble(gHistory_PA[0]); 
                   int Zone_Index = Get_OrderIndex(gPAZoneCSV,"Data",9,Selected_PA);
                   
                   if(Zone_Index == 0)
                     {
                        Selected_Values[i-1] = Selected_PA;
                        PAZoneNum += 1;
                     }
                                                              
               }
            if((PAZoneNum > 1))
              {
                  
                  ArraySort(Selected_Values,WHOLE_ARRAY,0,MODE_DESCEND);
                  
                  for(int ii=0;ii<PATotal;ii++)
                     {
                         if((ii+1) < PATotal)
                           {
                               double Price_Backward = Selected_Values[ii];
                               double Price_Forward = Selected_Values[ii+1];
                               double Differ = (Price_Backward - Price_Forward)/_Point;
                                                
                               if((Differ <= Zone) && (Differ != 0))
                                 {
                                                       
                                     Record_PriceAction(gPAZoneCSV,Price_Backward);
                                     Record_PriceAction(gPAZoneCSV,Price_Forward);
                                                  
                                     break;
                                                        
                                 }
                               else if(Selected_Values[ii+1] == 0) break;
                           }
                         else break;
                         
                            
                        
                     }
             }
                        
       }
   }
//+------------------------------------------------------------------+
bool Is_PriceAction_Repeated(string Filename, double Priceaction) 
   {
       int PAtotal;
       int PAtotal_Add;
       
       if(Filename == gPriceActionCSV)
         {
             Read_PriceAction(gAdditionalPACSV,1);
             if(gHistory_PA[0] != NULL)
               {
                  PAtotal_Add = Number_Of_EventRecorded(gAdditionalPACSV,9);
                  
                  
                  for(int i=1;i<=PAtotal_Add;i++)
                    {
                        Read_PriceAction(gAdditionalPACSV,i);
                        if(StringToDouble(gHistory_PA[0]) == Priceaction)
                          {
                             return true;
                          }
                    }
               }
             else return false;
         }
       else if(Filename == gAdditionalPACSV)
              {
                 Read_PriceAction(gPriceActionCSV,1);
                 if(gHistory_PA[0] != NULL)
                  {
                     PAtotal = Number_Of_EventRecorded(gPriceActionCSV,9);
                     
                     
                     for(int j=1;j<=PAtotal;j++)
                       {
                           Read_PriceAction(gPriceActionCSV,j);
                           if(StringToDouble(gHistory_PA[0]) == Priceaction)
                             {
                                return true;
                             }
                       }
                  }
             else return false;
              }
                   
     return false;     
    
   } 
//+------------------------------------------------------------------+
void Historical_PriceAction(string Filename)
   {
       
       int PATotal;
       double PALinePrice;
       string TF;
       
       if(Filename == gAdditionalPACSV)     TF = IntegerToString(Add_PriceAction_in_Minute);
       else if(Filename == gPriceActionCSV) TF = IntegerToString(Timeframe);
       else if(Filename == gStrongPACSV)    TF = "Strong";
       
       Read_PriceAction(Filename,1);
       if(gHistory_PA[0] != NULL) 
         {
            PATotal = Number_Of_EventRecorded(Filename,9);
            for(int i=1;i<=PATotal;i++)
              {
                  
                  Read_PriceAction(Filename,i);
                  string Line_Name = "";
                  Line_Name += TF;
                  Line_Name += "-PriceAction-";
                  Line_Name += gHistory_PA[0];
                  PALinePrice = StringToDouble(gHistory_PA[0]);
                  if(ObjectFind(ChartID(),Line_Name) == -1)
                    {
                         
                         if(Filename == gAdditionalPACSV)
                           {
                              ObjectCreate(ChartID(),Line_Name,OBJ_HLINE,0,0,PALinePrice);
                              ObjectSetInteger(ChartID(),Line_Name,OBJPROP_STYLE,STYLE_DOT);
                              ObjectSetInteger(ChartID(),Line_Name,OBJPROP_COLOR,clrOrange);
                           }
                         if(Filename == gStrongPACSV)
                           {
                              ObjectCreate(ChartID(),Line_Name,OBJ_HLINE,0,0,PALinePrice);
                              ObjectSetInteger(ChartID(),Line_Name,OBJPROP_STYLE,STYLE_DOT);
                              ObjectSetInteger(ChartID(),Line_Name,OBJPROP_COLOR,clrYellow);
                           }
                         else
                           {
                               ObjectCreate(ChartID(),Line_Name,OBJ_HLINE,0,0,PALinePrice);
                               ObjectSetInteger(ChartID(),Line_Name,OBJPROP_STYLE,STYLE_DOT);
                           }
                    }
                  
              }  
            
         }
   }
//+------------------------------------------------------------------+
void Remove_Historical_PA(string Filename)
   {
       
       int PATotal;
       gPARemove = 1;
       string TF;
       
       if(Filename == gAdditionalPACSV)     TF = IntegerToString(Add_PriceAction_in_Minute);
       else if(Filename == gPriceActionCSV) TF = IntegerToString(Timeframe);
       else if(Filename == gStrongPACSV)    TF = "Strong";
       
       Read_PriceAction(Filename,1);
       if(gHistory_PA[0] != NULL) 
         {
            PATotal = Number_Of_EventRecorded(Filename,9);
            for(int i=1;i<=PATotal;i++)
              {
                  Read_PriceAction(Filename,i);
                  string Line_Name = "";
                  Line_Name += TF;
                  Line_Name += "-PriceAction-";
                  Line_Name += gHistory_PA[0];
                  if(ObjectFind(ChartID(),Line_Name) != -1 ) ObjectDelete(ChartID(),Line_Name);
                  
              }  
            
         }
       
   }
//+------------------------------------------------------------------+
bool Is_PA_Recorded(string Filename, double Priceaction)
   {
         int PA_Index;
         PA_Index = Get_OrderIndex(Filename,"Data",9,Priceaction);
         if(PA_Index == 0) return false;
         else return true;
        
   }
//+------------------------------------------------------------------+
void Price_Action_Zone(string Filename, int TF)
   {
      
      if(Digits == 3)
         {
             gDepthKomu = NormalizeDouble(gDepthKomu,3);
             gPeakKomu = NormalizeDouble(gPeakKomu,3);
         }
      else
        {
             gDepthKomu = NormalizeDouble(gDepthKomu,5);
             gPeakKomu = NormalizeDouble(gPeakKomu,5);
        }    
       
            
      if((gPADepthLine == 0)  && (gDepthKomu != 0) && (BearEscapeAction(gDepthKomu) == False)
         && (Validation_for_Depth(TF,gDepthKomu) == True))
        {
            
            if(Is_PA_Recorded(Filename, gDepthKomu) == False)
              {
                 if(Is_PriceAction_Repeated(Filename, gDepthKomu) == False) // There is no record in other PA records
                   {
                      Record_PriceAction(Filename,gDepthKomu);
                      gPADepthLine = gDepthKomu;
                   }
                 else
                   {
                      if(Is_PA_Recorded(gStrongPACSV,gDepthKomu) == False)
                        {
                            Record_PriceAction(gStrongPACSV,gDepthKomu);
                            gPADepthLine = gDepthKomu;
                        }
                      
                   }
                 
              }
            
        }
      if((gPADepthLine != 0 )  && (gDepthKomu != gPADepthLine) && (BearEscapeAction(gDepthKomu) == False)
       && (Validation_for_Depth(TF,gDepthKomu) == True))
        {
            if(Is_PA_Recorded(Filename, gDepthKomu) == False)
              {
                  if(Is_PriceAction_Repeated(Filename, gDepthKomu) == False) // There is no record in other PA records
                   {
                      Record_PriceAction(Filename,gDepthKomu);
                      gPADepthLine = gDepthKomu;
                   }
                 else
                   {
                      if(Is_PA_Recorded(gStrongPACSV,gDepthKomu) == False)
                        {
                            Record_PriceAction(gStrongPACSV,gDepthKomu);
                            gPADepthLine = gDepthKomu;
                        }
                      
                   }
              }
            
        }
        
        
        
      if((gPAPeakLine == 0) && (gPeakKomu != 0) && (BullEscapeAction(gPeakKomu) == False) 
      && (Validation_for_Peak(TF,gPeakKomu) == True))
        {
            if(Is_PA_Recorded(Filename,gPeakKomu) == False)
              {
                  if(Is_PriceAction_Repeated(Filename,gPeakKomu) == False)
                    {
                       Record_PriceAction(Filename,gPeakKomu);
                       gPAPeakLine = gPeakKomu;
                    }
                  else
                    {
                       if(Is_PA_Recorded(gStrongPACSV,gPeakKomu) == False)
                         {
                            Record_PriceAction(gStrongPACSV,gPeakKomu);
                            gPAPeakLine = gPeakKomu;
                         }
                       
                    }
                  
              }
            
        }
      if((gPAPeakLine != 0)&& (gPeakKomu != gPAPeakLine) && (BullEscapeAction(gPeakKomu) == False) 
       && (Validation_for_Peak(TF,gPeakKomu) == True))
        {
            if(Is_PA_Recorded(Filename,gPeakKomu) == False)
              {
                  if(Is_PriceAction_Repeated(Filename,gPeakKomu) == False)
                    {
                       Record_PriceAction(Filename,gPeakKomu);
                       gPAPeakLine = gPeakKomu;
                    }
                  else
                    {
                       if(Is_PA_Recorded(gStrongPACSV,gPeakKomu) == False)
                         {
                            Record_PriceAction(gStrongPACSV,gPeakKomu);
                            gPAPeakLine = gPeakKomu;
                         }
                       
                    }
              }
            
            
        }
      
      
   }
//+------------------------------------------------------------------+
void Nearby_PriceAction(string Filename, int TF)
   {
      int PATotal;
      double PriceAction;
      string TF_String;
      
      if(Filename == gAdditionalPACSV)     TF_String = IntegerToString(Add_PriceAction_in_Minute);
      else if(Filename == gPriceActionCSV) TF_String = IntegerToString(Timeframe);
      else if(Filename == gStrongPACSV)    TF_String = "Strong";
       
       
      double Current_Price = Close[0];
      double UpperBound = Current_Price + (150*_Point);
      double LowerBound = Current_Price - (150*_Point);
      
      
       Read_PriceAction(Filename,1);
       if(gHistory_PA[0] != NULL) 
         {
            PATotal = Number_Of_EventRecorded(Filename,9);
            for(int i=1;i<=PATotal;i++)
              {
                  
                  Read_PriceAction(Filename,i);
                  PriceAction = StringToDouble(gHistory_PA[0]);
                  string Line_Name = "";
                  Line_Name += TF_String;
                  Line_Name += "-PriceAction-";
                  Line_Name += gHistory_PA[0];
                  if((PriceAction <= UpperBound) && (PriceAction >= LowerBound))
                    {
                        gActivePA = PriceAction;
                        ObjectSetInteger(ChartID(),Line_Name,OBJPROP_COLOR,clrWhite);
                        break;
                    }
                  else 
                   {
                     if(Filename == gAdditionalPACSV)
                       {
                          ObjectSetInteger(ChartID(),Line_Name,OBJPROP_COLOR,clrOrange);
                          continue;
                       }
                     if(Filename == gStrongPACSV)
                       {
                          ObjectSetInteger(ChartID(),Line_Name,OBJPROP_COLOR,clrYellow);
                          continue;
                       }
                     else
                       {
                          ObjectSetInteger(ChartID(),Line_Name,OBJPROP_COLOR,clrRed);
                          continue;
                       }
                     
                   }
             }
         }
                  
      
   }
//+------------------------------------------------------------------+
void Price_Action_Exit()
   {
      datetime RightBarTime = iTime(_Symbol,Timeframe,0);
      if((gPAExit_Peak != gActivePA) && (BullEscapeAction(gActivePA) == True))
        {
             if(Divergence(0) <= 100)
               {
                     Read_Signal(1);
                     if(StringToDouble(gSignal[1]) != Ask) Record_Signal(gSignalsCSV,RightBarTime,Ask,0);
                     
                     gPAExit_Peak = gActivePA;
                     string Message ="\n" + " >  Status: PRICEACTION -- PriceAction Exit";
                     Alert(gSymbol + " | Tenkensen/Kijunsen Exit form PriceAction -- Bulls In Control");
                     Comment(RightBarTime,Message);
               }
             else
               {
                     Read_Signal(1);
                     if(StringToDouble(gSignal[1]) != Ask) Record_Signal(gSignalsCSV,RightBarTime,Ask,0);
                     
                     gPAExit_Peak = gActivePA;
                     string Message ="\n" + " >  Status: PRICEACTION -- PriceAction Exit";
                     Alert(gSymbol + " | Tenkensen/Kijunsen Exit Form PriceAction -- Bulls In Control", "\r\n" , "But Divergence is too High");
                     Comment(RightBarTime,Message);
               }
             
        }
      if((gPAExit_Depth != gActivePA) && (BearEscapeAction(gActivePA) == True))
        {
            
             if(Divergence(0) <= 100)
               {
                    Read_Signal(1);
                    if(StringToDouble(gSignal[1]) != Bid) Record_Signal(gSignalsCSV,RightBarTime,Bid,1);
                    
                    gPAExit_Depth = gActivePA;
                    string Message ="\n" + " >  Status: PRICEACTION -- PriceAction Exit";
                    Alert(gSymbol + " | Tenkensen/Kijunsen Exit form PriceAction -- Bears In Control");
                    Comment(RightBarTime,Message);
               }
             else
               {
                    Read_Signal(1);
                    if(StringToDouble(gSignal[1]) != Bid) Record_Signal(gSignalsCSV,RightBarTime,Bid,1);
                    
                    gPAExit_Depth = gActivePA;
                     string Message ="\n" + " >  Status: PRICEACTION -- PriceAction Exit";
                    Alert(gSymbol + " | Tenkensen/Kijunsen Exit form PriceAction -- Bears In Control", "\r\n" , "But Divergence is too High");
                    Comment(RightBarTime,Message);
               }
             
        }
        
        
        
      if((Ask >= gActivePA) && (Candle_Breakeven(1,gActivePA) == True))
        {
             if(is_PrevCandle_Touch_Resistance(2,"BULLISH",gActivePA) == False)
               {
                   gBullCandleBreak = 1;
                   gBreakTime = RightBarTime;
                   string Message ="\n" + " >  Status: BULLISH BREAKEVEN -- Candle Broke PriceAction Resistance, Wait for Validation";
                   Alert(gSymbol + " | Price Action Breakeven -- Bullish Candle Broke PriceAction Resistance." ,"\r\n" ," But There is a probability of PullBack");
                   Comment(RightBarTime,Message);
               }
             else
               {
                   gBullCandleBreak = 1;
                   gBreakTime = RightBarTime;
                   string Message ="\n" + " >  Status: UNCURTAIN BREAKEVEN -- Candle Broke PriceAction Resistance, Wait for Validation";
                   Alert(gSymbol + " | Price Action Breakeven -- Bullish Candle Broke PriceAction Resistance." ,"\r\n" ,"Previous Candle Touched the Resistance.");
                   Comment(RightBarTime,Message);
               }
             
        }
      if((Bid <= gActivePA) && (Candle_Breakeven(1,gActivePA) == True))
         {
             if(is_PrevCandle_Touch_Resistance(2,"BEARISH",gActivePA) == False)
               {
                   gBearCandleBreak = 1;
                   gBreakTime = RightBarTime;
                   string Message ="\n" + " >  Status: BEARISH BREAKEVEN -- Candle Broke PriceAction Resistance, Wait for Validation";
                   Alert(gSymbol + " | Price Action Breakeven -- Bearish Candle Broke PriceAction Resistance." ,"\r\n" ,"But There is a probability of PullBack");
                   Comment(RightBarTime,Message);
               }
             else
               {
                   gBearCandleBreak = 1;
                   gBreakTime = RightBarTime;
                   string Message ="\n" + " >  Status: UNCURTAIN BREAKEVEN -- Candle Broke PriceAction Resistance, Wait for Validation";
                   Alert(gSymbol + " | Price Action Breakeven -- Bearish Candle Broke PriceAction Resistance." ,"\r\n" ,"Previous Candle Touched the Resistance.");
                   Comment(RightBarTime,Message);
               }
             
         }
      
   
   }
//+------------------------------------------------------------------+
void Price_Action_Check() 
   {
         datetime RightBarTime = iTime(_Symbol,Timeframe,0);
         if((gBullCandleBreak != 0) && (gBreakTime != RightBarTime))
           {
              
                   if((is_PrevCandle_Touch_Resistance(3,"BULLISH",gActivePA) ==False))
                      {
                        if((Break_Validation("BULLISH",gActivePA) == True))
                          {
                              gBullCandleBreak = 0;
                              Read_Signal(1);
                              if(StringToDouble(gSignal[1]) != Ask) Record_Signal(gSignalsCSV,RightBarTime,Ask,0);
                              
                              string Message ="\n" + " >  Status: PRICEACTION -- VALID BULLISH BREAKEVEN ";
                              Alert(gSymbol + " | Price Action Breakeven -- Bulls In Control. " ,"\r\n" ," There is a probability of PullBack");
                              Comment(RightBarTime,Message);
                          }
                        else
                          {
                              gBullCandleBreak = 0;
                              string Message ="\n" + " >  Status: PRICEACTION -- UNCURTAIN BULLISH BREAKEVEN";
                              Alert(gSymbol + " | Price Action Breakeven --  Bullish Candle Validly Broke PriceAction Resistance. " ,"\r\n" ,"But Last Candle Touched the Resistance, There is a probability of PullBack");
                              Comment(RightBarTime,Message);
                          }
                        
                      }
                   else
                     {
                        gBullCandleBreak = 0;
                        string Message ="\n" + " >  Status: PRICEACTION -- UNCURTAIN BULLISH BREAKEVEN";
                        Alert(gSymbol + " | Price Action Breakeven -- Bullish Candle Validly Broke PA Resistance. " ,"\r\n" ,"But Former Candles Touched the Resistance, There is a probability of PullBack");
                        Comment(RightBarTime,Message);
                     }

            
           }
         if((gBearCandleBreak != 0)  && (gBreakTime != RightBarTime))
           {
              
                    if((is_PrevCandle_Touch_Resistance(3,"BEARISH",gActivePA) == False))
                      {
                        if(Break_Validation("BEARSIH",gActivePA) == True)
                          {
                              gBearCandleBreak = 0;
                              Read_Signal(1);
                              if(StringToDouble(gSignal[1]) != Bid) Record_Signal(gSignalsCSV,RightBarTime,Bid,1);
                              
                              string Message ="\n" + " >  Status: PRICEACTION -- VALID BEARISH BREAKEVEN";
                              Alert(gSymbol + " | Price Action Breakeven -- Bears In Control. " ,"\r\n" ," There is a probability of PullBack");
                              Comment(RightBarTime,Message);
                          }
                        else
                          {
                              gBearCandleBreak = 0;
                              string Message ="\n" + " >  Status: PRICEACTION -- UNCURTAIN BEARISH BREAKEVEN";
                              Alert(gSymbol + " | Price Action Breakeven -- Bearish Candle Validly Broke PriceAction Resistance. " ,"\r\n" ,"But Last Candle Touched the Resistance, There is a probability of PullBack");
                              Comment(RightBarTime,Message);
                          }
                          }
                        
                    else
                     {
                        gBearCandleBreak = 0;
                        string Message ="\n" + " >  Status: PRICEACTION -- UNCURTAIN BEARISH BREAKEVEN -- Candle Validly Broke PriceAction Resistance";
                        Alert(gSymbol + " | Price Action Breakeven -- Bearish Candle Validly Broke PA Resistance. " ,"\r\n" ,"But Former Candles Touched the Resistance, There is a probability of PullBack");
                        Comment(RightBarTime,Message);
                     }
                  
            
          }
   }
//+------------------------------------------------------------------+
bool BullEscapeAction(double Price)
   {
         if(Price == 0) return false;
          
         double KijunSen = iIchimoku(_Symbol,Timeframe,9,26,52,2,0);
         if(KijunSen > Price)
           {
               for(int i=0;i<5;i++)
                 {
                     double TenkenSen = iIchimoku(_Symbol,Timeframe,9,26,52,1,i);
                     if(TenkenSen > Price) 
                        {
                           double TenkenSen_Prev = iIchimoku(_Symbol,Timeframe,9,26,52,1,i+1);
                           if(TenkenSen_Prev < Price) return true;
                             
                         } 
              
                 }
           }
         
         return false; 
    }    
//+------------------------------------------------------------------+         
bool BearEscapeAction(double Price)
   {
   
         if(Price == 0) return false;
         
         
         double KijunSen = iIchimoku(_Symbol,Timeframe,9,26,52,2,0);
         if(KijunSen < Price)
           {
               for(int i=0;i<5;i++)
                 {
                     double TenkenSen = iIchimoku(_Symbol,Timeframe,9,26,52,1,i);
                     if(TenkenSen < Price)
                       {
                            double TenkenSen_Prev = iIchimoku(_Symbol,Timeframe,9,26,52,1,i+1);
                            if(TenkenSen_Prev > Price) return true;
                             
                       }
                 }
           }
         return false; 
    }
//+------------------------------------------------------------------+ 
bool Validation_for_Peak(int TF, double PeakKomu)
   {
         double Senkou_A_Peak[];
         ArrayResize(Senkou_A_Peak,26);
         for(int i=0;i<26;i++)
           {
               double SenkouSpan_A = iIchimoku(_Symbol,TF,9,26,52,3,i-26);
               Senkou_A_Peak[i] = SenkouSpan_A;
           }
         int PeakKomuIndex = ArrayMaximum(Senkou_A_Peak,WHOLE_ARRAY,0); 
         double PeakForward = Senkou_A_Peak[PeakKomuIndex];
         if(PeakKomu >= PeakForward)
           {
               return true;
           }
         else return false;
           
   }
 //+------------------------------------------------------------------+  
bool Validation_for_Depth(int TF, double DepthKomu)
   {
         double Senkou_A_Depth[];
         ArrayResize(Senkou_A_Depth,26);
         for(int i=0;i<26;i++)
           {
               double SenkouSpan_A = iIchimoku(_Symbol,TF,9,26,52,3,i-26);
               Senkou_A_Depth[i] = SenkouSpan_A;
           }
         int DepthKomuIndex = ArrayMinimum(Senkou_A_Depth,WHOLE_ARRAY,0); 
         double DepthForward = Senkou_A_Depth[DepthKomuIndex];
         if(DepthKomu <= DepthForward)
           {
               
               return true;
           }
         else return false;
           
   }
 //+------------------------------------------------------------------+   
bool is_PrevCandle_Touch_Resistance(int Shift ,string Type, double Resistance)  
   {
      double LastClose = Close[Shift];
      if((Type == "BULLISH") && (LastClose >= Resistance))    return true;
      if((Type == "BEARISH") && (LastClose <= Resistance))    return true;
      else return false;
   }
//+------------------------------------------------------------------+  
bool Candle_Breakeven(int Shift ,double Resistance)  // ex : 152.234
   { 
      double Body ;
      double Up_Shadow;
      double Down_Shadow;
      double SumShadows;
      double UpperBreak;
      double LowerBreak;
      double Last_Close = Close[Shift];
      double Last_Open = Open[Shift];
      double Last_High = High[Shift];
      double Last_Low = Low[Shift];
      
      
      if((Last_Close > Last_Open) && (Last_Open <= Resistance)) // bullish
        {
            Body = Last_Close - Last_Open;
            Up_Shadow = Last_High - Last_Close;
            Down_Shadow = Last_Open - Last_Low;
            SumShadows = Up_Shadow + Down_Shadow;
            UpperBreak = Last_Close - Resistance;
            LowerBreak = Resistance - Last_Open;
            if((Body >= SumShadows) && (UpperBreak >= LowerBreak))   return true;
            else return false;
           
            
            
            
        }
      else if((Last_Close < Last_Open) && (Last_Open >= Resistance))  // bearish
        {
            Body = Last_Open - Last_Close;
            Up_Shadow = Last_High - Last_Open;
            Down_Shadow = Last_Close - Last_Low;
            SumShadows = Up_Shadow + Down_Shadow;
            UpperBreak = Last_Open - Resistance;
            LowerBreak = Resistance - Last_Close;
            if((Body >= SumShadows) && (LowerBreak >= UpperBreak))   return true;
            else return false;
       
         }
      return false;
   } 
//+------------------------------------------------------------------+ 
bool Break_Validation(string Type ,double Resistance) 
   {
      double Last_Close = Close[1];
      double Last_Open = Open[1];
      double Last_High = High[1];
      double Last_Low = Low[1];
      if(Type == "BULLISH")
        {
            if(Last_Low > Resistance)   return true;
        }
      else if(Type == "BEARISH")
             {
                  if(Last_High < Resistance)   return true;
             }
      return false;
   }
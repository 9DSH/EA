//+------------------------------------------------------------------+
//|                                                  The Hunter1.mq4 |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict



int gBuyTicket, gSellTicket, gClosedTicket ,gModifiedTicket, gTkLineBearish, gKjLineBearish, gChLineBearish ,gSwitch_Period,gBuyNum, gSellNum,
    gTkLineBullish , gKjLineBullish , gChLineBullish, gBuyLimitNum, gSellLimitNum; 
int  gModifiedOrder , gBullCross , gBearCross , gKjExitTime, gTkExitTime,gPADepthLine, gPAPeakLine;
double gPeakKomu, gDepthKomu, gBuyLimitOpen , gSellLimitOpen , gTotalSellProfit, gTotalBuyProfit, gInitialBalance, gPABuyOpened, gPASellOpened, gPAProfit, gRegularProfit = 0;
datetime gBarTime , gOpened_Time;
bool  gDeleteTicket,gPALine;


input int PriceAction = 1;
input int SmartRisk = 1;
input int Protection = 1;
input int TrailingStep= 100;
input int Trailing = 50;
input double Lot = 0.1;
input int PosNumber = 5;
input int Diverge = 100;
input int EMA = 59;
input int LimitSpread = 50;
input int ThreeExitCandleDiff = 4;
input int Volatility = 3;
input int ShadowMaximal = 500;
input int MaxDistance = 1000;
input int Shield_Activation = 70;
input int Shield = 10;
input double RISK = 10;




//+------------------------------------------------------------------+
int OnInit()
  {
      gInitialBalance = AccountBalance();
      datetime RightBarTime = iTime(_Symbol,_Period,0);
      string Message = " >> HUNTER START HUNTING !!!";
      Comment(RightBarTime,Message);

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
void OnTick()
  {
     
     
     if(OrdersTotal() > 0)
       {
           RiskManager();
           Get_Info_of_Positions();
           if(SmartRisk == 1)
             {
                  Smart_RiskManager();
             }
       }
     datetime RightBarTime = iTime(_Symbol,_Period,0);
     if(RightBarTime != gBarTime)
       {
           gBarTime = RightBarTime;
           
           CrossOver();
           CrossOrder();
           ThreeLinesSignal(27);
           ProfitCalculator();
           if(PriceAction == 1)
             {
                  Price_Action();
                  
             }
           
       }     
  }
//+------------------------------------------------------------------+
void ProfitCalculator()
   {
       int HSTTotal=OrdersHistoryTotal();
       gPAProfit =0;
       gRegularProfit = 0;
       for(int i=0;i<HSTTotal;i++)
          {
               if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY))
                 { 
                    if(OrderSymbol() == Symbol())
                       {
                           if(OrderMagicNumber() == 103)
                             { 
                                 gPAProfit = gPAProfit + OrderProfit();
                                 gPAProfit = NormalizeDouble(gPAProfit,2);
                                 
                             }
                           else
                             {
                                 gRegularProfit = gRegularProfit + OrderProfit();
                                 gRegularProfit = NormalizeDouble(gRegularProfit,2);
                             }
                       }
                 }
            }
   }
//+------------------------------------------------------------------+
void CrossOver()
  {
   datetime RightBarTime = iTime(_Symbol,_Period,0);
   double TenkenSen_current = iIchimoku(_Symbol,_Period,9,26,52,1,1); // Crossed Candle = 1
   double KijunSen_current = iIchimoku(_Symbol,_Period,9,26,52,2,1);
   double TenkenSen_previous = iIchimoku(_Symbol,_Period,9,26,52,1,2);
   double KijunSen_previous = iIchimoku(_Symbol,_Period,9,26,52,2,2);
   double ChikouSpan = iIchimoku(_Symbol,_Period,9,26,52,5,27);
   double HighPrice=High[27];
   double LowPrice = Low[27];
   
   
   if(TenkenSen_previous < KijunSen_previous && TenkenSen_current > KijunSen_current ) // is going to be Uptrend
     {
       if(ChikouSpan > HighPrice)
         {
            gBullCross++;
            gBearCross = 0;
            
            string Message ="\n" + " >  SIGNAL FOUND -- TK/KJ CROSS | Waiting For Greater Value..." + "\n" +  
            " > Trailing Step : " ;
            string PA ="\n" + " > PriceAction Profit : "; 
            string Profit = "\n" + " > Orders Profit : "; 
            Comment(RightBarTime,Message,TrailingStep,PA,gPAProfit,Profit,gRegularProfit);
         }
       else
         {
            string Message ="\n" + " >  WEAK SIGNAL | Looking For Stronger..." + "\n" +  
            " > Trailing Step : " ;
            string PA ="\n" + " > PriceAction Profit : "; 
            string Profit = "\n" + " > Orders Profit : "; 
            Comment(RightBarTime,Message,TrailingStep,PA,gPAProfit,Profit,gRegularProfit);
         
         }
            
     } 
   else if(TenkenSen_previous > KijunSen_previous && TenkenSen_current < KijunSen_current) // is going to be Downtrend
     {
       if(ChikouSpan < LowPrice)
         {
            gBearCross++;
            gBullCross = 0;
            string Message ="\n" + " >  SIGNAL FOUND -- TK/KJ CROSS | Waiting For Lower Value..."  + "\n" +  
            " > Trailing Step : ";
            string PA ="\n" + " > PriceAction Profit : "; 
            string Profit = "\n" + " > Orders Profit : "; 
            Comment(RightBarTime,Message,TrailingStep,PA,gPAProfit,Profit,gRegularProfit);
         }
       else
         {
            string Message ="\n" + " >  WEAK SIGNAL | Looking For Stronger..." + "\n" +  
            " > Trailing Step : " ;
            string PA ="\n" + " > PriceAction Profit : "; 
            string Profit = "\n" + " > Orders Profit : "; 
            Comment(RightBarTime,Message,TrailingStep,PA,gPAProfit,Profit,gRegularProfit);
         }
       
     } 
   else if(TenkenSen_current == KijunSen_current && TenkenSen_previous < KijunSen_previous) 
     { 
       if(ChikouSpan > HighPrice)
         {
            gBullCross++;
            gBearCross = 0;
            string Message ="\n" + " >  SIGNAL FOUND -- TK/KJ CROSS | Waiting For Greater Value..." + "\n" +  
            " > Trailing Step : ";
            string PA ="\n" + " > PriceAction Profit : "; 
            string Profit = "\n" + " > Orders Profit : "; 
            Comment(RightBarTime,Message,TrailingStep,PA,gPAProfit,Profit,gRegularProfit);
         }
       else
         {
            string Message ="\n" + " >  WEAK SIGNAL | Looking For Stronger..." + "\n" +  
            " > Trailing Step : ";
            string PA ="\n" + " > PriceAction Profit : "; 
            string Profit = "\n" + " > Orders Profit : "; 
            Comment(RightBarTime,Message,TrailingStep,PA,gPAProfit,Profit,gRegularProfit); 
         }
       
     }
   else if(TenkenSen_current == KijunSen_current && TenkenSen_previous > KijunSen_previous)
     {
       if(ChikouSpan < LowPrice)
         {
            gBearCross++;
            gBullCross = 0;
            string Message ="\n" + " >  SIGNAL FOUND -- TK/KJ CROSS | Waiting For Lower Value..." + "\n" +  
            " > Trailing Step : " ;
            string PA ="\n" + " > PriceAction Profit : "; 
            string Profit = "\n" + " > Orders Profit : "; 
            Comment(RightBarTime,Message,TrailingStep,PA,gPAProfit,Profit,gRegularProfit);
         }
       else
         {
            string Message ="\n" + " >  WEAK SIGNAL | Looking For Stronger..." + "\n" +  
            " > Trailing Step : ";
            string PA ="\n" + " > PriceAction Profit : "; 
            string Profit = "\n" + " > Orders Profit : "; 
            Comment(RightBarTime,Message,TrailingStep,PA,gPAProfit,Profit,gRegularProfit);
         }
     }
       
  } 

//+------------------------------------------------------------------+
string ICHI(int Shift)
   {
     double TenkenSen_current = iIchimoku(_Symbol,_Period,9,26,52,1,Shift);
     double KijunSen_current = iIchimoku(_Symbol,_Period,9,26,52,2,Shift); 
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
double  Divergence(int Shift)
   {
      double DivergValue;
      
      double KijunSen_new = iIchimoku(_Symbol,_Period,9,26,52,2,Shift);
      double TenkenSen_new = iIchimoku(_Symbol,_Period,9,26,52,1,Shift);
      
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
bool Is_Spread_Limited()
   {
      double Differention;
      if(Ask > Bid) Differention = (Ask - Bid)/_Point;
      else Differention = (Bid - Ask)/_Point;
      
      if(Differention >= LimitSpread) return true;
      else return false;
     
        
   }
//+------------------------------------------------------------------+ 
bool Is_Candle_Volatile(int period)   /// period = number of candles to check 
   {
      for(int i=0;i<period;i++)
        {
            if(Candle_Shadow_Length(i,"UP-SHADOW") >= ShadowMaximal) return true;
            if(Candle_Shadow_Length(i,"LOW-SHADOW") >= ShadowMaximal) return true;     
        }
      return false;
   }
//+------------------------------------------------------------------+ 
double Distance_PriceGetaway(string Type , int Shift)   
   {
      double Distance ;
      double LastClose = Close[Shift];
      double KijunSen = iIchimoku(_Symbol,_Period,9,26,52,2,Shift);
      if(Type == "BULL") {Distance = (LastClose - KijunSen)/_Point; return Distance;}
      if(Type == "BEAR") {Distance = (KijunSen - LastClose)/_Point; return Distance;}
      return NULL;
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
      if(Type == "UP-SHADOW") return UpperShadow/_Point;
      if(Type == "LOW-SHADOW") return LowerShadow/_Point;
      
      return NULL;
      
   }
//+------------------------------------------------------------------+ 
void Bull_Hunter()  
   {  
      datetime RightBarTime = iTime(_Symbol,_Period,0);
      double KijunSen_previous = iIchimoku(_Symbol,_Period,9,26,52,2,2);
      double KijunSen_new = iIchimoku(_Symbol,_Period,9,26,52,2,1);
      double EMALine = iMA(_Symbol,_Period,EMA,0,1,0,0);
      double LastClosePrice = Close[1];
      
      if(KijunSen_new > KijunSen_previous)
        {      
            if((Is_Candle_Volatile(Volatility) == False) && (Distance_PriceGetaway("BULL",1) <= MaxDistance)) 
              {
                  if((BuyConfirmation() == True) && (BearEscapeAction(gDepthKomu) == False)  && (Divergence(0) <= Diverge) && (Is_Spread_Limited() == False))
                    {
                        string Message ="\n" + " >  CROSS | BUY ORDER | HUNTER Launch Data Management" + "\n" + 
                        " > Trailing Step : ";
                        string PA ="\n" + " > PriceAction Profit : "; 
                        string Profit = "\n" + " > Orders Profit : "; 
                             
                        if(LastClosePrice > EMALine)
                            {
                              for(int i=0;i<PosNumber;i++)
                                 { 
                                    gBuyTicket = OrderSend(_Symbol,OP_BUY,Lot,Ask,100,0,0);
                                 }
                              gBullCross = 0;
                              Comment(RightBarTime,Message,TrailingStep,PA,gPAProfit,Profit,gRegularProfit);
                          }
                          
                        else
                          {
                              for(int i=0;i<PosNumber;i++)
                                 {
                                     gBuyTicket = OrderSend(_Symbol,OP_BUY,Lot/2,Ask,100,0,0);
                                 }
                              gBullCross = 0;
                               Comment(RightBarTime,Message,TrailingStep,PA,gPAProfit,gRegularProfit);
                          }
                        
                    }
                  else
                    {
                        string Mess = "\n" + " > Opening Position is not Allowed.(Another Position Exist, PA Escaped, Divergency)" + "\n" + 
                        " > Trailing Step : " ;
                        string PA ="\n" + " > PriceAction Profit : "; 
                        string Profit = "\n" + " > Orders Profit : ";   
                        gBullCross = 0;
                         Comment(RightBarTime,Mess,TrailingStep,PA,gPAProfit,Profit,gRegularProfit);
                        
                    }
              }
             else
               {
                     gBullCross = 0;
                     string HunterMessage ="\n" + " >  CROSS FAILED | Valitality is Too High..." + "\n" +
                     " > Trailing Step : ";
                     string PA ="\n" + " > PriceAction Profit : "; 
                     string Profit = "\n" + " > Orders Profit : ";  
                      Comment(RightBarTime,HunterMessage,TrailingStep,PA,gPAProfit,Profit,gRegularProfit);
               }
            
             
              
            
        }
      else
        {
            string HunterMessage ="\n" + " >  CROSS | Waiting For Greater Value..." + "\n" +
            " > Trailing Step : ";
            string PA ="\n" + " > PriceAction Profit : "; 
            string Profit = "\n" + " > Orders Profit : ";  
             Comment(RightBarTime,HunterMessage,TrailingStep,PA,gPAProfit,Profit,gRegularProfit);
             
        }
    } 

//+------------------------------------------------------------------+
void Bear_Hunter()
   {  
      datetime RightBarTime = iTime(_Symbol,_Period,0);
      double KijunSen_previous = iIchimoku(_Symbol,_Period,9,26,52,2,2);
      double KijunSen_new = iIchimoku(_Symbol,_Period,9,26,52,2,1);
      double EMALine = iMA(_Symbol,_Period,EMA,0,1,0,0);
      double LastClosePrice = Close[1];
      
      if(KijunSen_new < KijunSen_previous) 
        {
            if((Is_Candle_Volatile(Volatility) == False) && (Distance_PriceGetaway("BEAR",1) <= MaxDistance))
              {
                  if((SellConfirmation() == True) && (BullEscapeAction(gPeakKomu) == False) && (Divergence(0) <= Diverge)&& (Is_Spread_Limited() == False))
                       {
                           
                           string Message ="\n" + " >  CROSS | SELL ORDER | HUNTER Launch Data Management" + "\n" +
                           " > Trailing Step : ";
                           string PA ="\n" + " > PriceAction Profit : "; 
                           string Profit = "\n" + " > Orders Profit : ";  
                           if(LastClosePrice < EMALine)
                             {
                                for(int i=0;i<PosNumber;i++)
                                    {
                                          gSellTicket = OrderSend(_Symbol,OP_SELL,Lot,Bid,100,0,0);
                                    }
                                gBearCross = 0;
                                Comment(RightBarTime,Message,TrailingStep,PA,gPAProfit,Profit,gRegularProfit);
                             }
                           else
                             {
                                for(int i=0;i<PosNumber;i++)
                                    {
                                         gSellTicket = OrderSend(_Symbol,OP_SELL,Lot/2,Bid,100,0,0);
                                    }
                                gBearCross = 0;
                                Comment(RightBarTime,Message,TrailingStep,PA,gPAProfit,gRegularProfit);
                             }
                       }
                     else
                       {
                            
                           gBearCross = 0;
                           string Mess = "\n" + " > Opening Position is not Allowed.(Another Position Exist, PA Escaped, Divergency)" + "\n" + 
                           " > Trailing Step : " ;
                           string PA ="\n" + " > PriceAction Profit : "; 
                           string Profit = "\n" + " > Orders Profit : "; 
                           Comment(RightBarTime,Mess,TrailingStep,PA,gPAProfit,Profit,gRegularProfit);
                       }
              }
            else
              {
                  gBearCross = 0;
                  string HunterMessage ="\n" + " >  CROSS FAILED | Valitality is Too High..." + "\n" +
                  " > Trailing Step : "  ;
                  string PA ="\n" + " > PriceAction Profit : "; 
                  string Profit = "\n" + " > Orders Profit : ";   
                  Comment(RightBarTime,HunterMessage,TrailingStep,PA,gPAProfit,Profit,gRegularProfit);
              }
            
            
        }
      else
        {
            string HunterMessage ="\n" + " >  CROSS | Waiting For Lower Value..." + "\n" +
            " > Trailing Step : "  ;
            string PA ="\n" + " > PriceAction Profit : "; 
            string Profit = "\n" + " > Orders Profit : ";   
            Comment(RightBarTime,HunterMessage,TrailingStep,PA,gPAProfit,Profit,gRegularProfit);
             
        }     

    } 

//+------------------------------------------------------------------+
void CrossOrder()
   {
      if(gBullCross != 0)
        {   
            if(ICHI(0) == "UP"  || ICHI(0) == "ROAD")
              {
                  Bull_Hunter();
              }
        }
      else if(gBearCross != 0)
             {
               if(ICHI(0) == "DOWN" || ICHI(0) == "ROAD")
                 {
                     Bear_Hunter();
                 }
             }
   }
//+------------------------------------------------------------------+
void ThreeLinesSignal(int Shift) // 27
   {
      ThreeLinesExits(Shift);; //27   
      KomuSwitch(Shift+1); // 28
      Pullback_To_Komu(Shift-26);
      
      if(OrdersTotal() > 0)
        {
            RiskManager();
            ThreeLinesOrder(Shift); //27
        }
      else ThreeLinesOrder(Shift);
   }
//+------------------------------------------------------------------+
void KomuSwitch(int Shift) // 28
   {
      double SenkouSpan_B_For_Chikou_p = iIchimoku(_Symbol,_Period,9,26,52,4,Shift);
      double SenkouSpan_A_For_Chikou_p = iIchimoku(_Symbol,_Period,9,26,52,3,Shift);
      
      if(SenkouSpan_A_For_Chikou_p > SenkouSpan_B_For_Chikou_p)
        {
            
                  double SenkouSpan_B_Current = iIchimoku(_Symbol,_Period,9,26,52,4,Shift-1);
                  double SenkouSpan_A_Current = iIchimoku(_Symbol,_Period,9,26,52,3,Shift-1);
                  if(SenkouSpan_A_Current <= SenkouSpan_B_Current)
                    {
                        gTkLineBullish = 0;
                        gKjLineBullish = 0;
                        gChLineBullish = 0;
                        gTkLineBearish = 0;
                        gKjLineBearish = 0;
                        gChLineBearish = 0;
                    }

        }
      if(SenkouSpan_A_For_Chikou_p <= SenkouSpan_B_For_Chikou_p)
        {
            
                  double SenkouSpan_B_Current1 = iIchimoku(_Symbol,_Period,9,26,52,4,Shift-1);
                  double SenkouSpan_A_Current1 = iIchimoku(_Symbol,_Period,9,26,52,3,Shift-1);
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
      datetime ExitTime = iTime(_Symbol,_Period,Shift);
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
//+------------------------------------------------------------------+
void ThreeLinesExits(int Shift) //27
   {
      double Span_A = iIchimoku(_Symbol,_Period,9,26,52,3,Shift-27);
      double Span_B = iIchimoku(_Symbol,_Period,9,26,52,4,Shift-27);
      if(Span_A > Span_B)
        {
           if(TenkenSenLine_BullishExit(Shift-26) == True)
             {
                 string Message ="\n" + " > Status: KOMU -- Tenkensen Exits From Bullish Komu" + "\n" +
                  " > ThreeLines Status : ";
                 datetime RightBarTime = iTime(_Symbol,_Period,Shift-27); 
                 Comment(RightBarTime,Message,gTkLineBearish,gKjLineBearish,gChLineBearish);
             }
           if(KijunSenLine_BullishExit(Shift-26) == True)
             {
                string Message ="\n" + " > Status: KOMU -- Kijunsen Exits From Bullish Komu"+ "\n" +
                        " > ThreeLines Status : " ;
                datetime RightBarTime = iTime(_Symbol,_Period,Shift-27);
                Comment(RightBarTime,Message,gTkLineBearish,gKjLineBearish,gChLineBearish);                
             }
           if(ChikouSpanLine_BullishExit(Shift) == True)
             {
                string Message ="\n" + " > Status: KOMU -- Chikouspan Exits From Bullish Komu" + "\n" +
                        " > ThreeLines Status : ";
                datetime RightBarTime = iTime(_Symbol,_Period,Shift-1);  
                Comment(RightBarTime,Message,gTkLineBearish,gKjLineBearish,gChLineBearish);
             }
        }
      else if(Span_A <= Span_B)
             {
                  if(TenkenSenLine_BearishExit(Shift-26) == True)
                    {
                        string Message1 ="\n" + " > Status: KOMU -- Tenkensen Exits From Bearish Komu" + "\n" +
                        " > ThreeLines Status : ";
                        datetime RightBarTime = iTime(_Symbol,_Period,Shift-27);
                        Comment(RightBarTime,Message1,gTkLineBullish,gKjLineBullish,gChLineBullish);
                    }
                  if(KijunSenLine_BearishExit(Shift-26) == True)
                    {
                        string Message1 ="\n" + " > Status: KOMU -- Kijunsen Exits From Bearish Komu"+ "\n" +
                        " > ThreeLines Status : ";
                        datetime RightBarTime = iTime(_Symbol,_Period,Shift-27);
                        Comment(RightBarTime,Message1,gTkLineBullish,gKjLineBullish,gChLineBullish);
                    }
                  if(ChikouSpanLine_BearishExit(Shift) == True)
                    {
                        string Message1 ="\n" + " > Status: KOMU -- Chikouspan Exits From Bearish Komu"+ "\n" +
                        " > ThreeLines Status : " ;
                        datetime RightBarTime = iTime(_Symbol,_Period,Shift-1); 
                        Comment(RightBarTime,Message1,gTkLineBullish,gKjLineBullish,gChLineBullish);
                    }
             }
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
void ThreeLinesOrder(int Shift) //27
   {
      double SenkouSpan_B_For_Chikou = iIchimoku(_Symbol,_Period,9,26,52,4,Shift);
      double ChikouSpan = iIchimoku(_Symbol,_Period,9,26,52,5,Shift);
      double HighPrice=High[Shift];
      double LowPrice = Low[Shift];
      datetime RightBarTime = iTime(_Symbol,_Period,0);
      if((gTkLineBearish != 0) && (gKjLineBearish != 0) && (gChLineBearish != 0) && (SellConfirmation() == True))
                    {
                       if(is_there_switch_Forward(Shift-27) == True)
                         {
                              gTkLineBullish = 0;
                              gKjLineBullish = 0;
                              gChLineBullish = 0;
                              gTkLineBearish = 0;
                              gKjLineBearish = 0;
                              gChLineBearish = 0;
                              
                              
                              string Message ="\n" + " > Status: Invalid ThreeLines Exit -- There is a Switch Komu in Between."+ "\n" +
                              " > Trailing Step : " ;
                              string PA ="\n" + " > PriceAction Profit : "; 
                              string Profit = "\n" + " > Orders Profit : "; 
                              Comment(RightBarTime,Message,TrailingStep,PA,gPAProfit,Profit,gRegularProfit);
                         }
                       else
                         {
                              
                              if((ICHI(Shift-27) != "UP") && (TimeExitDifference(gKjExitTime , gTkExitTime) <= (ThreeExitCandleDiff*_Period)) 
                                && (Is_Candle_Volatile(Volatility) == False) && (Distance_PriceGetaway("BEAR",1) <= MaxDistance))
                                  {
                                       if((ChikouSpan < LowPrice) && (ChikouSpan < SenkouSpan_B_For_Chikou))
                                        {
                                            gTkLineBearish = 0;
                                            gKjLineBearish = 0;
                                            gChLineBearish = 0;
                                            
                                            for(int i=0;i<PosNumber;i++)
                                               {
                                                   gSellTicket = OrderSend(_Symbol,OP_SELL,Lot,Bid,100,0,0);
                                               }
                                            string Message ="\n" + " > SIGNAL FOUND -- Valid ThreeLines | SELL ORDER | HUNTER Launch Data Management" + "\n" +
                                            " > Trailing Step : "  ;
                                            string PA ="\n" + " > PriceAction Profit : "; 
                                            string Profit = "\n" + " > Orders Profit : "; 
                                            Comment(RightBarTime,Message,TrailingStep,PA,gPAProfit,Profit,gRegularProfit);
                                        }
                                  }
                                else
                                  {
                                       gTkLineBearish = 0;
                                       gKjLineBearish = 0;
                                       gChLineBearish = 0;
                                       string Message ="\n" + " > SIGNAL FAILED -- inValid ThreeLines | ICHI Limited | Looking For Another Signal..," + "\n" +
                                       " > Trailing Step : " ;
                                       string PA ="\n" + " > PriceAction Profit : "; 
                                       string Profit = "\n" + " > Orders Profit : "; 
                                       Comment(RightBarTime,Message,TrailingStep,PA,gPAProfit,Profit,gRegularProfit);
                                  }
                         }
                       
                       
                       
                    }
                    
      if((gTkLineBullish != 0) && (gKjLineBullish != 0) && (gChLineBullish != 0) && (BuyConfirmation() == True))
                    {
                      if(is_there_switch_Forward(Shift-27) == True)
                         {
                              gTkLineBullish = 0;
                              gKjLineBullish = 0;
                              gChLineBullish = 0;
                              gTkLineBearish = 0;
                              gKjLineBearish = 0;
                              gChLineBearish = 0;
                              string Message ="\n" + " > Status: Invalid ThreeLines Exit | There is a Switch Komu in Between..." + "\n" +
                              " > Trailing Step : " ;
                              string PA ="\n" + " > PriceAction Profit : "; 
                              string Profit = "\n" + " > Orders Profit : "; 
                              Comment(RightBarTime,Message,TrailingStep,PA,gPAProfit,Profit,gRegularProfit); 
                         }
                      else
                        {
                             if((ICHI(Shift-27) != "DOWN") && (TimeExitDifference(gKjExitTime , gTkExitTime) <= (ThreeExitCandleDiff*_Period))
                               && (Is_Candle_Volatile(Volatility) == False) && (Distance_PriceGetaway("BULL",1) <= MaxDistance))
                                 {
                                       if((ChikouSpan > HighPrice) && (ChikouSpan > SenkouSpan_B_For_Chikou))
                                          {
                                              gTkLineBullish = 0;
                                              gKjLineBullish = 0;
                                              gChLineBullish = 0;
                                              
                                              for(int i=0;i<PosNumber;i++)
                                                 {
                                                        gBuyTicket = OrderSend(_Symbol,OP_BUY,Lot,Ask,100,0,0);
                                                  }
                                              string Message1 ="\n" + " > SIGNAL FOUND -- Valid ThreeLines | BUY ORDER | HUNTER Launch Data Management"+ "\n" +
                                              " > Trailing Step : ";
                                              string PA ="\n" + " > PriceAction Profit : "; 
                                              string Profit = "\n" + " > Orders Profit : "; 
                                               Comment(RightBarTime,Message1,TrailingStep,PA,gPAProfit,Profit,gRegularProfit);
                                          }
                                 }
                               else
                                 {
                                       gTkLineBullish = 0;
                                       gKjLineBullish = 0;
                                       gChLineBullish = 0; 
                                       string Message ="\n" + " > SIGNAL FAILED -- inValid ThreeLines | ICHI Limited | Looking For Another Signal..," + "\n" +
                                       " > Trailing Step : "  ;
                                       string PA ="\n" + " > PriceAction Profit : "; 
                                       string Profit = "\n" + " > Orders Profit : "; 
                                        Comment(RightBarTime,Message,TrailingStep,PA,gPAProfit,Profit,gRegularProfit); 
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
      double SenkouSpan_B = iIchimoku(_Symbol,_Period,9,26,52,4,Shift);
      double SenkouSpan_A = iIchimoku(_Symbol,_Period,9,26,52,3,Shift);
      double TenkenSen_current = iIchimoku(_Symbol,_Period,9,26,52,1,Shift);
      datetime RightBarTime = iTime(_Symbol,_Period,Shift-1);
     
      if((TenkenSen_current <= SenkouSpan_B) && (TenkenSen_current < SenkouSpan_A) && (SenkouSpan_A > SenkouSpan_B))
        {
           for(int i=Shift+1;i<=Shift+2;i++)
             {
                  double SenkouSpan_B_previous = iIchimoku(_Symbol,_Period,9,26,52,4,i);
                  double TenkenSen_previous = iIchimoku(_Symbol,_Period,9,26,52,1,i);
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
      double SenkouSpan_B = iIchimoku(_Symbol,_Period,9,26,52,4,Shift);
      double SenkouSpan_A = iIchimoku(_Symbol,_Period,9,26,52,3,Shift);
      double TenkenSen_current = iIchimoku(_Symbol,_Period,9,26,52,1,Shift);
      datetime RightBarTime = iTime(_Symbol,_Period,Shift-1);
         
      if((TenkenSen_current >= SenkouSpan_B) && (TenkenSen_current > SenkouSpan_A) && (SenkouSpan_A < SenkouSpan_B))  
        {
           for(int j=Shift+1;j<=Shift+2;j++)
             {
                  double SenkouSpan_B_previous1 = iIchimoku(_Symbol,_Period,9,26,52,4,j);
                  double TenkenSen_previous1 = iIchimoku(_Symbol,_Period,9,26,52,1,j);
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
      double SenkouSpan_B = iIchimoku(_Symbol,_Period,9,26,52,4,Shift);
      double SenkouSpan_A = iIchimoku(_Symbol,_Period,9,26,52,3,Shift);
      double KijunSen_current = iIchimoku(_Symbol,_Period,9,26,52,2,Shift);
      datetime RightBarTime = iTime(_Symbol,_Period,Shift-1);
      
      if((KijunSen_current <= SenkouSpan_B) && (KijunSen_current < SenkouSpan_A) && (SenkouSpan_A > SenkouSpan_B))
        {
            for(int i=Shift+1;i<=Shift+2;i++)
              {
                  double SenkouSpan_B_previous = iIchimoku(_Symbol,_Period,9,26,52,4,i);
                  double KijunSen_previous = iIchimoku(_Symbol,_Period,9,26,52,2,i);
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
      double SenkouSpan_B = iIchimoku(_Symbol,_Period,9,26,52,4,Shift);
      double SenkouSpan_A = iIchimoku(_Symbol,_Period,9,26,52,3,Shift);
      double KijunSen_current = iIchimoku(_Symbol,_Period,9,26,52,2,Shift);
      datetime RightBarTime = iTime(_Symbol,_Period,Shift-1);
         
      if((KijunSen_current >= SenkouSpan_B) && (KijunSen_current > SenkouSpan_A) && (SenkouSpan_A < SenkouSpan_B))
        {
            for(int j=Shift+1;j<=Shift+2;j++)
              {
                  double SenkouSpan_B_previous1 = iIchimoku(_Symbol,_Period,9,26,52,4,j);
                  double KijunSen_previous1 = iIchimoku(_Symbol,_Period,9,26,52,2,j);
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
      if(Prev_Chikou_inKomu("BEAR",Shift) == True)
         {
            
            if((Span_A_For_Chikou > Span_B_For_Chikou) && (ChikouSpan_current <= Span_B_For_Chikou) && (ChikouSpan_current < Span_A_For_Chikou))
              {
                   if(ChikouConfirmSell(Shift) == true)
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
      if(Prev_Chikou_inKomu("BULL",Shift) == True)
        {
            if( (Span_A_For_Chikou < Span_B_For_Chikou) && (ChikouSpan_current >= Span_B_For_Chikou) && (ChikouSpan_current > Span_A_For_Chikou))
                 {
                     if(ChikouConfirmBuy(Shift) == True)
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
            for(int i=ThreeExitCandleDiff;i>=0;i--)
              {
                  double Span_B_For_Chikou = iIchimoku(_Symbol,_Period,9,26,52,4,Shift+i);
                  double ChikouSpan = iIchimoku(_Symbol,_Period,9,26,52,5,Shift+i);
                  if(ChikouSpan <= Span_B_For_Chikou) return true;   
              }
        }
      if(Type == "BEAR")
        {
             for(int i=ThreeExitCandleDiff;i>=0;i--)
              {
                  double Span_B_For_Chikou = iIchimoku(_Symbol,_Period,9,26,52,4,Shift+i);
                  double ChikouSpan = iIchimoku(_Symbol,_Period,9,26,52,5,Shift+i);
                  if(ChikouSpan >= Span_B_For_Chikou) return true;   
              }
        }
      
      return false;
   } 
//+------------------------------------------------------------------+ 
/* int Prev_Chikou_inKomu(string Type, int Shift) // 27
   {
      int inKomu = 0;
      if(Type == "BULL")
        {
            for(int i=ThreeExitCandleDiff;i>0;i--)
              {
                  double Span_B_For_Chikou = iIchimoku(_Symbol,_Period,9,26,52,4,Shift+i);
                  double ChikouSpan = iIchimoku(_Symbol,_Period,9,26,52,5,Shift+i);
                  if(ChikouSpan <= Span_B_For_Chikou) inKomu++;   
              }
        }
      if(Type == "BEAR")
        {
             for(int i=ThreeExitCandleDiff;i>0;i--)
              {
                  double Span_B_For_Chikou = iIchimoku(_Symbol,_Period,9,26,52,4,Shift+i);
                  double ChikouSpan = iIchimoku(_Symbol,_Period,9,26,52,5,Shift+i);
                  if(ChikouSpan >= Span_B_For_Chikou) inKomu++;   
              }
        }
      
      return false; 
   } */
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
 //+------------------------------------------------------------------+
 
void Price_Action()
   {
      double Span_A = iIchimoku(_Symbol,_Period,9,26,52,3,-26);
      double Span_B = iIchimoku(_Symbol,_Period,9,26,52,4,-26);
      
      if(Span_A > Span_B)
        {
             for(int i=0;i<52;i++)
              {
                  double Bull_SenkouSpan_A = iIchimoku(_Symbol,_Period,9,26,52,3,i-26);
                  double Bull_SenkouSpan_B = iIchimoku(_Symbol,_Period,9,26,52,4,i-26);
                  if(Bull_SenkouSpan_A > Bull_SenkouSpan_B)
                    {
                        double SenkouSpan_A_Previous = iIchimoku(_Symbol,_Period,9,26,52,3,(i+1)-26);
                        double SenkouSpan_B_Previous = iIchimoku(_Symbol,_Period,9,26,52,4,(i+1)-26);
                        if(SenkouSpan_A_Previous < SenkouSpan_B_Previous)
                          {
                              // Switch Komu
                              int Depth_Period = (i+1);
                              Get_Price_Action("Depth" ,Depth_Period);
                              for(int j=(Depth_Period+1);j<52;j++)
                                   {
                                       double SenkouSpan_A = iIchimoku(_Symbol,_Period,9,26,52,3,j-26);
                                       double SenkouSpan_B = iIchimoku(_Symbol,_Period,9,26,52,4,j-26);
                                       if(SenkouSpan_A < SenkouSpan_B)
                                         {
                                             double Bull_SenkouSpan_A_Previous = iIchimoku(_Symbol,_Period,9,26,52,3,(j+1)-26);
                                             double Bull_SenkouSpan_B_Previous = iIchimoku(_Symbol,_Period,9,26,52,4,(j+1)-26);
                                             if(Bull_SenkouSpan_A_Previous > Bull_SenkouSpan_B_Previous)
                                               {
                                                   // Switch Komu
                                                   int Peak_Period = (j+1);
                                                   Get_Price_Action("Peak" , Peak_Period);
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
                  double Bear_SenkouSpan_A = iIchimoku(_Symbol,_Period,9,26,52,3,i-26);
                  double Bear_SenkouSpan_B = iIchimoku(_Symbol,_Period,9,26,52,4,i-26);
                  if(Bear_SenkouSpan_A < Bear_SenkouSpan_B)
                    {
                        double SenkouSpan_A_Previous = iIchimoku(_Symbol,_Period,9,26,52,3,(i+1)-26);
                        double SenkouSpan_B_Previous = iIchimoku(_Symbol,_Period,9,26,52,4,(i+1)-26);
                        if(SenkouSpan_A_Previous > SenkouSpan_B_Previous)
                          {
                              // Switch Komu
                              int Peak_Period = (i+1);
                              Get_Price_Action("Peak" , Peak_Period);
                              for(int j=(Peak_Period+1);i<52;j++)
                                   {
                                       double SenkouSpan_A = iIchimoku(_Symbol,_Period,9,26,52,3,j-26);
                                       double SenkouSpan_B = iIchimoku(_Symbol,_Period,9,26,52,4,j-26);
                                       if(SenkouSpan_A > SenkouSpan_B)
                                         {
                                             double Bear_SenkouSpan_A_Previous = iIchimoku(_Symbol,_Period,9,26,52,3,(j+1)-26);
                                             double Bear_SenkouSpan_B_Previous = iIchimoku(_Symbol,_Period,9,26,52,4,(j+1)-26);
                                             if(Bear_SenkouSpan_A_Previous < Bear_SenkouSpan_B_Previous)
                                               {
                                                   // Switch Komu
                                                   int Depth_Period = (j+1);
                                                   Get_Price_Action("Depth" ,Depth_Period);
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
                         double SenkouSpan_A = iIchimoku(_Symbol,_Period,9,26,52,3,i-26);
                         double SenkouSpan_B = iIchimoku(_Symbol,_Period,9,26,52,4,i-26);
                         if(SenkouSpan_A > SenkouSpan_B)
                           {
                              int Peak_Period = (i+1);
                              Get_Price_Action("Peak" , Peak_Period);
                           }
                         if(SenkouSpan_A < SenkouSpan_B)
                           {
                               int Depth_Period = (i+1);
                               Get_Price_Action("Depth" ,Depth_Period);
                           }
                    }
             }
}
      

//+------------------------------------------------------------------+
void Get_Price_Action(string SwitchType, int SwitchPeriod)
   {
      double Senkou_A_Depth[];
      double Senkou_A_Peaks[];
      
      if(SwitchType == "Depth")
        {
             ArrayResize(Senkou_A_Depth,26);
             for(int i=SwitchPeriod;i<(SwitchPeriod+26);i++)
                 {
                     double SenkouSpan_A = iIchimoku(_Symbol,_Period,9,26,52,3,i-26);
                     Senkou_A_Depth[i-SwitchPeriod] = SenkouSpan_A;
                 }
             int DepthKomuIndex = ArrayMinimum(Senkou_A_Depth,WHOLE_ARRAY,0);
             gDepthKomu = Senkou_A_Depth[DepthKomuIndex]; 
                       
        }
      else if(SwitchType == "Peak")
             {
                  ArrayResize(Senkou_A_Peaks,26);
                  for(int i=SwitchPeriod;i<(SwitchPeriod+26);i++)
                     {
                          double SenkouSpan_A = iIchimoku(_Symbol,_Period,9,26,52,3,i-26);
                          Senkou_A_Peaks[i-SwitchPeriod] = SenkouSpan_A;
                     }
                  int PeakKomuIndex = ArrayMaximum(Senkou_A_Peaks,WHOLE_ARRAY,0); 
                  gPeakKomu = Senkou_A_Peaks[PeakKomuIndex];
                  
             }
   }
//+------------------------------------------------------------------+
bool SellConfirmation()
   {
      double Upper_Open = Open[2];
      double Current_Open = Open[0];
      double Upper_Bound = Bid + 40*_Point;
      double Lower_Bound = Bid - 40*_Point;
      double Span_A = iIchimoku(_Symbol,_Period,9,26,52,3,0);
      double Span_B = iIchimoku(_Symbol,_Period,9,26,52,4,0);
      if(OrdersTotal() > 0)
        {
            for(int i=OrdersTotal()-1;i>=0;i--)
                 {
                     if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
                       {
                           if(OrderSymbol() == Symbol())
                             {
                                 if(OrderType() == OP_SELL)
                                   {
                                       if((Upper_Bound >= OrderOpenPrice()) && (OrderOpenPrice() >= Lower_Bound))
                                         {
                                             return false;
                                         }
                                       
                                   }
                             }
                        }
                  }
        }
      
      if((Span_B > Span_A) && (Upper_Open > Span_B) && (Current_Open < Span_A))
        {
             return false;
        }
      return true;                       
     
   }
//+------------------------------------------------------------------+
bool BuyConfirmation()
   {
      double Lower_Open = Open[2];
      double Current_Open = Open[0];
      double Upper_Bound = Ask + 40*_Point;
      double Lower_Bound = Ask - 40*_Point;
      double Span_A = iIchimoku(_Symbol,_Period,9,26,52,3,0);
      double Span_B = iIchimoku(_Symbol,_Period,9,26,52,4,0);
      if(OrdersTotal() > 0)
        {
             for(int i=OrdersTotal()-1;i>=0;i--)
                 {
                     if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
                       {
                           if(OrderSymbol() == Symbol())
                             {
                                 if(OrderType() == OP_BUY)
                                   {
                                       if((Upper_Bound >= OrderOpenPrice()) && (OrderOpenPrice() >= Lower_Bound))
                                         {
                                             return false;
                                            
                                         }
                                       
                                       
                                   }
                             }
                        }
                  }
        }
     
       if((Span_B < Span_A) && (Lower_Open < Span_B) && (Current_Open > Span_A))
           {
                return false;
           }
       return true;
                             
     
   }
//+------------------------------------------------------------------+
void Get_Info_of_Positions()
 {
            gBuyNum = 0;
            gSellNum = 0;
            gBuyLimitNum = 0;
            gSellLimitNum = 0;
            gTotalSellProfit = 0;
            gTotalBuyProfit = 0;
            for(int i=OrdersTotal()-1;i>=0;i--)
              {
                  if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
                    {
                        if(OrderSymbol() == Symbol())
                          {
                              if(OrderType() == OP_BUY)
                                {
                                    gTotalBuyProfit += OrderProfit();
                                    if(OrderMagicNumber() == 103)
                                       {
                                           gBuyLimitNum++;
                                           gPABuyOpened = OrderOpenPrice(); 
                                       }
                                    else
                                       {
                                             gBuyNum++;
                                       }
                                }
                              if(OrderType() == OP_SELL)
                                {
                                    gTotalSellProfit += OrderProfit();
                                    if(OrderMagicNumber() == 103)
                                      {
                                          gSellLimitNum++;
                                          gPASellOpened = OrderOpenPrice();
                                      }
                                    else
                                      {
                                          gSellNum++;
                                      }
                                      
                                }
                              if(OrderType() == OP_BUYLIMIT)
                                 {
                                     gBuyLimitNum++; 
                                 }
                              if(OrderType() == OP_SELLLIMIT)
                                 {
                                    gSellLimitNum++;    
                                 }
                          }
                    }
               }

   }
//+------------------------------------------------------------------+ 
bool BullEscapeAction(double Price)
   {
         if(Price == 0)
           {
               return false;
           }
         double TenkenSen = iIchimoku(_Symbol,_Period,9,26,52,1,0);
         double KijunSen = iIchimoku(_Symbol,_Period,9,26,52,2,0);
         if((TenkenSen > Price) && (KijunSen > Price))
           {
               return true;
              
           }
         return false; 
    }    
//+------------------------------------------------------------------+         
bool BearEscapeAction(double Price)
   {
   
         if(Price == 0)
           {
               return false;
           }
         double TenkenSen = iIchimoku(_Symbol,_Period,9,26,52,1,0);
         double KijunSen = iIchimoku(_Symbol,_Period,9,26,52,2,0);
         if((TenkenSen < Price) && (KijunSen < Price))
           {
               
               return true;
              
           }
         return false; 
    }
//+------------------------------------------------------------------+ 

bool Shield_Zone(int Ticket, string Type, double OpenPrice)
   {
       double Price_Movement;
       if(Type == "BUY")
           {
               Price_Movement = Bid - OpenPrice; 
               if(Price_Movement >= Shield_Activation*_Point)  return true;
           }
       else if(Type == "SELL")
           {
               Price_Movement = OpenPrice - Ask; 
               if(Price_Movement >= Shield_Activation*_Point)  return true;
                   
           }
       return false;
        
   }
//+------------------------------------------------------------------+    
 
void RiskManager()
   {   
       
       for(int i=OrdersTotal()-1;i>=0;i--)
          {
               if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
                 { 
                    if(OrderSymbol() == Symbol())
                       {
                           if(OrderType() == OP_BUY)
                             {  
                                if(OrderProfit() <= -(AccountBalance()*RISK/100))
                                  {
                                       gClosedTicket = OrderClose(OrderTicket(),OrderLots(),Bid,100);
                                       datetime RightBarTime = iTime(_Symbol,_Period,0);
                                       string Message ="\n" + " >  RISK LIMITATION | Negative Position Closed";
                                       Comment(RightBarTime,Message);
                                  } 
                                
                                else if((BearEscapeAction(gDepthKomu) == True))
                                       {
                                           gClosedTicket = OrderClose(OrderTicket(),OrderLots(),Bid,100);
                                           datetime RightBarTime = iTime(_Symbol,_Period,0);
                                           string Message ="\n" + " >  PRICEACTION EXIT | Opposite Buy Position Closed";
                                           Comment(RightBarTime,Message,gDepthKomu);
                                       }  
                                if(Protection != 0)
                                  {
                                       if((OrderStopLoss() ==0) && (Shield_Zone(OrderTicket(),"BUY",OrderOpenPrice()) == True))
                                           {
                                                  gModifiedTicket = OrderModify(OrderTicket(), OrderOpenPrice(), OrderOpenPrice() + (Shield*_Point),0,0,0);
                                           } 
                                  }
                                                      
                                if(Bid - OrderOpenPrice() >= TrailingStep*_Point)
                                  {
                                     if((OrderStopLoss() ==0) || (OrderStopLoss() < Bid - (Trailing*_Point)))
                                       {
                                           gModifiedTicket = OrderModify(OrderTicket(),OrderOpenPrice(),Bid - (Trailing*_Point),0,0,0);
                                           
                                           
                                       }  
                                  }                                
                              }
                             
                           else if(OrderType() == OP_SELL)
                                  {
                                       if(OrderProfit() <= -(AccountBalance()*RISK/100))
                                         {
                                             gClosedTicket = OrderClose(OrderTicket(),OrderLots(),Ask,100);
                                             datetime RightBarTime = iTime(_Symbol,_Period,0);
                                             string Message1 ="\n" + " >  RISK LIMITATION | Negative Position Closed";
                                             Comment(RightBarTime,Message1);
                                         } 
                                       
                                       else if((BullEscapeAction(gPeakKomu) == True))
                                              {
                                                  gClosedTicket =OrderClose(OrderTicket(),OrderLots(),Ask,100); 
                                                  datetime RightBarTime = iTime(_Symbol,_Period,0);
                                                  string Message ="\n" + " >  PRICEACTION EXIT | Opposite Sell Position Closed";
                                                  Comment(RightBarTime,Message);
                                              } 
                                       if(Protection != 0)
                                         {
                                             if((OrderStopLoss() == 0) && (Shield_Zone(OrderTicket(),"SELL",OrderOpenPrice()) == True))
                                                 {
                                                        gModifiedTicket = OrderModify(OrderTicket(), OrderOpenPrice(), OrderOpenPrice() - (Shield*_Point),0,0,0);
                                                 }
                                         }
                                           
                                       if(OrderOpenPrice() - Ask >= TrailingStep*_Point)
                                         {
                                             if((OrderStopLoss() ==0) || (OrderStopLoss() > Ask + (Trailing*_Point)))
                                               {
                                                  
                                                    gModifiedTicket = OrderModify(OrderTicket(),OrderOpenPrice(), Ask + (Trailing*_Point),0,0,0); 
                                                    
                            
                                               }
                                       
                                         }
                                  } 
                       }                   
                         
                }
        }
    }

//+------------------------------------------------------------------+
void Smart_RiskManager()  
   {
      double LastClose = Close[1];
      double TenkenSen_Last = iIchimoku(_Symbol,_Period,9,26,52,1,1);
      double KijunSen_Last = iIchimoku(_Symbol,_Period,9,26,52,2,1);
      double EMALine = iMA(_Symbol,_Period,EMA,0,1,0,1);
      datetime TimeOut = iTime(_Symbol,_Period,0);
      
      double CriticalPrice = TenkenSen_Last;
      
      if(gOpened_Time != TimeOut)
         {
            int Sell=0;
            int Buy = 0;
            for(int i=OrdersTotal()-1;i>=0;i--)
               {   
                  if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
                       { 
                          if(OrderMagicNumber() == 103)
                            {
                                 continue;
                            }
                          if(OrderSymbol() == Symbol())
                             {
                                if((OrderType() == OP_SELL) && (Sell == 0))
                                   {
                                       if(ICHI(0) == "UP")
                                         {
                                             
                                             if(OrderOpenPrice() >= TenkenSen_Last)
                                               {
                                                     CriticalPrice = KijunSen_Last;
                                               }
                                             
                                               if((OrderOpenPrice() >= KijunSen_Last) && ( OrderOpenPrice() >= TenkenSen_Last))
                                                     {
                                                           CriticalPrice = EMALine;
                                                     }
                                                   
                                               if(LastClose > CriticalPrice)
                                                     {
                                                         gClosedTicket = OrderClose(OrderTicket(),OrderLots(),Ask,100);
                                                         gOpened_Time = TimeOut;
                                                     }
                                                 Sell++;
                                         }
                                       
                                   }
                                if((OrderType() == OP_BUY) && (Buy == 0))
                                  {
                                       if(ICHI(0) == "DOWN")
                                         {
                                            
                                             if(OrderOpenPrice() <= TenkenSen_Last)
                                               {
                                                    CriticalPrice = KijunSen_Last;
                                               }
                                             if((OrderOpenPrice() <= KijunSen_Last) && (OrderOpenPrice() <= TenkenSen_Last))
                                               {
                                                    CriticalPrice = EMALine;
                                               }
                                            
                                             if(LastClose < CriticalPrice)
                                               {
                                                   gClosedTicket = OrderClose(OrderTicket(),OrderLots(),Bid,100);
                                                   gOpened_Time = TimeOut;
                                               }
                                             Buy++;
                                         }
                                      
                                  }
                              }
                       }
                  }
                
           }
   }
//+------------------------------------------------------------------+ 
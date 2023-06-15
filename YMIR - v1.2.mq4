//+------------------------------------------------------------------+
//|                                                        frist.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

int gOpenTicket , gClosedTicket , gModifiedTicket ,gBullHammer, gBearHammer, gBullEng, gBearEng , gBuyNum, gSellNum;
double gBullLastOrder, gBearLastOrder, gLowestLow, gHighestHigh, gFirstENGHigh, gSecondENGHigh, gThirdENGHigh,
       gFirstENGLow, gSecondENGLow, gThirdENGLow;
datetime gBarTime , gOpened_Time;



input int SmartRisk = 1;
input int LossRecovery = 1;
input int Komu_OrderLimitation = 1;
input int Hammer = 1;
input int Engulf = 1;
input int ShootingStar =1;
input int InvertedHammer =1;
input int InvertedHammerToBear = 1;
input int PosNumber = 5;
input int Trailing = 20;
input int TrailingStep = 50;
input int RISK = 100;
input int FastEMA = 7;
input int SlowEMA = 59;
input int EngulfEMA = 21;
input double Lot = 0.1;
input double BodyRatio = 1.5;
input double ShadowRatio = 2;
input int MaxSize_Engulf = 100;
input int MinSize_BeforeENG = 10;
input int MinSize_Hammer = 30;
input int MaxSize_Hammer = 400;
input int Small_Shadow_Lenght = 30;






//+------------------------------------------------------------------+
int OnInit()
  {
      
      datetime RightBarTime = iTime(_Symbol,_Period,0);
      string Message = " >> Ymir START";
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
       datetime RightTime = iTime(_Symbol,_Period,0); 
       
      
       if(RightTime != gBarTime)
         
         {
        
           gBarTime = RightTime;
           
           Body_Detector();
           CandleStick_Order();
        }
 
 }
//+------------------------------------------------------------------+ 
void Body_Detector()
   {
      double BodySize = 0;
      double ClosePrice = Close[2];
      double OpenPrice = Open[2];
      if(ClosePrice > OpenPrice)  // Bull
        {
            BodySize = ClosePrice - OpenPrice;
        }
      if( ClosePrice < OpenPrice) // Bear
        {
            BodySize =  OpenPrice - ClosePrice;
        }
      if(ClosePrice == OpenPrice) // Doji
        {
            
             datetime RightTime = iTime(_Symbol,_Period,0);
             string Status = "\n" + "DOJI";
             Comment(RightTime,Status);    
        }
        
        
        
      if(((BodySize/_Point) >= MaxSize_Engulf) && (Engulf == 1))
        {
            if((Engulfing() == "BullEng") && (ICHI(2) == "Down") && (Bullish_Confirmation("Engulf") == True))
              {
                  gBullEng = 1;
                  gBearEng = 0;
                  gBearHammer = 0;
                  datetime RightBarTime = iTime(_Symbol,_Period,0);
                  string Message ="\n" + ">> STATUS: " + "SIGNAL | BUY Order - Bullish Engulfing Pattern." ;
                  Comment(RightBarTime,Message); 
              }
            if((Engulfing() == "BearEng") && (ICHI(2) == "Up") && (Bearish_Confirmation("Engulf") == True))
              {
                  
                  gBearEng = 1;
                  gBullEng =0;
                  gBullHammer =0;
                  datetime RightBarTime = iTime(_Symbol,_Period,0);
                  string Message ="\n" + ">> STATUS: " + "SIGNAL | SELL Order - Bearish Engulfing Pattern." ;
                  Comment(RightBarTime,Message);
              }
        } 
        
        
      if(((BodySize/_Point) <= MaxSize_Hammer) && ((BodySize/_Point) >= MinSize_Hammer))
        {
            
            if((Hammer_BEAR() == "ShootingStar" ) && (Trend() == "UP") && (Bearish_Confirmation("Hammer") == True) && (ShootingStar == 1))  // Shooting star always  to bear
              {
                 gBearHammer = 1;
                 gBullHammer =0;
                 gBullEng= 0;
                 datetime RightTime = iTime(_Symbol,_Period,0);
                 string Status = "\n" + ">> STATUS: " + "SIGNAL | SELL Order - ShootingStar Pattern";
                 Comment(RightTime,Status);
              }
            if((Hammer_BULL() ==  "Hammer") && (Trend() == "DOWN") && (Bullish_Confirmation("Hammer") == True) && (Hammer == 1))   //  Hammer Always to Bull
              {
                 gBullHammer = 1;
                 gBearHammer =0;
                 gBearEng =0;
                 datetime RightTime1 = iTime(_Symbol,_Period,0);
                 string Status1 = "\n"  + ">> STATUS: " + "SIGNAL | BUY Order - Hammer Pattern";
                 Comment(RightTime1,Status1);
              }
            if((Hammer_BULL() ==  "InvertedHammer") && (Trend() == "DOWN") && (Bullish_Confirmation("Hammer") == True) && (InvertedHammer == 1))  // Bullish Inverted Hammer
                   {
                       gBullHammer = 1;
                       gBearHammer = 0;
                       gBearEng = 0;
                       datetime RightTime = iTime(_Symbol,_Period,0);
                       string Status = "\n"  + ">> STATUS: " + "SIGNAL | BUY Order - InvertedHammer Pattern";
                       Comment(RightTime,Status);
                   }  
            if((Hammer_BULL() ==  "InvertedHammerToBear")  && (Bearish_Confirmation("Hammer") == True) && (InvertedHammerToBear == 1))  // Bulish Inverted Hammer To bear
                   {
                       gBullHammer = 0;
                       gBearHammer = 1;
                       gBearEng = 0;
                       datetime RightTime = iTime(_Symbol,_Period,0);
                       string Status = "\n"  + ">> STATUS: " + "SIGNAL | SELL Order - InvertedHammer Pattern";
                       Comment(RightTime,Status);
                   }        
        }
      
   }
//+------------------------------------------------------------------+
string Trend()
   {
      double Fast_EMA = iMA(_Symbol,_Period,FastEMA,0,1,0,2);
      double Slow_EMA = iMA(_Symbol,_Period,SlowEMA,0,1,0,2);
      if(Fast_EMA > Slow_EMA)
        {
            string trend = "UP";
            return trend;
        }
      if(Fast_EMA < Slow_EMA)
        {
            string trend = "DOWN";
            return trend;
        }
      if(Fast_EMA == Slow_EMA)
        {
            Fast_EMA = iMA(_Symbol,_Period,FastEMA,0,1,0,3);
            Slow_EMA = iMA(_Symbol,_Period,SlowEMA,0,1,0,3);
            if(Fast_EMA > Slow_EMA)
              {
                  string trend = "UP";
                  return trend;
              }
            if(Fast_EMA < Slow_EMA)
              {
                  string trend = "DOWN";
                  return trend;
              }
        }
      return NULL;
   }
//+------------------------------------------------------------------+
string ICHI(int Shift)
    {
      double Tenkensen_Current = iIchimoku(_Symbol,_Period,9,26,52,1,Shift);
      double Kijunsen_Current = iIchimoku(_Symbol,_Period,9,26,52,2,Shift);
      if(Tenkensen_Current > Kijunsen_Current)
         {
             string Uptrend = "Up";
             return Uptrend;
         }
      else if(Tenkensen_Current < Kijunsen_Current)
         {
               string Downtrend = "Down";
               return Downtrend;
         }
      else
         {
               string Sidetrend = "Side";
               return Sidetrend;
         }
      return NULL;
   }   
//+------------------------------------------------------------------+       
string Hammer_BEAR()
 {     
       
       double Last_High = High[2];
       double Last_Low = Low[2];
       double Last_Open = Open[2];
       double Last_Close = Close[2];
       
       double PrevOpen = Open[3];
       double PrevClose = Close[3];
       double PrevHigh = High[3];
       double PrevLow = Low[3];
       
       double UpShadowBullish = PrevHigh - PrevClose;
       double DownShadowBullish = PrevOpen - PrevLow;
       double UpShadowBearish = PrevHigh - PrevOpen;
       double DownShadowBearish = PrevClose - PrevLow;
       
       double PrevBodyBullish = PrevClose - PrevOpen;
       double PrevBodyBearish = PrevOpen - PrevClose;
       
     
       
       if(Last_Open > Last_Close)  // Bearish Candle
        {
            double Body = (Last_Open - Last_Close)/_Point;
            double Up_shadow = (Last_High - Last_Open)/_Point;
            double Down_shadow = (Last_Close - Last_Low)/_Point;
            
            if(Up_shadow == 0) Up_shadow = 1;
            if(Down_shadow == 0) Down_shadow =1;
            
            if((PrevClose > PrevOpen) && (PrevBodyBullish > UpShadowBullish)  && (PrevBodyBullish > DownShadowBullish))  // Bullish Candle trend
                  {
                  
                     
                     if(((Body*BodyRatio) <= Up_shadow) && ((Up_shadow/Down_shadow) >= ShadowRatio)) //  Shooting star
                        {
                           
                          
                            string Candle = "ShootingStar";
                            return Candle;
                                            
                        }
                   }
           else if((PrevClose < PrevOpen) && (PrevBodyBearish > UpShadowBearish)  && (PrevBodyBearish > DownShadowBearish))  //Bearish Candle Trend
                       {
                            
                            if(((Body*BodyRatio) <= Up_shadow) && ((Up_shadow/Down_shadow) >= ShadowRatio)) //  Shooting star to bear
                              {
                                 
                                
                                  string Candle = "ShootingStar";
                                  return Candle;
                                                  
                              }
                       }
         }
       return NULL;
          
          
  }
//+------------------------------------------------------------------+       
string Hammer_BULL()
   {
       double Last_High = High[2];
       double Last_Low = Low[2];
       double Last_Open = Open[2];
       double Last_Close = Close[2];
       
       double PrevOpen = Open[3];
       double PrevClose = Close[3];
       double PrevHigh = High[3];
       double PrevLow = Low[3];
       
       double UpShadowBullish = PrevHigh - PrevClose;
       double DownShadowBullish = PrevOpen - PrevLow;
       double UpShadowBearish = PrevHigh - PrevOpen;
       double DownShadowBearish = PrevClose - PrevLow;
       
       double PrevBodyBullish = PrevClose - PrevOpen;
       double PrevBodyBearish = PrevOpen - PrevClose;
       
       
       if(Last_Close > Last_Open )
            {
               double Body = (Last_Close - Last_Open)/_Point;
               double Up_shadow = (Last_High - Last_Close)/_Point; 
               double Down_shadow = (Last_Open - Last_Low)/_Point;
               
               if(Up_shadow == 0) Up_shadow = 1;
               if(Down_shadow == 0) Down_shadow =1;
               
               if((PrevClose > PrevOpen) && (PrevBodyBullish > UpShadowBullish)  && (PrevBodyBullish > DownShadowBullish))  // Bullish Candle trend
                  {
                     
                        if(((Body*BodyRatio) <= Up_shadow) && ((Up_shadow/Down_shadow) >= ShadowRatio) && (Down_shadow <= Small_Shadow_Lenght))  // inverted hammer to Bear
                           {
                              string Candle = "InvertedHammerToBear";
                              return Candle;
                           }
                        if(((Body*BodyRatio) <= Down_shadow) && ((Down_shadow/Up_shadow) >= ShadowRatio) && (Up_shadow <= Small_Shadow_Lenght))   // Hammer to Bull
                           {
                              string Candle = "Hammer";
                              return Candle;
                                    
                           }
                    
                  
                   }
               
               else if((PrevClose < PrevOpen) && (PrevBodyBearish > UpShadowBearish)  && (PrevBodyBearish > DownShadowBearish))  //Bearish Candle Trend
                       {
                                                   
                            if(((Body*BodyRatio) <= Down_shadow) && ((Down_shadow/Up_shadow) >= ShadowRatio) && (Up_shadow <= Small_Shadow_Lenght))  // Hammer to Bull
                                 {
                                       string Candle = "Hammer";
                                       return Candle;
                                          
                                 }
                               
                            if(((Body*BodyRatio) <= Up_shadow) && ((Up_shadow/Down_shadow) >= ShadowRatio) && (Down_shadow <= Small_Shadow_Lenght))   // inverted hammer to Bull
                                 {
                                    string Candle = "InvertedHammer";
                                    return Candle;
                                 }
                           
                        } 
              }
 
       return NULL;
   
  }
//+------------------------------------------------------------------+
string Engulfing()
   {
      double LastOpen = Open[2];
      double LastClose = Close[2];
      double LastHigh = High[2];
      double LastLow = Low[2];
      
      double PrevOpen = Open[3];
      double PrevClose = Close[3];
      double PrevHigh = High[3];
      double PrevLow = Low[3];
      
      double SmallShadow = 0;
      
           
      if(PrevClose < PrevOpen)                            // last bearish Candle
        {
           double PrevUpShadowBearish = PrevHigh - PrevOpen;
           double PrevDownShadowBearish = PrevClose - PrevLow;
           double PrevBodyBearish = PrevOpen - PrevClose;
           double SumShadowsBullish = (LastHigh - LastClose) + (LastOpen - LastLow);
           double LastBodyBullish = LastClose - LastOpen;
           if(PrevUpShadowBearish < PrevDownShadowBearish)
              {
                  SmallShadow = PrevUpShadowBearish;
              }
           else SmallShadow = PrevDownShadowBearish;
           
           
           if((PrevBodyBearish > SmallShadow) && (PrevOpen < LastClose) && (LastOpen <= (PrevClose + (10*_Point))) && (LastBodyBullish > SumShadowsBullish)
               && ((PrevBodyBearish/_Point) >= MinSize_BeforeENG) && (KomuZone(LastClose) == False) && (KomuZone(LastOpen) == False))
              {
                  string BullStatus = "BullEng";
                  return BullStatus;
              }
         }
      else if(PrevClose > PrevOpen)                       // last bullish Candle
        {
           double PrevUpShadowBullish = PrevHigh - PrevClose;
           double PrevDownShadowBullish = PrevOpen - PrevLow;
           double PrevBodyBullish = PrevClose - PrevOpen;
           double SumShadowsBearish = (LastHigh - LastOpen) + (LastClose - LastLow);
           double LastBodyBearish = LastOpen - LastClose;
           if(PrevUpShadowBullish < PrevDownShadowBullish)
              {
                  SmallShadow = PrevUpShadowBullish;
              }
           else SmallShadow = PrevDownShadowBullish;
           
           if((PrevBodyBullish > SmallShadow) && (PrevOpen > LastClose) && (LastOpen >= (PrevClose - (10*_Point))) && ( LastBodyBearish > SumShadowsBearish)
                && ((PrevBodyBullish/_Point) >= MinSize_BeforeENG)&& (KomuZone(LastClose) == False) && (KomuZone(LastOpen) == False))
              {
                  string BearStatus = "BearEng";
                  return BearStatus;
              }
           
        }
      return NULL;
        
     }
     
//+------------------------------------------------------------------+
bool ICHI_Validation(string Order)
   {
      double LastOpen = Open[0];
      double SenkouSpan_A = iIchimoku(_Symbol,_Period,9,26,52,3,0);
      
      if((Order == "Sell") && (ICHI(2) == "Up") && (LastOpen < SenkouSpan_A))
        {
            return false;
        }
      if((Order == "Buy") && (ICHI(2) == "Down") && (LastOpen > SenkouSpan_A))
        {
            return false;
        }
      else return true;
   }
//+------------------------------------------------------------------+
bool Bullish_Confirmation(string JP_Pattern)
   {
      double SmallShadow = 0;
      double LongShadow = 0;
      int KomuStruggle = 0;
      
      double Span_A = iIchimoku(_Symbol,_Period,9,26,52,3,0);
      double Span_B = iIchimoku(_Symbol,_Period,9,26,52,4,0);
      double Slow_EMA = iMA(_Symbol,_Period,EngulfEMA,0,1,0,0); 
      double Current_Open = Open[0];
      double Lower_Open = Open[2];
      
      double LastClose = Close[1];
      double LastOpen = Open[1];
      double LastHigh = High[1];
      double LastLow = Low[1];
      
      
      double PrevClose = Close[2];
      double PrevOpen = Open[2];
      
      double LastBody = LastClose - LastOpen;
      double UpShadowBullish = LastHigh - LastClose;
      double DownShadowBullish = LastOpen - LastLow;
      
      
      if(UpShadowBullish < DownShadowBullish) 
         {
            SmallShadow = UpShadowBullish;
            LongShadow = DownShadowBullish;
         }
      else 
         {
            SmallShadow = DownShadowBullish;
            LongShadow = UpShadowBullish;
          }
      
      
      if((Span_B < Span_A) && (Lower_Open < Span_B) && (Current_Open > Span_A)) KomuStruggle = 1;
      if((Span_B > Span_A) && (Lower_Open < Span_A) && (Current_Open > Span_B)) KomuStruggle = 1;
      
      if(JP_Pattern == "Engulf")
        {
            if((LastClose >= PrevClose) && (LastBody > SmallShadow)  && (KomuStruggle == 0) && (LastClose >= Slow_EMA))
              {
                  return true;
              }
            
            else
              {
                 datetime RightTime = iTime(_Symbol,_Period,0);
                 string Status = "\n" + ">> STATUS: " + "Non-Confirmed | Bullish Engulfing Pattern Dosen't Confirmed.";
                 Comment(RightTime,Status);
                 return false;
              }
        }
      if(JP_Pattern == "Hammer")
        {
            if((LastClose > LastOpen) && (LastClose >= PrevOpen) && (LastBody >=  SmallShadow) && (LastBody >= LongShadow) && (KomuStruggle == 0))
              {
                 return true;
              }
                  
            else
              {
                 datetime RightTime = iTime(_Symbol,_Period,0);
                 string Status = "\n" + ">> STATUS: " + "Non-Confirmed | Candlestick Pattern Dosen't Confirmed.";
                 Comment(RightTime,Status);
                 return false;
              }
         }
         
      else return false;
      
   }
//+------------------------------------------------------------------+
bool Bearish_Confirmation(string JP_Pattern)
   {
      double SmallShadow = 0;
      double LongShadow = 0;
      int KomuStruggle = 0;
      
      double Span_A = iIchimoku(_Symbol,_Period,9,26,52,3,0);
      double Span_B = iIchimoku(_Symbol,_Period,9,26,52,4,0);
      double Slow_EMA = iMA(_Symbol,_Period,EngulfEMA,0,1,0,0);
      double Upper_Open = Open[2];
      double Current_Open = Open[0];
      
      double LastClose = Close[1];
      double LastOpen = Open[1];
      double LastHigh = High[1];
      double LastLow = Low[1];
          
      double PrevClose = Close[2];
      double PrevOpen = Open[2];
      
      double LastBody = LastOpen - LastClose;
      double UpShadowBearish = LastHigh - LastOpen;
      double DownShadowBearish = LastClose - LastLow;
      
      
      if(UpShadowBearish < DownShadowBearish) 
        {
            SmallShadow = UpShadowBearish;
            LongShadow = DownShadowBearish;
        }
      else 
        {
            SmallShadow = DownShadowBearish;
            LongShadow = UpShadowBearish;
        }
      
      if((Span_B > Span_A) && (Upper_Open > Span_B) && (Current_Open < Span_A)) KomuStruggle = 1;
      if((Span_B < Span_A) && (Upper_Open > Span_A) && (Current_Open < Span_B)) KomuStruggle = 1;
    
      if(JP_Pattern == "Engulf")
        {
            if((LastClose <= PrevClose) && (LastBody > SmallShadow)  && (KomuStruggle == 0) && (LastClose <= Slow_EMA))
              {
                  return true;
              }
            else
              {
                 datetime RightTime = iTime(_Symbol,_Period,0);
                 string Status = "\n" + ">> STATUS: " + "Non-Confirmed | Bearish Engulfing Pattern Dosen't Confirmed.";
                 Comment(RightTime,Status);
                 return false;
              }
        }
      if(JP_Pattern == "Hammer")
        {
            if((LastClose < LastOpen) && (LastClose <= PrevOpen) && (LastBody >= SmallShadow) && (LastBody >= LongShadow)  && (KomuStruggle == 0))
              {
                  return true;
              }
            else
              {
                 datetime RightTime = iTime(_Symbol,_Period,0);
                 string Status = "\n" + ">> STATUS: " + "Non-Confirmed | Candlestick Pattern Dosen't Confirmed.";
                 Comment(RightTime,Status);
                 return false;
              }
        }
        
      else return false;
   } 
//+------------------------------------------------------------------+ 
void CandleStick_Order()  
   {
       double SignalHigh = High[2];
       double SignalLow = Low[2];
       double Spread = Ask - Bid;  // in digit
       double Current_Open = Open[0];
       bool KomuLimitation = False;
       string EngulfComment;
       
       if(Komu_OrderLimitation == 1)
           { 
               KomuLimitation = KomuZone(Current_Open);
           } 
       if(KomuLimitation == False)
         {
              if(gBullEng == 1)   // Engulfing MagicNumber = 101
                 {
                     EngulfComment = Engulf_Comment("BUY");
                         
                     for(int i=0;i<PosNumber;i++)
                         {
                              gOpenTicket = OrderSend(_Symbol,OP_BUY,Lot,Ask,100,0,0,EngulfComment,101);
                         }
                     gOpened_Time = iTime(_Symbol,_Period,0);
                     gBullEng = 0;
                  }
     
              if(gBearEng == 1)
                {
                     EngulfComment = Engulf_Comment("SELL");
                     for(int i=0;i<PosNumber;i++)
                         {
                               gOpenTicket =OrderSend(_Symbol,OP_SELL,Lot,Bid,100,0,0,EngulfComment,101);
                         }
                     gOpened_Time = iTime(_Symbol,_Period,0);
                     gBearEng = 0;
                              
                }
                
                
                
                
                
              if(gBullHammer == 1)  // Hammer MagicNumber = 102
                {
                       
                     for(int i=0;i<PosNumber;i++)
                         {
                               gOpenTicket = OrderSend(_Symbol,OP_BUY,Lot,Ask,100,0,0,NULL,102);
                         }
                     gBullLastOrder = Ask;
                     gLowestLow = SignalLow - Spread;
                     gOpened_Time = iTime(_Symbol,_Period,0);
                     gBullHammer = 0;
                      }
     
              if(gBearHammer == 1)
                {
                     for(int i=0;i<PosNumber;i++)
                         {
                               gOpenTicket =OrderSend(_Symbol,OP_SELL,Lot,Bid,100,0,0,NULL,102);
                         }
                     gBearLastOrder = Bid;
                     gHighestHigh = SignalHigh + Spread;
                     gOpened_Time = iTime(_Symbol,_Period,0);
                     gBearHammer = 0;
                }
        
       
         }
       else
              {
                    gBullEng =0;
                    gBearEng =0;
                    gBullHammer =0;
                    gBearHammer =0;
                    datetime RightTime = iTime(_Symbol,_Period,0);
                    string Status = "\n" + ">> STATUS: " + "KomuZone Limitation | Opening Order Is Not Allowed, Looking For Another JP Patterns...";
                    Comment(RightTime,Status);
              }  
               
                 
   }
//+------------------------------------------------------------------+
string Engulf_Comment(string Order_Type)
   {
      int Engulf_BuyNumber = 0;
      int Engulf_SellNumber = 0;
      double SignalHigh = High[2];
      double SignalLow = Low[2];
      double Spread = Ask - Bid;  // in digit
      
      for(int i=OrdersTotal()-1;i>=0;i--)
           {
               if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
                 { 
                    if(OrderSymbol() == Symbol())
                       {
                           if((OrderType() == OP_BUY ) && (OrderMagicNumber() == 101))
                             {
                                 Engulf_BuyNumber++;
                             }
                           if((OrderType() == OP_SELL) && (OrderMagicNumber() == 101))
                             {
                                 Engulf_SellNumber++;
                             }
                       }
                 }
            }
       if(Order_Type == "BUY")
         {
               if(Engulf_BuyNumber == 0)
                 {
                     string Status = "First";
                     gFirstENGLow = SignalLow - Spread;
                     return Status;
                 }
               if(Engulf_BuyNumber <= PosNumber)
                 {
                     string Status = "Second";
                     gSecondENGLow = SignalLow - Spread;
                     return Status;
                     
                 }
               else if((Engulf_BuyNumber >= PosNumber) || (Engulf_BuyNumber <= (PosNumber*2)))
                  {
                     string Status = "Third";
                     gThirdENGLow = SignalLow - Spread;
                     return Status;
                  }
         }
       else if(Order_Type == "SELL")
              {
                  if(Engulf_SellNumber == 0)
                    {
                        string Status = "First";
                        gFirstENGHigh = SignalHigh + Spread;
                        return Status;
                    }
                  if(Engulf_SellNumber <= PosNumber)
                    {
                        string Status = "Second";
                        gSecondENGHigh = SignalHigh + Spread;
                        return Status;
                        
                    }
                  else if((Engulf_SellNumber >= PosNumber) || (Engulf_SellNumber <= (PosNumber*2)))
                    {
                        string Status = "Third";
                        gThirdENGHigh = SignalHigh + Spread;
                        return Status;
                        
                    } 
                   
               }
         
       return NULL;
   }
 //+------------------------------------------------------------------+  
bool KomuZone(double Price)
   {
      
      double SenkouSpan_B = iIchimoku(_Symbol,_Period,9,26,52,4,0);
      double SenkouSpan_A = iIchimoku(_Symbol,_Period,9,26,52,3,0);
      if((Price > SenkouSpan_A) && (Price < SenkouSpan_B))
        {
             return true;
        }
      if((Price < SenkouSpan_A) && (Price > SenkouSpan_B))
        {
             return true;
        }
      else return false;
      
   }
//+------------------------------------------------------------------+
void Get_Info_of_Positions()
 {
            gBuyNum = 0;
            gSellNum = 0;
            for(int i=OrdersTotal()-1;i>=0;i--)
              {
                  if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
                    {
                        if(OrderSymbol() == Symbol())
                          {
                              if(OrderType() == OP_BUY)
                                {
                                    
                                   gBuyNum++;
                                    
                                }
                              if(OrderType() == OP_SELL)
                                {
                                   
                                   gSellNum++;
                                 
                                }
                             
                              
                          }
                    }
               }

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
                                       string Message ="\n" + ">> STATUS: " + " RISK LIMITATION | Negative Position Closed";
                                       Comment(RightBarTime,Message);
                                  } 
                                                        
                                if(Ask - OrderOpenPrice() >= TrailingStep*_Point)
                                  {
                                     if(OrderStopLoss() == 0 || (OrderStopLoss() < Bid - (Trailing*_Point)))
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
                                             string Message1 ="\n" + ">> STATUS: " +" RISK LIMITATION | Negative Position Closed";
                                             Comment(RightBarTime,Message1);
                                         } 
                                       
                                       if(OrderOpenPrice() - Bid >= TrailingStep*_Point)
                                         {
                                             if(OrderStopLoss() == 0 || (OrderStopLoss() > Ask + (Trailing*_Point)))
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
void Recovery(string Order)
   {
      if(Order == "SELL")
           {
               for(int i=0;i<PosNumber;i++)
                    {
                              gOpenTicket = OrderSend(_Symbol,OP_BUY,Lot,Ask,100,0,0,NULL,400);   // 400 is MagicNumber of Recavery Order
                    }
           }
      else if(Order == "BUY")
           {
               for(int i=0;i<PosNumber;i++)
                     {
                             gOpenTicket =OrderSend(_Symbol,OP_SELL,Lot,Bid,100,0,0,NULL,400);
                     }
           }
   }
//+------------------------------------------------------------------+
void Smart_RiskManager()  
   {
      double LastClose = Close[1];
      double TenkenSen_Last = iIchimoku(_Symbol,_Period,9,26,52,1,1);
      double KijunSen_Last = iIchimoku(_Symbol,_Period,9,26,52,2,1);
      double EMALine = iMA(_Symbol,_Period,SlowEMA,0,1,0,1);
      datetime TimeOut = iTime(_Symbol,_Period,0);
      
      double CriticalPrice = 0;
      
      if(gOpened_Time != TimeOut)
         {
            int Sell=0;
            int Buy = 0;
            for(int i=OrdersTotal()-1;i>=0;i--)
               {   
                  if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
                       { 
                          
                          if(OrderSymbol() == Symbol())
                             {
                                if((OrderType() == OP_SELL) && (Sell == 0))
                                   {
                                       
                                       if(OrderMagicNumber() == 101)  // Engulfing Order
                                         {
                                             if(OrderComment() == "First")  CriticalPrice = gFirstENGHigh; 
                                             if(OrderComment() == "Second") CriticalPrice = gSecondENGHigh;
                                             if(OrderComment() == "Third")  CriticalPrice = gThirdENGHigh;
                                            
                                             if(LastClose > CriticalPrice)
                                               {
                                                   gClosedTicket = OrderClose(OrderTicket(),OrderLots(),Ask,100);
                                                   
                                                   if(LossRecovery == 1 ) Recovery("SELL");
                                                   gOpened_Time = TimeOut;
                                               }
                                             Sell++;
                                         }
                                       if(OrderMagicNumber() == 400)  // Recover
                                         {
                                             CriticalPrice = KijunSen_Last;
                                             if(LastClose > CriticalPrice)
                                               {
                                                   gClosedTicket = OrderClose(OrderTicket(),OrderLots(),Ask,100);
                                                   gOpened_Time = TimeOut;
                                               }
                                             Sell++;
                                         }
                                         
                                       if(OrderMagicNumber() == 102)  // Hammer
                                         {
                                            
                                              CriticalPrice = gHighestHigh;
                                              if(LastClose > CriticalPrice)
                                                 {
                                                   gClosedTicket = OrderClose(OrderTicket(),OrderLots(),Ask,100);
                                                   if(LossRecovery == 1) Recovery("SELL");
                                                   gOpened_Time = TimeOut;
                                                 }
                                              Sell++;
                                            
                                         }
                                       
                                       
                                   }
                                if((OrderType() == OP_BUY) && (Buy == 0))
                                  {
                                       if(OrderMagicNumber() == 101)  // Engulfing Order
                                         {
                                             if(OrderComment() == "First") CriticalPrice = gFirstENGLow;
                                             if(OrderComment() == "Second")CriticalPrice = gSecondENGLow;
                                             if(OrderComment() == "Third") CriticalPrice = gThirdENGLow;
                                             
                                             if(LastClose < CriticalPrice)
                                               {
                                                   gClosedTicket = OrderClose(OrderTicket(),OrderLots(),Bid,100);
                                                   
                                                   if(LossRecovery == 1) Recovery("BUY");
                                                   gOpened_Time = TimeOut;
                                                   
                                               }
                                             Buy++;
                                         }
                                       if(OrderMagicNumber() == 400)
                                         {
                                             CriticalPrice = KijunSen_Last;
                                             if(LastClose < CriticalPrice)
                                               {
                                                   gClosedTicket = OrderClose(OrderTicket(),OrderLots(),Bid,100);
                                                   gOpened_Time = TimeOut;
                                               }
                                             Buy++;
                                         }
                                       if(OrderMagicNumber() == 102)
                                         {
                                            
                                             CriticalPrice = gLowestLow;
                                             if(LastClose < CriticalPrice)
                                              {
                                                   gClosedTicket = OrderClose(OrderTicket(),OrderLots(),Bid,100);
                                                   if(LossRecovery == 1) Recovery("BUY");
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
    
                          
                                        
                                        
                                       
 
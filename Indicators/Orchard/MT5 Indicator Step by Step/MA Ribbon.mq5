/***********
   MA Ribbon.mq5
   Copyright 2012-2020, Novateq Pty Ltd
   https://www.orchardforex.com

   Version History
   ===============
   1.00		Original version

***********/

/**=
 *
 * Disclaimer and Licence
 *
 * This file is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * All trading involves risk. You should have received the risk warnings
 * and terms of use in the README.MD file distributed with this software.
 * See the README.MD file for more information and before using this software.
 *
 **/
#property copyright "Copyright 2020, Novateq Pty Ltd"
#property link "https://www.orchardforex.com"
#property version "1.00"
#property indicator_chart_window

#property indicator_buffers 5 //	How many data buffers are we using
#property indicator_plots 3   //	How many indicators are being drawn on screen

#property indicator_type1 DRAW_FILLING //	This type draws a filled channel between the 2 buffers
#property indicator_label1 "Channel FastMA;Channel SlowMA"
//	Semi colon lets us put labels on both values
#property indicator_color1 clrYellow, clrFireBrick //	Colors when fast>slow or slow>fast

#property indicator_type2  DRAW_LINE   //	This type draws a simple line
#property indicator_label2 "SlowMA"    //	label to show in the data window
#property indicator_color2 clrGray     //	Line colour
#property indicator_style2 STYLE_SOLID //	Solid, dotted etc
#property indicator_width2 4           //	4 because it's easier to see in the demo

#property indicator_type3 DRAW_LINE    //	This type draws a simple line
#property indicator_label3 "FastMA"    //	label to show in the data window
#property indicator_color3 clrBlue     //	Line colour
#property indicator_style3 STYLE_SOLID //	Solid, dotted etc
#property indicator_width3 4           //	4 because it's easier to see in the demo

//--- input parameters
input int            InpSlowMAPeriod   = 34;       // Slow period
input ENUM_MA_METHOD InpSlowMAMode     = MODE_EMA; // Slow MA Mode

input int            InpFastMAPeriod   = 13;       // Fast period
input ENUM_MA_METHOD InpFastMAMode     = MODE_EMA; // Fast MA Mode

input int            InpSignalMAPeriod = 5;        // Signal period
input ENUM_MA_METHOD InpSignalMAMode   = MODE_EMA; // MA Mode

double               BufferFastChannel[];
double               BufferSlowChannel[];
double               BufferFast[];
double               BufferSlow[];
double               BufferSignal[];

int                  MaxPeriod;

int                  FastHandle;
int                  SlowHandle;
int                  SignalHandle;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int                  OnInit() {
   //--- indicator buffers mapping
   SetIndexBuffer( 0, BufferFastChannel, INDICATOR_DATA );
   SetIndexBuffer( 1, BufferSlowChannel, INDICATOR_DATA );
   SetIndexBuffer( 2, BufferSlow, INDICATOR_DATA );
   SetIndexBuffer( 3, BufferFast, INDICATOR_DATA );
   SetIndexBuffer( 4, BufferSignal, INDICATOR_DATA );

   MaxPeriod = ( int )MathMax( MathMax( InpSignalMAPeriod, InpFastMAPeriod ), InpSlowMAPeriod );

   SlowHandle = iMA( Symbol(), Period(), InpSlowMAPeriod, 0, InpSlowMAMode, PRICE_CLOSE );
   FastHandle = iMA( Symbol(), Period(), InpFastMAPeriod, 0, InpFastMAMode, PRICE_CLOSE );
   SignalHandle = iMA( Symbol(), Period(), InpSignalMAPeriod, 0, InpSignalMAMode, PRICE_CLOSE );

   PlotIndexSetInteger( 0, PLOT_DRAW_BEGIN, MaxPeriod );
   PlotIndexSetInteger( 1, PLOT_DRAW_BEGIN, MaxPeriod );
   PlotIndexSetInteger( 2, PLOT_DRAW_BEGIN, MaxPeriod );

   //---
   return ( INIT_SUCCEEDED );
}

void OnDeinit( const int reason ) {

   if ( SlowHandle != INVALID_HANDLE ) IndicatorRelease( SlowHandle );
   if ( FastHandle != INVALID_HANDLE ) IndicatorRelease( FastHandle );
   if ( SignalHandle != INVALID_HANDLE ) IndicatorRelease( SignalHandle );
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate( const int rates_total, const int prev_calculated, const datetime &time[],
                 const double &open[], const double &high[], const double &low[],
                 const double &close[], const long &tick_volume[], const long &volume[],
                 const int &spread[] ) {
   //---
   if ( IsStopped() ) return ( 0 ); //	Must respect the stop flag

   if ( rates_total < MaxPeriod )
      return ( 0 ); //	Check that we have enough bars available to calculate

   //	Check that the moving averages have all been calculated
   if ( BarsCalculated( SlowHandle ) < rates_total ) return ( 0 );
   if ( BarsCalculated( FastHandle ) < rates_total ) return ( 0 );
   if ( BarsCalculated( SignalHandle ) < rates_total ) return ( 0 );

   int copyBars = 0;
   int startBar = 0;
   if ( prev_calculated > rates_total || prev_calculated <= 0 ) {
      copyBars = rates_total;
      startBar = MaxPeriod;
   }
   else {
      copyBars = rates_total - prev_calculated;
      if ( prev_calculated > 0 ) copyBars++;
      startBar = prev_calculated - 1;
   }

   if ( IsStopped() ) return ( 0 ); //	Must respect the stop flag
   if ( CopyBuffer( FastHandle, 0, 0, copyBars, BufferFastChannel ) <= 0 ) return ( 0 );
   if ( CopyBuffer( SlowHandle, 0, 0, copyBars, BufferSlowChannel ) <= 0 ) return ( 0 );
   if ( CopyBuffer( SlowHandle, 0, 0, copyBars, BufferSlow ) <= 0 ) return ( 0 );
   if ( CopyBuffer( FastHandle, 0, 0, copyBars, BufferFast ) <= 0 ) return ( 0 );
   if ( CopyBuffer( SignalHandle, 0, 0, copyBars, BufferSignal ) <= 0 ) return ( 0 );

   if ( IsStopped() ) return ( 0 ); //	Must respect the stop flag
   for ( int i = startBar; i < rates_total && !IsStopped(); i++ ) {
      if ( ( BufferFast[i] >= BufferSlow[i] && BufferSignal[i] < BufferFast[i] ) ||
           ( BufferFast[i] < BufferSlow[i] && BufferSignal[i] > BufferFast[i] ) ) {
         BufferFast[i]        = EMPTY_VALUE;
         BufferSlow[i]        = EMPTY_VALUE;
         BufferFastChannel[i] = EMPTY_VALUE;
         BufferSlowChannel[i] = EMPTY_VALUE;
      }
   }

   //--- return value of prev_calculated for next call
   return ( rates_total );
}
//+------------------------------------------------------------------+

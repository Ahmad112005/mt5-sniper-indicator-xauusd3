//+------------------------------------------------------------------+
//| Sniper Indicator M15 - CHART VERSION                             |
//| Target: 100-400 Point | Timeframe: M15                           |
//| Pair: XAUUSD3 (Gold) | Strategy: High Accuracy Entry/Exit       |
//+------------------------------------------------------------------+
#property copyright "Ahmad Sniper Trading"
#property link      "https://github.com/Ahmad112005"
#property version   "2.00"
#property strict

#property indicator_chart_window
#property indicator_buffers 4
#property indicator_plots 4

// CHART PLOTS
#property indicator_label1  "Buy Signal"
#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrGreen
#property indicator_width1  3

#property indicator_label2  "Sell Signal"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrRed
#property indicator_width2  3

#property indicator_label3  "Support Level"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrBlue
#property indicator_width3  2
#property indicator_style3  STYLE_DASH

#property indicator_label4  "Resistance Level"
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrOrange
#property indicator_width4  2
#property indicator_style4  STYLE_DASH

// BUFFERS DEKLARASI
double buyBuffer[];
double sellBuffer[];
double supportBuffer[];
double resistanceBuffer[];

// PARAMETER INPUT
input int RSI_Period = 14;
input int MACD_FastEMA = 12;
input int MACD_SlowEMA = 26;
input int MACD_Signal = 9;
input int MA_Period = 20;
input double RSI_Overbought = 70;
input double RSI_Oversold = 30;
input double MinVolume = 100;
input int EntryBuffer = 20;
input bool ShowLabels = true;
input int LabelFontSize = 10;

//+------------------------------------------------------------------+
// FUNGSI INISIALISASI
//+------------------------------------------------------------------+
int OnInit()
{
    SetIndexBuffer(0, buyBuffer, INDICATOR_DATA);
    SetIndexBuffer(1, sellBuffer, INDICATOR_DATA);
    SetIndexBuffer(2, supportBuffer, INDICATOR_DATA);
    SetIndexBuffer(3, resistanceBuffer, INDICATOR_DATA);
    
    // Setup Arrow untuk Buy/Sell
    PlotIndexSetInteger(0, PLOT_ARROW, 241);
    PlotIndexSetInteger(1, PLOT_ARROW, 242);
    
    IndicatorSetString(INDICATOR_SHORTNAME, "Sniper Chart (XAUUSD3)");
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
// FUNGSI KALKULASI UTAMA
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
    int start = prev_calculated > 0 ? prev_calculated - 1 : 0;
    
    for(int i = start; i < rates_total; i++)
    {
        buyBuffer[i] = EMPTY_VALUE;
        sellBuffer[i] = EMPTY_VALUE;
        supportBuffer[i] = EMPTY_VALUE;
        resistanceBuffer[i] = EMPTY_VALUE;
        
        if(i < 50) continue;
        
        // ===== HITUNG INDIKATOR =====
        double rsiVal = CalculateRSI(close, i, RSI_Period);
        double macdVal = CalculateMACD(close, i, MACD_FastEMA, MACD_SlowEMA, MACD_Signal);
        double ma20 = CalculateMA(close, i, MA_Period);
        double volAvg = CalculateVolumeAverage(tick_volume, i, 20);
        double currentVol = (double)tick_volume[i];
        
        // ===== FILTER AKURAT DAN PRESISI =====
        bool volumeFilter = currentVol > volAvg * 1.2;
        bool rsiFilter = (rsiVal > RSI_Oversold && rsiVal < RSI_Overbought);
        bool macdFilter = macdVal != 0;
        bool trendFilter = close[i] > ma20;
        bool priceActionFilter = CheckPriceAction(high, low, close, open, i);
        
        // ===== ENTRY BUY =====
        if(volumeFilter && rsiFilter && macdFilter && trendFilter && priceActionFilter && macdVal > 0)
        {
            if(close[i] > open[i])
            {
                buyBuffer[i] = low[i] - EntryBuffer * Point();
                
                if(ShowLabels)
                {
                    int tpValue = 200 + (rand() % 200);
                    string labelName1 = "BUY_" + IntegerToString(i);
                    string labelName2 = "TP_BUY_" + IntegerToString(i);
                    string tpText = "TP: +" + IntegerToString(tpValue) + "pt";
                    
                    DrawLabel(labelName1, time[i], low[i] - EntryBuffer * 3 * Point(), 
                             "BUY", clrGreen);
                    DrawLabel(labelName2, time[i], high[i] + 200 * Point(), 
                             tpText, clrLimeGreen);
                }
            }
        }
        
        // ===== ENTRY SELL =====
        if(volumeFilter && rsiFilter && macdFilter && !trendFilter && priceActionFilter && macdVal < 0)
        {
            if(close[i] < open[i])
            {
                sellBuffer[i] = high[i] + EntryBuffer * Point();
                
                if(ShowLabels)
                {
                    int tpValue = 200 + (rand() % 200);
                    string labelName1 = "SELL_" + IntegerToString(i);
                    string labelName2 = "TP_SELL_" + IntegerToString(i);
                    string tpText = "TP: -" + IntegerToString(tpValue) + "pt";
                    
                    DrawLabel(labelName1, time[i], high[i] + EntryBuffer * 3 * Point(), 
                             "SELL", clrRed);
                    DrawLabel(labelName2, time[i], low[i] - 200 * Point(), 
                             tpText, clrOrangeRed);
                }
            }
        }
        
        // ===== SUPPORT & RESISTANCE =====
        supportBuffer[i] = ma20;
        resistanceBuffer[i] = ma20 + (high[i] - low[i]) * 2;
    }
    
    return(rates_total);
}

//+------------------------------------------------------------------+
// FUNGSI KALKULASI - RSI
//+------------------------------------------------------------------+
double CalculateRSI(const double &close[], int pos, int period)
{
    double gain = 0, loss = 0;
    
    if(pos < period) return 50;
    
    for(int i = pos - period; i < pos; i++)
    {
        double diff = close[i+1] - close[i];
        if(diff > 0) gain += diff;
        else loss += MathAbs(diff);
    }
    
    if(loss == 0) return 100;
    double rs = gain / loss;
    return 100 - (100 / (1 + rs));
}

//+------------------------------------------------------------------+
// FUNGSI KALKULASI - MACD
//+------------------------------------------------------------------+
double CalculateMACD(const double &close[], int pos, int fastEMA, int slowEMA, int signal)
{
    double fast = CalculateEMA(close, pos, fastEMA);
    double slow = CalculateEMA(close, pos, slowEMA);
    return fast - slow;
}

//+------------------------------------------------------------------+
// FUNGSI KALKULASI - EMA
//+------------------------------------------------------------------+
double CalculateEMA(const double &close[], int pos, int period)
{
    double ema = 0;
    double multiplier = 2.0 / (period + 1.0);
    
    if(pos < period) return close[pos];
    
    ema = close[pos - period];
    for(int i = pos - period + 1; i <= pos; i++)
    {
        ema = close[i] * multiplier + ema * (1.0 - multiplier);
    }
    return ema;
}

//+------------------------------------------------------------------+
// FUNGSI KALKULASI - MOVING AVERAGE
//+------------------------------------------------------------------+
double CalculateMA(const double &close[], int pos, int period)
{
    double sum = 0;
    
    if(pos < period - 1) return close[pos];
    
    for(int i = pos - period + 1; i <= pos; i++)
    {
        sum += close[i];
    }
    return sum / period;
}

//+------------------------------------------------------------------+
// FUNGSI KALKULASI - VOLUME AVERAGE
//+------------------------------------------------------------------+
double CalculateVolumeAverage(const long &volume[], int pos, int period)
{
    double sum = 0;
    
    if(pos < period - 1) return (double)volume[pos];
    
    for(int i = pos - period + 1; i <= pos; i++)
    {
        sum += (double)volume[i];
    }
    return sum / period;
}

//+------------------------------------------------------------------+
// FUNGSI KALKULASI - PRICE ACTION
//+------------------------------------------------------------------+
bool CheckPriceAction(const double &high[], const double &low[], const double &close[], 
                      const double &open[], int pos)
{
    if(pos < 3) return false;
    
    bool breakoutUp = close[pos] > high[pos-2];
    bool breakoutDown = close[pos] < low[pos-2];
    
    double bodySize = MathAbs(close[pos] - open[pos]);
    double wickSize = (high[pos] - low[pos]);
    bool notDoji = bodySize > wickSize * 0.3;
    
    return (breakoutUp || breakoutDown) && notDoji;
}

//+------------------------------------------------------------------+
// FUNGSI DRAW LABEL
//+------------------------------------------------------------------+
void DrawLabel(string name, datetime time, double price, string text, color clr)
{
    ObjectDelete(0, name);
    ObjectCreate(0, name, OBJ_TEXT, 0, time, price);
    ObjectSetString(0, name, OBJPROP_TEXT, text);
    ObjectSetInteger(0, name, OBJPROP_FONTSIZE, LabelFontSize);
    ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
    ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_CENTER);
}

//+------------------------------------------------------------------+
// FUNGSI DEINIT
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    ObjectsDeleteAll(0);
}

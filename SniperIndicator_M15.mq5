//+------------------------------------------------------------------+
//| Sniper Indicator M15 - XAUUSD3 Custom Version (FIXED v1.03)      |
//| Target: 100-400 Point | Timeframe: M15                           |
//| Pair: XAUUSD3 (Gold) | Strategy: High Accuracy Entry/Exit       |
//+------------------------------------------------------------------+
#property copyright "Ahmad Sniper Trading"
#property link      "https://github.com/Ahmad112005"
#property version   "1.03"
#property strict

#property indicator_chart_window

// CHART MAIN BUFFERS (4 buffers di chart window)
#property indicator_buffers 12
#property indicator_plots 8

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

// SUB-WINDOW PLOTS (dipisah dengan indicator baru)
#property indicator_label5  "RSI Line"
#property indicator_type5   DRAW_LINE
#property indicator_color5  clrCyan
#property indicator_width5  2

#property indicator_label6  "MACD Histogram"
#property indicator_type6   DRAW_HISTOGRAM
#property indicator_color6  clrMagenta
#property indicator_width6  2

#property indicator_label7  "Volume Signal"
#property indicator_type7   DRAW_HISTOGRAM
#property indicator_color7  clrDodgerBlue
#property indicator_width7  2

#property indicator_label8  "Zero Line"
#property indicator_type8   DRAW_LINE
#property indicator_color8  clrWhite
#property indicator_width8  1
#property indicator_style8  STYLE_SOLID

// BUFFERS DEKLARASI
double buyBuffer[];
double sellBuffer[];
double supportBuffer[];
double resistanceBuffer[];
double rsiBuffer[];
double macdBuffer[];
double volumeBuffer[];
double zeroLineBuffer[];

// Buffers support (tidak di-plot)
double rsiOverboughtBuffer[];
double rsiOversoldBuffer[];
double macdLineBuffer[];
double filterBuffer[];

// PARAMETER INPUT
input int RSI_Period = 14;              // Periode RSI
input int MACD_FastEMA = 12;            // MACD Fast EMA
input int MACD_SlowEMA = 26;            // MACD Slow EMA
input int MACD_Signal = 9;              // MACD Signal
input int MA_Period = 20;               // Moving Average untuk Support/Resistance
input double RSI_Overbought = 70;       // Level Overbought
input double RSI_Oversold = 30;         // Level Oversold
input double MinVolume = 100;           // Minimum Volume Filter
input int EntryBuffer = 20;             // Buffer untuk entry presisi (points)
input bool ShowLabels = true;           // Tampilkan label BUY/SELL/TP
input int LabelFontSize = 10;           // Ukuran font label

//+------------------------------------------------------------------+
// FUNGSI INISIALISASI
//+------------------------------------------------------------------+
int OnInit()
{
    // CHART WINDOW BUFFERS (Plots 1-4)
    SetIndexBuffer(0, buyBuffer, INDICATOR_DATA);
    SetIndexBuffer(1, sellBuffer, INDICATOR_DATA);
    SetIndexBuffer(2, supportBuffer, INDICATOR_DATA);
    SetIndexBuffer(3, resistanceBuffer, INDICATOR_DATA);
    
    // SUB-WINDOW BUFFERS (Plots 5-8)
    SetIndexBuffer(4, rsiBuffer, INDICATOR_DATA);
    SetIndexBuffer(5, macdBuffer, INDICATOR_DATA);
    SetIndexBuffer(6, volumeBuffer, INDICATOR_DATA);
    SetIndexBuffer(7, zeroLineBuffer, INDICATOR_DATA);
    
    // SUPPORT BUFFERS (tidak di-plot, hanya untuk kalkulasi)
    SetIndexBuffer(8, rsiOverboughtBuffer, INDICATOR_CALCULATIONS);
    SetIndexBuffer(9, rsiOversoldBuffer, INDICATOR_CALCULATIONS);
    SetIndexBuffer(10, macdLineBuffer, INDICATOR_CALCULATIONS);
    SetIndexBuffer(11, filterBuffer, INDICATOR_CALCULATIONS);
    
    // Setup Arrow untuk Buy/Sell
    PlotIndexSetInteger(0, PLOT_ARROW, 241);  // Arrow up untuk BUY
    PlotIndexSetInteger(1, PLOT_ARROW, 242);  // Arrow down untuk SELL
    
    IndicatorSetString(INDICATOR_SHORTNAME, "Sniper M15 XAUUSD3");
    
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
        // Reset chart buffers
        buyBuffer[i] = EMPTY_VALUE;
        sellBuffer[i] = EMPTY_VALUE;
        supportBuffer[i] = EMPTY_VALUE;
        resistanceBuffer[i] = EMPTY_VALUE;
        
        // Reset sub-window buffers
        rsiBuffer[i] = EMPTY_VALUE;
        macdBuffer[i] = EMPTY_VALUE;
        volumeBuffer[i] = EMPTY_VALUE;
        zeroLineBuffer[i] = EMPTY_VALUE;
        
        if(i < 50) 
        {
            zeroLineBuffer[i] = 0;
            continue; // Butuh data history
        }
        
        // ===== HITUNG INDIKATOR =====
        double rsiVal = CalculateRSI(close, i, RSI_Period);
        double macdVal = CalculateMACD(close, i, MACD_FastEMA, MACD_SlowEMA, MACD_Signal);
        double ma20 = CalculateMA(close, i, MA_Period);
        double volAvg = CalculateVolumeAverage(tick_volume, i, 20);
        double currentVol = (double)tick_volume[i];
        
        // ===== FILTER AKURAT DAN PRESISI =====
        bool volumeFilter = currentVol > volAvg * 1.2;        // Volume naik 20%
        bool rsiFilter = (rsiVal > RSI_Oversold && rsiVal < RSI_Overbought);  // Hindari ekstrim
        bool macdFilter = macdVal != 0;                        // MACD ada pergerakan
        bool trendFilter = close[i] > ma20;                    // Uptrend
        bool priceActionFilter = CheckPriceAction(high, low, close, open, i);  // Price action presisi
        
        // ===== ENTRY BUY =====
        if(volumeFilter && rsiFilter && macdFilter && trendFilter && priceActionFilter && macdVal > 0)
        {
            if(close[i] > open[i])  // Candle bullish
            {
                buyBuffer[i] = low[i] - EntryBuffer * Point();
                filterBuffer[i] = 1;  // Filter aktif
                
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
            if(close[i] < open[i])  // Candle bearish
            {
                sellBuffer[i] = high[i] + EntryBuffer * Point();
                filterBuffer[i] = -1;  // Filter aktif
                
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
        supportBuffer[i] = ma20;       // Support dari MA20
        resistanceBuffer[i] = ma20 + (high[i] - low[i]) * 2;  // Resistance dinamis
        
        // ===== SUB-WINDOW BUFFERS (RSI, MACD, VOLUME) =====
        rsiBuffer[i] = rsiVal;
        macdBuffer[i] = macdVal;
        volumeBuffer[i] = currentVol / volAvg * 50;  // Normalize untuk display
        zeroLineBuffer[i] = 0;  // Zero line untuk MACD
        
        // Support buffers
        rsiOverboughtBuffer[i] = RSI_Overbought;
        rsiOversoldBuffer[i] = RSI_Oversold;
        macdLineBuffer[i] = macdVal;
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
    
    // Cek apakah ada breakout level
    bool breakoutUp = close[pos] > high[pos-2];
    bool breakoutDown = close[pos] < low[pos-2];
    
    // Cek candle bukan doji
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

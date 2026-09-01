//+------------------------------------------------------------------+
//| Sniper SubWindow M15 - RSI MACD VOLUME                            |
//| Target: 100-400 Point | Timeframe: M15                           |
//| Pair: XAUUSD3 (Gold) | Strategy: High Accuracy Entry/Exit       |
//+------------------------------------------------------------------+
#property copyright "Ahmad Sniper Trading"
#property link      "https://github.com/Ahmad112005"
#property version   "2.00"
#property strict

#property indicator_separate_window
#property indicator_buffers 8
#property indicator_plots 8

// SUB-WINDOW PLOTS
#property indicator_label1  "RSI Line"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrCyan
#property indicator_width1  2

#property indicator_label2  "RSI Overbought"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrRed
#property indicator_width2  1
#property indicator_style2  STYLE_SOLID

#property indicator_label3  "RSI Oversold"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrGreen
#property indicator_width3  1
#property indicator_style3  STYLE_SOLID

#property indicator_label4  "MACD Line"
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrYellow
#property indicator_width4  2

#property indicator_label5  "MACD Histogram"
#property indicator_type5   DRAW_HISTOGRAM
#property indicator_color5  clrMagenta
#property indicator_width5  2

#property indicator_label6  "Volume Signal"
#property indicator_type6   DRAW_HISTOGRAM
#property indicator_color6  clrDodgerBlue
#property indicator_width6  2

#property indicator_label7  "Zero Line"
#property indicator_type7   DRAW_LINE
#property indicator_color7  clrWhite
#property indicator_width7  1

#property indicator_label8  "Middle Line (50)"
#property indicator_type8   DRAW_LINE
#property indicator_color8  clrGray
#property indicator_width8  1
#property indicator_style8  STYLE_DOT

// BUFFERS DEKLARASI
double rsiBuffer[];
double rsiOverboughtBuffer[];
double rsiOversoldBuffer[];
double macdLineBuffer[];
double macdHistogramBuffer[];
double volumeBuffer[];
double zeroLineBuffer[];
double middleLineBuffer[];

// PARAMETER INPUT
input int RSI_Period = 14;
input int MACD_FastEMA = 12;
input int MACD_SlowEMA = 26;
input int MACD_Signal = 9;
input int MA_Period = 20;
input double RSI_Overbought = 70;
input double RSI_Oversold = 30;

//+------------------------------------------------------------------+
// FUNGSI INISIALISASI
//+------------------------------------------------------------------+
int OnInit()
{
    SetIndexBuffer(0, rsiBuffer, INDICATOR_DATA);
    SetIndexBuffer(1, rsiOverboughtBuffer, INDICATOR_DATA);
    SetIndexBuffer(2, rsiOversoldBuffer, INDICATOR_DATA);
    SetIndexBuffer(3, macdLineBuffer, INDICATOR_DATA);
    SetIndexBuffer(4, macdHistogramBuffer, INDICATOR_DATA);
    SetIndexBuffer(5, volumeBuffer, INDICATOR_DATA);
    SetIndexBuffer(6, zeroLineBuffer, INDICATOR_DATA);
    SetIndexBuffer(7, middleLineBuffer, INDICATOR_DATA);
    
    IndicatorSetString(INDICATOR_SHORTNAME, "Sniper SubWindow (RSI/MACD/Volume)");
    IndicatorSetInteger(INDICATOR_HEIGHT, 250);
    
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
        // Reset buffers
        rsiBuffer[i] = EMPTY_VALUE;
        rsiOverboughtBuffer[i] = EMPTY_VALUE;
        rsiOversoldBuffer[i] = EMPTY_VALUE;
        macdLineBuffer[i] = EMPTY_VALUE;
        macdHistogramBuffer[i] = EMPTY_VALUE;
        volumeBuffer[i] = EMPTY_VALUE;
        zeroLineBuffer[i] = EMPTY_VALUE;
        middleLineBuffer[i] = EMPTY_VALUE;
        
        if(i < 50) 
        {
            zeroLineBuffer[i] = 0;
            middleLineBuffer[i] = 50;
            rsiOverboughtBuffer[i] = RSI_Overbought;
            rsiOversoldBuffer[i] = RSI_Oversold;
            continue;
        }
        
        // ===== HITUNG INDIKATOR =====
        double rsiVal = CalculateRSI(close, i, RSI_Period);
        double macdVal = CalculateMACD(close, i, MACD_FastEMA, MACD_SlowEMA, MACD_Signal);
        double volAvg = CalculateVolumeAverage(tick_volume, i, 20);
        double currentVol = (double)tick_volume[i];
        
        // ===== RSI BUFFER =====
        rsiBuffer[i] = rsiVal;
        rsiOverboughtBuffer[i] = RSI_Overbought;
        rsiOversoldBuffer[i] = RSI_Oversold;
        
        // ===== MACD BUFFERS =====
        macdLineBuffer[i] = macdVal;
        macdHistogramBuffer[i] = macdVal;
        
        // ===== VOLUME BUFFER =====
        volumeBuffer[i] = currentVol / volAvg * 50;
        
        // ===== ZERO & MIDDLE LINES =====
        zeroLineBuffer[i] = 0;
        middleLineBuffer[i] = 50;
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
// FUNGSI DEINIT
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
}

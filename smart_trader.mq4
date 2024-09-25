//+------------------------------------------------------------------+
//|                                                 smart_trader.mq4 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

// ------------------------------------------------------------------

// ------------------------------------------------------------------

interface IIndicatorData { };

class IchimokuIndicatorData : public IIndicatorData {
  public:
    double tenkanSen;
    double kijunSen;
    double senkouSpanA;
    double senkouSpanB;
    double chikouSpan;
};

class RSIIndicatorData : public IIndicatorData {
  public:
    double rsiValue;
};

class MACDIndicatorData : public IIndicatorData {
  public:
    double macdValue;
    double signalValue;
    double macdHistValue;
};

class MAIndicatorData : public IIndicatorData {
  public:
    double maValue;
};

class BBIndicatorData : public IIndicatorData {
  public:
    double upperValue;
    double middleValue;
    double lowerValue;
};

class VolumeIndicatorData : public IIndicatorData {
  public:
    long volume;
    long avgVolume;
};
// ------------------------------------------------------------------

class Indicator {
  protected:
    IIndicatorData* data[];

    virtual IIndicatorData* calcValue(int shift) = 0;

    void cleanData() {
      for (int i = 0; i < ArraySize(data); ++i) {
        if (data[i] != NULL) {
          delete data[i];
          data[i] = NULL;
        }
      }
    }
  public:
    void collectData(int period) {
      cleanData();

      if (period < 0) ArrayResize(data, 1);
      else ArrayResize(data, period + 1);

      for (int i = 0; i < ArraySize(data); ++i) data[i] = calcValue(i);
    }

    IIndicatorData* getData(int shift) {
      if (shift >= 0 && shift < ArraySize(data)) return data[shift];
      else return NULL;
    }

    ~Indicator() {
      cleanData();
    }
};

class IchimokuIndicator : public Indicator {
  private:
    int tenkanSenPeriod;
    int kijunSenPeriod;
    int senkouSpanBPeriod;
  protected:
    IIndicatorData* calcValue(int shift) {
      IchimokuIndicatorData* d = new IchimokuIndicatorData();
      d.tenkanSen = iIchimoku(NULL, 0, tenkanSenPeriod, kijunSenPeriod, senkouSpanBPeriod, MODE_TENKANSEN, shift);
      d.kijunSen = iIchimoku(NULL, 0, tenkanSenPeriod, kijunSenPeriod, senkouSpanBPeriod, MODE_KIJUNSEN, shift);
      d.senkouSpanA = iIchimoku(NULL, 0, tenkanSenPeriod, kijunSenPeriod, senkouSpanBPeriod, MODE_SENKOUSPANA, shift);
      d.senkouSpanB = iIchimoku(NULL, 0, tenkanSenPeriod, kijunSenPeriod, senkouSpanBPeriod, MODE_SENKOUSPANB, shift);
      d.chikouSpan = iIchimoku(NULL, 0, tenkanSenPeriod, kijunSenPeriod, senkouSpanBPeriod, MODE_CHIKOUSPAN, shift + kijunSenPeriod);
      return d;
    }
  public:
    IchimokuIndicator(int _tenkanSenPeriod, int _kijunSenPeriod, int _senkouSpanBPeriod) {
      this.tenkanSenPeriod = _tenkanSenPeriod;
      this.kijunSenPeriod = _kijunSenPeriod;
      this.senkouSpanBPeriod = _senkouSpanBPeriod;
    }
};

class RSIIndicator : public Indicator {
  private:
    int period;
    ENUM_APPLIED_PRICE appliedPrice;
  protected:
    IIndicatorData* calcValue(int shift) {
      RSIIndicatorData* d = new RSIIndicatorData();
      d.rsiValue = iRSI(NULL, 0, period, appliedPrice, shift);
      return d;
    }
  public:
    RSIIndicator(int _period, ENUM_APPLIED_PRICE _appliedPrice) {
      this.period = _period;
      this.appliedPrice = _appliedPrice;
    }
};

class MACDIndicator : public Indicator {
  private:
    int fastEMAPeriod;
    int slowEMAPeriod;
    int signalPeriod;
    ENUM_APPLIED_PRICE appliedPrice;
  protected:
    IIndicatorData* calcValue(int shift) {
      MACDIndicatorData* d = new MACDIndicatorData();
      d.macdValue = iMACD(NULL, 0, fastEMAPeriod, slowEMAPeriod, signalPeriod, appliedPrice, MODE_MAIN, shift);
      d.signalValue = iMACD(NULL, 0, fastEMAPeriod, slowEMAPeriod, signalPeriod, appliedPrice, MODE_SIGNAL, shift);
      d.macdHistValue = d.macdValue - d.signalValue;
      return d;
    }
  public:
    MACDIndicator(int _fastEMAPeriod, int _slowEMAPeriod, int _signalPeriod, ENUM_APPLIED_PRICE _appliedPrice) {
      this.fastEMAPeriod = _fastEMAPeriod;
      this.slowEMAPeriod = _slowEMAPeriod;
      this.signalPeriod = _signalPeriod;
      this.appliedPrice = _appliedPrice;
    }
};

class MAIndicator : public Indicator {
  private:
    int maPeriod;
    int maShift;
    ENUM_MA_METHOD maMethod;
    ENUM_APPLIED_PRICE appliedPrice;
  protected:
    IIndicatorData* calcValue(int shift) {
      MAIndicatorData* d = new MAIndicatorData();
      d.maValue = iMA(NULL, 0, maPeriod, maShift, maMethod, appliedPrice, shift);
      return d;
    }
  public:
    MAIndicator(int _maPeriod, ENUM_MA_METHOD _maMethod, ENUM_APPLIED_PRICE _appliedPrice) {
      this.maPeriod = _maPeriod;
      this.maShift = 0;
      this.maMethod = _maMethod;
      this.appliedPrice = _appliedPrice;
    }
};

class BBIndicator : public Indicator {
  private:
    int period;
    double deviation;
    int bandsShift;
    ENUM_APPLIED_PRICE appliedPrice;
  protected:
    IIndicatorData* calcValue(int shift) {
      BBIndicatorData* d = new BBIndicatorData();
      d.upperValue = iBands(NULL, 0, period, deviation, bandsShift, appliedPrice, MODE_UPPER, shift);
      d.middleValue = iBands(NULL, 0, period, deviation, bandsShift, appliedPrice, MODE_MAIN, shift);
      d.lowerValue = iBands(NULL, 0, period, deviation, bandsShift, appliedPrice, MODE_LOWER, shift);
      return d;
    }
  public:
    BBIndicator(int _period, ENUM_APPLIED_PRICE _appliedPrice) {
      this.period = _period;
      this.deviation = 2.0;
      this.bandsShift = 0;
      this.appliedPrice = _appliedPrice;
    }
};

class VolumeIndicator : public Indicator {
  private:
    int period;
  protected:
    IIndicatorData* calcValue(int shift) {
      long totalVolume = 0;
      for (int i = 0; i < period; ++i) {
        totalVolume += iVolume(NULL, 0, shift + i);
      }

      VolumeIndicatorData* d = new VolumeIndicatorData();
      d.volume = iVolume(NULL, 0, shift);
      d.avgVolume = totalVolume / period;
      return d;
    }
  public:
    VolumeIndicator(int _period) {
      this.period = _period;
    }
};
// ------------------------------------------------------------------

class IndicatorDataCollector {
  public:
    void collectData(Indicator& indicator, int period = 0) const {
      indicator.collectData(period);
    }
    IIndicatorData* getData(Indicator& indicator, int shift = 0) const {
      return indicator.getData(shift);
    }
};
// ------------------------------------------------------------------

class AlgoTrader {

};
// ------------------------------------------------------------------

const IndicatorDataCollector collector;

IchimokuIndicator ichimoku1(9, 17, 26);
IchimokuIndicator ichimoku2(65, 129, 52);

RSIIndicator rsi(14, PRICE_CLOSE);

MACDIndicator macd(12, 26, 9, PRICE_CLOSE);

MAIndicator ma14(14, MODE_SMA, PRICE_CLOSE);

BBIndicator bb(20, PRICE_CLOSE);

VolumeIndicator v(20);

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
//--- create timer
  EventSetTimer(60);

//---
  return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
//--- destroy timer
  EventKillTimer();

}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
  collector.collectData(ichimoku1);
  collector.collectData(ichimoku2);
  collector.collectData(rsi);
  collector.collectData(macd);
  collector.collectData(ma14);
  collector.collectData(bb);
  collector.collectData(v);

  IchimokuIndicatorData* d1 = collector.getData(ichimoku1);
  IchimokuIndicatorData* d2 = collector.getData(ichimoku2);
  Print("Tenkan-sen: ", d1.tenkanSen, " | ", d2.tenkanSen);
  Print("Kijun-sen: ", d1.kijunSen, " | ", d2.kijunSen);
  Print("Senkou Span A: ", d1.senkouSpanA, " | ", d2.senkouSpanA);
  Print("Senkou Span B: ", d1.senkouSpanB, " | ", d2.senkouSpanB);
  Print("Chikou Span: ", d1.chikouSpan, " | ", d2.chikouSpan);

  RSIIndicatorData* d3 = collector.getData(rsi);
  Print("RSI: ", d3.rsiValue);

  MACDIndicatorData* d4 = collector.getData(macd);
  Print("MACD: ", d4.macdValue, " | ", d4.signalValue, " | ", d4.macdHistValue);

  MAIndicatorData* d5 = collector.getData(ma14);
  Print("MA: ", d5.maValue);

  BBIndicatorData* d6 = collector.getData(bb);
  Print("BB: ", d6.upperValue, " | ", d6.middleValue, " | ", d6.lowerValue);

  VolumeIndicatorData* d7 = collector.getData(v);
  Print("Volume: ", d7.volume, " | ", d7.avgVolume);
}

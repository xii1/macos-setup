//+------------------------------------------------------------------+
//|                                                         test.mq4 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

// ------------------------------------------------------------------
// INDICATOR DATA

interface IIndicatorData { };

// =====================================

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

class SARIndicatorData : public IIndicatorData {
  public:
    double sarValue;
};

// ------------------------------------------------------------------
// INDICATORS

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
    ~Indicator() {
      cleanData();
    }

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
};

// =====================================

class IchimokuIndicator : public Indicator {
  private:
    int tenkanSenPeriod;
    int kijunSenPeriod;
    int senkouSpanBPeriod;
    int timeframe;
  protected:
    IIndicatorData* calcValue(int shift) {
      IchimokuIndicatorData* d = new IchimokuIndicatorData();
      d.tenkanSen = iIchimoku(NULL, timeframe, tenkanSenPeriod, kijunSenPeriod, senkouSpanBPeriod, MODE_TENKANSEN, shift);
      d.kijunSen = iIchimoku(NULL, timeframe, tenkanSenPeriod, kijunSenPeriod, senkouSpanBPeriod, MODE_KIJUNSEN, shift);
      d.senkouSpanA = iIchimoku(NULL, timeframe, tenkanSenPeriod, kijunSenPeriod, senkouSpanBPeriod, MODE_SENKOUSPANA, shift);
      d.senkouSpanB = iIchimoku(NULL, timeframe, tenkanSenPeriod, kijunSenPeriod, senkouSpanBPeriod, MODE_SENKOUSPANB, shift);
      d.chikouSpan = iIchimoku(NULL, timeframe, tenkanSenPeriod, kijunSenPeriod, senkouSpanBPeriod, MODE_CHIKOUSPAN, shift + kijunSenPeriod);
      return d;
    }
  public:
    IchimokuIndicator(int _tenkanSenPeriod, int _kijunSenPeriod, int _senkouSpanBPeriod, int _timeframe = PERIOD_CURRENT) {
      this.tenkanSenPeriod = _tenkanSenPeriod;
      this.kijunSenPeriod = _kijunSenPeriod;
      this.senkouSpanBPeriod = _senkouSpanBPeriod;
      this.timeframe = _timeframe;
    }
};

class RSIIndicator : public Indicator {
  private:
    int period;
    int timeframe;
    ENUM_APPLIED_PRICE appliedPrice;
  protected:
    IIndicatorData* calcValue(int shift) {
      RSIIndicatorData* d = new RSIIndicatorData();
      d.rsiValue = iRSI(NULL, timeframe, period, appliedPrice, shift);
      return d;
    }
  public:
    RSIIndicator(int _period, int _timeframe = PERIOD_CURRENT, ENUM_APPLIED_PRICE _appliedPrice = PRICE_CLOSE) {
      this.period = _period;
      this.timeframe = timeframe;
      this.appliedPrice = _appliedPrice;
    }
};

class MACDIndicator : public Indicator {
  private:
    int fastEMAPeriod;
    int slowEMAPeriod;
    int signalPeriod;
    int timeframe;
    ENUM_APPLIED_PRICE appliedPrice;
  protected:
    IIndicatorData* calcValue(int shift) {
      MACDIndicatorData* d = new MACDIndicatorData();
      d.macdValue = iMACD(NULL, timeframe, fastEMAPeriod, slowEMAPeriod, signalPeriod, appliedPrice, MODE_MAIN, shift);
      d.signalValue = iMACD(NULL, timeframe, fastEMAPeriod, slowEMAPeriod, signalPeriod, appliedPrice, MODE_SIGNAL, shift);
      d.macdHistValue = d.macdValue - d.signalValue;
      return d;
    }
  public:
    MACDIndicator(int _fastEMAPeriod, int _slowEMAPeriod, int _signalPeriod, int _timeframe = PERIOD_CURRENT, ENUM_APPLIED_PRICE _appliedPrice = PRICE_CLOSE) {
      this.fastEMAPeriod = _fastEMAPeriod;
      this.slowEMAPeriod = _slowEMAPeriod;
      this.signalPeriod = _signalPeriod;
      this.appliedPrice = _appliedPrice;
      this.timeframe = _timeframe;
      this.appliedPrice = _appliedPrice;
    }
};

class MAIndicator : public Indicator {
  private:
    int maPeriod;
    int maShift;
    ENUM_MA_METHOD maMethod;
    int timeframe;
    ENUM_APPLIED_PRICE appliedPrice;
  protected:
    IIndicatorData* calcValue(int shift) {
      MAIndicatorData* d = new MAIndicatorData();
      d.maValue = iMA(NULL, timeframe, maPeriod, maShift, maMethod, appliedPrice, shift);
      return d;
    }
  public:
    MAIndicator(int _maPeriod, ENUM_MA_METHOD _maMethod, int _timeframe = PERIOD_CURRENT, ENUM_APPLIED_PRICE _appliedPrice = PRICE_CLOSE) {
      this.maPeriod = _maPeriod;
      this.maShift = 0;
      this.maMethod = _maMethod;
      this.timeframe = _timeframe;
      this.appliedPrice = _appliedPrice;
    }
};

class BBIndicator : public Indicator {
  private:
    int period;
    double deviation;
    int bandsShift;
    int timeframe;
    ENUM_APPLIED_PRICE appliedPrice;
  protected:
    IIndicatorData* calcValue(int shift) {
      BBIndicatorData* d = new BBIndicatorData();
      d.upperValue = iBands(NULL, timeframe, period, deviation, bandsShift, appliedPrice, MODE_UPPER, shift);
      d.middleValue = iBands(NULL, timeframe, period, deviation, bandsShift, appliedPrice, MODE_MAIN, shift);
      d.lowerValue = iBands(NULL, timeframe, period, deviation, bandsShift, appliedPrice, MODE_LOWER, shift);
      return d;
    }
  public:
    BBIndicator(int _period, int _timeframe = PERIOD_CURRENT, ENUM_APPLIED_PRICE _appliedPrice = PRICE_CLOSE) {
      this.period = _period;
      this.deviation = 2.0;
      this.bandsShift = 0;
      this.timeframe = _timeframe;
      this.appliedPrice = _appliedPrice;
    }
};

class VolumeIndicator : public Indicator {
  private:
    int period;
    int timeframe;
  protected:
    IIndicatorData* calcValue(int shift) {
      long totalVolume = 0;
      for (int i = 0; i < period; ++i) {
        totalVolume += iVolume(NULL, 0, shift + i);
      }

      VolumeIndicatorData* d = new VolumeIndicatorData();
      d.volume = iVolume(NULL, timeframe, shift);
      d.avgVolume = totalVolume / period;
      return d;
    }
  public:
    VolumeIndicator(int _period, int _timeframe = PERIOD_CURRENT) {
      this.period = _period;
      this.timeframe = _timeframe;
    }
};

class SARIndicator : public Indicator {
  private:
    double step;
    double maximum;
    int timeframe;
  protected:
    IIndicatorData* calcValue(int shift) {
      SARIndicatorData* d = new SARIndicatorData();
      d.sarValue = iSAR(NULL, timeframe, step, maximum, shift);
      return d;
    }
  public:
    SARIndicator(double _step, double _maximum, int _timeframe = PERIOD_CURRENT) {
      this.step = _step;
      this.maximum = _maximum;
      this.timeframe = _timeframe;
    }
};

// ------------------------------------------------------------------
// DATA COLLECTOR

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
// COMMON SETTINGS

#define TO_POINTS(p) (p) * 10 * Point
#define SLOT_SIZE 0.1
#define BUY_PRICE Ask
#define SELL_PRICE Bid
#define STOP_LOSS_PIPS 10
#define TAKE_PROFIT_PIPS 150
#define TRAILING_PIPS 15

// ------------------------------------------------------------------
// INDICATOR SETTINGS

#define SAR_STEP 0.02
#define SAR_MAXIMUM 0.2

#define ICHIMOKU1_TENKANSEN_PERIOD 9
#define ICHIMOKU1_KIJUNSEN_PERIOD 17
#define ICHIMOKU1_SENKOUSPAN_PERIOD 26

#define ICHIMOKU2_TENKANSEN_PERIOD 65
#define ICHIMOKU2_KIJUNSEN_PERIOD 129
#define ICHIMOKU2_SENKOUSPAN_PERIOD 52

#define MACD_FAST_EMA_PERIOD 12
#define MACD_SLOW_EMA_PERIOD 26
#define MACD_SIGNAL_PERIOD 9

#define RSI_PERIOD 14

// ------------------------------------------------------------------
// TREND DECTECTORS

enum Trend { UNDETERMINED = -1, DOWN = 0, SIDEWAY = 1, UP = 2 };

class TrendDetector {
  protected:
    IndicatorDataCollector collector;
  public:
    virtual void collectData(int shift = 0) = 0;
    virtual Trend getTrend(int shift = 0) = 0;
    virtual double getStrongSupport(int shift = 0) = 0;
    virtual double getStrongResistance(int shift = 0) = 0;
    virtual double getWeakSupport(int shift = 0) = 0;
    virtual double getWeakResistance(int shift = 0) = 0;
};

// =====================================

class BasicTrendDetector : public TrendDetector {
  private:
    int timeframe;
    IchimokuIndicator icmk1;
    IchimokuIndicator icmk2;
    MAIndicator ema50;
    MAIndicator ema200;

    bool isUpTrend(
      double prevClosePrice, double currentPrice,
      double prevTenkanSen2, double currentTenkanSen2,
      double prevKijunSen2, double currentKijunSen2,
      double prevSenkouSpanA, double currentSenkouSpanA,
      double prevSenkouSpanB, double currentSenkouSpanB,
      double prevTenkanSen1, double currentTenkanSen1,
      double prevKijunSen1, double currentKijunSen1,
      double prevEMA50, double currentEMA50,
      double prevEMA200, double currentEMA200) {

      bool prevClosePriceCondition = (prevClosePrice >= prevTenkanSen2) && (prevClosePrice >= prevKijunSen2)
                                     && (prevClosePrice >= prevSenkouSpanA) && (prevClosePrice >= prevSenkouSpanB)
                                     && (prevClosePrice >= prevTenkanSen1) && (prevClosePrice >= prevKijunSen1)
                                     && (prevClosePrice >= prevEMA200) && (prevEMA50 >= prevEMA200);

      bool currentPriceCondition = (currentPrice > currentTenkanSen2) && (currentPrice > currentKijunSen2)
                                     && (currentPrice > currentSenkouSpanA) && (currentPrice > currentSenkouSpanB)
                                     && (currentPrice > currentTenkanSen1) && (currentPrice > currentKijunSen1)
                                     && (currentPrice > currentEMA200) && (currentEMA50 > currentEMA200);

      return prevClosePriceCondition && currentPriceCondition;
    }

    bool isDownTrend(
      double prevClosePrice, double currentPrice,
      double prevTenkanSen2, double currentTenkanSen2,
      double prevKijunSen2, double currentKijunSen2,
      double prevSenkouSpanA, double currentSenkouSpanA,
      double prevSenkouSpanB, double currentSenkouSpanB,
      double prevTenkanSen1, double currentTenkanSen1,
      double prevKijunSen1, double currentKijunSen1,
      double prevEMA50, double currentEMA50,
      double prevEMA200, double currentEMA200) {

      bool prevClosePriceCondition = (prevClosePrice <= prevTenkanSen2) && (prevClosePrice <= prevKijunSen2)
                                     && (prevClosePrice <= prevSenkouSpanA) && (prevClosePrice <= prevSenkouSpanB)
                                     && (prevClosePrice <= prevTenkanSen1) && (prevClosePrice <= prevKijunSen1)
                                     && (prevClosePrice <= prevEMA200) && (prevEMA50 <= prevEMA200);

      bool currentPriceCondition = (currentPrice < currentTenkanSen2) && (currentPrice < currentKijunSen2)
                                     && (currentPrice < currentSenkouSpanA) && (currentPrice < currentSenkouSpanB)
                                     && (currentPrice < currentTenkanSen1) && (currentPrice < currentKijunSen1)
                                     && (currentPrice < currentEMA200) && (currentEMA50 < currentEMA200);

      return prevClosePriceCondition && currentPriceCondition;
    }
  public:
    BasicTrendDetector(int _timeframe = PERIOD_CURRENT) : timeframe(_timeframe),
      icmk1(ICHIMOKU1_TENKANSEN_PERIOD, ICHIMOKU1_KIJUNSEN_PERIOD, ICHIMOKU1_SENKOUSPAN_PERIOD, _timeframe),
      icmk2(ICHIMOKU2_TENKANSEN_PERIOD, ICHIMOKU2_KIJUNSEN_PERIOD, ICHIMOKU2_SENKOUSPAN_PERIOD, _timeframe),
      ema50(50, MODE_EMA, _timeframe), ema200(200, MODE_EMA, _timeframe) {}

    void collectData(int shift = 0) {
      collector.collectData(icmk1, shift + 1);
      collector.collectData(icmk2, shift + 1);
      collector.collectData(ema50, shift + 1);
      collector.collectData(ema200, shift + 1);
    }

    Trend getTrend(int shift = 0) {
      double prevClosePrice = iClose(NULL, timeframe, shift + 1);
      double currentPrice = iClose(NULL, timeframe, shift);

      double prevTenkanSen2 = ((IchimokuIndicatorData*)collector.getData(icmk2, shift + 1)).tenkanSen;
      double currentTenkanSen2 = ((IchimokuIndicatorData*)collector.getData(icmk2, shift)).tenkanSen;

      double prevKijunSen2 = ((IchimokuIndicatorData*)collector.getData(icmk2, shift + 1)).kijunSen;
      double currentKijunSen2 = ((IchimokuIndicatorData*)collector.getData(icmk2, shift)).kijunSen;

      double prevSenkouSpanA = ((IchimokuIndicatorData*)collector.getData(icmk1, shift + 1)).senkouSpanA;
      double currentSenkouSpanA = ((IchimokuIndicatorData*)collector.getData(icmk1, shift)).senkouSpanA;

      double prevSenkouSpanB = ((IchimokuIndicatorData*)collector.getData(icmk1, shift + 1)).senkouSpanB;
      double currentSenkouSpanB = ((IchimokuIndicatorData*)collector.getData(icmk1, shift)).senkouSpanB;

      double prevTenkanSen1 = ((IchimokuIndicatorData*)collector.getData(icmk1, shift + 1)).tenkanSen;
      double currentTenkanSen1 = ((IchimokuIndicatorData*)collector.getData(icmk1, shift)).tenkanSen;

      double prevKijunSen1 = ((IchimokuIndicatorData*)collector.getData(icmk1, shift + 1)).kijunSen;
      double currentKijunSen1 = ((IchimokuIndicatorData*)collector.getData(icmk1, shift)).kijunSen;

      double prevEMA50 = ((MAIndicatorData*)collector.getData(ema50, shift + 1)).maValue;
      double currentEMA50 = ((MAIndicatorData*)collector.getData(ema50, shift)).maValue;

      double prevEMA200 = ((MAIndicatorData*)collector.getData(ema200, shift + 1)).maValue;
      double currentEMA200 = ((MAIndicatorData*)collector.getData(ema200, shift)).maValue;

      if (isUpTrend(prevClosePrice, currentPrice, prevTenkanSen2, currentTenkanSen2, prevKijunSen2, currentKijunSen2,
                    prevSenkouSpanA, currentSenkouSpanA, prevSenkouSpanB, currentSenkouSpanB,
                    prevTenkanSen1, currentTenkanSen1, prevKijunSen1, currentKijunSen1,
                    prevEMA50, currentEMA50, prevEMA200, currentEMA200)) {
        return UP;
      } else if (isDownTrend(prevClosePrice, currentPrice, prevTenkanSen2, currentTenkanSen2, prevKijunSen2, currentKijunSen2,
                           prevSenkouSpanA, currentSenkouSpanA, prevSenkouSpanB, currentSenkouSpanB,
                           prevTenkanSen1, currentTenkanSen1, prevKijunSen1, currentKijunSen1,
                           prevEMA50, currentEMA50, prevEMA200, currentEMA200)) {
        return DOWN;
      } else {
        return SIDEWAY;
      }
    }

    double getStrongSupport(int shift = 0) {
      double currentPrice = iClose(NULL, timeframe, shift);
      double currentTenkanSen2 = ((IchimokuIndicatorData*)collector.getData(icmk2, shift)).tenkanSen;
      double currentKijunSen2 = ((IchimokuIndicatorData*)collector.getData(icmk2, shift)).kijunSen;

      double min = MathMin(currentTenkanSen2, currentKijunSen2);

      if (currentPrice >= min) return min;
      else return -1;
    }

    double getStrongResistance(int shift = 0) {
      double currentPrice = iClose(NULL, timeframe, shift);
      double currentTenkanSen2 = ((IchimokuIndicatorData*)collector.getData(icmk2, shift)).tenkanSen;
      double currentKijunSen2 = ((IchimokuIndicatorData*)collector.getData(icmk2, shift)).kijunSen;

      double max = MathMax(currentTenkanSen2, currentKijunSen2);

      if (currentPrice <= max) return max;
      else return -1;
    }

    double getWeakSupport(int shift = 0) {
      double currentPrice = iClose(NULL, timeframe, shift);
      double currentTenkanSen1 = ((IchimokuIndicatorData*)collector.getData(icmk1, shift)).tenkanSen;
      double currentKijunSen1 = ((IchimokuIndicatorData*)collector.getData(icmk1, shift)).kijunSen;

      double min = MathMin(currentTenkanSen1, currentKijunSen1);

      if (currentPrice >= min) return min;
      else return -1;
    }

    double getWeakResistance(int shift = 0) {
      double currentPrice = iClose(NULL, timeframe, shift);
      double currentTenkanSen1 = ((IchimokuIndicatorData*)collector.getData(icmk1, shift)).tenkanSen;
      double currentKijunSen1 = ((IchimokuIndicatorData*)collector.getData(icmk1, shift)).kijunSen;

      double max = MathMax(currentTenkanSen1, currentKijunSen1);

      if (currentPrice <= max) return max;
      else return -1;
    }
};

// ------------------------------------------------------------------
// SIGNAL DECTECTORS

class SignalDetector {
  protected:
    IndicatorDataCollector collector;
  public:
    virtual void collectData() = 0;
    virtual bool isBuySignal() = 0;
    virtual bool isSellSignal() = 0;
};

// =====================================

class DefaultSignalDetector : public SignalDetector {
  private:
    BasicTrendDetector cTrend;
    BasicTrendDetector h1Trend;
    BasicTrendDetector d1Trend;
    BasicTrendDetector w1Trend;
  public:
    DefaultSignalDetector() : cTrend(PERIOD_CURRENT), h1Trend(PERIOD_H1), d1Trend(PERIOD_D1), w1Trend(PERIOD_W1) {}

    void collectData() {
      cTrend.collectData(1);
      h1Trend.collectData(1);
      d1Trend.collectData(1);
      w1Trend.collectData(1);

      Print(">>>>> Before: ", cTrend.getTrend(1), " | ", cTrend.getStrongSupport(1), " | ", cTrend.getStrongResistance(1), " | ", cTrend.getWeakSupport(1), " | ", cTrend.getWeakResistance(1));
      Print(">>>>> Current: ", cTrend.getTrend(), " | ", cTrend.getStrongSupport(), " | ", cTrend.getStrongResistance(), " | ", cTrend.getWeakSupport(), " | ", cTrend.getWeakResistance());
      Print(">>>>> Before H1: ", h1Trend.getTrend(1), " | ", h1Trend.getStrongSupport(1), " | ", h1Trend.getStrongResistance(1), " | ", h1Trend.getWeakSupport(1), " | ", h1Trend.getWeakResistance(1));
      Print(">>>>> Current H1: ", h1Trend.getTrend(), " | ", h1Trend.getStrongSupport(), " | ", h1Trend.getStrongResistance(), " | ", h1Trend.getWeakSupport(), " | ", h1Trend.getWeakResistance());
      Print(">>>>> Before D1: ", d1Trend.getTrend(1), " | ", d1Trend.getStrongSupport(1), " | ", d1Trend.getStrongResistance(1), " | ", d1Trend.getWeakSupport(1), " | ", d1Trend.getWeakResistance(1));
      Print(">>>>> Current D1: ", d1Trend.getTrend(), " | ", d1Trend.getStrongSupport(), " | ", d1Trend.getStrongResistance(), " | ", d1Trend.getWeakSupport(), " | ", d1Trend.getWeakResistance());
      Print(">>>>> Before W1: ", w1Trend.getTrend(1), " | ", w1Trend.getStrongSupport(1), " | ", w1Trend.getStrongResistance(1), " | ", w1Trend.getWeakSupport(1), " | ", w1Trend.getWeakResistance(1));
      Print(">>>>> Current W1: ", w1Trend.getTrend(), " | ", w1Trend.getStrongSupport(), " | ", w1Trend.getStrongResistance(), " | ", w1Trend.getWeakSupport(), " | ", w1Trend.getWeakResistance());

    }

    bool isBuySignal() {
      return false;
    }

    bool isSellSignal() {
      return false;
    }
};

class USDJPYSignalDetector : public SignalDetector {
  private:
    Trend tracking;
    BasicTrendDetector cTrend;
    BasicTrendDetector h1Trend;
    MACDIndicator macd;
    RSIIndicator rsi;
  public:
    USDJPYSignalDetector() : tracking(UNDETERMINED), cTrend(PERIOD_CURRENT), h1Trend(PERIOD_H1),
                             macd(MACD_FAST_EMA_PERIOD, MACD_SLOW_EMA_PERIOD, MACD_SIGNAL_PERIOD),
                             rsi(RSI_PERIOD) {
    }

    void collectData() {
      cTrend.collectData(1);
      h1Trend.collectData(1);
      collector.collectData(macd);
      collector.collectData(rsi);
    }

    bool isBuySignal() {
      if (tracking == UNDETERMINED) {
        tracking = cTrend.getTrend();
        return false;
      }

      Trend current = cTrend.getTrend();
      double macdHist = ((MACDIndicatorData*)collector.getData(macd)).macdHistValue;
      double rsiValue = ((RSIIndicatorData*)collector.getData(rsi)).rsiValue;

      bool condition = (tracking == SIDEWAY) && ((cTrend.getStrongSupport() + TO_POINTS(2) >= Close[0]) || (current == UP && macdHist > 0 && rsiValue > 50 && rsiValue < 70));
      tracking = current;

      return condition;
    }

    bool isSellSignal() {
      if (tracking == UNDETERMINED) {
        tracking = cTrend.getTrend();
        return false;
      }

      Trend current = cTrend.getTrend();
      double macdHist = ((MACDIndicatorData*)collector.getData(macd)).macdHistValue;
      double rsiValue = ((RSIIndicatorData*)collector.getData(rsi)).rsiValue;

      bool condition = (tracking == SIDEWAY) && ((cTrend.getStrongResistance() - TO_POINTS(2) <= Close[0]) && (current == DOWN && macdHist < 0 && rsiValue < 50 && rsiValue > 30));
      tracking = current;

      return condition;
    }
};

// ------------------------------------------------------------------
// ORDER & UTILITIES

class Order {
  public:
    string symbol;
    ENUM_ORDER_TYPE orderType;
    double lotSize;
    double price;
    int slippage;
    double stopLoss;
    double takeProfit;
    string comment;
    color lineColor;

    Order(string _symbol, ENUM_ORDER_TYPE _orderType, double _lotSize, double _price, int _slippage, double _stopLoss, double _takeProfit, string _comment, color _lineColor) {
      this.symbol = _symbol;
      this.orderType = _orderType;
      this.lotSize = _lotSize;
      this.price = _price;
      this.slippage = _slippage;
      this.stopLoss = _stopLoss;
      this.takeProfit = _takeProfit;
      this.comment = _comment;
      this.lineColor = _lineColor;
    }

    Order(Order& order) {
      this.symbol = order.symbol;
      this.orderType = order.orderType;
      this.lotSize = order.lotSize;
      this.price = order.price;
      this.slippage = order.slippage;
      this.stopLoss = order.stopLoss;
      this.takeProfit = order.takeProfit;
      this.comment = order.comment;
      this.lineColor = order.lineColor;
    }

    string info() {
      return comment + " lotSize=" + (string)lotSize + ", price=" + (string)price + ", stopLoss=" + (string)stopLoss + ", takeProfit=" + (string)takeProfit + ".";
    }
};

class OrderUtils {
  public:
    static Order createBuyOrder(double lotSize, double price, double slPips, double tpPips) {
      return Order(Symbol(), ORDER_TYPE_BUY, lotSize, price, 1, price - TO_POINTS(slPips), price + TO_POINTS(tpPips), "Buy " + Symbol(), clrGreen);
    }

    static Order createSellOrder(double lotSize, double price, double slPips, double tpPips) {
      return Order(Symbol(), ORDER_TYPE_SELL, lotSize, price, 1, price + TO_POINTS(slPips), price - TO_POINTS(tpPips), "Sell " + Symbol(), clrRed);
    }

    static int send(Order& order) {
      int ticket = OrderSend(order.symbol, order.orderType, order.lotSize, order.price, order.slippage, order.stopLoss, order.takeProfit, order.comment, 0, 0, order.lineColor);

      if (ticket < 0) {
        int errorCode = GetLastError();
        Alert("OrderSend failed with error code: ", errorCode, ". Order info: ", order.info());

        switch (errorCode) {
          case 130: Print("Error: Invalid stop levels."); break;
          case 131: Print("Error: Invalid lot size."); break;
          case 133: Print("Error: Market is closed."); break;
          case 134: Print("Error: Not enough money."); break;
          case 146: Print("Error: Trade context is busy."); break;
          default: Print("OrderSend failed with an unknown error.");
        }
        ResetLastError();

        Print("MODE_LOTSIZE = ", MarketInfo(Symbol(), MODE_LOTSIZE));
        Print("MODE_MINLOT = ", MarketInfo(Symbol(), MODE_MINLOT));
        Print("MODE_LOTSTEP = ", MarketInfo(Symbol(), MODE_LOTSTEP));
        Print("MODE_MAXLOT = ", MarketInfo(Symbol(), MODE_MAXLOT));
        Print("MODE_STOPLEVEL = ", MarketInfo(Symbol(), MODE_STOPLEVEL));
      } else {
        Alert("OrderSend successful! Ticket number: ", ticket, ". Order info: ", order.info());
      }

      return ticket;
    }

    static bool modify(int orderTicket, double orderOpenPrice, double stopLoss, double takeProfit) {
      bool result = OrderModify(orderTicket, orderOpenPrice, stopLoss, takeProfit, 0, clrBlue);
      if(!result) {
        Alert("OrderModify failed with error code: ", GetLastError(), ". Ticket number: ", orderTicket);
      } else {
        Alert("OrderModify successful! Ticket number: ", orderTicket);
      }
       return result;
    }

    static int countTotalOrders() {
      int count = 0;
      for (int i = 0; i < OrdersTotal(); ++i) {
        if (OrderSelect(i, SELECT_BY_POS) && OrderSymbol() == Symbol()) ++count;
      }
      return count;
    }

    static int countBuyOrders() {
      int count = 0;
      for (int i = 0; i < OrdersTotal(); ++i) {
        if (OrderSelect(i, SELECT_BY_POS) && OrderSymbol() == Symbol() && OrderType() == OP_BUY) ++count;
      }
      return count;
    }

    static int countSellOrders() {
      int count = 0;
      for (int i = 0; i < OrdersTotal(); ++i) {
        if (OrderSelect(i, SELECT_BY_POS) && OrderSymbol() == Symbol() && OrderType() == OP_SELL) ++count;
      }
      return count;
    }
};

// ------------------------------------------------------------------
// RISK MANAGERS

class RiskManager {
  public:
    virtual void execute() = 0;
};

class BasicRiskManager : public RiskManager {
  public:
    void execute() {
      for (int i = 0; i < OrdersTotal(); ++i) {
        if (OrderSelect(i, SELECT_BY_POS) && OrderSymbol() == Symbol()) {
          if (OrderType() == OP_BUY) {
            if (OrderStopLoss() < OrderOpenPrice()) {
              if (Close[0] - OrderOpenPrice() >= TO_POINTS(1.5 * TRAILING_PIPS)) {
                OrderUtils::modify(OrderTicket(), OrderOpenPrice(), Close[0] - TO_POINTS(TRAILING_PIPS), OrderTakeProfit());
                Print(">>> Modify buy");
              }
            } else {
              if (Close[0] - OrderStopLoss() >= TO_POINTS(1.5 * TRAILING_PIPS)) {
                OrderUtils::modify(OrderTicket(), OrderOpenPrice(), Close[0] - TO_POINTS(TRAILING_PIPS), OrderTakeProfit());
                Print(">>> Modify buy");
              }
            }
          } else if (OrderType() == OP_SELL) {
            if (OrderStopLoss() > OrderOpenPrice()) {
              if (OrderOpenPrice() - Close[0] >= TO_POINTS(1.5 * TRAILING_PIPS)) {
                OrderUtils::modify(OrderTicket(), OrderOpenPrice(), Close[0] + TO_POINTS(TRAILING_PIPS), OrderTakeProfit());
                Print(">>> Modify sell");
              }
            } else {
              if (OrderStopLoss() - Close[0] >= TO_POINTS(1.5 * TRAILING_PIPS)) {
                OrderUtils::modify(OrderTicket(), OrderOpenPrice(), Close[0] + TO_POINTS(TRAILING_PIPS), OrderTakeProfit());
                Print(">>> Modify sell");
              }
            }
          }
        }
      }
    }
};

// ------------------------------------------------------------------
// VALIDATORS

class Validator {
  public:
    virtual bool isAccept() = 0;
};

class LimitBuyOrderValidator : public Validator {
  public:
    bool isAccept() {
      return (OrderUtils::countBuyOrders() == 0);
    }
};

class LimitSellOrderValidator : public Validator {
  public:
    bool isAccept() {
      return (OrderUtils::countSellOrders() == 0);
    }
};

class LimitBuyPriceValidator : public Validator {
  public:
    bool isAccept() {
      return (Close[0] <= (MathMax(Close[1], Open[1]) - MathAbs(Close[1] - Open[1]) / 2));
    }
};

class LimitSellPriceValidator : public Validator {
  public:
    bool isAccept() {
      return (Close[0] >= (MathMin(Close[1], Open[1]) + MathAbs(Close[1] - Open[1]) / 2));
    }
};

// ------------------------------------------------------------------
// TRADER

class SmartTrader {
  private:
    SignalDetector* detector;
    RiskManager* riskManager;
  protected:
    void cleanUp() {
      if (detector != NULL) {
        delete detector;
        detector = NULL;
      }
    }
  public:
    ~SmartTrader() {
      cleanUp();
    }

    void useSignalDetector(string name) {
      cleanUp();

      if (name == "USDJPY") {
        detector = new USDJPYSignalDetector();
      } else {
        detector = new DefaultSignalDetector();
      }
    }

    void setRiskManager(RiskManager& _riskManager) {
      riskManager = &_riskManager;
    }

    void execute() {
      if (riskManager != NULL) riskManager.execute();
      if (detector == NULL) return;

      detector.collectData();

      LimitBuyOrderValidator bv;
      LimitBuyPriceValidator bv1;
      if (detector.isBuySignal()) {
        // if (bv.isAccept() && bv1.isAccept()) {
        if (bv.isAccept()) {
          OrderUtils::send(OrderUtils::createBuyOrder(SLOT_SIZE, BUY_PRICE, STOP_LOSS_PIPS, TAKE_PROFIT_PIPS));
        }
      } else {
        // Print(">>>>> NOT BUY");
      }

      LimitSellOrderValidator sv;
      LimitSellPriceValidator sv1;
      if (detector.isSellSignal()) {
        // if (sv.isAccept() && sv1.isAccept()) {
        if (sv.isAccept()) {
          OrderUtils::send(OrderUtils::createSellOrder(SLOT_SIZE, SELL_PRICE, STOP_LOSS_PIPS, TAKE_PROFIT_PIPS));
        }
      } else {
        // Print(">>>>> NOT SELL");
      }
    }
};

// ------------------------------------------------------------------
// GLOBAL VARIABLES

SmartTrader trader;
BasicRiskManager riskManager;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

int OnInit() {
//--- create timer
  EventSetTimer(60);
  trader.useSignalDetector("test");
  trader.setRiskManager(riskManager);
  Alert("Smart Trader has started for automatic trading ", Symbol(), " in timeframe ", Period(), " minutes.");
//---
  return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+

void OnDeinit(const int reason) {
//--- destroy timer
  Alert("Smart Trader has stopped for automatic trading ", Symbol(), " in timeframe ", Period(), " minutes.");
  EventKillTimer();
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+

void OnTick() {
  trader.execute();
}
